import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/migration_manager.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Migration v10 Tests', () {
    test('Upgrade from v9 to v10 creates customer_machines and machine_parts', () async {
      final tempDir = Directory.systemTemp.createTempSync('upgrade_test_');
      final dbPath = p.join(tempDir.path, 'upgrade_test.db');

      // 1. Create a true v9 database
      var db = await openDatabase(
        dbPath,
        version: 9,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE customers (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              name        TEXT NOT NULL,
              mobilePhone TEXT NOT NULL,
              companyName TEXT,
              address     TEXT,
              notes       TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
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
          await db.execute('''
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
              notes            TEXT    NOT NULL DEFAULT '',
              imagePath        TEXT
            )
          ''');
          await db.execute('''
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
          await db.execute('''
            CREATE TABLE maintenance_records (
              id               INTEGER PRIMARY KEY AUTOINCREMENT,
              equipmentId      INTEGER NOT NULL REFERENCES inventory(id) ON DELETE CASCADE,
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
          await db.execute('''
            CREATE TABLE maintenance_schedule (
              id              INTEGER PRIMARY KEY AUTOINCREMENT,
              equipmentId     INTEGER NOT NULL REFERENCES inventory(id) ON DELETE CASCADE,
              scheduledDate   TEXT    NOT NULL,
              type            TEXT    NOT NULL DEFAULT 'preventive',
              reminderEnabled INTEGER NOT NULL DEFAULT 1,
              completedAt     TEXT,
              notes           TEXT    NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
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
          await db.execute('''
            CREATE TABLE settings (
              key   TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await db.execute('''
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
          await db.execute('''
            CREATE TABLE users (
              id       INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT    UNIQUE NOT NULL,
              password TEXT    NOT NULL
            )
          ''');
        },
      );
      await db.close();

      // Verify db is version 9
      var roDb = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      var res = await roDb.rawQuery('PRAGMA user_version');
      expect(Sqflite.firstIntValue(res), 9);
      await roDb.close();

      // 2. Test pre-upgrade safety copy
      final backupsDir = p.join(tempDir.path, 'backups');
      await MigrationManager.createSafetyCopyBeforeUpgrade(dbPath, backupsDir);
      final backupDirObj = Directory(backupsDir);
      expect(backupDirObj.existsSync(), isTrue);
      final backupFiles = backupDirObj.listSync().whereType<File>().toList();
      expect(backupFiles.isNotEmpty, isTrue);
      expect(backupFiles.first.path.contains('pre_upgrade_safety_v9_to_v10'), isTrue);

      // 3. Perform upgrade to v10
      db = await openDatabase(
        dbPath,
        version: 10,
        onUpgrade: MigrationManager.migrate,
      );

      // Verify tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      expect(tableNames.contains(TableNames.customerMachines), isTrue);
      expect(tableNames.contains(TableNames.machineParts), isTrue);

      // Verify customer_machines columns
      final machineCols = await db.rawQuery('PRAGMA table_info(${TableNames.customerMachines})');
      final machineColNames = machineCols.map((c) => c['name'] as String).toSet();
      expect(machineColNames.contains(CustomerMachineColumns.id), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.customerId), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.machineType), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.model), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.manufactureYear), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.serialNumber), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.installDate), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.notes), isTrue);
      expect(machineColNames.contains(CustomerMachineColumns.createdAt), isTrue);

      // Verify machine_parts columns
      final partCols = await db.rawQuery('PRAGMA table_info(${TableNames.machineParts})');
      final partColNames = partCols.map((c) => c['name'] as String).toSet();
      expect(partColNames.contains(MachinePartColumns.id), isTrue);
      expect(partColNames.contains(MachinePartColumns.machineId), isTrue);
      expect(partColNames.contains(MachinePartColumns.partName), isTrue);
      expect(partColNames.contains(MachinePartColumns.partNumber), isTrue);
      expect(partColNames.contains(MachinePartColumns.replacedDate), isTrue);
      expect(partColNames.contains(MachinePartColumns.runningHoursAtReplacement), isTrue);
      expect(partColNames.contains(MachinePartColumns.nextDueDate), isTrue);
      expect(partColNames.contains(MachinePartColumns.cost), isTrue);
      expect(partColNames.contains(MachinePartColumns.notes), isTrue);
      expect(partColNames.contains(MachinePartColumns.createdAt), isTrue);

      // Verify customerId column in maintenance_records and maintenance_schedule
      final maintRecCols = await db.rawQuery('PRAGMA table_info(${TableNames.maintenanceRecords})');
      expect(maintRecCols.any((c) => c['name'] == 'customerId'), isTrue);
      final maintSchedCols = await db.rawQuery('PRAGMA table_info(${TableNames.maintenanceSchedule})');
      expect(maintSchedCols.any((c) => c['name'] == 'customerId'), isTrue);

      await db.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}
