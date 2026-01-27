import 'package:equatable/equatable.dart';
import 'package:gomaa_management/features/customer/data/models/customer.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;

  const CustomerLoaded(this.customers);

  double get totalAmount =>
      customers.fold(0.0, (sum, customer) => sum + customer.amount);

  double get totalPaid =>
      customers.fold(0.0, (sum, customer) => sum + customer.paidAmount);

  double get totalRemaining =>
      customers.fold(0.0, (sum, customer) => sum + customer.remainingBalance);

  @override
  List<Object> get props => [customers];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object> get props => [message];
}
