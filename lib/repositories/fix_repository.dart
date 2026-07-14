import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/fix_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_fix_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class FixRepository implements IFixRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'FixRepository';

  FixRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<FixModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.fixes,
        orderBy: '${FixColumns.date} DESC',
      );
      return List.generate(maps.length, (i) => FixModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all fixes', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<FixModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.fixes,
        where: '${FixColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return FixModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get fix by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(FixModel fix) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.fixes, fix.toMap());
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.fix,
          entityId: id,
          description: 'إضافة صيانة للماكينة: ${fix.machineName} (المشكلة: ${fix.issue})',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create fix', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(FixModel fix) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.fixes,
          fix.toMap(),
          where: '${FixColumns.id} = ?',
          whereArgs: [fix.id],
        );
      });

      if (count > 0 && fix.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.fix,
          entityId: fix.id,
          description: 'تعديل صيانة الماكينة: ${fix.machineName} (الحالة: ${fix.status})',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update fix: ${fix.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final fix = await getById(id);
      if (fix == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.fixes,
          where: '${FixColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.fix,
          entityId: id,
          description: 'حذف صيانة الماكينة: ${fix.machineName}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete fix: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<FixModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.fixes,
        where: '${FixColumns.machineName} LIKE ? OR ${FixColumns.model} LIKE ? OR ${FixColumns.issue} LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: '${FixColumns.date} DESC',
      );
      return List.generate(maps.length, (i) => FixModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to search fixes with query: $query', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
