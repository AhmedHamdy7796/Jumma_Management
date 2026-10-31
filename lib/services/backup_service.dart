import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';
import 'package:gomaa_management/database/database_constants.dart';

// ─── Result types ────────────────────────────────────────────────────────────

class BackupResult {
  final String filePath;
  final int sizeBytes;
  const BackupResult({required this.filePath, required this.sizeBytes});
}

// ─── Core tables that must be present for a valid DB ─────────────────────────

const _coreTables = [
  TableNames.customers,
  TableNames.purchases,
  TableNames.fixes,
  TableNames.salesInvoices,
  TableNames.inventory,
  TableNames.settings,
];

/// Optional tables introduced in schema v10 (customer machines & parts).
/// Checked during restore for diagnostics, but their absence does NOT block restore:
/// older backups without them will be seamlessly migrated by [MigrationManager] on reopen.
const _optionalTables = [
  TableNames.customerMachines,
  TableNames.machineParts,
  TableNames.maintenanceRecords,
  TableNames.maintenanceSchedule,
];

/// Maximum number of backup files to keep in the local backups folder.
const _maxLocalBackups = 10;

/// Produces and restores SQLite backups using VACUUM INTO.
///
/// Key design decisions:
/// - Backup never closes the live connection; VACUUM INTO writes an
///   atomic, consistent, single-file snapshot.
/// - Restore validates the chosen file before touching anything:
///   opens it read-only, runs PRAGMA integrity_check, and confirms
///   the core tables are present.
/// - A safety copy is made via VACUUM INTO before the current DB is
///   replaced, so a restore failure leaves the original intact.
/// - WAL and SHM side-files are deleted when they exist, to avoid
///   stale journal data confusing the reopened connection.
class BackupService {
  static const _tag = 'BackupService';

  final DatabaseService _dbService;
  final AuditLogRepository _auditLogRepository;
  final String? _customBackupsDir;

