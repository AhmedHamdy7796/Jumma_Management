import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/services/backup_service.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class BackupState extends Equatable {
  const BackupState();
  @override
  List<Object?> get props => [];
}

class BackupInitial extends BackupState {}

class BackupLoading extends BackupState {}

class BackupSuccess extends BackupState {
  final String filePath;
  final int sizeBytes;
  final String kind; // 'local' | 'drive'
  const BackupSuccess({
    required this.filePath,
    required this.sizeBytes,
    this.kind = 'local',
  });
  @override
  List<Object?> get props => [filePath, sizeBytes, kind];
}

class RestoreSuccess extends BackupState {}

class BackupError extends BackupState {
  final String message;
  const BackupError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

/// [onRestoreComplete] is called after a successful restore so that the
/// caller (Settings screen / main.dart) can reload all cubits.
class BackupCubit extends Cubit<BackupState> {
  final BackupService _backupService;

  /// Called after a successful restore. Reload ALL cubits here.
  final VoidCallback? onRestoreComplete;

  BackupCubit({
    BackupService? backupService,
    this.onRestoreComplete,
  })  : _backupService = backupService ?? BackupService(),
        super(BackupInitial());

  // ── Backup actions ──────────────────────────────────────────────────────────

  /// Creates a backup, prompting the user for a folder via the OS picker.
  /// If the picker is cancelled, no backup is created and state resets to initial.
  Future<void> createBackupWithPicker() async {
    if (isClosed) return;
    emit(BackupLoading());
    try {
      final result = await _backupService.createBackupWithPicker();
      if (result == null) {
        if (!isClosed) emit(BackupInitial());
        return;
      }
      if (!isClosed) {
        emit(BackupSuccess(
          filePath: result.filePath,
          sizeBytes: result.sizeBytes,
          kind: 'local',
        ));
      }
    } catch (e) {
      final msg = e is AppException ? e.userMessage : e.toString();
      if (!isClosed) emit(BackupError(msg));
    }
  }

  /// Creates a backup to the default local backups folder (no picker).
  Future<void> createLocalBackup() async {
    if (isClosed) return;
    emit(BackupLoading());
    try {
      final result = await _backupService.createBackupFile();
      if (!isClosed) {
        emit(BackupSuccess(
          filePath: result.filePath,
          sizeBytes: result.sizeBytes,
          kind: 'local',
        ));
      }
    } catch (e) {
      final msg = e is AppException ? e.userMessage : e.toString();
      if (!isClosed) emit(BackupError(msg));
    }
  }

  // ── Restore actions ─────────────────────────────────────────────────────────

  /// Opens a file picker for the user to select a `.db` file, validates it,
  /// and replaces the live database.
  Future<void> restoreWithPicker() async {
    if (isClosed) return;
    emit(BackupLoading());
    try {
      final picked = await _backupService.restoreWithPicker();
      if (!picked) {
        // User cancelled — reset to initial without error.
        if (!isClosed) emit(BackupInitial());
        return;
      }
      if (!isClosed) emit(RestoreSuccess());
      onRestoreComplete?.call();
    } catch (e) {
      final msg = e is AppException ? e.userMessage : 'فشلت عملية الاستعادة. يرجى المحاولة مرة أخرى.';
      if (!isClosed) emit(BackupError(msg));
    }
  }

  /// Restores directly from a known file path (used by legacy code path and
  /// tests).
  Future<void> restoreFromFile(String dbFilePath) async {
    if (isClosed) return;
    emit(BackupLoading());
    try {
      await _backupService.restoreFromFile(dbFilePath);
      if (!isClosed) emit(RestoreSuccess());
      onRestoreComplete?.call();
    } catch (e) {
      final msg = e is AppException ? e.userMessage : 'فشلت عملية الاستعادة. يرجى المحاولة مرة أخرى.';
      if (!isClosed) emit(BackupError(msg));
    }
  }
}
