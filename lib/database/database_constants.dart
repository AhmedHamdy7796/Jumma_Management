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
  static const String scheduledDate = 'scheduledDate';
  static const String type = 'type';
  static const String reminderEnabled = 'reminderEnabled';
  static const String completedAt = 'completedAt';
  static const String notes = 'notes';
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

  // Display
  static const String currencySymbol = 'currency_symbol';
  static const String language = 'language';
  static const String themeMode = 'theme_mode';

  // Backup
  static const String backupFolderPath = 'backup_folder_path';
  static const String autoBackupEnabled = 'auto_backup_enabled';
  static const String autoBackupIntervalDays = 'auto_backup_interval_days';
  static const String lastBackupAt = 'last_backup_at';
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
  static const String system = 'system';
}
