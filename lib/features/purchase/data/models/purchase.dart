class Purchase {
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

  final String? imagePath;

  Purchase({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'machineName': machineName,
      'model': model,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingBalance': remainingBalance,
      'date': date.toIso8601String(),
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      machineName: map['machineName'] as String,
      model: map['model'] as String? ?? '',
      quantity: map['quantity'] as int,
      price: map['price'] as double,
      totalAmount: map['totalAmount'] as double,
      paidAmount: map['paidAmount'] as double,
      remainingBalance: map['remainingBalance'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  Purchase copyWith({
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
    return Purchase(
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
}
