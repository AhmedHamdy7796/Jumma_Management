import 'package:gomaa_management/models/machine_model.dart';

/// Repository interface for customer machines.
abstract class IMachineRepository {
  /// Retrieves all customer machines.
  Future<List<MachineModel>> getAll();

  /// Retrieves all machines installed at a specific customer's site.
  Future<List<MachineModel>> getByCustomerId(int customerId);

  /// Retrieves a specific machine by ID.
  Future<MachineModel?> getById(int id);

  /// Creates a new customer machine record.
  Future<int> create(MachineModel machine);

  /// Updates an existing customer machine record.
  Future<int> update(MachineModel machine);

  /// Deletes a customer machine by ID.
  Future<int> delete(int id);

  /// Searches machines by model or serial number.
  Future<List<MachineModel>> search(String query);
}
