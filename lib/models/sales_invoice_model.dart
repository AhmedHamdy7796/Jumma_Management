import 'package:gomaa_management/database/database_constants.dart';

/// Represents a sales invoice issued to a customer.
///
/// Each invoice is linked to a [CustomerModel] via [customerId].
/// The item sold can optionally reference a product from the inventory.
class SalesInvoiceModel {
  final int? id;
  final int customerId;
  final String customerName; // transient — populated via JOIN, not stored
  final String customerAddress; // transient — populated via JOIN
  final String itemName;
  final String model;
  final int quantity;
  final double price;
  final double totalAmount;
  final double paidAmount;
  final double remainingBalance;
  final DateTime date;
  final String notes;

  const SalesInvoiceModel({
    this.id,
    required this.customerId,
    this.customerName = '',
    this.customerAddress = '',
    required this.itemName,
    required this.model,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingBalance,
    required this.date,
    required this.notes,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      SalesInvoiceColumns.id: id,
      SalesInvoiceColumns.customerId: customerId,
      SalesInvoiceColumns.itemName: itemName,
      SalesInvoiceColumns.model: model,
      SalesInvoiceColumns.quantity: quantity,
      SalesInvoiceColumns.price: price,
      SalesInvoiceColumns.totalAmount: totalAmount,
      SalesInvoiceColumns.paidAmount: paidAmount,
      SalesInvoiceColumns.remainingBalance: remainingBalance,
      SalesInvoiceColumns.date: date.toIso8601String(),
      SalesInvoiceColumns.notes: notes,
    };
  }

  factory SalesInvoiceModel.fromMap(Map<String, dynamic> map) {
    return SalesInvoiceModel(
      id: map[SalesInvoiceColumns.id] as int?,
      customerId: map[SalesInvoiceColumns.customerId] as int,
      customerName: map['customerName'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      itemName: map[SalesInvoiceColumns.itemName] as String,
      model: map[SalesInvoiceColumns.model] as String? ?? '',
      quantity: map[SalesInvoiceColumns.quantity] as int? ?? 1,
      price: (map[SalesInvoiceColumns.price] as num).toDouble(),
      totalAmount: (map[SalesInvoiceColumns.totalAmount] as num).toDouble(),
      paidAmount: (map[SalesInvoiceColumns.paidAmount] as num).toDouble(),
      remainingBalance:
          (map[SalesInvoiceColumns.remainingBalance] as num).toDouble(),
      date: DateTime.parse(map[SalesInvoiceColumns.date] as String),
      notes: map[SalesInvoiceColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  SalesInvoiceModel copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? customerAddress,
    String? itemName,
    String? model,
    int? quantity,
    double? price,
    double? totalAmount,
    double? paidAmount,
    double? remainingBalance,
    DateTime? date,
    String? notes,
  }) {
    return SalesInvoiceModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      itemName: itemName ?? this.itemName,
      model: model ?? this.model,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'SalesInvoiceModel(id: $id, customerId: $customerId, itemName: $itemName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesInvoiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
