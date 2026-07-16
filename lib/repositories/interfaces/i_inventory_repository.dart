import 'package:gomaa_management/models/inventory_model.dart';

/// Repository interface for Inventory operations.
abstract class IInventoryRepository {
  /// Retrieves all inventory items.
  Future<List<InventoryModel>> getAll();

  /// Retrieves a specific item by ID. Returns null if not found.
  Future<InventoryModel?> getById(int id);

  /// Inserts a new inventory item. Returns the new ID.
  Future<int> create(InventoryModel item);

  /// Updates an existing inventory item. Returns the number of rows affected.
  Future<int> update(InventoryModel item);

  /// Deletes an inventory item by ID. Returns the number of rows affected.
  Future<int> delete(int id);

  /// Searches inventory items by name, model or category.
  Future<List<InventoryModel>> search(String query);

  /// Adjusts the quantity of an item by [delta] (positive = add, negative = remove).
  Future<void> adjustQuantity(int id, int delta);
}
