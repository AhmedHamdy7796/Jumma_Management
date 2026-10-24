import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/machine_part_model.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_machine_part_repository.dart';

class MachinePartRepository implements IMachinePartRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'MachinePartRepository';

  MachinePartRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<MachinePartModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.machineParts,
        orderBy: '${MachinePartColumns.replacedDate} DESC',
      );
      return List.generate(maps.length, (i) => MachinePartModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all machine parts', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<MachinePartModel>> getByMachineId(int machineId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.machineParts,
        where: '${MachinePartColumns.machineId} = ?',
        whereArgs: [machineId],
        orderBy: '${MachinePartColumns.replacedDate} DESC',
      );
      return List.generate(maps.length, (i) => MachinePartModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error(
        'Failed to get machine parts for machine: $machineId',
        tag: _tag,
        exception: e,
      );
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<MachinePartModel>> getByCustomerId(int customerId) async {
    try {
      final db = await _dbService.database;
      final sql = '''
        SELECT mp.* FROM ${TableNames.machineParts} mp
        JOIN ${TableNames.customerMachines} cm ON mp.${MachinePartColumns.machineId} = cm.${CustomerMachineColumns.id}
        WHERE cm.${CustomerMachineColumns.customerId} = ?
        ORDER BY mp.${MachinePartColumns.replacedDate} DESC
      ''';
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [customerId]);
      return List.generate(maps.length, (i) => MachinePartModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error(
        'Failed to get machine parts for customer: $customerId',
        tag: _tag,
        exception: e,
      );
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<MachinePartModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.machineParts,
        where: '${MachinePartColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return MachinePartModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get machine part by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(
    MachinePartModel part, {
    int? inventoryItemId,
    int quantityToDeduct = 1,
  }) async {
    try {
      final db = await _dbService.database;
      int id = -1;

      await db.transaction((txn) async {
        // 1. Insert part replacement record
        id = await txn.insert(TableNames.machineParts, part.toMap());

        // 2. Optional stock link: deduct from inventory in the same transaction
        if (inventoryItemId != null && quantityToDeduct > 0) {
          final invRows = await txn.query(
            TableNames.inventory,
            where: '${InventoryColumns.id} = ?',
            whereArgs: [inventoryItemId],
          );

          if (invRows.isNotEmpty) {
            final currentQty = invRows.first[InventoryColumns.quantity] as int? ?? 0;
            final updatedQty = currentQty - quantityToDeduct;
            await txn.update(
              TableNames.inventory,
              {InventoryColumns.quantity: updatedQty},
              where: '${InventoryColumns.id} = ?',
              whereArgs: [inventoryItemId],
            );

            AppLogger.instance.info(
              'Deducted $quantityToDeduct units from inventory item #$inventoryItemId. New qty: $updatedQty',
              tag: _tag,
            );
          }
        }
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.machinePart,
          entityId: id,
          description: 'تسجيل استبدال قطعة (${part.partName}) للماكينة رقم #${part.machineId}',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create machine part record', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(MachinePartModel part) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.machineParts,
          part.toMap(),
          where: '${MachinePartColumns.id} = ?',
          whereArgs: [part.id],
        );
      });

      if (count > 0 && part.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.machinePart,
          entityId: part.id,
          description: 'تعديل سجل استبدال قطعة (${part.partName}) للماكينة رقم #${part.machineId}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update machine part: ${part.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final part = await getById(id);
      if (part == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.machineParts,
          where: '${MachinePartColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.machinePart,
          entityId: id,
          description: 'حذف سجل استبدال قطعة (${part.partName}) للماكينة رقم #${part.machineId}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete machine part: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
