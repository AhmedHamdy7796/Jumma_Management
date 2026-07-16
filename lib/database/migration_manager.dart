import 'package:sqflite/sqflite.dart';

import 'package:gomaa_management/core/logging/app_logger.dart';

/// Responsible for all SQLite schema migrations.
///
/// Each version is a self-contained static method. The [migrate] entry point
/// runs only the migrations between [oldVersion] and [newVersion], in order.
///
/// Rules:
/// - Never change an existing migration method — only add new ones.
/// - Each migration is wrapped in a savepoint so a failure rolls back
///   only that single version, not the entire upgrade.
/// - Version numbers must be sequential with no gaps.
class MigrationManager {
  MigrationManager._();

  /// The current schema version. Increment this every time a new migration
  /// is added. [DatabaseService] uses this as the `version` argument to
  /// [openDatabase].
  static const int currentVersion = 9;

  static const _tag = 'MigrationManager';

  // ── Migration registry ────────────────────────────────────────────────────

  static final List<_Migration> _migrations = [
    _Migration(version: 2, up: _v2AddPurchasesAndModelToCustomers),
    _Migration(version: 3, up: _v3AddModelToPurchases),
    _Migration(version: 4, up: _v4RenamePurchaseColumns),
    _Migration(version: 5, up: _v5RemovePhoneColumnFromCustomers),
    _Migration(version: 6, up: _v6AddImagePathToPurchases),
    _Migration(version: 7, up: _v7AddAllNewTablesAndIndexes),
    _Migration(version: 8, up: _v8AddUsersTable),
    _Migration(version: 9, up: _v9RefactorSchema),
  ];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Called by [DatabaseService] via the [onUpgrade] callback.
  ///
  /// Runs every pending migration between [oldVersion]+1 and [newVersion].
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    AppLogger.instance.info(
      'Starting schema migration from v$oldVersion to v$newVersion',
      tag: _tag,
    );

