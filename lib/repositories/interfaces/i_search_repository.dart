import 'package:gomaa_management/models/search_result_model.dart';

/// Repository interface for Global Search operations across the application.
abstract class ISearchRepository {
  /// Queries database tables via UNION based on text matching.
  Future<List<SearchResultModel>> globalSearch(String query);
}
