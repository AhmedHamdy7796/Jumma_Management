import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/purchase_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_purchase_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class PurchaseRepository implements IPurchaseRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'PurchaseRepository';

  PurchaseRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<PurchaseModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.purchases,
        orderBy: '${PurchaseColumns.date} DESC',
      );
      return List.generate(maps.length, (i) => PurchaseModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all purchases', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<PurchaseModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.purchases,
        where: '${PurchaseColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return PurchaseModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get purchase by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(PurchaseModel purchase) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.purchases, purchase.toMap());

        // Sync with inventory
        final inventoryMaps = await txn.query(
          TableNames.inventory,
          where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
          whereArgs: [purchase.machineName, purchase.model],
        );
        
        if (inventoryMaps.isNotEmpty) {
          final invMap = inventoryMaps.first;
          final currentQty = invMap[InventoryColumns.quantity] as int? ?? 0;
          await txn.update(
            TableNames.inventory,
            {InventoryColumns.quantity: currentQty + purchase.quantity},
            where: '${InventoryColumns.id} = ?',
            whereArgs: [invMap[InventoryColumns.id]],
          );
        } else {
          await txn.insert(TableNames.inventory, {
            InventoryColumns.name: purchase.machineName,
            InventoryColumns.model: purchase.model,
            InventoryColumns.quantity: purchase.quantity,
            InventoryColumns.category: 'مشتريات جديدة',
            InventoryColumns.purchasePrice: purchase.price,
            InventoryColumns.sellingPrice: purchase.price * 1.2,
            InventoryColumns.notes: '',
          });
        }
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.purchase,
          entityId: id,
          description: 'إضافة مشترى: ${purchase.machineName} (الكمية: ${purchase.quantity})',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create purchase', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(PurchaseModel purchase) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        // 1. Get old purchase to find diff
        final oldMaps = await txn.query(
          TableNames.purchases,
          where: '${PurchaseColumns.id} = ?',
          whereArgs: [purchase.id],
        );
        
        int qtyDiff = purchase.quantity;
        bool itemChanged = false;
        
        if (oldMaps.isNotEmpty) {
          final oldPurchase = PurchaseModel.fromMap(oldMaps.first);
          if (oldPurchase.machineName == purchase.machineName && oldPurchase.model == purchase.model) {
            qtyDiff = purchase.quantity - oldPurchase.quantity;
          } else {
            itemChanged = true;
            // Name or model changed, revert old inventory qty
            final oldInvMaps = await txn.query(
              TableNames.inventory,
              where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
              whereArgs: [oldPurchase.machineName, oldPurchase.model],
            );
            if (oldInvMaps.isNotEmpty) {
              final oldInvMap = oldInvMaps.first;
              final oldCurrentQty = oldInvMap[InventoryColumns.quantity] as int? ?? 0;
              int newQty = oldCurrentQty - oldPurchase.quantity;
              if (newQty < 0) newQty = 0;
              await txn.update(
                TableNames.inventory,
                {InventoryColumns.quantity: newQty},
                where: '${InventoryColumns.id} = ?',
                whereArgs: [oldInvMap[InventoryColumns.id]],
              );
            }
          }
        }
        
        // 2. Update purchase record
        count = await txn.update(
          TableNames.purchases,
          purchase.toMap(),
          where: '${PurchaseColumns.id} = ?',
          whereArgs: [purchase.id],
        );

        // 3. Update new inventory qty
        if (qtyDiff != 0 || itemChanged) {
          final inventoryMaps = await txn.query(
            TableNames.inventory,
            where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
            whereArgs: [purchase.machineName, purchase.model],
          );
          if (inventoryMaps.isNotEmpty) {
            final invMap = inventoryMaps.first;
            final currentQty = invMap[InventoryColumns.quantity] as int? ?? 0;
            int newQty = currentQty + qtyDiff;
            if (newQty < 0) newQty = 0;
            await txn.update(
              TableNames.inventory,
              {InventoryColumns.quantity: newQty},
              where: '${InventoryColumns.id} = ?',
              whereArgs: [invMap[InventoryColumns.id]],
            );
          } else {
            await txn.insert(TableNames.inventory, {
              InventoryColumns.name: purchase.machineName,
              InventoryColumns.model: purchase.model,
              InventoryColumns.quantity: purchase.quantity,
              InventoryColumns.category: 'مشتريات جديدة',
              InventoryColumns.purchasePrice: purchase.price,
              InventoryColumns.sellingPrice: purchase.price * 1.2,
              InventoryColumns.notes: '',
            });
          }
        }
      });

      if (count > 0 && purchase.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.purchase,
          entityId: purchase.id,
          description: 'تعديل مشترى: ${purchase.machineName}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update purchase: ${purchase.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final purchase = await getById(id);
      if (purchase == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.purchases,
          where: '${PurchaseColumns.id} = ?',
          whereArgs: [id],
        );

        if (count > 0) {
          final inventoryMaps = await txn.query(
            TableNames.inventory,
            where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
            whereArgs: [purchase.machineName, purchase.model],
          );
          if (inventoryMaps.isNotEmpty) {
            final invMap = inventoryMaps.first;
            final currentQty = invMap[InventoryColumns.quantity] as int? ?? 0;
            int newQty = currentQty - purchase.quantity;
            if (newQty < 0) newQty = 0;
            await txn.update(
              TableNames.inventory,
              {InventoryColumns.quantity: newQty},
              where: '${InventoryColumns.id} = ?',
              whereArgs: [invMap[InventoryColumns.id]],
            );
          }
        }
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.purchase,
          entityId: id,
          description: 'حذف مشترى: ${purchase.machineName}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete purchase: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<PurchaseModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.purchases,
        where: '${PurchaseColumns.machineName} LIKE ? OR ${PurchaseColumns.model} LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '${PurchaseColumns.date} DESC',
      );
      return List.generate(maps.length, (i) => PurchaseModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to search purchases with query: $query', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
