import 'package:gomaa_management/models/purchase_model.dart';

/// Repository interface for Purchase operations.
abstract class IPurchaseRepository {
  /// Retrieves all purchase records, ordered by date descending.
  Future<List<PurchaseModel>> getAll();

  /// Retrieves a specific purchase by ID.
  Future<PurchaseModel?> getById(int id);

  /// Inserts a new purchase record.
  Future<int> create(PurchaseModel purchase);

  /// Updates an existing purchase record.
  Future<int> update(PurchaseModel purchase);

  /// Deletes a purchase by ID.
  Future<int> delete(int id);

  /// Searches purchases by machine name.
  Future<List<PurchaseModel>> search(String query);
}
