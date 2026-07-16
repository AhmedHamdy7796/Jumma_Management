import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/inventory_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_inventory_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<InventoryModel> items;
  const InventoryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class InventoryCubit extends Cubit<InventoryState> {
  final IInventoryRepository _repo;
  List<InventoryModel> _allItems = [];

  InventoryCubit(this._repo) : super(InventoryInitial());

  Future<void> loadInventory() async {
    emit(InventoryLoading());
    try {
      _allItems = await _repo.getAll();
      emit(InventoryLoaded(List.from(_allItems)));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> addItem(InventoryModel item) async {
    try {
      await _repo.create(item);
      await loadInventory();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> updateItem(InventoryModel item) async {
    try {
      await _repo.update(item);
      await loadInventory();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _repo.delete(id);
      await loadInventory();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  void searchInventory(String query) {
    if (query.isEmpty) {
      emit(InventoryLoaded(List.from(_allItems)));
      return;
    }
    final q = query.toLowerCase();
    final filtered = _allItems.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.model.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
    emit(InventoryLoaded(filtered));
  }
}
