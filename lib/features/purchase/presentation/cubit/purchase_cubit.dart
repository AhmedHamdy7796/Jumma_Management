import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/features/purchase/data/models/purchase.dart';
import 'package:gomaa_management/core/services/database_helper.dart';
import 'purchase_state.dart';

class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit() : super(PurchaseInitial());

  List<Purchase> _allPurchases = [];

  Future<void> loadPurchases() async {
    emit(PurchaseLoading());
    try {
      _allPurchases = await DatabaseHelper.instance.getAllPurchases();
      emit(PurchaseLoaded(_allPurchases));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> addPurchase(Purchase purchase) async {
    try {
      await DatabaseHelper.instance.createPurchase(purchase);
      loadPurchases();
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> updatePurchase(Purchase purchase) async {
    try {
      await DatabaseHelper.instance.updatePurchase(purchase);
      loadPurchases();
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> deletePurchase(int id) async {
    try {
      await DatabaseHelper.instance.deletePurchase(id);
      loadPurchases();
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  void searchPurchases(String query) {
    if (state is! PurchaseLoaded && state is! PurchaseInitial) return;

    if (query.isEmpty) {
      emit(PurchaseLoaded(_allPurchases));
      return;
    }

    final filtered = _allPurchases.where((purchase) {
      return purchase.machineName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    emit(PurchaseLoaded(filtered));
  }
}
