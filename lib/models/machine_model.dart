import 'package:gomaa_management/database/database_constants.dart';

/// Represents a machine installed at a customer's site.
class MachineModel {
  final int? id;
  final int customerId;
  final String machineType;
  final String model;
  final int? manufactureYear;
  final String? serialNumber;
  final DateTime? installDate;
  final String? notes;
  final String source;
  final String? brand;
  final String? capacity;
  final DateTime createdAt;

  const MachineModel({
    this.id,
    required this.customerId,
    required this.machineType,
    required this.model,
    this.manufactureYear,
    this.serialNumber,
    this.installDate,
    this.notes,
    this.source = MachineSourceValues.other,
    this.brand,
    this.capacity,
    required this.createdAt,
  });

  bool get isOurs => source == MachineSourceValues.ours;
  String get sourceDisplayName => isOurs ? 'منّا' : 'من مورد آخر';

  Map<String, dynamic> toMap() {
    return {
      CustomerMachineColumns.id: id,
      CustomerMachineColumns.customerId: customerId,
      CustomerMachineColumns.machineType: machineType,
      CustomerMachineColumns.model: model,
      CustomerMachineColumns.manufactureYear: manufactureYear,
      CustomerMachineColumns.serialNumber: serialNumber,
      CustomerMachineColumns.installDate: installDate?.toIso8601String(),
      CustomerMachineColumns.notes: notes,
      CustomerMachineColumns.source: source,
      CustomerMachineColumns.brand: brand,
      CustomerMachineColumns.capacity: capacity,
      CustomerMachineColumns.createdAt: createdAt.toIso8601String(),
    };
  }

  factory MachineModel.fromMap(Map<String, dynamic> map) {
    return MachineModel(
      id: map[CustomerMachineColumns.id] as int?,
      customerId: map[CustomerMachineColumns.customerId] as int,
      machineType: map[CustomerMachineColumns.machineType] as String,
      model: map[CustomerMachineColumns.model] as String,
      manufactureYear: map[CustomerMachineColumns.manufactureYear] as int?,
      serialNumber: map[CustomerMachineColumns.serialNumber] as String?,
      installDate: map[CustomerMachineColumns.installDate] != null
          ? DateTime.tryParse(map[CustomerMachineColumns.installDate] as String)
          : null,
      notes: map[CustomerMachineColumns.notes] as String?,
      source: (map[CustomerMachineColumns.source] as String?) ?? MachineSourceValues.other,
      brand: map[CustomerMachineColumns.brand] as String?,
      capacity: map[CustomerMachineColumns.capacity] as String?,
      createdAt: DateTime.parse(
        map[CustomerMachineColumns.createdAt] as String,
      ),
    );
  }

  MachineModel copyWith({
    int? id,
    int? customerId,
    String? machineType,
    String? model,
    int? manufactureYear,
    String? serialNumber,
    DateTime? installDate,
    String? notes,
    String? source,
    String? brand,
    String? capacity,
    DateTime? createdAt,
  }) {
    return MachineModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      machineType: machineType ?? this.machineType,
      model: model ?? this.model,
      manufactureYear: manufactureYear ?? this.manufactureYear,
      serialNumber: serialNumber ?? this.serialNumber,
      installDate: installDate ?? this.installDate,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      brand: brand ?? this.brand,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'MachineModel(id: $id, customerId: $customerId, model: $model, type: $machineType, source: $source, brand: $brand, capacity: $capacity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MachineModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
