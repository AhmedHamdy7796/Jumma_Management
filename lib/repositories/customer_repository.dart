import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/customer_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_customer_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';

class CustomerRepository implements ICustomerRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'CustomerRepository';

  CustomerRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<CustomerModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.customers,
        orderBy: '${CustomerColumns.date} DESC',
      );
      return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all customers', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<CustomerModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.customers,
        where: '${CustomerColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return CustomerModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get customer by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(CustomerModel customer) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.customers, customer.toMap());
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.customer,
          entityId: id,
          description: 'إضافة العميل: ${customer.name}',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create customer', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(CustomerModel customer) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.customers,
          customer.toMap(),
          where: '${CustomerColumns.id} = ?',
          whereArgs: [customer.id],
        );
      });

      if (count > 0 && customer.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.customer,
          entityId: customer.id,
          description: 'تعديل بيانات العميل: ${customer.name}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update customer: ${customer.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final customer = await getById(id);
      if (customer == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.customers,
          where: '${CustomerColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.customer,
          entityId: id,
          description: 'حذف العميل: ${customer.name}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete customer: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<CustomerModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.customers,
        where: '${CustomerColumns.name} LIKE ? OR ${CustomerColumns.mobilePhone} LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '${CustomerColumns.date} DESC',
      );
      return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to search customers with query: $query', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
