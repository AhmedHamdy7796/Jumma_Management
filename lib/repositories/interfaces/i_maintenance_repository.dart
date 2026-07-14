import 'package:gomaa_management/models/maintenance_record_model.dart';
import 'package:gomaa_management/models/maintenance_schedule_model.dart';

/// Repository interface for Maintenance operations (both records and scheduling).
abstract class IMaintenanceRepository {
  // ── Maintenance Records ───────────────────────────────────────────────────

  /// Retrieves all maintenance records for a specific equipment.
  Future<List<MaintenanceRecordModel>> getRecordsForEquipment(int equipmentId);

  /// Retrieves a specific maintenance record by ID.
  Future<MaintenanceRecordModel?> getRecordById(int id);

  /// Inserts a new maintenance record.
  Future<int> createRecord(MaintenanceRecordModel record);

  /// Updates an existing maintenance record.
  Future<int> updateRecord(MaintenanceRecordModel record);

  /// Deletes a maintenance record by ID.
  Future<int> deleteRecord(int id);

  /// Retrieves all records in the system.
  Future<List<MaintenanceRecordModel>> getAllRecords();

  // ── Maintenance Scheduling ────────────────────────────────────────────────

  /// Retrieves the scheduled maintenance items for a specific equipment.
  Future<List<MaintenanceScheduleModel>> getScheduleForEquipment(int equipmentId);

  /// Retrieves all scheduled maintenance items.
  Future<List<MaintenanceScheduleModel>> getAllScheduledItems();

  /// Inserts a new maintenance schedule task.
  Future<int> createScheduleItem(MaintenanceScheduleModel item);

  /// Updates a maintenance schedule task.
  Future<int> updateScheduleItem(MaintenanceScheduleModel item);

  /// Deletes a maintenance schedule task by ID.
  Future<int> deleteScheduleItem(int id);
}
