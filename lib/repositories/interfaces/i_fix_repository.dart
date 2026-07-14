import 'package:gomaa_management/models/fix_model.dart';

/// Repository interface for Fix (Maintenance Jobs) operations.
abstract class IFixRepository {
  /// Retrieves all fix records, ordered by date descending.
  Future<List<FixModel>> getAll();

  /// Retrieves a specific fix by ID.
  Future<FixModel?> getById(int id);

  /// Inserts a new fix record.
  Future<int> create(FixModel fix);

  /// Updates an existing fix record.
  Future<int> update(FixModel fix);

  /// Deletes a fix by ID.
  Future<int> delete(int id);

  /// Searches fixes by machine name, model or issue description.
  Future<List<FixModel>> search(String query);
}
