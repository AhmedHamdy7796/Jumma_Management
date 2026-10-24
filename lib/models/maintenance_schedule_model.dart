import 'package:gomaa_management/database/database_constants.dart';

/// Represents a scheduled maintenance task for a piece of equipment.
///
/// Always linked to an [EquipmentModel] via [equipmentId].
/// [completedAt] is null until the task is marked done.
class MaintenanceScheduleModel {
  final int? id;

  /// Foreign key → [EquipmentModel.id].
  final int equipmentId;

  /// Foreign key → [CustomerModel.id] (optional).
  final int? customerId;

  /// Display name of the customer (populated from join, optional).
  final String? customerName;

  final DateTime scheduledDate;

  /// One of [MaintenanceScheduleType]: `preventive`, `inspection`, `calibration`.
  final String type;
  final bool reminderEnabled;

  /// Set when the scheduled task is completed. Null = not yet done.
  final DateTime? completedAt;
  final String notes;

  const MaintenanceScheduleModel({
    this.id,
    required this.equipmentId,
    this.customerId,
    this.customerName,
    required this.scheduledDate,
    required this.type,
    this.reminderEnabled = true,
    this.completedAt,
    this.notes = '',
  });

  bool get isCompleted => completedAt != null;

  bool get isOverdue =>
      completedAt == null && scheduledDate.isBefore(DateTime.now());

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      MaintenanceScheduleColumns.id: id,
      MaintenanceScheduleColumns.equipmentId: equipmentId,
      MaintenanceScheduleColumns.customerId: customerId,
      MaintenanceScheduleColumns.scheduledDate: scheduledDate.toIso8601String(),
      MaintenanceScheduleColumns.type: type,
      MaintenanceScheduleColumns.reminderEnabled: reminderEnabled ? 1 : 0,
      MaintenanceScheduleColumns.completedAt: completedAt?.toIso8601String(),
      MaintenanceScheduleColumns.notes: notes,
    };
  }

  factory MaintenanceScheduleModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceScheduleModel(
      id: map[MaintenanceScheduleColumns.id] as int?,
      equipmentId: map[MaintenanceScheduleColumns.equipmentId] as int,
      customerId: map[MaintenanceScheduleColumns.customerId] as int?,
      customerName: map['customerName'] as String?,
      scheduledDate: DateTime.parse(
        map[MaintenanceScheduleColumns.scheduledDate] as String,
      ),
      type: map[MaintenanceScheduleColumns.type] as String,
      reminderEnabled:
          (map[MaintenanceScheduleColumns.reminderEnabled] as int? ?? 1) == 1,
      completedAt: map[MaintenanceScheduleColumns.completedAt] != null
          ? DateTime.tryParse(
              map[MaintenanceScheduleColumns.completedAt] as String,
            )
          : null,
      notes: map[MaintenanceScheduleColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  MaintenanceScheduleModel copyWith({
    int? id,
    int? equipmentId,
    int? customerId,
    String? customerName,
    DateTime? scheduledDate,
    String? type,
    bool? reminderEnabled,
    DateTime? completedAt,
    String? notes,
  }) {
    return MaintenanceScheduleModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      type: type ?? this.type,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'MaintenanceScheduleModel(id: $id, scheduledDate: $scheduledDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
