import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/fix_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_fix_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class FixState extends Equatable {
  const FixState();

  @override
  List<Object?> get props => [];
}

class FixInitial extends FixState {}

class FixLoading extends FixState {}

class FixLoaded extends FixState {
  final List<FixModel> fixes;
  const FixLoaded(this.fixes);

  int get pendingCount => fixes.where((f) => f.status == 'pending').length;
  int get inProgressCount => fixes.where((f) => f.status == 'in_progress').length;
  int get completedCount => fixes.where((f) => f.status == 'completed').length;
  double get totalCost => fixes.fold(0, (sum, f) => sum + f.cost);

  @override
  List<Object?> get props => [fixes];
}

class FixError extends FixState {
  final String message;
  const FixError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class FixCubit extends Cubit<FixState> {
  final IFixRepository _fixRepository;
  List<FixModel> _allFixes = [];

  FixCubit(this._fixRepository) : super(FixInitial());

  Future<void> loadFixes() async {
    emit(FixLoading());
    try {
      _allFixes = await _fixRepository.getAll();
      emit(FixLoaded(List.from(_allFixes)));
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  Future<void> addFix(FixModel fix) async {
    try {
      await _fixRepository.create(fix);
      await loadFixes();
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  Future<void> updateFix(FixModel fix) async {
    try {
      await _fixRepository.update(fix);
      await loadFixes();
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  Future<void> deleteFix(int id) async {
    try {
      await _fixRepository.delete(id);
      await loadFixes();
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  void searchFixes(String query) {
    if (query.isEmpty) {
      emit(FixLoaded(List.from(_allFixes)));
      return;
    }
    final filtered = _allFixes.where((f) {
      final q = query.toLowerCase();
      return f.machineName.toLowerCase().contains(q) ||
          f.model.toLowerCase().contains(q) ||
          f.issue.toLowerCase().contains(q);
    }).toList();
    emit(FixLoaded(filtered));
  }

  void filterByStatus(String? status) {
    if (status == null || status.isEmpty) {
      emit(FixLoaded(List.from(_allFixes)));
      return;
    }
    final filtered = _allFixes.where((f) => f.status == status).toList();
    emit(FixLoaded(filtered));
  }
}
