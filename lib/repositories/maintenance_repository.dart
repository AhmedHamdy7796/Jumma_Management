import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/maintenance_record_model.dart';
import 'package:gomaa_management/models/maintenance_schedule_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_maintenance_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class MaintenanceRepository implements IMaintenanceRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'MaintenanceRepository';

  MaintenanceRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  // ── Maintenance Records ───────────────────────────────────────────────────

  @override
  Future<List<MaintenanceRecordModel>> getRecordsForEquipment(int equipmentId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.maintenanceRecords,
        where: '${MaintenanceRecordColumns.equipmentId} = ?',
        whereArgs: [equipmentId],
        orderBy: '${MaintenanceRecordColumns.startDate} DESC',
      );
      return List.generate(maps.length, (i) => MaintenanceRecordModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get records for equipment: $equipmentId', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<MaintenanceRecordModel?> getRecordById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.maintenanceRecords,
        where: '${MaintenanceRecordColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return MaintenanceRecordModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get maintenance record by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> createRecord(MaintenanceRecordModel record) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.maintenanceRecords, record.toMap());
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.maintenanceRecord,
          entityId: id,
          description: 'إضافة سجل صيانة للمعدة ذات الرقم #${record.equipmentId}',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create maintenance record', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> updateRecord(MaintenanceRecordModel record) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.maintenanceRecords,
          record.toMap(),
          where: '${MaintenanceRecordColumns.id} = ?',
          whereArgs: [record.id],
        );
      });

      if (count > 0 && record.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.maintenanceRecord,
          entityId: record.id,
          description: 'تعديل سجل صيانة للمعدة ذات الرقم #${record.equipmentId} (الحالة: ${record.status})',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update maintenance record: ${record.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> deleteRecord(int id) async {
    try {
      final record = await getRecordById(id);
      if (record == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.maintenanceRecords,
          where: '${MaintenanceRecordColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.maintenanceRecord,
          entityId: id,
          description: 'حذف سجل صيانة للمعدة ذات الرقم #${record.equipmentId}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete maintenance record: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<MaintenanceRecordModel>> getAllRecords() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.maintenanceRecords,
        orderBy: '${MaintenanceRecordColumns.startDate} DESC',
      );
      return List.generate(maps.length, (i) => MaintenanceRecordModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all maintenance records', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  // ── Maintenance Scheduling ────────────────────────────────────────────────

  @override
  Future<List<MaintenanceScheduleModel>> getScheduleForEquipment(int equipmentId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.maintenanceSchedule,
        where: '${MaintenanceScheduleColumns.equipmentId} = ?',
        whereArgs: [equipmentId],
        orderBy: '${MaintenanceScheduleColumns.scheduledDate} ASC',
      );
      return List.generate(maps.length, (i) => MaintenanceScheduleModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get schedule for equipment: $equipmentId', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<MaintenanceScheduleModel>> getAllScheduledItems() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.maintenanceSchedule,
        orderBy: '${MaintenanceScheduleColumns.scheduledDate} ASC',
      );
      return List.generate(maps.length, (i) => MaintenanceScheduleModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all scheduled items', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> createScheduleItem(MaintenanceScheduleModel item) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.maintenanceSchedule, item.toMap());
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.maintenance,
          entityType: AuditEntityType.inventory,
          entityId: item.equipmentId,
          description: 'جدولة عملية صيانة جديدة للمعدة ذات الرقم #${item.equipmentId} بتاريخ: ${item.scheduledDate.toLocal()}',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create scheduled maintenance item', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> updateScheduleItem(MaintenanceScheduleModel item) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.maintenanceSchedule,
          item.toMap(),
          where: '${MaintenanceScheduleColumns.id} = ?',
          whereArgs: [item.id],
        );
      });

      if (count > 0 && item.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.maintenance,
          entityType: AuditEntityType.inventory,
          entityId: item.equipmentId,
          description: 'تعديل جدول صيانة للمعدة ذات الرقم #${item.equipmentId} (مكتملة: ${item.isCompleted})',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update scheduled maintenance item: ${item.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> deleteScheduleItem(int id) async {
    try {
      final db = await _dbService.database;
      
      // Get item to log details
      final maps = await db.query(
        TableNames.maintenanceSchedule,
        where: '${MaintenanceScheduleColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return 0;
      final item = MaintenanceScheduleModel.fromMap(maps.first);

      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.maintenanceSchedule,
          where: '${MaintenanceScheduleColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.inventory,
          entityId: item.equipmentId,
          description: 'حذف موعد صيانة مجدول للمعدة ذات الرقم #${item.equipmentId}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete scheduled maintenance item: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
