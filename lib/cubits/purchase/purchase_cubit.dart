import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/purchase_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_purchase_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object?> get props => [];
}

class PurchaseInitial extends PurchaseState {}

class PurchaseLoading extends PurchaseState {}

class PurchaseLoaded extends PurchaseState {
  final List<PurchaseModel> purchases;
  const PurchaseLoaded(this.purchases);

  double get totalAmount => purchases.fold(0, (sum, p) => sum + p.totalAmount);
  double get totalPaid => purchases.fold(0, (sum, p) => sum + p.paidAmount);
  double get totalRemaining => purchases.fold(0, (sum, p) => sum + p.remainingBalance);

  @override
  List<Object?> get props => [purchases];
}

class PurchaseError extends PurchaseState {
  final String message;
  const PurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class PurchaseCubit extends Cubit<PurchaseState> {
  final IPurchaseRepository _purchaseRepository;
  List<PurchaseModel> _allPurchases = [];

  PurchaseCubit(this._purchaseRepository) : super(PurchaseInitial());

  Future<void> loadPurchases() async {
    emit(PurchaseLoading());
    try {
      _allPurchases = await _purchaseRepository.getAll();
      emit(PurchaseLoaded(List.from(_allPurchases)));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    try {
      await _purchaseRepository.create(purchase);
      await loadPurchases();
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> updatePurchase(PurchaseModel purchase) async {
    try {
      await _purchaseRepository.update(purchase);
      await loadPurchases();
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> deletePurchase(int id) async {
    try {
      await _purchaseRepository.delete(id);
      await loadPurchases();
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  void searchPurchases(String query) {
    if (query.isEmpty) {
      emit(PurchaseLoaded(List.from(_allPurchases)));
      return;
    }
    final filtered = _allPurchases.where((p) {
      final q = query.toLowerCase();
      return p.machineName.toLowerCase().contains(q) ||
          p.model.toLowerCase().contains(q);
    }).toList();
    emit(PurchaseLoaded(filtered));
  }
}
