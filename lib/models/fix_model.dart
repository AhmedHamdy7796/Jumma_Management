import 'package:gomaa_management/database/database_constants.dart';

/// Represents a maintenance / repair job record.
class FixModel {
  final int? id;
  final String machineName;
  final String model;
  final String dryerType;
  final int quantity;
  final String issue;

  /// One of [FixStatus] values: `pending`, `in_progress`, `completed`.
  final String status;
  final double cost;
  final DateTime date;
  final String notes;

  const FixModel({
    this.id,
    required this.machineName,
    required this.model,
    required this.dryerType,
    required this.quantity,
    required this.issue,
    required this.status,
    required this.cost,
    required this.date,
    required this.notes,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      FixColumns.id: id,
      FixColumns.machineName: machineName,
      FixColumns.model: model,
      FixColumns.dryerType: dryerType,
      FixColumns.quantity: quantity,
      FixColumns.issue: issue,
      FixColumns.status: status,
      FixColumns.cost: cost,
      FixColumns.date: date.toIso8601String(),
      FixColumns.notes: notes,
    };
  }

  factory FixModel.fromMap(Map<String, dynamic> map) {
    return FixModel(
      id: map[FixColumns.id] as int?,
      machineName: map[FixColumns.machineName] as String,
      model: map[FixColumns.model] as String? ?? '',
      dryerType: map[FixColumns.dryerType] as String? ?? '',
      quantity: map[FixColumns.quantity] as int,
      issue: map[FixColumns.issue] as String,
      status: map[FixColumns.status] as String,
      cost: (map[FixColumns.cost] as num).toDouble(),
      date: DateTime.parse(map[FixColumns.date] as String),
      notes: map[FixColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  FixModel copyWith({
    int? id,
    String? machineName,
    String? model,
    String? dryerType,
    int? quantity,
    String? issue,
    String? status,
    double? cost,
    DateTime? date,
    String? notes,
  }) {
    return FixModel(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      model: model ?? this.model,
      dryerType: dryerType ?? this.dryerType,
      quantity: quantity ?? this.quantity,
      issue: issue ?? this.issue,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'FixModel(id: $id, machineName: $machineName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
