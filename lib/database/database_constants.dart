/// All SQLite table names and column names as compile-time constants.
///
/// Rules:
/// - Never use raw strings like `'customers'` inside repository SQL.
/// - Always reference these constants instead.
/// - This makes renaming a table or column a single-file change.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Table Names
// ─────────────────────────────────────────────────────────────────────────────

abstract final class TableNames {
  static const String customers = 'customers';
  static const String purchases = 'purchases';
  static const String fixes = 'fixes';
  static const String inventory = 'inventory';
  static const String salesInvoices = 'sales_invoices';
  static const String maintenanceRecords = 'maintenance_records';
  static const String maintenanceSchedule = 'maintenance_schedule';
  static const String customerMachines = 'customer_machines';
  static const String machineParts = 'machine_parts';
  static const String notes = 'notes';
  static const String settings = 'settings';
  static const String auditLogs = 'audit_logs';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Customers
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CustomerColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String mobilePhone = 'mobilePhone';
  static const String companyName = 'companyName';
  static const String address = 'address';
  static const String notes = 'notes';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Purchases
// ─────────────────────────────────────────────────────────────────────────────

abstract final class PurchaseColumns {
  static const String id = 'id';
  static const String machineName = 'machineName';
  static const String model = 'model';
  static const String quantity = 'quantity';
  static const String price = 'price';
  static const String totalAmount = 'totalAmount';
  static const String paidAmount = 'paidAmount';
  static const String remainingBalance = 'remainingBalance';
  static const String date = 'date';
  static const String notes = 'notes';
  static const String imagePath = 'imagePath';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Fixes (Maintenance Jobs)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class FixColumns {
  static const String id = 'id';
  static const String machineName = 'machineName';
  static const String model = 'model';
  static const String dryerType = 'dryerType';
  static const String quantity = 'quantity';
  static const String issue = 'issue';
  static const String status = 'status';
  static const String cost = 'cost';
  static const String date = 'date';
  static const String notes = 'notes';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Equipment
// ─────────────────────────────────────────────────────────────────────────────

abstract final class InventoryColumns {
  static const String id = 'id';
  static const String name = 'name';
  static const String model = 'model';
  static const String quantity = 'quantity';
  static const String category = 'category';
  static const String purchasePrice = 'purchasePrice';
  static const String sellingPrice = 'sellingPrice';
  static const String location = 'location';
  static const String notes = 'notes';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Sales Invoices
// ─────────────────────────────────────────────────────────────────────────────

abstract final class SalesInvoiceColumns {
  static const String id = 'id';
  static const String customerId = 'customerId';
  static const String itemName = 'itemName';
  static const String model = 'model';
  static const String quantity = 'quantity';
  static const String price = 'price';
  static const String totalAmount = 'totalAmount';
  static const String paidAmount = 'paidAmount';
  static const String remainingBalance = 'remainingBalance';
  static const String date = 'date';
  static const String notes = 'notes';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Maintenance Records
// ─────────────────────────────────────────────────────────────────────────────

abstract final class MaintenanceRecordColumns {
  static const String id = 'id';
  static const String equipmentId = 'equipmentId';
  static const String customerId = 'customerId';
  static const String technicianName = 'technicianName';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String issueDescription = 'issueDescription';
  static const String workDone = 'workDone';
  static const String cost = 'cost';
  static const String status = 'status';
  static const String notes = 'notes';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Maintenance Schedule
// ─────────────────────────────────────────────────────────────────────────────

abstract final class MaintenanceScheduleColumns {
  static const String id = 'id';
  static const String equipmentId = 'equipmentId';
  static const String customerId = 'customerId';
  static const String scheduledDate = 'scheduledDate';
  static const String type = 'type';
  static const String reminderEnabled = 'reminderEnabled';
  static const String completedAt = 'completedAt';
  static const String notes = 'notes';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Customer Machines
// ─────────────────────────────────────────────────────────────────────────────

abstract final class CustomerMachineColumns {
  static const String id = 'id';
  static const String customerId = 'customer_id';
  static const String machineType = 'machine_type';
  static const String model = 'model';
  static const String manufactureYear = 'manufacture_year';
  static const String serialNumber = 'serial_number';
  static const String installDate = 'install_date';
  static const String notes = 'notes';
  static const String source = 'source';
  static const String brand = 'brand';
  static const String capacity = 'capacity';
  static const String createdAt = 'created_at';
}

abstract final class MachineSourceValues {
  static const String ours = 'ours';
  static const String other = 'other';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Machine Parts
// ─────────────────────────────────────────────────────────────────────────────

abstract final class MachinePartColumns {
  static const String id = 'id';
  static const String machineId = 'machine_id';
  static const String partName = 'part_name';
  static const String partNumber = 'part_number';
  static const String replacedDate = 'replaced_date';
  static const String runningHoursAtReplacement = 'running_hours_at_replacement';
  static const String nextDueDate = 'next_due_date';
  static const String cost = 'cost';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Notes
// ─────────────────────────────────────────────────────────────────────────────

abstract final class NoteColumns {
  static const String id = 'id';
  static const String title = 'title';
  static const String content = 'content';
  static const String entityType = 'entityType';
  static const String entityId = 'entityId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Settings
// ─────────────────────────────────────────────────────────────────────────────

abstract final class SettingsColumns {
  static const String key = 'key';
  static const String value = 'value';
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Names — Audit Logs
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AuditLogColumns {
  static const String id = 'id';
  static const String occurredAt = 'occurredAt';
  static const String operation = 'operation';
  static const String entityType = 'entityType';
  static const String entityId = 'entityId';
  static const String description = 'description';
  static const String username = 'username';
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Keys
// ─────────────────────────────────────────────────────────────────────────────

/// All keys used in the [settings] table.
///
/// Using constants prevents typo bugs when reading/writing settings.
abstract final class SettingsKeys {
  // Company
  static const String companyName = 'company_name';
  static const String companyLogoPath = 'company_logo_path';
  static const String companyPhone = 'company_phone';
  static const String companyAddress = 'company_address';
  static const String companyTaxNumber = 'company_tax_number';
  static const String invoiceFooterNote = 'invoice_footer_note';

  // Display
  static const String currencySymbol = 'currency_symbol';
  static const String themeMode = 'theme_mode';

  // Backup — local
  static const String backupFolderPath = 'backup_folder_path';
  static const String autoBackupEnabled = 'auto_backup_enabled';
  static const String autoBackupIntervalDays = 'auto_backup_interval_days';
  static const String lastBackupAt = 'last_backup_at';
  /// 'local' or 'drive' — records which kind of backup ran last.
  static const String lastBackupKind = 'last_backup_kind';
  /// Last error message from a backup/restore operation (empty = none).
  static const String lastBackupError = 'last_backup_error';

  // Backup — Google Drive (phase-2; Drive integration requires manual OAuth setup)
  static const String driveEnabled = 'drive_enabled';
  static const String driveFolderName = 'drive_folder_name';
  static const String driveFolderId = 'drive_folder_id';
  static const String driveBackupFrequency = 'drive_backup_frequency';
  static const String driveKeepCount = 'drive_keep_count';
  static const String driveWifiOnly = 'drive_wifi_only';
  static const String lastDriveBackupAt = 'last_drive_backup_at';
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Values
// ─────────────────────────────────────────────────────────────────────────────

abstract final class FixStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}

abstract final class EquipmentStatus {
  static const String active = 'active';
  static const String maintenance = 'maintenance';
  static const String retired = 'retired';
}

abstract final class MaintenanceRecordStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String closed = 'closed';
}

abstract final class MaintenanceScheduleType {
  static const String preventive = 'preventive';
  static const String inspection = 'inspection';
  static const String calibration = 'calibration';
}

abstract final class AuditOperation {
  static const String add = 'add';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String backup = 'backup';
  static const String restore = 'restore';
  static const String maintenance = 'maintenance';
}

abstract final class AuditEntityType {
  static const String customer = 'customer';
  static const String purchase = 'purchase';
  static const String fix = 'fix';
  static const String inventory = 'inventory';
  static const String salesInvoice = 'sales_invoice';
  static const String maintenanceRecord = 'maintenance_record';
  static const String customerMachine = 'customer_machine';
  static const String machinePart = 'machine_part';
  static const String system = 'system';
}
