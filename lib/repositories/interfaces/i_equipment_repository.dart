import 'package:gomaa_management/models/equipment_model.dart';

/// Repository interface for Equipment operations.
abstract class IEquipmentRepository {
  /// Retrieves all equipment records.
  Future<List<EquipmentModel>> getAll();

  /// Retrieves a specific equipment by ID.
  Future<EquipmentModel?> getById(int id);

  /// Inserts a new equipment record.
  Future<int> create(EquipmentModel equipment);

  /// Updates an existing equipment record.
  Future<int> update(EquipmentModel equipment);

  /// Deletes an equipment by ID.
  Future<int> delete(int id);

  /// Searches equipment by name or model or serial number.
  Future<List<EquipmentModel>> search(String query);
}
