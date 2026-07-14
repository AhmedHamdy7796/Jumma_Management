import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/audit_log_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_audit_log_repository.dart';

// States
abstract class AuditLogState extends Equatable {
  const AuditLogState();
  @override
  List<Object?> get props => [];
}

class AuditLogInitial extends AuditLogState {}
class AuditLogLoading extends AuditLogState {}
class AuditLogLoaded extends AuditLogState {
  final List<AuditLogModel> logs;
  const AuditLogLoaded(this.logs);
  @override
  List<Object?> get props => [logs];
}
class AuditLogError extends AuditLogState {
  final String message;
  const AuditLogError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class AuditLogCubit extends Cubit<AuditLogState> {
  final IAuditLogRepository _auditLogRepository;

  AuditLogCubit(this._auditLogRepository) : super(AuditLogInitial());

  Future<void> loadLogs({DateTime? from, DateTime? to, String? operation}) async {
    emit(AuditLogLoading());
    try {
      final logs = await _auditLogRepository.getAllLogs(from: from, to: to, operation: operation);
      emit(AuditLogLoaded(logs));
    } catch (e) {
      emit(AuditLogError(e.toString()));
    }
  }

  Future<void> clearLogsOlderThan(DateTime date) async {
    try {
      await _auditLogRepository.clearLogsOlderThan(date);
      await loadLogs();
    } catch (e) {
      emit(AuditLogError(e.toString()));
    }
  }
}
