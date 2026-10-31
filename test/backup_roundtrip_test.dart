import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/database_service.dart';
import 'package:gomaa_management/database/migration_manager.dart';
import 'package:gomaa_management/services/backup_service.dart';

class _CancelledFilePicker extends FilePicker {
  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    return null; // Simulate user clicking Cancel
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return null; // Simulate user clicking Cancel
  }
}

class _EmptyPathFilePicker extends FilePicker {
  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    return '   '; // Simulate empty string
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return FilePickerResult([
      PlatformFile(name: 'empty.db', size: 0, path: '   '),
    ]);
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PART A: Backup & Restore Round-Trip Tests', () {
    late Directory tempDir;
    late String dbPath;
    late String backupsDir;
    late DatabaseService dbService;
    late BackupService backupService;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('backup_roundtrip_');
      dbPath = p.join(tempDir.path, 'gomaa_management.db');
      backupsDir = p.join(tempDir.path, 'backups');
      dbService = DatabaseService.withPath(dbPath);
      backupService = BackupService(
        dbService: dbService,
        customBackupsDir: backupsDir,
      );
    });

    tearDown(() async {
      await dbService.close();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('1. Create temp DB at latest version, insert sample rows, VACUUM INTO backup matches source', () async {
      final db = await dbService.database;

      // Insert sample rows in every table
      final custId = await db.insert(TableNames.customers, {
        CustomerColumns.name: 'شركة النصر للمقاولات',
        CustomerColumns.mobilePhone: '01012345678',
        CustomerColumns.companyName: 'النصر',
        CustomerColumns.address: 'العاشر من رمضان',
        CustomerColumns.notes: 'عميل رئيسي',
      });

      final machineId = await db.insert(TableNames.customerMachines, {
        CustomerMachineColumns.customerId: custId,
        CustomerMachineColumns.machineType: 'ضاغط حلزوني',
        CustomerMachineColumns.model: 'Atlas-GA37',
        CustomerMachineColumns.source: MachineSourceValues.ours,
        CustomerMachineColumns.brand: 'Atlas Copco',
        CustomerMachineColumns.capacity: '37 kW',
        CustomerMachineColumns.manufactureYear: 2021,
        CustomerMachineColumns.serialNumber: 'SN-778899',
        CustomerMachineColumns.installDate: '2021-05-10',
        CustomerMachineColumns.notes: 'حالة ممتازة',
        CustomerMachineColumns.createdAt: '2021-05-10T10:00:00.000',
      });

      await db.insert(TableNames.machineParts, {
        MachinePartColumns.machineId: machineId,
        MachinePartColumns.partName: 'فلتر فاصل الزيت',
        MachinePartColumns.partNumber: 'SEP-990',
        MachinePartColumns.replacedDate: '2023-01-15',
        MachinePartColumns.runningHoursAtReplacement: 3500.5,
        MachinePartColumns.nextDueDate: '2023-07-15',
        MachinePartColumns.cost: 1250.0,
        MachinePartColumns.notes: 'تم الاستبدال بنجاح',
        MachinePartColumns.createdAt: '2023-01-15T14:30:00.000',
      });

      await db.insert(TableNames.salesInvoices, {
        SalesInvoiceColumns.customerId: custId,
        SalesInvoiceColumns.itemName: 'صيانة دورية 4000 ساعة',
        SalesInvoiceColumns.model: 'GA37',
        SalesInvoiceColumns.quantity: 1,
        SalesInvoiceColumns.price: 4500.0,
        SalesInvoiceColumns.totalAmount: 4500.0,
        SalesInvoiceColumns.paidAmount: 3000.0,
        SalesInvoiceColumns.remainingBalance: 1500.0,
        SalesInvoiceColumns.date: '2023-02-01',
        SalesInvoiceColumns.notes: 'متبقي 1500 جنيه',
      });

      await db.insert(TableNames.purchases, {
        PurchaseColumns.machineName: 'ضاغط هواء تردد 15 حصان',
        PurchaseColumns.model: 'REC-15',
        PurchaseColumns.quantity: 2,
        PurchaseColumns.price: 18000.0,
        PurchaseColumns.totalAmount: 36000.0,
        PurchaseColumns.paidAmount: 20000.0,
        PurchaseColumns.remainingBalance: 16000.0,
        PurchaseColumns.date: '2023-03-01',
        PurchaseColumns.notes: 'توريد ورشة',
      });

      await db.insert(TableNames.inventory, {
        InventoryColumns.name: 'زيت كمبروسر 46',
        InventoryColumns.model: 'OIL-46-20L',
        InventoryColumns.quantity: 8,
        InventoryColumns.purchasePrice: 1600.0,
        InventoryColumns.sellingPrice: 2100.0,
        InventoryColumns.category: 'زيوت',
        InventoryColumns.notes: 'جركن 20 لتر',
      });

      await db.insert(TableNames.settings, {
        SettingsColumns.key: SettingsKeys.companyName,
        SettingsColumns.value: 'مؤسسة جمعة لصيانة الضواغط',
      });

      // Execute VACUUM INTO backup
      final backupResult = await backupService.createBackupFile();
      expect(File(backupResult.filePath).existsSync(), isTrue);
      expect(backupResult.sizeBytes, greaterThan(0));

      // Open the backup file read-only
      final roBackupDb = await databaseFactoryFfi.openDatabase(
        backupResult.filePath,
        options: OpenDatabaseOptions(readOnly: true),
      );

      // Verify PRAGMA integrity_check
      final integrityRes = await roBackupDb.rawQuery('PRAGMA integrity_check');
      expect(integrityRes.first.values.first.toString().toLowerCase(), 'ok');

      // Verify all tables and row counts equal source
      for (final table in [
        TableNames.customers,
        TableNames.customerMachines,
        TableNames.machineParts,
        TableNames.salesInvoices,
        TableNames.purchases,
        TableNames.inventory,
        TableNames.settings,
      ]) {
        final srcCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table'),
        );
        final bkpCount = Sqflite.firstIntValue(
          await roBackupDb.rawQuery('SELECT COUNT(*) FROM $table'),
        );
        expect(bkpCount, equals(srcCount), reason: 'Row count mismatch for $table');
      }

      await roBackupDb.close();
    });

    test('2. Modify/delete data, restore from backup: row counts restored, -wal/-shm removed, safety copy exists', () async {
      final db = await dbService.database;

      // Seed initial data
      await db.insert(TableNames.customers, {
        CustomerColumns.name: 'عميل تجريبي',
        CustomerColumns.mobilePhone: '01111111111',
      });
      await db.insert(TableNames.inventory, {
        InventoryColumns.name: 'فلتر هواء أصلي',
        InventoryColumns.model: 'FLT-1',
        InventoryColumns.quantity: 5,
        InventoryColumns.purchasePrice: 100.0,
        InventoryColumns.sellingPrice: 150.0,
      });
      await db.insert(TableNames.settings, {
        SettingsColumns.key: SettingsKeys.companyName,
        SettingsColumns.value: 'الاسم الأصلي قبل التعديل',
      });

      // Create backup
      final backupResult = await backupService.createBackupFile();

      // Modify and delete data
      await db.delete(TableNames.customers);
      await db.delete(TableNames.inventory);
      await db.update(
        TableNames.settings,
        {SettingsColumns.value: 'اسم تم تعديله'},
        where: '${SettingsColumns.key} = ?',
        whereArgs: [SettingsKeys.companyName],
      );

      // Ensure counts changed
      final postDeleteCustCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.customers}'),
      );
      expect(postDeleteCustCount, 0);

      // Ensure stale -wal file exists before restore
      final staleBytes = [99, 88, 77, 66, 55];
      final walFile = File('$dbPath-wal');
      walFile.writeAsBytesSync(staleBytes);
      expect(walFile.readAsBytesSync(), equals(staleBytes));

      // Run restore
      await backupService.restoreFromFile(backupResult.filePath);

      // Verify old stale -wal content was purged during restore (any new WAL is SQLite's binary audit log)
      final currentBytes = walFile.existsSync() ? walFile.readAsBytesSync() : null;
      expect(currentBytes, isNot(equals(staleBytes)));

      // Verify safety copy exists in backupsDir
      final safetyCopies = Directory(backupsDir)
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('pre_restore_safety_'))
          .toList();
      expect(safetyCopies.isNotEmpty, isTrue);

      // Verify restored data matches original
      final liveDb = await dbService.database;
      final restoredCust = await liveDb.query(TableNames.customers);
      expect(restoredCust.length, 1);
      expect(restoredCust.first[CustomerColumns.name], 'عميل تجريبي');

      final restoredInv = await liveDb.query(TableNames.inventory);
      expect(restoredInv.length, 1);
      expect(restoredInv.first[InventoryColumns.name], 'فلتر هواء أصلي');

      final restoredSetting = await liveDb.query(
        TableNames.settings,
        where: '${SettingsColumns.key} = ?',
        whereArgs: [SettingsKeys.companyName],
      );
      expect(restoredSetting.first[SettingsColumns.value], 'الاسم الأصلي قبل التعديل');
    });

    test('3. Restore of corrupted file and non-DB file: rejected, live DB untouched, no safety copy leftovers', () async {
      final db = await dbService.database;

      await db.insert(TableNames.customers, {
        CustomerColumns.name: 'عميل آمن',
        CustomerColumns.mobilePhone: '01222222222',
      });

      final initialSafetyCopiesCount = Directory(backupsDir).existsSync()
          ? Directory(backupsDir)
              .listSync()
              .whereType<File>()
              .where((f) => p.basename(f.path).startsWith('pre_restore_safety_'))
              .length
          : 0;

      // 3a. Corrupted file (random bytes)
      final corruptFile = File(p.join(tempDir.path, 'corrupted.db'))
        ..writeAsBytesSync(List.generate(512, (i) => (i * 31 + 7) % 256));

      await expectLater(
        backupService.restoreFromFile(corruptFile.path),
        throwsA(isA<BackupException>()),
      );

      // 3b. Non-DB file (plain text)
      final textFile = File(p.join(tempDir.path, 'plain.txt'))
        ..writeAsStringSync('Hello, this is just a plain text file, not SQLite.');

      await expectLater(
        backupService.restoreFromFile(textFile.path),
        throwsA(isA<BackupException>()),
      );

      // Verify live DB is untouched
      final liveDb = await dbService.database;
      final custRows = await liveDb.query(TableNames.customers);
      expect(custRows.length, 1);
      expect(custRows.first[CustomerColumns.name], 'عميل آمن');

      // Verify no safety copy leftovers were created by the failed restores
      final safetyCopiesAfter = Directory(backupsDir).existsSync()
          ? Directory(backupsDir)
              .listSync()
              .whereType<File>()
              .where((f) => p.basename(f.path).startsWith('pre_restore_safety_'))
              .length
          : 0;
      expect(safetyCopiesAfter, equals(initialSafetyCopiesCount));
    });

    test('4. Restore of older backups (v9 and v10 fixtures): restored, migrated to latest, data intact', () async {
      // 4a. Handcrafted v9 fixture (no customer_machines, no machine_parts)
      final v9Path = p.join(tempDir.path, 'fixture_v9.db');
      var fixtureDb = await openDatabase(
        v9Path,
        version: 9,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${TableNames.customers} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              mobilePhone TEXT NOT NULL,
              companyName TEXT,
              address TEXT,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.purchases} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              machineName TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 1,
              price REAL NOT NULL,
              totalAmount REAL NOT NULL,
              paidAmount REAL NOT NULL,
              remainingBalance REAL NOT NULL,
              date TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.fixes} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              machineName TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              dryerType TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL,
              issue TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              cost REAL NOT NULL DEFAULT 0,
              date TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.salesInvoices} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customerId INTEGER NOT NULL,
              itemName TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 1,
              price REAL NOT NULL,
              totalAmount REAL NOT NULL,
              paidAmount REAL NOT NULL,
              remainingBalance REAL NOT NULL,
              date TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.inventory} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 0,
              category TEXT NOT NULL DEFAULT '',
              purchasePrice REAL NOT NULL DEFAULT 0,
              sellingPrice REAL NOT NULL DEFAULT 0,
              location TEXT,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.settings} (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.auditLogs} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              occurredAt TEXT NOT NULL,
              operation TEXT NOT NULL,
              entityType TEXT NOT NULL,
              entityId INTEGER,
              description TEXT NOT NULL,
              username TEXT NOT NULL DEFAULT 'المستخدم'
            )
          ''');
        },
      );

      await fixtureDb.insert(TableNames.customers, {
        CustomerColumns.name: 'عميل قاعدة قديمة v9',
        CustomerColumns.mobilePhone: '01009998888',
      });
      await fixtureDb.insert(TableNames.settings, {
        'key': SettingsKeys.companyName,
        'value': 'مؤسسة v9',
      });
      await fixtureDb.close();

      // Restore v9 backup into live database
      await backupService.restoreFromFile(v9Path);

      // Verify live database was migrated to latest version and data is intact
      var liveDb = await dbService.database;
      final verV9 = await liveDb.rawQuery('PRAGMA user_version');
      expect(Sqflite.firstIntValue(verV9), equals(MigrationManager.currentVersion));

      final custV9 = await liveDb.query(TableNames.customers);
      expect(custV9.length, 1);
      expect(custV9.first[CustomerColumns.name], 'عميل قاعدة قديمة v9');

      // Verify that customer_machines table was created during migration
      final cmTableCheck = await liveDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [TableNames.customerMachines],
      );
      expect(cmTableCheck.isNotEmpty, isTrue);

      // 4b. Handcrafted v10 fixture (with customer_machines & machine_parts)
      final v10Path = p.join(tempDir.path, 'fixture_v10.db');
      fixtureDb = await openDatabase(
        v10Path,
        version: 10,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${TableNames.customers} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              mobilePhone TEXT NOT NULL,
              companyName TEXT,
              address TEXT,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.purchases} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              machineName TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 1,
              price REAL NOT NULL,
              totalAmount REAL NOT NULL,
              paidAmount REAL NOT NULL,
              remainingBalance REAL NOT NULL,
              date TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.fixes} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              machineName TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              dryerType TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL,
              issue TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              cost REAL NOT NULL DEFAULT 0,
              date TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.salesInvoices} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customerId INTEGER NOT NULL,
              itemName TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 1,
              price REAL NOT NULL,
              totalAmount REAL NOT NULL,
              paidAmount REAL NOT NULL,
              remainingBalance REAL NOT NULL,
              date TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.inventory} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 0,
              category TEXT NOT NULL DEFAULT '',
              purchasePrice REAL NOT NULL DEFAULT 0,
              sellingPrice REAL NOT NULL DEFAULT 0,
              location TEXT,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.settings} (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.auditLogs} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              occurredAt TEXT NOT NULL,
              operation TEXT NOT NULL,
              entityType TEXT NOT NULL,
              entityId INTEGER,
              description TEXT NOT NULL,
              username TEXT NOT NULL DEFAULT 'المستخدم'
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.customerMachines} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
              machine_type TEXT NOT NULL,
              model TEXT NOT NULL,
              manufacture_year INTEGER,
              serial_number TEXT,
              install_date TEXT,
              notes TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ${TableNames.machineParts} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              machine_id INTEGER NOT NULL REFERENCES customer_machines(id) ON DELETE CASCADE,
              part_name TEXT NOT NULL,
              part_number TEXT,
              replaced_date TEXT NOT NULL,
              running_hours_at_replacement REAL,
              next_due_date TEXT,
              cost REAL,
              notes TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        },
      );

      final v10CustId = await fixtureDb.insert(TableNames.customers, {
        CustomerColumns.name: 'عميل قاعدة v10',
        CustomerColumns.mobilePhone: '01007776666',
      });
      await fixtureDb.insert(TableNames.customerMachines, {
        CustomerMachineColumns.customerId: v10CustId,
        CustomerMachineColumns.machineType: 'ضاغط مائي',
        CustomerMachineColumns.model: 'HYDRO-50',
        CustomerMachineColumns.createdAt: '2023-01-01T00:00:00.000',
      });
      await fixtureDb.close();

      // Restore v10 backup into live database
      await backupService.restoreFromFile(v10Path);

      liveDb = await dbService.database;
      final verV10 = await liveDb.rawQuery('PRAGMA user_version');
      expect(Sqflite.firstIntValue(verV10), equals(MigrationManager.currentVersion));

      final custV10 = await liveDb.query(TableNames.customers);
      expect(custV10.length, 1);
      expect(custV10.first[CustomerColumns.name], 'عميل قاعدة v10');

      final machinesV10 = await liveDb.query(TableNames.customerMachines);
      expect(machinesV10.length, 1);
      expect(machinesV10.first[CustomerMachineColumns.model], 'HYDRO-50');
      expect(machinesV10.first[CustomerMachineColumns.source], 'other');
      expect(machinesV10.first[CustomerMachineColumns.brand], isNull);
      expect(machinesV10.first[CustomerMachineColumns.capacity], isNull);
    });

    test('5. Picker cancel (null or empty string) in backup and restore aborts silently', () async {
      final db = await dbService.database;
      await db.insert(TableNames.customers, {
        CustomerColumns.name: 'عميل اختبار الإلغاء',
        CustomerColumns.mobilePhone: '01011112222',
      });

      // 1. Cancelled backup picker (null path)
      FilePicker.platform = _CancelledFilePicker();
      final backupNullResult = await backupService.createBackupWithPicker();
      expect(backupNullResult, isNull);

      // 2. Cancelled backup picker (empty string path)
      FilePicker.platform = _EmptyPathFilePicker();
      final backupEmptyResult = await backupService.createBackupWithPicker();
      expect(backupEmptyResult, isNull);

      // 3. Cancelled restore picker (null path)
      FilePicker.platform = _CancelledFilePicker();
      final restoreNullResult = await backupService.restoreWithPicker();
      expect(restoreNullResult, isFalse);

      // 4. Cancelled restore picker (empty string path)
      FilePicker.platform = _EmptyPathFilePicker();
      final restoreEmptyResult = await backupService.restoreWithPicker();
      expect(restoreEmptyResult, isFalse);

      // Verify no backup or safety copies created
      final backupFiles = Directory(backupsDir).existsSync()
          ? Directory(backupsDir).listSync()
          : [];
      expect(backupFiles, isEmpty);

      // Verify live DB untouched and connection remains valid
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${TableNames.customers}'),
      );
      expect(count, 1);
    });
  });
}
