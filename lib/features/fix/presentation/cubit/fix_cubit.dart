import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/features/fix/data/models/fix.dart';
import 'package:gomaa_management/core/services/database_helper.dart';
import 'fix_state.dart';

class FixCubit extends Cubit<FixState> {
  FixCubit() : super(FixInitial());

  List<Fix> _allFixes = [];

  Future<void> loadFixes() async {
    emit(FixLoading());
    try {
      _allFixes = await DatabaseHelper.instance.getAllFixes();
      emit(FixLoaded(_allFixes));
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  Future<void> addFix(Fix fix) async {
    try {
      await DatabaseHelper.instance.createFix(fix);
      loadFixes();
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  Future<void> updateFix(Fix fix) async {
    try {
      await DatabaseHelper.instance.updateFix(fix);
      loadFixes();
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  Future<void> deleteFix(int id) async {
    try {
      await DatabaseHelper.instance.deleteFix(id);
      loadFixes();
    } catch (e) {
      emit(FixError(e.toString()));
    }
  }

  void searchFixes(String query) {
    if (state is! FixLoaded && state is! FixInitial) return;

    if (query.isEmpty) {
      emit(FixLoaded(_allFixes));
      return;
    }

    final filtered = _allFixes.where((fix) {
      return fix.machineName.toLowerCase().contains(query.toLowerCase()) ||
          fix.model.toLowerCase().contains(query.toLowerCase()) ||
          fix.issue.toLowerCase().contains(query.toLowerCase());
    }).toList();

    emit(FixLoaded(filtered));
  }

  void filterFixesByStatus(String status) {
    if (state is! FixLoaded && state is! FixInitial) return;

    if (status == 'all') {
      emit(FixLoaded(_allFixes));
      return;
    }

    final filtered = _allFixes.where((fix) => fix.status == status).toList();
    emit(FixLoaded(filtered));
  }
}
