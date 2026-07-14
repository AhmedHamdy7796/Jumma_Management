import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/repositories/settings_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';
import 'package:gomaa_management/database/database_constants.dart';

/// Full snapshot zip-free directory backup of SQLite DB, settings and images.
class BackupService {
  static const _tag = 'BackupService';
  final DatabaseService _dbService;
  final SettingsRepository _settingsRepository;
  final AuditLogRepository _auditLogRepository;

  BackupService({
    DatabaseService? dbService,
    SettingsRepository? settingsRepository,
    AuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  /// Backup database, settings JSON and all images to a new timestamped folder.
  Future<String> createBackup(String destinationDir) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final backupFolderName = 'jumaa_backup_$timestamp';
      final backupDir = Directory(join(destinationDir, backupFolderName));
      await backupDir.create(recursive: true);

      // Save database file path
      final dbPath = await _dbService.databasePath;
      final dbFile = File(dbPath);

      // Close connection
      await _dbService.close();

      // Copy database
      if (dbFile.existsSync()) {
        await dbFile.copy(join(backupDir.path, 'gomaa_management.db'));
      }

      // Reopen connection to write manifest and setting snapshot
      await _dbService.reopen();

      // Export settings as a json file
      final settings = await _settingsRepository.getAllSettings();
      final settingsFile = File(join(backupDir.path, 'settings_export.json'));
      await settingsFile.writeAsString(jsonEncode(settings));

      // Copy images folder
      final appDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(join(appDir.path, 'images'));
      if (imagesDir.existsSync()) {
        await _copyDirectory(imagesDir, Directory(join(backupDir.path, 'images')));
      }

      // Write manifest
      final manifestFile = File(join(backupDir.path, 'backup_manifest.json'));
      final manifest = {
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'dbVersion': 7,
      };
      await manifestFile.writeAsString(jsonEncode(manifest));

      AppLogger.instance.info('Backup created successfully: ${backupDir.path}', tag: _tag);
      
      // Log audit
      await _auditLogRepository.log(
        operation: AuditOperation.backup,
        entityType: AuditEntityType.system,
        description: 'إنشاء نسخة احتياطية كاملة في المجلد: $backupFolderName',
      );

      return backupDir.path;
    } catch (e) {
      AppLogger.instance.error('Failed to create backup', tag: _tag, exception: e);
      // Ensure DB is open in case of failure mid-way
      try {
        await _dbService.reopen();
      } catch (_) {}
      throw BackupException(technicalDetail: e.toString());
    }
  }

  /// Restores complete app state from folder backup.
  Future<void> restoreBackup(String backupFolderPath) async {
    try {
      final backupDir = Directory(backupFolderPath);
      if (!backupDir.existsSync()) {
        throw const BackupException(technicalDetail: 'Backup folder does not exist');
      }

      final manifestFile = File(join(backupDir.path, 'backup_manifest.json'));
      if (!manifestFile.existsSync()) {
        throw const BackupException(technicalDetail: 'Invalid backup: missing manifest file');
      }

      final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      final dbVersion = manifest['dbVersion'] as int? ?? 0;
      if (dbVersion > 7) {
        throw const BackupException(technicalDetail: 'Database version in backup is newer than the app version');
      }

      // Close current DB
      await _dbService.close();

      // Copy database back
      final targetDbPath = await _dbService.databasePath;
      final sourceDbFile = File(join(backupDir.path, 'gomaa_management.db'));
      if (sourceDbFile.existsSync()) {
        await sourceDbFile.copy(targetDbPath);
      }

      // Copy images back
      final appDir = await getApplicationSupportDirectory();
      final targetImagesDir = Directory(join(appDir.path, 'images'));
      final sourceImagesDir = Directory(join(backupDir.path, 'images'));

      if (targetImagesDir.existsSync()) {
        await targetImagesDir.delete(recursive: true);
      }
      if (sourceImagesDir.existsSync()) {
        await _copyDirectory(sourceImagesDir, targetImagesDir);
      }

      // Reopen DB
      await _dbService.reopen();

      // Import settings
      final sourceSettingsFile = File(join(backupDir.path, 'settings_export.json'));
      if (sourceSettingsFile.existsSync()) {
        final settingsMap = Map<String, String>.from(
          jsonDecode(await sourceSettingsFile.readAsString()) as Map,
        );
        await _settingsRepository.setAllSettings(settingsMap);
      }

      AppLogger.instance.info('Backup restored successfully from: $backupFolderPath', tag: _tag);

      // Log audit
      await _auditLogRepository.log(
        operation: AuditOperation.restore,
        entityType: AuditEntityType.system,
        description: 'استعادة نسخة احتياطية كاملة من المجلد: ${basename(backupFolderPath)}',
      );
    } catch (e) {
      AppLogger.instance.error('Failed to restore backup', tag: _tag, exception: e);
      try {
        await _dbService.reopen();
      } catch (_) {}
      throw BackupException(technicalDetail: e.toString());
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(join(destination.path, basename(entity.path)));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        await entity.copy(join(destination.path, basename(entity.path)));
      }
    }
  }
}
