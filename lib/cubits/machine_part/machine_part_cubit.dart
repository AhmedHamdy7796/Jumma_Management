import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/machine_part_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_machine_part_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class MachinePartState extends Equatable {
  const MachinePartState();

  @override
  List<Object?> get props => [];
}

class MachinePartInitial extends MachinePartState {}

class MachinePartLoading extends MachinePartState {}

class MachinePartLoaded extends MachinePartState {
  final List<MachinePartModel> parts;
  const MachinePartLoaded(this.parts);

  @override
  List<Object?> get props => [parts];
}

class MachinePartError extends MachinePartState {
  final String message;
  const MachinePartError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class MachinePartCubit extends Cubit<MachinePartState> {
  final IMachinePartRepository _repo;
  final VoidCallback? onInventoryChanged;
  final VoidCallback? onDataChanged;
  int? _currentMachineId;
  int? _currentCustomerId;

  MachinePartCubit(
    this._repo, {
    this.onInventoryChanged,
    this.onDataChanged,
  }) : super(MachinePartInitial());

  int? get currentMachineId => _currentMachineId;

  Future<void> loadForMachine(int machineId) async {
    _currentMachineId = machineId;
    _currentCustomerId = null;
    emit(MachinePartLoading());
    try {
      final parts = await _repo.getByMachineId(machineId);
      emit(MachinePartLoaded(parts));
    } catch (e) {
      emit(MachinePartError(e.toString()));
    }
  }

  Future<void> loadForCustomer(int customerId) async {
    _currentCustomerId = customerId;
    _currentMachineId = null;
    emit(MachinePartLoading());
    try {
      final parts = await _repo.getByCustomerId(customerId);
      emit(MachinePartLoaded(parts));
    } catch (e) {
      emit(MachinePartError(e.toString()));
    }
  }

  Future<void> loadAll() async {
    _currentMachineId = null;
    _currentCustomerId = null;
    emit(MachinePartLoading());
    try {
      final parts = await _repo.getAll();
      emit(MachinePartLoaded(parts));
    } catch (e) {
      emit(MachinePartError(e.toString()));
    }
  }

  Future<void> _reloadCurrent() async {
    if (_currentMachineId != null) {
      await loadForMachine(_currentMachineId!);
    } else if (_currentCustomerId != null) {
      await loadForCustomer(_currentCustomerId!);
    } else {
      await loadAll();
    }
  }

  Future<int> addPartReplacement(
    MachinePartModel part, {
    int? inventoryItemId,
    int quantityToDeduct = 1,
  }) async {
    try {
      final id = await _repo.create(
        part,
        inventoryItemId: inventoryItemId,
        quantityToDeduct: quantityToDeduct,
      );
      await _reloadCurrent();
      if (inventoryItemId != null) {
        onInventoryChanged?.call();
      }
      onDataChanged?.call();
      return id;
    } catch (e) {
      emit(MachinePartError(e.toString()));
      rethrow;
    }
  }

  Future<void> updatePart(MachinePartModel part) async {
    try {
      await _repo.update(part);
      await _reloadCurrent();
      onDataChanged?.call();
    } catch (e) {
      emit(MachinePartError(e.toString()));
      rethrow;
    }
  }

  Future<void> deletePart(int id) async {
    try {
      await _repo.delete(id);
      await _reloadCurrent();
      onDataChanged?.call();
    } catch (e) {
      emit(MachinePartError(e.toString()));
      rethrow;
    }
  }
}
