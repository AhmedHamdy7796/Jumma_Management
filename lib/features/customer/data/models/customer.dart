class Customer {
  final int? id;
  final String name;
  final String mobilePhone;
  final String transactionType; // 'income' or 'expense'
  final String purchases;
  final String model;
  final double amount;
  final double paidAmount;
  final double remainingBalance;
  final DateTime date;
  final String notes;

  Customer({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobilePhone': mobilePhone,
      'transactionType': transactionType,
      'purchases': purchases,
      'model': model,
      'amount': amount,
      'paidAmount': paidAmount,
      'remainingBalance': remainingBalance,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      mobilePhone: map['mobilePhone'] as String,
      transactionType: map['transactionType'] as String,
      purchases: map['purchases'] as String? ?? '',
      model: map['model'] as String? ?? '',
      amount: map['amount'] as double,
      paidAmount: map['paidAmount'] as double,
      remainingBalance: map['remainingBalance'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String,
    );
  }

  Customer copyWith({
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
    return Customer(
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
}
