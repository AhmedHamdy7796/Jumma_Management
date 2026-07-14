import 'package:gomaa_management/database/database_constants.dart';

/// Represents a machine / product purchase record.
///
/// [imagePath] is a path **relative to the app's data directory**.
/// Use [ImageStorageService.resolveImage] to get the absolute [File].
class PurchaseModel {
  final int? id;
  final String machineName;
  final String model;
  final int quantity;
  final double price;
  final double totalAmount;
  final double paidAmount;
  final double remainingBalance;
  final DateTime date;
  final String notes;

  /// Relative path inside the app images folder, e.g. `images/purchases/<uuid>.jpg`.
  /// Null if no image was attached.
  final String? imagePath;

  const PurchaseModel({
    this.id,
    required this.machineName,
    required this.model,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingBalance,
    required this.date,
    required this.notes,
    this.imagePath,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      PurchaseColumns.id: id,
      PurchaseColumns.machineName: machineName,
      PurchaseColumns.model: model,
      PurchaseColumns.quantity: quantity,
      PurchaseColumns.price: price,
      PurchaseColumns.totalAmount: totalAmount,
      PurchaseColumns.paidAmount: paidAmount,
      PurchaseColumns.remainingBalance: remainingBalance,
      PurchaseColumns.date: date.toIso8601String(),
      PurchaseColumns.notes: notes,
      PurchaseColumns.imagePath: imagePath,
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map[PurchaseColumns.id] as int?,
      machineName: map[PurchaseColumns.machineName] as String,
      model: map[PurchaseColumns.model] as String? ?? '',
      quantity: map[PurchaseColumns.quantity] as int,
      price: (map[PurchaseColumns.price] as num).toDouble(),
      totalAmount: (map[PurchaseColumns.totalAmount] as num).toDouble(),
      paidAmount: (map[PurchaseColumns.paidAmount] as num).toDouble(),
      remainingBalance:
          (map[PurchaseColumns.remainingBalance] as num).toDouble(),
      date: DateTime.parse(map[PurchaseColumns.date] as String),
      notes: map[PurchaseColumns.notes] as String? ?? '',
      imagePath: map[PurchaseColumns.imagePath] as String?,
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  PurchaseModel copyWith({
    int? id,
    String? machineName,
    String? model,
    int? quantity,
    double? price,
    double? totalAmount,
    double? paidAmount,
    double? remainingBalance,
    DateTime? date,
    String? notes,
    String? imagePath,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      machineName: machineName ?? this.machineName,
      model: model ?? this.model,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() => 'PurchaseModel(id: $id, machineName: $machineName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
