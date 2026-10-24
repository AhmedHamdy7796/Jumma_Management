import 'package:gomaa_management/models/machine_part_model.dart';

/// Repository interface for machine parts and replacement history.
abstract class IMachinePartRepository {
  /// Retrieves all part replacement records in the system.
  Future<List<MachinePartModel>> getAll();

  /// Retrieves all part replacement records for a specific machine, latest first.
  Future<List<MachinePartModel>> getByMachineId(int machineId);

  /// Retrieves all part replacement records for a customer across all their machines.
  Future<List<MachinePartModel>> getByCustomerId(int customerId);

  /// Retrieves a specific part replacement record by ID.
  Future<MachinePartModel?> getById(int id);

  /// Creates a new part replacement record.
  /// If [inventoryItemId] is provided, deducts [quantityToDeduct] from that
  /// inventory item inside the same database transaction.
  Future<int> create(
    MachinePartModel part, {
    int? inventoryItemId,
    int quantityToDeduct = 1,
  });

  /// Updates an existing part replacement record.
  Future<int> update(MachinePartModel part);

  /// Deletes a part replacement record by ID.
  Future<int> delete(int id);
}
