import 'package:gomaa_management/database/database_constants.dart';

/// Represents a customer / client record.
///
/// Plain Dart class — no Flutter, no SQLite imports.
/// The [toMap] / [fromMap] pattern keeps serialization in one place.
class CustomerModel {
  final int? id;
  final String name;
  final String mobilePhone;

  /// Either `'income'` or `'expense'`.
  final String transactionType;
  final String purchases;
  final String model;
  final double amount;
  final double paidAmount;
  final double remainingBalance;
  final DateTime date;
  final String notes;

  const CustomerModel({
    this.id,
    required this.name,
    required this.mobilePhone,
    required this.transactionType,
    required this.purchases,
    required this.model,
    required this.amount,
    required this.paidAmount,
    required this.remainingBalance,
    required this.date,
    required this.notes,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      CustomerColumns.id: id,
      CustomerColumns.name: name,
      CustomerColumns.mobilePhone: mobilePhone,
      CustomerColumns.transactionType: transactionType,
      CustomerColumns.purchases: purchases,
      CustomerColumns.model: model,
      CustomerColumns.amount: amount,
      CustomerColumns.paidAmount: paidAmount,
      CustomerColumns.remainingBalance: remainingBalance,
      CustomerColumns.date: date.toIso8601String(),
      CustomerColumns.notes: notes,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map[CustomerColumns.id] as int?,
      name: map[CustomerColumns.name] as String,
      mobilePhone: map[CustomerColumns.mobilePhone] as String,
      transactionType: map[CustomerColumns.transactionType] as String,
      purchases: map[CustomerColumns.purchases] as String? ?? '',
      model: map[CustomerColumns.model] as String? ?? '',
      amount: (map[CustomerColumns.amount] as num).toDouble(),
      paidAmount: (map[CustomerColumns.paidAmount] as num).toDouble(),
      remainingBalance:
          (map[CustomerColumns.remainingBalance] as num).toDouble(),
      date: DateTime.parse(map[CustomerColumns.date] as String),
      notes: map[CustomerColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  CustomerModel copyWith({
    int? id,
    String? name,
    String? mobilePhone,
    String? transactionType,
    String? purchases,
    String? model,
    double? amount,
    double? paidAmount,
    double? remainingBalance,
    DateTime? date,
    String? notes,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      transactionType: transactionType ?? this.transactionType,
      purchases: purchases ?? this.purchases,
      model: model ?? this.model,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'CustomerModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
