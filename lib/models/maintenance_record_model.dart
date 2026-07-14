import 'package:gomaa_management/database/database_constants.dart';

/// Represents a maintenance work record performed on a piece of [equipment].
///
/// Always linked to an [EquipmentModel] via [equipmentId].
/// When the equipment is deleted, all its records are CASCADE deleted.
class MaintenanceRecordModel {
  final int? id;

  /// Foreign key → [EquipmentModel.id].
  final int equipmentId;
  final String technicianName;
  final DateTime startDate;
  final DateTime? endDate;
  final String issueDescription;
  final String workDone;
  final double cost;

  /// One of [MaintenanceRecordStatus]: `open`, `in_progress`, `closed`.
  final String status;
  final String notes;

  const MaintenanceRecordModel({
    this.id,
    required this.equipmentId,
    required this.technicianName,
    required this.startDate,
    required this.issueDescription,
    required this.status,
    this.endDate,
    this.workDone = '',
    this.cost = 0,
    this.notes = '',
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      MaintenanceRecordColumns.id: id,
      MaintenanceRecordColumns.equipmentId: equipmentId,
      MaintenanceRecordColumns.technicianName: technicianName,
      MaintenanceRecordColumns.startDate: startDate.toIso8601String(),
      MaintenanceRecordColumns.endDate: endDate?.toIso8601String(),
      MaintenanceRecordColumns.issueDescription: issueDescription,
      MaintenanceRecordColumns.workDone: workDone,
      MaintenanceRecordColumns.cost: cost,
      MaintenanceRecordColumns.status: status,
      MaintenanceRecordColumns.notes: notes,
    };
  }

  factory MaintenanceRecordModel.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecordModel(
      id: map[MaintenanceRecordColumns.id] as int?,
      equipmentId: map[MaintenanceRecordColumns.equipmentId] as int,
      technicianName: map[MaintenanceRecordColumns.technicianName] as String,
      startDate: DateTime.parse(
        map[MaintenanceRecordColumns.startDate] as String,
      ),
      endDate: map[MaintenanceRecordColumns.endDate] != null
          ? DateTime.tryParse(
              map[MaintenanceRecordColumns.endDate] as String,
            )
          : null,
      issueDescription:
          map[MaintenanceRecordColumns.issueDescription] as String,
      workDone: map[MaintenanceRecordColumns.workDone] as String? ?? '',
      cost: (map[MaintenanceRecordColumns.cost] as num?)?.toDouble() ?? 0,
      status: map[MaintenanceRecordColumns.status] as String,
      notes: map[MaintenanceRecordColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  MaintenanceRecordModel copyWith({
    int? id,
    int? equipmentId,
    String? technicianName,
    DateTime? startDate,
    DateTime? endDate,
    String? issueDescription,
    String? workDone,
    double? cost,
    String? status,
    String? notes,
  }) {
    return MaintenanceRecordModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      technicianName: technicianName ?? this.technicianName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      issueDescription: issueDescription ?? this.issueDescription,
      workDone: workDone ?? this.workDone,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'MaintenanceRecordModel(id: $id, equipmentId: $equipmentId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceRecordModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
