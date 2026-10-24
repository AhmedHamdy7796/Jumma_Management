import 'package:equatable/equatable.dart';

/// Represents an aggregated financial balance summary for a customer.
class CustomerBalanceSummary extends Equatable {
  final double totalInvoiced;
  final double totalPaid;
  final double totalRemaining;

  const CustomerBalanceSummary({
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalRemaining,
  });

  static const zero = CustomerBalanceSummary(
    totalInvoiced: 0.0,
    totalPaid: 0.0,
    totalRemaining: 0.0,
  );

  @override
  List<Object?> get props => [totalInvoiced, totalPaid, totalRemaining];
}
