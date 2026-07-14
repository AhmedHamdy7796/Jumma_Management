import 'package:gomaa_management/models/audit_log_model.dart';

/// Repository interface for Audit Logging.
abstract class IAuditLogRepository {
  /// Logs an operation performed on an entity.
  Future<int> log({
    required String operation,
    required String entityType,
    int? entityId,
    required String description,
    String username = 'المستخدم',
  });

  /// Retrieves all audit logs from the database, ordered by occurrence descending.
  Future<List<AuditLogModel>> getAllLogs({
    DateTime? from,
    DateTime? to,
    String? operation,
  });

  /// Deletes logs older than a specific date to free space.
  Future<void> clearLogsOlderThan(DateTime date);
}