  BackupService({
    DatabaseService? dbService,
    AuditLogRepository? auditLogRepository,
    String? customBackupsDir,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ??
            AuditLogRepository(dbService: dbService ?? DatabaseService.instance),
        _customBackupsDir = customBackupsDir;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns the app-managed local backups directory, creating it if needed.
  Future<Directory> get localBackupsDir async {
    if (_customBackupsDir != null) {
      final dir = Directory(_customBackupsDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'backups'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Creates a backup file using VACUUM INTO.
  ///
  /// If [destinationDir] is null the file goes to [localBackupsDir]; otherwise
  /// it goes to the supplied directory.  Either way the local backups folder is
  /// pruned to [_maxLocalBackups] files (only files inside that folder are
  /// ever deleted; custom-location files are never touched).
  Future<BackupResult> createBackupFile({String? destinationDir}) async {
    try {
      final targetDir = destinationDir != null
          ? Directory(destinationDir)
          : await localBackupsDir;

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final now = DateTime.now();
      final stamp =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}_'
          '${now.millisecond.toString().padLeft(3, '0')}';
      final fileName = 'gomaa_backup_$stamp.db';
      final destPath = p.join(targetDir.path, fileName);

      // VACUUM INTO requires the destination NOT to exist.
      final destFile = File(destPath);
      if (destFile.existsSync()) destFile.deleteSync();

      final db = await _dbService.database;
      // VACUUM INTO is an online operation — no connection close needed.
      await db.execute("VACUUM INTO '${destPath.replaceAll("'", "''")}'");

      final sizeBytes = await destFile.length();

      AppLogger.instance.info(
        'Backup created: $destPath ($sizeBytes bytes)',
        tag: _tag,
      );

      // Prune old backups in the LOCAL backups folder only.
      await _pruneLocalBackups();

      await _auditLogRepository.log(
        operation: AuditOperation.backup,
        entityType: AuditEntityType.system,
        description: 'نسخة احتياطية: $fileName',
      );

      return BackupResult(filePath: destPath, sizeBytes: sizeBytes);
    } catch (e) {
      AppLogger.instance.error('createBackupFile failed', tag: _tag, exception: e);
      throw BackupException(technicalDetail: e.toString());
    }
  }

  /// Lets the user pick a destination folder (via [FilePicker]) and saves the
  /// backup there. Returns null if the picker is cancelled or fails, creating nothing.
  Future<BackupResult?> createBackupWithPicker() async {
    String? chosenDir;
    try {
      chosenDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلد حفظ النسخة الاحتياطية',
      );
    } catch (_) {
      // Platform may not support directory picker
      return null;
    }
    if (chosenDir == null || chosenDir.trim().isEmpty) {
      return null;
    }
    return createBackupFile(destinationDir: chosenDir);
  }

  /// Validates [dbFilePath], makes a safety copy of the current DB, then
  /// replaces it with the chosen file.
  ///
  /// Validation steps (performed WITHOUT closing the live connection):
  ///   1. Open the candidate file read-only with sqflite_common_ffi.
  ///   2. Run `PRAGMA integrity_check` — must return 'ok'.
  ///   3. Confirm all [_coreTables] exist.
  ///
  /// Replacement steps:
  ///   4. VACUUM INTO a safety copy (so current DB is never lost).
  ///   5. Close the live connection.
  ///   6. Delete stale -wal and -shm files if they exist.
  ///   7. Copy the validated file over the main DB file.
  ///   8. Reopen the connection.
  Future<void> restoreFromFile(String dbFilePath) async {
    // ── Step 1-3: validate ───────────────────────────────────────────────────
    await _validateDbFile(dbFilePath);

    final currentDbPath = await _dbService.databasePath;

    // ── Step 4: safety copy ──────────────────────────────────────────────────
    try {
      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}_'
          '${now.millisecond.toString().padLeft(3, '0')}';
      final safetyDir = await localBackupsDir;
      String safetyPath = p.join(safetyDir.path, 'pre_restore_safety_$stamp.db');
      int counter = 1;
      while (File(safetyPath).existsSync()) {
        safetyPath = p.join(safetyDir.path, 'pre_restore_safety_${stamp}_$counter.db');
        counter++;
      }

      final db = await _dbService.database;
      await db.execute("VACUUM INTO '${safetyPath.replaceAll("'", "''")}'");
      AppLogger.instance.info('Safety copy created at $safetyPath', tag: _tag);
    } catch (e) {
      // Not fatal — log and continue.
      AppLogger.instance.error(
          'Could not create safety copy before restore', tag: _tag, exception: e);
    }

    // ── Steps 5-8: replace ───────────────────────────────────────────────────
    try {
      await _dbService.close();

      // Remove WAL and SHM files so SQLite starts clean.
      for (final ext in ['-wal', '-shm']) {
        final sideFile = File('$currentDbPath$ext');
        if (sideFile.existsSync()) {
          sideFile.deleteSync();
          AppLogger.instance.info('Deleted $ext file', tag: _tag);
        }
      }

      // Replace main file.
      await File(dbFilePath).copy(currentDbPath);

      await _dbService.reopen();

      AppLogger.instance.info('Restore completed from $dbFilePath', tag: _tag);

      await _auditLogRepository.log(
        operation: AuditOperation.restore,
        entityType: AuditEntityType.system,
        description: 'استعادة من ملف: ${p.basename(dbFilePath)}',
      );
    } catch (e) {
      // Try to reopen even if copy failed so the app is not bricked.
      try {
        await _dbService.reopen();
      } catch (_) {}
      AppLogger.instance.error('restoreFromFile failed', tag: _tag, exception: e);
      throw BackupException(
        technicalDetail: e.toString(),
        userMessage: 'فشلت عملية الاستعادة. قاعدة البيانات الحالية سليمة.',
      );
    }
  }

  /// Opens a file-picker for the user to choose a `.db` file, then delegates
  /// to [restoreFromFile].  Returns true on success, false if user cancelled.
  Future<bool> restoreWithPicker() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'اختر ملف قاعدة البيانات للاستعادة',
      );
    } catch (e) {
      throw BackupException(
          technicalDetail: 'FilePicker failed: $e',
          userMessage: 'فشل فتح نافذة اختيار الملف.');
    }

    if (result == null || result.files.isEmpty) return false;
    final path = result.files.single.path;
    if (path == null || path.trim().isEmpty) return false;

    await restoreFromFile(path);
    return true;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Validates a candidate DB file without touching the live connection.
  Future<void> _validateDbFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw const BackupException(
        technicalDetail: 'Candidate file does not exist',
        userMessage: 'الملف المحدد غير موجود.',
      );
    }

    Database? candidateDb;
    try {
      try {
        // Open read-only using sqflite_ffi so we never touch the live DB.
        candidateDb = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(readOnly: true),
        );
      } catch (e) {
        throw BackupException(
          technicalDetail: 'Candidate file cannot be opened as SQLite database: $e',
          userMessage: 'الملف المحدد تالف أو ليس ملف قاعدة بيانات صالح.',
        );
      }

      // integrity_check
      final List<Map<String, Object?>> integrityRows;
      try {
        integrityRows = await candidateDb.rawQuery('PRAGMA integrity_check');
      } catch (e) {
        throw BackupException(
          technicalDetail: 'integrity_check failed with exception: $e',
          userMessage: 'الملف المحدد تالف (فشل فحص التكامل).',
        );
      }

      final integrityResult =
          integrityRows.isNotEmpty ? integrityRows.first.values.first : null;
      if (integrityResult?.toString().toLowerCase() != 'ok') {
        throw BackupException(
          technicalDetail: 'integrity_check returned: $integrityResult',
          userMessage: 'الملف المحدد تالف (PRAGMA integrity_check فشل).',
        );
      }

      // Core tables check.
      for (final tableName in _coreTables) {
        final rows = await candidateDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        if (rows.isEmpty) {
          // Backward compatibility: v7/v8 backups used 'equipment', which
          // is automatically migrated to 'inventory' on open by MigrationManager.
          if (tableName == TableNames.inventory) {
            final legacyRows = await candidateDb.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='equipment'",
            );
            if (legacyRows.isNotEmpty) continue;
          }

          throw BackupException(
            technicalDetail: 'Core table missing: $tableName',
            userMessage:
                'الملف المحدد ليس نسخة احتياطية صالحة (جدول "$tableName" مفقود).',
          );
        }
      }

      // Optional tables check (diagnostic: does not block restore).
      for (final tableName in _optionalTables) {
        final rows = await candidateDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        if (rows.isEmpty) {
          AppLogger.instance.info(
            'Optional table absent in backup: $tableName (will be created by migration on reopen)',
            tag: _tag,
          );
        }
      }

      AppLogger.instance.info('Validation passed for $path', tag: _tag);
    } finally {
      try {
        await candidateDb?.close();
      } catch (_) {}
    }
  }

  /// Deletes the oldest files in [localBackupsDir] keeping only
  /// [_maxLocalBackups] most-recent files.  Safety copies (prefix
  /// `pre_restore_safety_`) count toward the limit.
  Future<void> _pruneLocalBackups() async {
    try {
      final dir = await localBackupsDir;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.db')
          .toList()
        ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

      while (files.length > _maxLocalBackups) {
        final oldest = files.removeAt(0);
        oldest.deleteSync();
        AppLogger.instance.info(
            'Pruned old backup: ${p.basename(oldest.path)}',
            tag: _tag);
      }
    } catch (e) {
      AppLogger.instance.error('_pruneLocalBackups failed', tag: _tag, exception: e);
    }
  }
}
