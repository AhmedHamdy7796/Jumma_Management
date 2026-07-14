import 'package:gomaa_management/models/search_result_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_search_repository.dart';
import 'package:gomaa_management/repositories/search_repository.dart';

class SearchService {
  final ISearchRepository _searchRepository;

  SearchService({ISearchRepository? searchRepository})
      : _searchRepository = searchRepository ?? SearchRepository();

  Future<List<SearchResultModel>> search(String query) async {
    return await _searchRepository.globalSearch(query);
  }
}
