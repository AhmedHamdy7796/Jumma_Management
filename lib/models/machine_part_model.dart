import 'package:gomaa_management/database/database_constants.dart';

/// Represents a consumable part replacement for a customer machine.
class MachinePartModel {
  final int? id;
  final int machineId;
  final String partName;
  final String? partNumber;
  final DateTime replacedDate;
  final double? runningHoursAtReplacement;
  final DateTime? nextDueDate;
  final double? cost;
  final String? notes;
  final DateTime createdAt;

  const MachinePartModel({
    this.id,
    required this.machineId,
    required this.partName,
    this.partNumber,
    required this.replacedDate,
    this.runningHoursAtReplacement,
    this.nextDueDate,
    this.cost,
    this.notes,
    required this.createdAt,
  });

  /// Overdue if nextDueDate is before today (midnight).
  bool get isOverdue {
    if (nextDueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return due.isBefore(today);
  }

  /// Due within 14 days if not overdue and within the next 14 days.
  bool get isDueSoon {
    if (nextDueDate == null || isOverdue) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    final in14Days = today.add(const Duration(days: 14));
    return due.isBefore(in14Days) || due.isAtSameMomentAs(in14Days);
  }

  /// Number of days until due (negative if overdue).
  int? get daysUntilDue {
    if (nextDueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return due.difference(today).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      MachinePartColumns.id: id,
      MachinePartColumns.machineId: machineId,
      MachinePartColumns.partName: partName,
      MachinePartColumns.partNumber: partNumber,
      MachinePartColumns.replacedDate: replacedDate.toIso8601String(),
      MachinePartColumns.runningHoursAtReplacement: runningHoursAtReplacement,
      MachinePartColumns.nextDueDate: nextDueDate?.toIso8601String(),
      MachinePartColumns.cost: cost,
      MachinePartColumns.notes: notes,
      MachinePartColumns.createdAt: createdAt.toIso8601String(),
    };
  }

  factory MachinePartModel.fromMap(Map<String, dynamic> map) {
    return MachinePartModel(
      id: map[MachinePartColumns.id] as int?,
      machineId: map[MachinePartColumns.machineId] as int,
      partName: map[MachinePartColumns.partName] as String,
      partNumber: map[MachinePartColumns.partNumber] as String?,
      replacedDate: DateTime.parse(map[MachinePartColumns.replacedDate] as String),
      runningHoursAtReplacement:
          (map[MachinePartColumns.runningHoursAtReplacement] as num?)?.toDouble(),
      nextDueDate: map[MachinePartColumns.nextDueDate] != null
          ? DateTime.tryParse(map[MachinePartColumns.nextDueDate] as String)
          : null,
      cost: (map[MachinePartColumns.cost] as num?)?.toDouble(),
      notes: map[MachinePartColumns.notes] as String?,
      createdAt: DateTime.parse(map[MachinePartColumns.createdAt] as String),
    );
  }

  MachinePartModel copyWith({
    int? id,
    int? machineId,
    String? partName,
    String? partNumber,
    DateTime? replacedDate,
    double? runningHoursAtReplacement,
    DateTime? nextDueDate,
    double? cost,
    String? notes,
    DateTime? createdAt,
  }) {
    return MachinePartModel(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      partName: partName ?? this.partName,
      partNumber: partNumber ?? this.partNumber,
      replacedDate: replacedDate ?? this.replacedDate,
      runningHoursAtReplacement:
          runningHoursAtReplacement ?? this.runningHoursAtReplacement,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'MachinePartModel(id: $id, machineId: $machineId, partName: $partName, due: $nextDueDate)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachinePartModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
