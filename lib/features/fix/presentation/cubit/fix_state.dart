import 'package:equatable/equatable.dart';
import 'package:gomaa_management/features/fix/data/models/fix.dart';

abstract class FixState extends Equatable {
  const FixState();

  @override
  List<Object> get props => [];
}

class FixInitial extends FixState {}

class FixLoading extends FixState {}

class FixLoaded extends FixState {
  final List<Fix> fixes;

  const FixLoaded(this.fixes);

  double get totalCost => fixes.fold(0.0, (sum, fix) => sum + fix.cost);

  int get pendingCount => fixes.where((fix) => fix.status == 'pending').length;
  int get inProgressCount =>
      fixes.where((fix) => fix.status == 'in_progress').length;
  int get completedCount =>
      fixes.where((fix) => fix.status == 'completed').length;

  @override
  List<Object> get props => [fixes];
}

class FixError extends FixState {
  final String message;

  const FixError(this.message);

  @override
  List<Object> get props => [message];
}
