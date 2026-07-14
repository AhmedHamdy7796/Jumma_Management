import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/equipment_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_equipment_repository.dart';

// States
abstract class EquipmentState extends Equatable {
  const EquipmentState();
  @override
  List<Object?> get props => [];
}

class EquipmentInitial extends EquipmentState {}
class EquipmentLoading extends EquipmentState {}
class EquipmentLoaded extends EquipmentState {
  final List<EquipmentModel> equipment;
  const EquipmentLoaded(this.equipment);
  @override
  List<Object?> get props => [equipment];
}
class EquipmentError extends EquipmentState {
  final String message;
  const EquipmentError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class EquipmentCubit extends Cubit<EquipmentState> {
  final IEquipmentRepository _equipmentRepository;
  List<EquipmentModel> _allEquipment = [];

  EquipmentCubit(this._equipmentRepository) : super(EquipmentInitial());

  Future<void> loadEquipment() async {
    emit(EquipmentLoading());
    try {
      _allEquipment = await _equipmentRepository.getAll();
      emit(EquipmentLoaded(_allEquipment));
    } catch (e) {
      emit(EquipmentError(e.toString()));
    }
  }

  Future<void> addEquipment(EquipmentModel item) async {
    try {
      await _equipmentRepository.create(item);
      await loadEquipment();
    } catch (e) {
      emit(EquipmentError(e.toString()));
    }
  }

  Future<void> updateEquipment(EquipmentModel item) async {
    try {
      await _equipmentRepository.update(item);
      await loadEquipment();
    } catch (e) {
      emit(EquipmentError(e.toString()));
    }
  }

  Future<void> deleteEquipment(int id) async {
    try {
      await _equipmentRepository.delete(id);
      await loadEquipment();
    } catch (e) {
      emit(EquipmentError(e.toString()));
    }
  }

  void searchEquipment(String query) {
    if (state is! EquipmentLoaded && state is! EquipmentInitial) return;

    if (query.isEmpty) {
      emit(EquipmentLoaded(_allEquipment));
      return;
    }

    final filtered = _allEquipment.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.model.toLowerCase().contains(query.toLowerCase()) ||
          (item.serialNumber != null && item.serialNumber!.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    emit(EquipmentLoaded(filtered));
  }
}
