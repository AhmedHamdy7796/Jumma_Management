import 'package:sqflite/sqflite.dart';
import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/repositories/interfaces/i_settings_repository.dart';

class SettingsRepository implements ISettingsRepository {
  final DatabaseService _dbService;
  static const _tag = 'SettingsRepository';

  SettingsRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  @override
  Future<String?> getSetting(String key) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.settings,
        columns: [SettingsColumns.value],
        where: '${SettingsColumns.key} = ?',
        whereArgs: [key],
      );
      if (maps.isNotEmpty) {
        return maps.first[SettingsColumns.value] as String;
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get setting for key: $key', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await _dbService.database;
      await db.transaction((txn) async {
        await txn.insert(
          TableNames.settings,
          {SettingsColumns.key: key, SettingsColumns.value: value},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      AppLogger.instance.info('Setting updated: $key = $value', tag: _tag);
    } catch (e) {
      AppLogger.instance.error('Failed to set setting: $key', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<Map<String, String>> getAllSettings() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(TableNames.settings);
      final Map<String, String> settingsMap = {};
      for (final map in maps) {
        final key = map[SettingsColumns.key] as String;
        final value = map[SettingsColumns.value] as String;
        settingsMap[key] = value;
      }
      return settingsMap;
    } catch (e) {
      AppLogger.instance.error('Failed to get all settings', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<void> setAllSettings(Map<String, String> settings) async {
    try {
      final db = await _dbService.database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        settings.forEach((key, value) {
          batch.insert(
            TableNames.settings,
            {SettingsColumns.key: key, SettingsColumns.value: value},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });
        await batch.commit(noResult: true);
      });
      AppLogger.instance.info('Batch settings update complete', tag: _tag);
    } catch (e) {
      AppLogger.instance.error('Failed to save batch settings', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
