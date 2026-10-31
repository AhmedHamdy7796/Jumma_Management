import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';
import 'package:gomaa_management/database/migration_manager.dart';

/// The single access point for the SQLite database.
///
/// Responsibilities:
/// - Determines the correct platform-specific database file path.
/// - Applies all required SQLite PRAGMAs on every connection open.
/// - Delegates schema creation and migrations to [MigrationManager].
/// - Exposes [close] and [reopen] for the Backup/Restore system.
///
/// Usage:
/// ```dart
/// final db = await DatabaseService.instance.database;
/// final rows = await db.query('customers');
/// ```
class DatabaseService {
  DatabaseService._() : _customDbPath = null;

  /// Singleton instance. Inject this into every repository via constructor.
  static final DatabaseService instance = DatabaseService._();

  /// Optional custom path (used in tests or custom storage configurations).
  final String? _customDbPath;

  /// Creates a [DatabaseService] targeting a specific [customDbPath].
  DatabaseService.withPath(String customDbPath) : _customDbPath = customDbPath;

  static const _tag = 'DatabaseService';
  static const _dbFileName = 'gomaa_management.db';

  Database? _database;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the open database, initializing it on first access.
  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  /// Returns the absolute path of the database file.
  ///
  /// Used by [BackupService] to locate the file for copying.
  Future<String> get databasePath async {
    if (_customDbPath != null) return _customDbPath;
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, _dbFileName);
  }

  /// Closes the database connection.
  ///
  /// Called by [BackupService] before copying or replacing the file.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      AppLogger.instance.info('Database closed.', tag: _tag);
    }
    _database = null;
  }

  /// Re-opens the database after a restore operation.
  Future<void> reopen() async {
    _database = await _open();
    AppLogger.instance.info('Database reopened.', tag: _tag);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Database> _open() async {
    try {
      final String path;
      final String backupsDir;

      if (_customDbPath != null) {
        path = _customDbPath;
        final parentDir = Directory(dirname(path));
        if (!parentDir.existsSync()) {
          parentDir.createSync(recursive: true);
        }
        backupsDir = join(parentDir.path, 'backups');
      } else {
        final dir = await getApplicationSupportDirectory();
        final appDir = Directory(dir.path);
        if (!appDir.existsSync()) {
          appDir.createSync(recursive: true);
        }
        path = join(dir.path, _dbFileName);
        backupsDir = join(dir.path, 'backups');
      }

      await MigrationManager.createSafetyCopyBeforeUpgrade(path, backupsDir);
      AppLogger.instance.info('Opening database at: $path', tag: _tag);

      final db = await openDatabase(
        path,
        version: MigrationManager.currentVersion,
        onCreate: _onCreate,
        onUpgrade: MigrationManager.migrate,
        onOpen: _onOpen,
      );

      return db;
    } catch (e) {
      AppLogger.instance.error(
        'Failed to open database.',
        tag: _tag,
        exception: e,
      );
      throw AppDatabaseException(
        technicalDetail: 'DatabaseService._open() failed: $e',
        userMessage: 'فشل فتح قاعدة البيانات. يرجى إعادة تشغيل التطبيق.',
      );
    }
  }

  /// Called when the database is opened (every launch).
  ///
  /// Applies performance and integrity PRAGMAs.
  Future<void> _onOpen(Database db) async {
    // Enforce referential integrity — OFF by default in SQLite.
    await db.execute('PRAGMA foreign_keys = ON');

    // WAL mode: better concurrency and crash recovery.
    await db.execute('PRAGMA journal_mode = WAL');

    // NORMAL: safe sync without fsync on every write (good balance).
    await db.execute('PRAGMA synchronous = NORMAL');

    // 8 MB in-memory page cache (negative value = kilobytes).
    await db.execute('PRAGMA cache_size = -8000');

    // Keep temp tables in memory instead of disk.
    await db.execute('PRAGMA temp_store = MEMORY');

    AppLogger.instance.info('Database PRAGMAs applied.', tag: _tag);
  }

  /// Called on a brand-new installation (no existing database).
  ///
  /// Creates the complete schema at the latest version directly —
  /// no need to run individual migrations for a fresh install.
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.instance.info(
      'Creating new database at version $version.',
      tag: _tag,
    );

    await db.transaction((txn) async {
      // ── Existing tables ─────────────────────────────────────────────────

      await txn.execute('''
        CREATE TABLE customers (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          name        TEXT NOT NULL,
          mobilePhone TEXT NOT NULL,
          companyName TEXT,
          address     TEXT,
          notes       TEXT NOT NULL DEFAULT ''
        )
      ''');

      await txn.execute('''
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
          notes            TEXT    NOT NULL DEFAULT '',
          imagePath        TEXT
        )
      ''');

      await txn.execute('''
        CREATE TABLE fixes (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          machineName TEXT    NOT NULL,
          model       TEXT    NOT NULL DEFAULT '',
          dryerType   TEXT    NOT NULL DEFAULT '',
          quantity    INTEGER NOT NULL,
          issue       TEXT    NOT NULL,
          status      TEXT    NOT NULL DEFAULT 'pending',
          cost        REAL    NOT NULL DEFAULT 0,
          date        TEXT    NOT NULL,
          notes       TEXT    NOT NULL DEFAULT ''
        )
      ''');

      // ── New tables ───────────────────────────────────────────────────────

      await txn.execute('''
        CREATE TABLE sales_invoices (
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

      await txn.execute('''
        CREATE TABLE inventory (
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

      await txn.execute('''
        CREATE TABLE maintenance_records (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          equipmentId      INTEGER NOT NULL
                           REFERENCES inventory(id) ON DELETE CASCADE,
          customerId       INTEGER
                           REFERENCES customers(id) ON DELETE SET NULL,
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

      await txn.execute('''
        CREATE TABLE maintenance_schedule (
          id              INTEGER PRIMARY KEY AUTOINCREMENT,
          equipmentId     INTEGER NOT NULL
                          REFERENCES inventory(id) ON DELETE CASCADE,
          customerId      INTEGER
                          REFERENCES customers(id) ON DELETE SET NULL,
          scheduledDate   TEXT    NOT NULL,
          type            TEXT    NOT NULL DEFAULT 'preventive',
          reminderEnabled INTEGER NOT NULL DEFAULT 1,
          completedAt     TEXT,
          notes           TEXT    NOT NULL DEFAULT ''
        )
      ''');

      await txn.execute('''
        CREATE TABLE customer_machines (
          id               INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id      INTEGER NOT NULL
                           REFERENCES customers(id) ON DELETE CASCADE,
          machine_type     TEXT    NOT NULL,
          model            TEXT    NOT NULL,
          manufacture_year INTEGER,
          serial_number    TEXT,
          install_date     TEXT,
          notes            TEXT,
          source           TEXT    NOT NULL DEFAULT 'other',
          brand            TEXT,
          capacity         TEXT,
          created_at       TEXT    NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE machine_parts (
          id                          INTEGER PRIMARY KEY AUTOINCREMENT,
          machine_id                  INTEGER NOT NULL
                                      REFERENCES customer_machines(id) ON DELETE CASCADE,
          part_name                   TEXT    NOT NULL,
          part_number                 TEXT,
          replaced_date               TEXT    NOT NULL,
          running_hours_at_replacement REAL,
          next_due_date               TEXT,
          cost                        REAL,
          notes                       TEXT,
          created_at                  TEXT    NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE notes (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          title      TEXT    NOT NULL,
          content    TEXT    NOT NULL DEFAULT '',
          entityType TEXT,
          entityId   INTEGER,
          createdAt  TEXT    NOT NULL,
          updatedAt  TEXT    NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      await txn.execute('''
        CREATE TABLE audit_logs (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          occurredAt  TEXT    NOT NULL,
          operation   TEXT    NOT NULL,
          entityType  TEXT    NOT NULL,
          entityId    INTEGER,
          description TEXT    NOT NULL,
          username    TEXT    NOT NULL DEFAULT 'المستخدم'
        )
      ''');

      // users
      await txn.execute('''
        CREATE TABLE users (
          id       INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT    UNIQUE NOT NULL,
          password TEXT    NOT NULL
        )
      ''');

      // Default user — INSERT OR IGNORE prevents errors on duplicate runs
      await txn.rawInsert('''
        INSERT OR IGNORE INTO users (username, password)
        VALUES ('admin', 'admin')
      ''');

      // ── Indexes ──────────────────────────────────────────────────────────

      // customers
      await txn.execute(
        'CREATE INDEX idx_customers_name ON customers(name)',
      );
      await txn.execute(
        'CREATE INDEX idx_customers_phone ON customers(mobilePhone)',
      );
      await txn.execute(
        'CREATE INDEX idx_customers_name_phone ON customers(name, mobilePhone)',
      );

      // sales_invoices
      await txn.execute(
        'CREATE INDEX idx_sales_customer ON sales_invoices(customerId)',
      );
      await txn.execute(
        'CREATE INDEX idx_sales_date ON sales_invoices(date)',
      );
      await txn.execute(
        'CREATE INDEX idx_sales_cust_remaining ON sales_invoices(customerId, remainingBalance)',
      );
      await txn.execute(
        'CREATE INDEX idx_sales_item ON sales_invoices(itemName)',
      );

      // inventory
      await txn.execute(
        'CREATE INDEX idx_inventory_name ON inventory(name)',
      );
      await txn.execute(
        'CREATE INDEX idx_inventory_category ON inventory(category)',
      );

      // purchases
      await txn.execute(
        'CREATE INDEX idx_purchases_machine ON purchases(machineName)',
      );
      await txn.execute(
        'CREATE INDEX idx_purchases_date ON purchases(date)',
      );

      // maintenance_records
      await txn.execute(
        'CREATE INDEX idx_maint_equipment ON maintenance_records(equipmentId)',
      );
      await txn.execute(
        'CREATE INDEX idx_maint_customer ON maintenance_records(customerId)',
      );
      await txn.execute(
        'CREATE INDEX idx_maint_status ON maintenance_records(status)',
      );
      await txn.execute(
        'CREATE INDEX idx_maint_start ON maintenance_records(startDate)',
      );
      await txn.execute(
        'CREATE INDEX idx_maint_start_status '
        'ON maintenance_records(startDate, status)',
      );

      // maintenance_schedule
      await txn.execute(
        'CREATE INDEX idx_sched_equipment '
        'ON maintenance_schedule(equipmentId)',
      );
      await txn.execute(
        'CREATE INDEX idx_sched_customer ON maintenance_schedule(customerId)',
      );
      await txn.execute(
        'CREATE INDEX idx_sched_date ON maintenance_schedule(scheduledDate)',
      );

      // customer_machines
      await txn.execute(
        'CREATE INDEX idx_customer_machines_customer ON customer_machines(customer_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_customer_machines_model ON customer_machines(model)',
      );
      await txn.execute(
        'CREATE INDEX idx_customer_machines_serial ON customer_machines(serial_number)',
      );
      await txn.execute(
        'CREATE INDEX idx_customer_machines_brand ON customer_machines(brand)',
      );

      // machine_parts
      await txn.execute(
        'CREATE INDEX idx_machine_parts_machine ON machine_parts(machine_id)',
      );
      await txn.execute(
        'CREATE INDEX idx_machine_parts_date ON machine_parts(replaced_date)',
      );
      await txn.execute(
        'CREATE INDEX idx_machine_parts_due ON machine_parts(next_due_date)',
      );

      // notes
      await txn.execute(
        'CREATE INDEX idx_notes_entity ON notes(entityType, entityId)',
      );
      await txn.execute(
        'CREATE INDEX idx_notes_created ON notes(createdAt)',
      );

      // audit_logs
      await txn.execute(
        'CREATE INDEX idx_audit_occurred ON audit_logs(occurredAt)',
      );
      await txn.execute(
        'CREATE INDEX idx_audit_operation ON audit_logs(operation)',
      );
      await txn.execute(
        'CREATE INDEX idx_audit_type_date ON audit_logs(entityType, occurredAt)',
      );
    });

    AppLogger.instance.info(
      'Database schema v$version created successfully.',
      tag: _tag,
    );
  }
}
