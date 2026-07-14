import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/equipment_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_equipment_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class EquipmentRepository implements IEquipmentRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'EquipmentRepository';

  EquipmentRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<EquipmentModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.equipment,
        orderBy: '${EquipmentColumns.name} ASC',
      );
      return List.generate(maps.length, (i) => EquipmentModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all equipment', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<EquipmentModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.equipment,
        where: '${EquipmentColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return EquipmentModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get equipment by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(EquipmentModel equipment) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.equipment, equipment.toMap());
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.equipment,
          entityId: id,
          description: 'إضافة معدة/جهاز: ${equipment.name}',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create equipment', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(EquipmentModel equipment) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.equipment,
          equipment.toMap(),
          where: '${EquipmentColumns.id} = ?',
          whereArgs: [equipment.id],
        );
      });

      if (count > 0 && equipment.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.equipment,
          entityId: equipment.id,
          description: 'تعديل بيانات المعدة: ${equipment.name}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update equipment: ${equipment.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final equipment = await getById(id);
      if (equipment == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.equipment,
          where: '${EquipmentColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.equipment,
          entityId: id,
          description: 'حذف المعدة: ${equipment.name}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete equipment: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<EquipmentModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.equipment,
        where: '${EquipmentColumns.name} LIKE ? OR ${EquipmentColumns.model} LIKE ? OR ${EquipmentColumns.serialNumber} LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: '${EquipmentColumns.name} ASC',
      );
      return List.generate(maps.length, (i) => EquipmentModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to search equipment with query: $query', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
