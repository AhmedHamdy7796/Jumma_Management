import 'package:gomaa_management/database/database_constants.dart';

/// Represents a scheduled maintenance task for a piece of equipment.
///
/// Always linked to an [EquipmentModel] via [equipmentId].
/// [completedAt] is null until the task is marked done.
class MaintenanceScheduleModel {
  final int? id;

  /// Foreign key → [EquipmentModel.id].
  final int equipmentId;
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
    DateTime? scheduledDate,
    String? type,
    bool? reminderEnabled,
    DateTime? completedAt,
    String? notes,
  }) {
    return MaintenanceScheduleModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
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
