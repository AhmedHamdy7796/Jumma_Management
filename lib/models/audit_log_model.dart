import 'package:gomaa_management/database/database_constants.dart';

/// Represents a single audit log entry.
///
/// The audit log is append-only: no update or delete operations are exposed.
/// Every write operation in the app (add, edit, delete, backup, restore)
/// produces one [AuditLogModel] entry.
class AuditLogModel {
  final int? id;

  /// When the operation occurred (ISO-8601 with time).
  final DateTime occurredAt;

  /// One of [AuditOperation] values.
  final String operation;

  /// One of [AuditEntityType] values.
  final String entityType;

  /// The ID of the affected record, or null for system-level operations.
  final int? entityId;

  /// Human-readable Arabic description of the operation.
  final String description;

  /// The username who performed the operation.
  final String username;

  const AuditLogModel({
    this.id,
    required this.occurredAt,
    required this.operation,
    required this.entityType,
    required this.description,
    this.entityId,
    this.username = 'المستخدم',
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      AuditLogColumns.id: id,
      AuditLogColumns.occurredAt: occurredAt.toIso8601String(),
      AuditLogColumns.operation: operation,
      AuditLogColumns.entityType: entityType,
      AuditLogColumns.entityId: entityId,
      AuditLogColumns.description: description,
      AuditLogColumns.username: username,
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map[AuditLogColumns.id] as int?,
      occurredAt:
          DateTime.parse(map[AuditLogColumns.occurredAt] as String),
      operation: map[AuditLogColumns.operation] as String,
      entityType: map[AuditLogColumns.entityType] as String,
      entityId: map[AuditLogColumns.entityId] as int?,
      description: map[AuditLogColumns.description] as String,
      username:
          map[AuditLogColumns.username] as String? ?? 'المستخدم',
    );
  }

  @override
  String toString() =>
      'AuditLogModel(id: $id, operation: $operation, entity: $entityType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
