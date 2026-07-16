import 'package:gomaa_management/database/database_constants.dart';

/// Represents an inventory item in the company's stock.
///
/// Distinct from [PurchaseModel] which tracks individual supplier purchases.
/// When a purchase is recorded, the corresponding inventory item quantity
/// is automatically incremented.
/// When a sale invoice is created, the quantity is decremented.
class InventoryModel {
  final int? id;
  final String name;
  final String model;
  final int quantity;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final String? location;
  final String notes;

  const InventoryModel({
    this.id,
    required this.name,
    required this.model,
    required this.quantity,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    this.location,
    this.notes = '',
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      InventoryColumns.id: id,
      InventoryColumns.name: name,
      InventoryColumns.model: model,
      InventoryColumns.quantity: quantity,
      InventoryColumns.category: category,
      InventoryColumns.purchasePrice: purchasePrice,
      InventoryColumns.sellingPrice: sellingPrice,
      InventoryColumns.location: location,
      InventoryColumns.notes: notes,
    };
  }

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map[InventoryColumns.id] as int?,
      name: map[InventoryColumns.name] as String,
      model: map[InventoryColumns.model] as String? ?? '',
      quantity: map[InventoryColumns.quantity] as int? ?? 0,
      category: map[InventoryColumns.category] as String? ?? '',
      purchasePrice:
          (map[InventoryColumns.purchasePrice] as num?)?.toDouble() ?? 0,
      sellingPrice:
          (map[InventoryColumns.sellingPrice] as num?)?.toDouble() ?? 0,
      location: map[InventoryColumns.location] as String?,
      notes: map[InventoryColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  InventoryModel copyWith({
    int? id,
    String? name,
    String? model,
    int? quantity,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    String? location,
    String? notes,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'InventoryModel(id: $id, name: $name, qty: $quantity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
