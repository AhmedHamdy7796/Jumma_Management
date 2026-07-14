import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/search_result_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_search_repository.dart';

// States
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchLoaded extends SearchState {
  final List<SearchResultModel> results;
  const SearchLoaded(this.results);
  @override
  List<Object?> get props => [results];
}
class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class SearchCubit extends Cubit<SearchState> {
  final ISearchRepository _searchRepository;

  SearchCubit(this._searchRepository) : super(SearchInitial());

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }
    
    emit(SearchLoading());
    try {
      final results = await _searchRepository.globalSearch(query);
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  void clearSearch() {
    emit(SearchInitial());
  }
}
