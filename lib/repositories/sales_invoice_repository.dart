import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_sales_invoice_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class SalesInvoiceRepository implements ISalesInvoiceRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'SalesInvoiceRepository';

  SalesInvoiceRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<SalesInvoiceModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final maps = await db.rawQuery('''
        SELECT
          si.*,
          c.${CustomerColumns.name}    AS customerName,
          c.${CustomerColumns.address} AS customerAddress
        FROM ${TableNames.salesInvoices} si
        LEFT JOIN ${TableNames.customers} c ON si.${SalesInvoiceColumns.customerId} = c.${CustomerColumns.id}
        ORDER BY si.${SalesInvoiceColumns.date} DESC
      ''');
      return maps.map(SalesInvoiceModel.fromMap).toList();
    } catch (e) {
      AppLogger.instance.error('Failed to get all sales invoices',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<SalesInvoiceModel>> getByCustomer(int customerId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.rawQuery('''
        SELECT
          si.*,
          c.${CustomerColumns.name}    AS customerName,
          c.${CustomerColumns.address} AS customerAddress
        FROM ${TableNames.salesInvoices} si
        LEFT JOIN ${TableNames.customers} c ON si.${SalesInvoiceColumns.customerId} = c.${CustomerColumns.id}
        WHERE si.${SalesInvoiceColumns.customerId} = ?
        ORDER BY si.${SalesInvoiceColumns.date} DESC
      ''', [customerId]);
      return maps.map(SalesInvoiceModel.fromMap).toList();
    } catch (e) {
      AppLogger.instance.error(
          'Failed to get invoices for customer $customerId',
          tag: _tag,
          exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<SalesInvoiceModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.salesInvoices,
        where: '${SalesInvoiceColumns.id} = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty ? SalesInvoiceModel.fromMap(maps.first) : null;
    } catch (e) {
      AppLogger.instance.error('Failed to get invoice $id',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(SalesInvoiceModel invoice) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.salesInvoices, invoice.toMap());

        // Sync with inventory (deduct sold quantity)
        final inventoryMaps = await txn.query(
          TableNames.inventory,
          where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
          whereArgs: [invoice.itemName.trim(), invoice.model.trim()],
        );

        if (inventoryMaps.isNotEmpty) {
          final invMap = inventoryMaps.first;
          final currentQty = invMap[InventoryColumns.quantity] as int? ?? 0;
          await txn.update(
            TableNames.inventory,
            {InventoryColumns.quantity: currentQty - invoice.quantity},
            where: '${InventoryColumns.id} = ?',
            whereArgs: [invMap[InventoryColumns.id]],
          );
        } else {
          await txn.insert(TableNames.inventory, {
            InventoryColumns.name: invoice.itemName.trim(),
            InventoryColumns.model: invoice.model.trim(),
            InventoryColumns.quantity: -invoice.quantity,
            InventoryColumns.category: 'مبيعات',
            InventoryColumns.purchasePrice: 0.0,
            InventoryColumns.sellingPrice: invoice.price,
            InventoryColumns.notes: '',
          });
        }
      });
      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.salesInvoice,
          entityId: id,
          description: 'إنشاء فاتورة مبيعات: ${invoice.itemName} (الكمية: ${invoice.quantity})',
        );
      }
      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create sales invoice',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(SalesInvoiceModel invoice) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        // 1. Get old invoice to find diff
        final oldMaps = await txn.query(
          TableNames.salesInvoices,
          where: '${SalesInvoiceColumns.id} = ?',
          whereArgs: [invoice.id],
        );

        int qtyDiff = invoice.quantity;
        bool itemChanged = false;

        if (oldMaps.isNotEmpty) {
          final oldInvoice = SalesInvoiceModel.fromMap(oldMaps.first);
          if (oldInvoice.itemName.trim() == invoice.itemName.trim() &&
              oldInvoice.model.trim() == invoice.model.trim()) {
            qtyDiff = invoice.quantity - oldInvoice.quantity;
          } else {
            itemChanged = true;
            // Name or model changed, revert old inventory qty
            final oldInvMaps = await txn.query(
              TableNames.inventory,
              where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
              whereArgs: [oldInvoice.itemName.trim(), oldInvoice.model.trim()],
            );
            if (oldInvMaps.isNotEmpty) {
              final oldInvMap = oldInvMaps.first;
              final oldCurrentQty = oldInvMap[InventoryColumns.quantity] as int? ?? 0;
              await txn.update(
                TableNames.inventory,
                {InventoryColumns.quantity: oldCurrentQty + oldInvoice.quantity},
                where: '${InventoryColumns.id} = ?',
                whereArgs: [oldInvMap[InventoryColumns.id]],
              );
            }
          }
        }

        // 2. Update invoice record
        count = await txn.update(
          TableNames.salesInvoices,
          invoice.toMap(),
          where: '${SalesInvoiceColumns.id} = ?',
          whereArgs: [invoice.id],
        );

        // 3. Update new inventory qty (deduct qtyDiff or invoice.quantity)
        if (qtyDiff != 0 || itemChanged) {
          final inventoryMaps = await txn.query(
            TableNames.inventory,
            where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
            whereArgs: [invoice.itemName.trim(), invoice.model.trim()],
          );
          final deductQty = itemChanged ? invoice.quantity : qtyDiff;
          if (inventoryMaps.isNotEmpty) {
            final invMap = inventoryMaps.first;
            final currentQty = invMap[InventoryColumns.quantity] as int? ?? 0;
            await txn.update(
              TableNames.inventory,
              {InventoryColumns.quantity: currentQty - deductQty},
              where: '${InventoryColumns.id} = ?',
              whereArgs: [invMap[InventoryColumns.id]],
            );
          } else {
            await txn.insert(TableNames.inventory, {
              InventoryColumns.name: invoice.itemName.trim(),
              InventoryColumns.model: invoice.model.trim(),
              InventoryColumns.quantity: -deductQty,
              InventoryColumns.category: 'مبيعات',
              InventoryColumns.purchasePrice: 0.0,
              InventoryColumns.sellingPrice: invoice.price,
              InventoryColumns.notes: '',
            });
          }
        }
      });
      if (count > 0 && invoice.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.salesInvoice,
          entityId: invoice.id,
          description: 'تعديل فاتورة: ${invoice.itemName}',
        );
      }
      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update invoice: ${invoice.id}',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final invoice = await getById(id);
      if (invoice == null) return 0;
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.salesInvoices,
          where: '${SalesInvoiceColumns.id} = ?',
          whereArgs: [id],
        );

        if (count > 0) {
          // Restore inventory quantity
          final inventoryMaps = await txn.query(
            TableNames.inventory,
            where: '${InventoryColumns.name} = ? AND ${InventoryColumns.model} = ?',
            whereArgs: [invoice.itemName.trim(), invoice.model.trim()],
          );
          if (inventoryMaps.isNotEmpty) {
            final invMap = inventoryMaps.first;
            final currentQty = invMap[InventoryColumns.quantity] as int? ?? 0;
            await txn.update(
              TableNames.inventory,
              {InventoryColumns.quantity: currentQty + invoice.quantity},
              where: '${InventoryColumns.id} = ?',
              whereArgs: [invMap[InventoryColumns.id]],
            );
          }
        }
      });
      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.salesInvoice,
          entityId: id,
          description: 'حذف فاتورة: ${invoice.itemName}',
        );
      }
      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete invoice $id',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<SalesInvoiceModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.salesInvoices,
        where:
            '${SalesInvoiceColumns.itemName} LIKE ? OR ${SalesInvoiceColumns.model} LIKE ? OR ${SalesInvoiceColumns.notes} LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: '${SalesInvoiceColumns.date} DESC',
      );
      return maps.map(SalesInvoiceModel.fromMap).toList();
    } catch (e) {
      AppLogger.instance.error('Failed to search invoices: $query',
          tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<double> getCustomerBalance(int customerId) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(${SalesInvoiceColumns.remainingBalance}), 0) AS total '
        'FROM ${TableNames.salesInvoices} '
        'WHERE ${SalesInvoiceColumns.customerId} = ?',
        [customerId],
      );
      return (result.first['total'] as num).toDouble();
    } catch (e) {
      AppLogger.instance.error(
          'Failed to get balance for customer $customerId',
          tag: _tag,
          exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
