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
      final maps = await db.query(
        TableNames.salesInvoices,
        orderBy: '${SalesInvoiceColumns.date} DESC',
      );
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
      final maps = await db.query(
        TableNames.salesInvoices,
        where: '${SalesInvoiceColumns.customerId} = ?',
        whereArgs: [customerId],
        orderBy: '${SalesInvoiceColumns.date} DESC',
      );
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
      });
      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.salesInvoice,
          entityId: id,
          description: 'إنشاء فاتورة مبيعات: ${invoice.itemName}',
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
        count = await txn.update(
          TableNames.salesInvoices,
          invoice.toMap(),
          where: '${SalesInvoiceColumns.id} = ?',
          whereArgs: [invoice.id],
        );
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
