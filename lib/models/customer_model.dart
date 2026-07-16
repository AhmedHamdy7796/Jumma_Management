import 'package:gomaa_management/database/database_constants.dart';

/// Represents a customer / client record.
///
/// A customer holds contact and company information.
/// Financial data (balance, invoices) is derived from [SalesInvoiceModel] records.
class CustomerModel {
  final int? id;
  final String name;
  final String mobilePhone;
  final String? companyName;
  final String? address;
  final String notes;

  const CustomerModel({
    this.id,
    required this.name,
    required this.mobilePhone,
    this.companyName,
    this.address,
    required this.notes,
  });

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      CustomerColumns.id: id,
      CustomerColumns.name: name,
      CustomerColumns.mobilePhone: mobilePhone,
      CustomerColumns.companyName: companyName,
      CustomerColumns.address: address,
      CustomerColumns.notes: notes,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map[CustomerColumns.id] as int?,
      name: map[CustomerColumns.name] as String,
      mobilePhone: map[CustomerColumns.mobilePhone] as String,
      companyName: map[CustomerColumns.companyName] as String?,
      address: map[CustomerColumns.address] as String?,
      notes: map[CustomerColumns.notes] as String? ?? '',
    );
  }

  // ── Immutable copy ────────────────────────────────────────────────────────

  CustomerModel copyWith({
    int? id,
    String? name,
    String? mobilePhone,
    String? companyName,
    String? address,
    String? notes,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
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
