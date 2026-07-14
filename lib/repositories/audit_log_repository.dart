import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/models/audit_log_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';

class AuditLogRepository implements IAuditLogRepository {
  final DatabaseService _dbService;
  static const _tag = 'AuditLogRepository';

  AuditLogRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  @override
  Future<int> log({
    required String operation,
    required String entityType,
    int? entityId,
    required String description,
    String username = 'المستخدم',
  }) async {
    try {
      final db = await _dbService.database;
      final logModel = AuditLogModel(
        occurredAt: DateTime.now(),
        operation: operation,
        entityType: entityType,
        entityId: entityId,
        description: description,
        username: username,
      );

      final id = await db.insert(
        TableNames.auditLogs,
        logModel.toMap(),
      );

      AppLogger.instance.audit(
        'Audit log created: $description (User: $username)',
        tag: _tag,
      );
      return id;
    } catch (e) {
      AppLogger.instance.error('Failed to write audit log', tag: _tag, exception: e);
      // We do not throw exceptions for audit logs failing so it doesn't crash the main business logic
      return -1;
    }
  }

  @override
  Future<List<AuditLogModel>> getAllLogs({
    DateTime? from,
    DateTime? to,
    String? operation,
  }) async {
    try {
      final db = await _dbService.database;
      
      String? whereClause;
      List<dynamic> whereArgs = [];

      if (from != null && to != null) {
        whereClause = '${AuditLogColumns.occurredAt} BETWEEN ? AND ?';
        whereArgs.addAll([from.toIso8601String(), to.toIso8601String()]);
      } else if (from != null) {
        whereClause = '${AuditLogColumns.occurredAt} >= ?';
        whereArgs.add(from.toIso8601String());
      } else if (to != null) {
        whereClause = '${AuditLogColumns.occurredAt} <= ?';
        whereArgs.add(to.toIso8601String());
      }

      if (operation != null) {
        if (whereClause != null) {
          whereClause += ' AND ${AuditLogColumns.operation} = ?';
        } else {
          whereClause = '${AuditLogColumns.operation} = ?';
        }
        whereArgs.add(operation);
      }

      final List<Map<String, dynamic>> maps = await db.query(
        TableNames.auditLogs,
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: '${AuditLogColumns.occurredAt} DESC',
      );

      return List.generate(maps.length, (i) => AuditLogModel.fromMap(maps[i]));
    } catch (e) {
      AppLogger.instance.error('Failed to get audit logs', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }

  @override
  Future<void> clearLogsOlderThan(DateTime date) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        TableNames.auditLogs,
        where: '${AuditLogColumns.occurredAt} < ?',
        whereArgs: [date.toIso8601String()],
      );
      AppLogger.instance.info('Cleared logs older than ${date.toIso8601String()}', tag: _tag);
    } catch (e) {
      AppLogger.instance.error('Failed to clear old audit logs', tag: _tag, exception: e);
      throw AppDatabaseException(technicalDetail: e.toString());
    }
  }
}
