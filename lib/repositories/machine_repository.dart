import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/machine_model.dart';
import 'package:gomaa_management/repositories/audit_log_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';
import 'package:gomaa_management/repositories/interfaces/i_machine_repository.dart';

class MachineRepository implements IMachineRepository {
  final DatabaseService _dbService;
  final IAuditLogRepository _auditLogRepository;
  static const _tag = 'MachineRepository';

  MachineRepository({
    DatabaseService? dbService,
    IAuditLogRepository? auditLogRepository,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _auditLogRepository = auditLogRepository ?? AuditLogRepository();

  @override
  Future<List<MachineModel>> getAll() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.customerMachines,
        orderBy: '${CustomerMachineColumns.createdAt} DESC',
      );
      return List.generate(maps.length, (i) => MachineModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get all machines', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<MachineModel>> getByCustomerId(int customerId) async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.customerMachines,
        where: '${CustomerMachineColumns.customerId} = ?',
        whereArgs: [customerId],
        orderBy: '${CustomerMachineColumns.createdAt} DESC',
      );
      return List.generate(maps.length, (i) => MachineModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error(
        'Failed to get machines for customer: $customerId',
        tag: _tag,
        exception: e,
      );
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<MachineModel?> getById(int id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        TableNames.customerMachines,
        where: '${CustomerMachineColumns.id} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return MachineModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      AppLogger.instance.error('Failed to get machine by id: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> create(MachineModel machine) async {
    try {
      final db = await _dbService.database;
      int id = -1;
      await db.transaction((txn) async {
        id = await txn.insert(TableNames.customerMachines, machine.toMap());
      });

      if (id != -1) {
        await _auditLogRepository.log(
          operation: AuditOperation.add,
          entityType: AuditEntityType.customerMachine,
          entityId: id,
          description: 'إضافة ماكينة (${machine.machineType} - ${machine.model}) للعميل رقم #${machine.customerId}',
        );
      }

      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to create customer machine', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> update(MachineModel machine) async {
    try {
      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.update(
          TableNames.customerMachines,
          machine.toMap(),
          where: '${CustomerMachineColumns.id} = ?',
          whereArgs: [machine.id],
        );
      });

      if (count > 0 && machine.id != null) {
        await _auditLogRepository.log(
          operation: AuditOperation.edit,
          entityType: AuditEntityType.customerMachine,
          entityId: machine.id,
          description: 'تعديل ماكينة (${machine.machineType} - ${machine.model}) للعميل رقم #${machine.customerId}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to update machine: ${machine.id}', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<int> delete(int id) async {
    try {
      final machine = await getById(id);
      if (machine == null) return 0;

      final db = await _dbService.database;
      int count = 0;
      await db.transaction((txn) async {
        count = await txn.delete(
          TableNames.customerMachines,
          where: '${CustomerMachineColumns.id} = ?',
          whereArgs: [id],
        );
      });

      if (count > 0) {
        await _auditLogRepository.log(
          operation: AuditOperation.delete,
          entityType: AuditEntityType.customerMachine,
          entityId: id,
          description: 'حذف ماكينة (${machine.machineType} - ${machine.model}) للعميل رقم #${machine.customerId}',
        );
      }

      return count;
    } catch (e) {
      AppLogger.instance.error('Failed to delete machine: $id', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<List<MachineModel>> search(String query) async {
    try {
      final db = await _dbService.database;
      final wildCard = '%$query%';
      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.customerMachines,
        where:
            '${CustomerMachineColumns.model} LIKE ? OR ${CustomerMachineColumns.serialNumber} LIKE ? OR ${CustomerMachineColumns.machineType} LIKE ? OR ${CustomerMachineColumns.brand} LIKE ?',
        whereArgs: [wildCard, wildCard, wildCard, wildCard],
        orderBy: '${CustomerMachineColumns.createdAt} DESC',
      );
      return List.generate(maps.length, (i) => MachineModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to search machines: $query', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