    for (final migration in _migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        AppLogger.instance.info(
          'Applying migration v${migration.version}...',
          tag: _tag,
        );
        try {
          // Each migration runs inside its own savepoint so a failure
          // only rolls back that version.
          await db.execute('SAVEPOINT migration_v${migration.version}');
          await migration.up(db);
          await db.execute('RELEASE migration_v${migration.version}');
          AppLogger.instance.info(
            'Migration v${migration.version} applied successfully.',
            tag: _tag,
          );
        } catch (e) {
          await db.execute(
            'ROLLBACK TO SAVEPOINT migration_v${migration.version}',
          );
          AppLogger.instance.error(
            'Migration v${migration.version} FAILED — rolled back.',
            tag: _tag,
            exception: e,
          );
          rethrow;
        }
      }
    }

    AppLogger.instance.info(
      'All migrations complete. Schema is now at v$newVersion.',
      tag: _tag,
    );
  }

  // ── v2 ────────────────────────────────────────────────────────────────────

  /// Adds [purchases] and [model] columns to the [customers] table.
  static Future<void> _v2AddPurchasesAndModelToCustomers(Database db) async {
    await db.execute(
      "ALTER TABLE customers ADD COLUMN purchases TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      "ALTER TABLE customers ADD COLUMN model TEXT NOT NULL DEFAULT ''",
    );
  }

  // ── v3 ────────────────────────────────────────────────────────────────────

  /// Adds [model] column to the [purchases] table.
  static Future<void> _v3AddModelToPurchases(Database db) async {
    await db.execute(
      "ALTER TABLE purchases ADD COLUMN model TEXT NOT NULL DEFAULT ''",
    );
  }

  // ── v4 ────────────────────────────────────────────────────────────────────

  /// Renames [productName] → [machineName] in the [purchases] table.
  ///
  /// SQLite does not support column renaming directly, so the table is
  /// recreated with the correct schema.
  static Future<void> _v4RenamePurchaseColumns(Database db) async {
    // Guard: if productName column doesn't exist, table was already correct.
    final info = await db.rawQuery('PRAGMA table_info(purchases)');
    final hasProductName = info.any((c) => c['name'] == 'productName');
    if (!hasProductName) return;

    await db.execute('ALTER TABLE purchases RENAME TO purchases_old');
    await db.execute('''
      CREATE TABLE purchases (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        machineName      TEXT    NOT NULL,
        model            TEXT    NOT NULL DEFAULT '',
        quantity         INTEGER NOT NULL,
        price            REAL    NOT NULL,
        totalAmount      REAL    NOT NULL,
        paidAmount       REAL    NOT NULL,
        remainingBalance REAL    NOT NULL,
        date             TEXT    NOT NULL,
        notes            TEXT    NOT NULL
      )
    ''');
    await db.execute('''
      INSERT INTO purchases
        (id, machineName, model, quantity, price,
         totalAmount, paidAmount, remainingBalance, date, notes)
      SELECT
        id, productName, model, quantity, price,
        totalAmount, paidAmount, remainingBalance, date, notes
      FROM purchases_old
    ''');
    await db.execute('DROP TABLE purchases_old');
  }

  // ── v5 ────────────────────────────────────────────────────────────────────

  /// Removes the [phone] column from the [customers] table.
  ///
  /// SQLite does not support DROP COLUMN below version 3.35.
  /// The table is recreated without the phone column.
  static Future<void> _v5RemovePhoneColumnFromCustomers(Database db) async {
    // Guard: only migrate if phone column exists.
    final info = await db.rawQuery('PRAGMA table_info(customers)');
    final hasPhone = info.any((c) => c['name'] == 'phone');
    if (!hasPhone) return;

    await db.execute('''
      CREATE TABLE customers_new (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        name             TEXT    NOT NULL,
        mobilePhone      TEXT    NOT NULL,
        transactionType  TEXT    NOT NULL,
        purchases        TEXT    NOT NULL DEFAULT '',
        model            TEXT    NOT NULL DEFAULT '',
        amount           REAL    NOT NULL,
        paidAmount       REAL    NOT NULL,
        remainingBalance REAL    NOT NULL,
        date             TEXT    NOT NULL,
        notes            TEXT    NOT NULL
      )
    ''');
    await db.execute('''
      INSERT INTO customers_new
        (id, name, mobilePhone, transactionType, purchases, model,
         amount, paidAmount, remainingBalance, date, notes)
      SELECT
        id, name, mobilePhone, transactionType, purchases, model,
        amount, paidAmount, remainingBalance, date, notes
      FROM customers
    ''');
    await db.execute('DROP TABLE customers');
    await db.execute('ALTER TABLE customers_new RENAME TO customers');
  }

  // ── v6 ────────────────────────────────────────────────────────────────────

  /// Adds the [imagePath] column to the [purchases] table.
  static Future<void> _v6AddImagePathToPurchases(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(purchases)');
    final hasImagePath = info.any((c) => c['name'] == 'imagePath');
    if (!hasImagePath) {
      await db.execute('ALTER TABLE purchases ADD COLUMN imagePath TEXT');
    }
  }

  // ── v7 ────────────────────────────────────────────────────────────────────

  /// Creates all new tables and all indexes.
  ///
  /// Uses IF NOT EXISTS throughout so the method is idempotent.
  static Future<void> _v7AddAllNewTablesAndIndexes(Database db) async {
    // equipment
    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipment (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT    NOT NULL,
        model          TEXT    NOT NULL DEFAULT '',
        serialNumber   TEXT,
        category       TEXT    NOT NULL DEFAULT '',
        purchaseDate   TEXT,
        purchasePrice  REAL    NOT NULL DEFAULT 0,
        currentStatus  TEXT    NOT NULL DEFAULT 'active',
        location       TEXT,
        notes          TEXT    NOT NULL DEFAULT ''
      )
    ''');

    // maintenance_records
    await db.execute('''
      CREATE TABLE IF NOT EXISTS maintenance_records (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId      INTEGER NOT NULL
                         REFERENCES equipment(id) ON DELETE CASCADE,
        technicianName   TEXT    NOT NULL,
        startDate        TEXT    NOT NULL,
        endDate          TEXT,
        issueDescription TEXT    NOT NULL,
        workDone         TEXT    NOT NULL DEFAULT '',
        cost             REAL    NOT NULL DEFAULT 0,
        status           TEXT    NOT NULL DEFAULT 'open',
        notes            TEXT    NOT NULL DEFAULT ''
      )
    ''');

    // maintenance_schedule
    await db.execute('''
      CREATE TABLE IF NOT EXISTS maintenance_schedule (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId     INTEGER NOT NULL
                        REFERENCES equipment(id) ON DELETE CASCADE,
        scheduledDate   TEXT    NOT NULL,
        type            TEXT    NOT NULL DEFAULT 'preventive',
        reminderEnabled INTEGER NOT NULL DEFAULT 1,
        completedAt     TEXT,
        notes           TEXT    NOT NULL DEFAULT ''
      )
    ''');

    // notes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        content    TEXT    NOT NULL DEFAULT '',
        entityType TEXT,
        entityId   INTEGER,
        createdAt  TEXT    NOT NULL,
        updatedAt  TEXT    NOT NULL
      )
    ''');

    // settings
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // audit_logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        occurredAt  TEXT    NOT NULL,
        operation   TEXT    NOT NULL,
        entityType  TEXT    NOT NULL,
        entityId    INTEGER,
        description TEXT    NOT NULL,
        username    TEXT    NOT NULL DEFAULT 'المستخدم'
      )
    ''');

    // ── Indexes ──────────────────────────────────────────────────────────

    // customers
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(mobilePhone)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_date ON customers(date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name_phone '
      'ON customers(name, mobilePhone)',
    );

    // purchases
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_machine '
      'ON purchases(machineName)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_purchases_date ON purchases(date)',
    );

    // fixes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_fixes_machine ON fixes(machineName)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_fixes_status ON fixes(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_fixes_date ON fixes(date)',
    );

    // equipment
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_equipment_name ON equipment(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_equipment_status '
      'ON equipment(currentStatus)',
    );

    // maintenance_records
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_maint_equipment '
      'ON maintenance_records(equipmentId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_maint_status '
      'ON maintenance_records(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_maint_start '
      'ON maintenance_records(startDate)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_maint_start_status '
      'ON maintenance_records(startDate, status)',
    );

    // maintenance_schedule
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sched_equipment '
      'ON maintenance_schedule(equipmentId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sched_date '
      'ON maintenance_schedule(scheduledDate)',
    );

    // notes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_entity '
      'ON notes(entityType, entityId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notes_created ON notes(createdAt)',
    );

    // audit_logs
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_occurred '
      'ON audit_logs(occurredAt)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_operation '
      'ON audit_logs(operation)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_audit_type_date '
      'ON audit_logs(entityType, occurredAt)',
    );
  }

  // ── v8 ────────────────────────────────────────────────────────────────────

  static Future<void> _v8AddUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT    UNIQUE NOT NULL,
        password TEXT    NOT NULL
      )
    ''');
    
    // Add default admin user — INSERT OR IGNORE prevents duplicates
    // if the migration runs more than once on the same database.
    await db.rawInsert('''
      INSERT OR IGNORE INTO users (username, password)
      VALUES ('admin', 'admin')
    ''');
  }

  // ── v9 ────────────────────────────────────────────────────────────────────

  /// Restructures the database schema:
  /// - Rebuilds [customers] table with company/address fields, removing old financial columns.
  /// - Creates [sales_invoices] table linked to customers.
  /// - Creates [inventory] table replacing the old [equipment] table.
  static Future<void> _v9RefactorSchema(Database db) async {
    // 1. Rebuild customers table (keep only contact/company info)
    await db.execute('''
      CREATE TABLE customers_v9 (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,
        mobilePhone TEXT NOT NULL,
        companyName TEXT,
        address     TEXT,
        notes       TEXT NOT NULL DEFAULT ''
      )
    ''');
    // Copy existing customer names and phones — discard old financial columns
    await db.execute('''
      INSERT INTO customers_v9 (id, name, mobilePhone, notes)
      SELECT id, name, mobilePhone, COALESCE(notes, '') FROM customers
    ''');
    await db.execute('DROP TABLE customers');
    await db.execute('ALTER TABLE customers_v9 RENAME TO customers');

    // 2. Create sales_invoices table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales_invoices (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId       INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
        itemName         TEXT    NOT NULL,
        model            TEXT    NOT NULL DEFAULT '',
        quantity         INTEGER NOT NULL DEFAULT 1,
        price            REAL    NOT NULL,
        totalAmount      REAL    NOT NULL,
        paidAmount       REAL    NOT NULL,
        remainingBalance REAL    NOT NULL,
        date             TEXT    NOT NULL,
        notes            TEXT    NOT NULL DEFAULT ''
      )
    ''');

    // 3. Create inventory table (replaces equipment)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL,
        model         TEXT    NOT NULL DEFAULT '',
        quantity      INTEGER NOT NULL DEFAULT 0,
        category      TEXT    NOT NULL DEFAULT '',
        purchasePrice REAL    NOT NULL DEFAULT 0,
        sellingPrice  REAL    NOT NULL DEFAULT 0,
        location      TEXT,
        notes         TEXT    NOT NULL DEFAULT ''
      )
    ''');

    // Migrate old equipment records to inventory (quantity defaults to 0)
    final equipInfo = await db.rawQuery('PRAGMA table_info(equipment)');
    if (equipInfo.isNotEmpty) {
      await db.execute('''
        INSERT INTO inventory (id, name, model, category, purchasePrice, notes)
        SELECT id, name, model, COALESCE(category, ''), COALESCE(purchasePrice, 0), COALESCE(notes, '')
        FROM equipment
      ''');
      await db.execute('DROP TABLE IF EXISTS equipment');
    }

    // 4. Rebuild customer index
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(mobilePhone)',
    );

    // 5. Sales invoices indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales_invoices(customerId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_date ON sales_invoices(date)',
    );

    // 6. Inventory indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_name ON inventory(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inventory_category ON inventory(category)',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal data type
// ─────────────────────────────────────────────────────────────────────────────

class _Migration {
  final int version;
  final Future<void> Function(Database db) up;

  const _Migration({required this.version, required this.up});
}
