import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/services/backup_service.dart';

// States
abstract class BackupState extends Equatable {
  const BackupState();
  @override
  List<Object?> get props => [];
}

class BackupInitial extends BackupState {}
class BackupLoading extends BackupState {}
class BackupSuccess extends BackupState {
  final String path;
  const BackupSuccess(this.path);
  @override
  List<Object?> get props => [path];
}
class RestoreSuccess extends BackupState {}
class BackupError extends BackupState {
  final String message;
  const BackupError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class BackupCubit extends Cubit<BackupState> {
  final BackupService _backupService;

  BackupCubit({BackupService? backupService})
      : _backupService = backupService ?? BackupService(),
        super(BackupInitial());

  Future<void> createBackup(String destinationDir) async {
    emit(BackupLoading());
    try {
      final path = await _backupService.createBackup(destinationDir);
      emit(BackupSuccess(path));
    } catch (e) {
      emit(BackupError(e.toString()));
    }
  }

  Future<void> restoreBackup(String backupFolderPath) async {
    emit(BackupLoading());
    try {
      await _backupService.restoreBackup(backupFolderPath);
      emit(RestoreSuccess());
    } catch (e) {
      emit(BackupError(e.toString()));
    }
  }
}
