import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/maintenance_record_model.dart';
import 'package:gomaa_management/models/maintenance_schedule_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_maintenance_repository.dart';

// States
abstract class MaintenanceState extends Equatable {
  const MaintenanceState();
  @override
  List<Object?> get props => [];
}

class MaintenanceInitial extends MaintenanceState {}
class MaintenanceLoading extends MaintenanceState {}
class MaintenanceLoaded extends MaintenanceState {
  final List<MaintenanceRecordModel> records;
  final List<MaintenanceScheduleModel> schedule;
  const MaintenanceLoaded({required this.records, required this.schedule});
  @override
  List<Object?> get props => [records, schedule];
}
class MaintenanceError extends MaintenanceState {
  final String message;
  const MaintenanceError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class MaintenanceCubit extends Cubit<MaintenanceState> {
  final IMaintenanceRepository _maintenanceRepository;
  List<MaintenanceRecordModel> _allRecords = [];
  List<MaintenanceScheduleModel> _allSchedule = [];

  MaintenanceCubit(this._maintenanceRepository) : super(MaintenanceInitial());

  Future<void> loadMaintenanceData() async {
    emit(MaintenanceLoading());
    try {
      _allRecords = await _maintenanceRepository.getAllRecords();
      _allSchedule = await _maintenanceRepository.getAllScheduledItems();
      emit(MaintenanceLoaded(records: _allRecords, schedule: _allSchedule));
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> addRecord(MaintenanceRecordModel record) async {
    try {
      await _maintenanceRepository.createRecord(record);
      await loadMaintenanceData();
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> updateRecord(MaintenanceRecordModel record) async {
    try {
      await _maintenanceRepository.updateRecord(record);
      await loadMaintenanceData();
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _maintenanceRepository.deleteRecord(id);
      await loadMaintenanceData();
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> addScheduleItem(MaintenanceScheduleModel item) async {
    try {
      await _maintenanceRepository.createScheduleItem(item);
      await loadMaintenanceData();
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> updateScheduleItem(MaintenanceScheduleModel item) async {
    try {
      await _maintenanceRepository.updateScheduleItem(item);
      await loadMaintenanceData();
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }

  Future<void> deleteScheduleItem(int id) async {
    try {
      await _maintenanceRepository.deleteScheduleItem(id);
      await loadMaintenanceData();
    } catch (e) {
      emit(MaintenanceError(e.toString()));
    }
  }
}
