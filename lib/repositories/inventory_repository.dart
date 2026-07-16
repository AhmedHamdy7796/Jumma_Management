import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/inventory_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_inventory_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class InventoryRepository implements IInventoryRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'InventoryRepository';

  InventoryRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<InventoryModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.inventory,
        orderBy: '${InventoryColumns.name} ASC',
      );
      return maps.map(InventoryModel.fromMap).toList();
    } catch (e) {
      AppLogger.instance.error('Failed to get all inventory items',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<InventoryModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.inventory,
        where: '${InventoryColumns.id} = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty ? InventoryModel.fromMap(maps.first) : null;
    } catch (e) {
      AppLogger.instance.error('Failed to get inventory item $id',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(InventoryModel item) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.inventory, item.toMap());
      });
      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.inventory,
          entityId: id,
          description: 'إضافة للمخزون: ${item.name}',
        );
      }
      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create inventory item',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(InventoryModel item) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.inventory,
          item.toMap(),
          where: '${InventoryColumns.id} = ?',
          whereArgs: [item.id],
        );
      });
      if (count > 0 && item.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.inventory,
          entityId: item.id,
          description: 'تعديل عنصر المخزون: ${item.name}',
        );
      }
      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update inventory item: ${item.id}',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final item = await getById(id);
      if (item == null) return 0;
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.inventory,
          where: '${InventoryColumns.id} = ?',
          whereArgs: [id],
        );
      });
      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.inventory,
          entityId: id,
          description: 'حذف من المخزون: ${item.name}',
        );
      }
      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete inventory item: $id',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<InventoryModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.inventory,
        where:
            '${InventoryColumns.name} LIKE ? OR ${InventoryColumns.model} LIKE ? OR ${InventoryColumns.category} LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: '${InventoryColumns.name} ASC',
      );
      return maps.map(InventoryModel.fromMap).toList();
    } catch (e) {
      AppLogger.instance.error('Failed to search inventory: $query',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<void> adjustQuantity(int id, int delta) async {
    try {
      final db = await _dbService.database;
      await db.rawUpdate(
        'UPDATE ${TableNames.inventory} SET ${InventoryColumns.quantity} = ${InventoryColumns.quantity} + ? WHERE ${InventoryColumns.id} = ?',
        [delta, id],
      );
    } catch (e) {
      AppLogger.instance.error('Failed to adjust inventory quantity for $id',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
