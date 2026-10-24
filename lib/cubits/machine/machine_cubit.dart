import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/machine_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_machine_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class MachineState extends Equatable {
  const MachineState();

  @override
  List<Object?> get props => [];
}

class MachineInitial extends MachineState {}

class MachineLoading extends MachineState {}

class MachineLoaded extends MachineState {
  final List<MachineModel> machines;
  const MachineLoaded(this.machines);

  @override
  List<Object?> get props => [machines];
}

class MachineError extends MachineState {
  final String message;
  const MachineError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class MachineCubit extends Cubit<MachineState> {
  final IMachineRepository _repo;
  final VoidCallback? onDataChanged;
  List<MachineModel> _allMachines = [];
  int? _currentCustomerId;

  MachineCubit(
    this._repo, {
    this.onDataChanged,
  }) : super(MachineInitial());

  int? get currentCustomerId => _currentCustomerId;

  Future<void> loadAll() async {
    _currentCustomerId = null;
    emit(MachineLoading());
    try {
      _allMachines = await _repo.getAll();
      emit(MachineLoaded(List.from(_allMachines)));
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> loadForCustomer(int customerId) async {
    _currentCustomerId = customerId;
    emit(MachineLoading());
    try {
      final machines = await _repo.getByCustomerId(customerId);
      emit(MachineLoaded(machines));
    } catch (e) {
      emit(MachineError(e.toString()));
    }
  }

  Future<void> _reloadCurrent() async {
    if (_currentCustomerId != null) {
      await loadForCustomer(_currentCustomerId!);
    } else {
      await loadAll();
    }
  }

  Future<int> addMachine(MachineModel machine) async {
    try {
      final id = await _repo.create(machine);
      await _reloadCurrent();
      onDataChanged?.call();
      return id;
    } catch (e) {
      emit(MachineError(e.toString()));
      rethrow;
    }
  }

  Future<void> updateMachine(MachineModel machine) async {
    try {
      await _repo.update(machine);
      await _reloadCurrent();
      onDataChanged?.call();
    } catch (e) {
      emit(MachineError(e.toString()));
      rethrow;
    }
  }

  Future<void> deleteMachine(int id) async {
    try {
      await _repo.delete(id);
      await _reloadCurrent();
      onDataChanged?.call();
    } catch (e) {
      emit(MachineError(e.toString()));
      rethrow;
    }
  }
}
