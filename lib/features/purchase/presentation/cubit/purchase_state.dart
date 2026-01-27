import 'package:equatable/equatable.dart';
import 'package:gomaa_management/features/purchase/data/models/purchase.dart';

abstract class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object> get props => [];
}

class PurchaseInitial extends PurchaseState {}

class PurchaseLoading extends PurchaseState {}

class PurchaseLoaded extends PurchaseState {
  final List<Purchase> purchases;

  const PurchaseLoaded(this.purchases);

  double get totalAmount =>
      purchases.fold(0.0, (sum, purchase) => sum + purchase.totalAmount);

  double get totalPaid =>
      purchases.fold(0.0, (sum, purchase) => sum + purchase.paidAmount);

  double get totalRemaining =>
      purchases.fold(0.0, (sum, purchase) => sum + purchase.remainingBalance);

  @override
  List<Object> get props => [purchases];
}

class PurchaseError extends PurchaseState {
  final String message;

  const PurchaseError(this.message);

  @override
  List<Object> get props => [message];
}
