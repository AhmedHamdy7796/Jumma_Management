import 'package:gomaa_management/database/database_constants.dart';

/// Represents a piece of company-owned equipment tracked for maintenance.
///
/// Distinct from [PurchaseModel] which tracks supplier purchases.
/// Equipment records are linked to [MaintenanceRecordModel] and
/// [MaintenanceScheduleModel] via [id].
class EquipmentModel {
  final int? id;
  final String name;
  final String model;
  final String? serialNumber;
  final String category;
  final DateTime? purchaseDate;
  final double purchasePrice;

  /// One of [EquipmentStatus] values: `active`, `maintenance`, `retired`.
  final String currentStatus;
  final String? location;
  final String notes;

  const EquipmentModel({
    this.id,
    required this.name,
    required this.model,
    required this.category,
    required this.currentStatus,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice = 0,
    this.location,
    this.notes = '',
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      EquipmentColumns.id: id,
      EquipmentColumns.name: name,
      EquipmentColumns.model: model,
      EquipmentColumns.serialNumber: serialNumber,
      EquipmentColumns.category: category,
      EquipmentColumns.purchaseDate: purchaseDate?.toIso8601String(),
      EquipmentColumns.purchasePrice: purchasePrice,
      EquipmentColumns.currentStatus: currentStatus,
      EquipmentColumns.location: location,
      EquipmentColumns.notes: notes,
    };
  }

  factory EquipmentModel.fromMap(Map<String, dynamic> map) {
    return EquipmentModel(
      id: map[EquipmentColumns.id] as int?,
      name: map[EquipmentColumns.name] as String,
      model: map[EquipmentColumns.model] as String? ?? '',
      serialNumber: map[EquipmentColumns.serialNumber] as String?,
      category: map[EquipmentColumns.category] as String? ?? '',
      purchaseDate: map[EquipmentColumns.purchaseDate] != null
          ? DateTime.tryParse(map[EquipmentColumns.purchaseDate] as String)
          : null,
      purchasePrice:
          (map[EquipmentColumns.purchasePrice] as num?)?.toDouble() ?? 0,
      currentStatus:
          map[EquipmentColumns.currentStatus] as String? ?? EquipmentStatus.active,
      location: map[EquipmentColumns.location] as String?,
      notes: map[EquipmentColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  EquipmentModel copyWith({
    int? id,
    String? name,
    String? model,
    String? serialNumber,
    String? category,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? currentStatus,
    String? location,
    String? notes,
  }) {
    return EquipmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentStatus: currentStatus ?? this.currentStatus,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'EquipmentModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
