class Fix {
  final int? id;
  final String machineName;
  final String model;
  final String dryerType;
  final int quantity;
  final String issue;
  final String status; // 'pending', 'in_progress', 'completed'
  final double cost;
  final DateTime date;
  final String notes;

  Fix({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'machineName': machineName,
      'model': model,
      'dryerType': dryerType,
      'quantity': quantity,
      'issue': issue,
      'status': status,
      'cost': cost,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Fix.fromMap(Map<String, dynamic> map) {
    return Fix(
      id: map['id'] as int?,
      machineName: map['machineName'] as String,
      model: map['model'] as String,
      dryerType: map['dryerType'] as String,
      quantity: map['quantity'] as int,
      issue: map['issue'] as String,
      status: map['status'] as String,
      cost: map['cost'] as double,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String,
    );
  }

  Fix copyWith({
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
    return Fix(
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
}
