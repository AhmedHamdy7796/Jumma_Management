import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/models/machine_model.dart';
import 'package:gomaa_management/services/validation_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Customer Machines Tests', () {
    test('MachineModel serialization and validation', () {
      final now = DateTime.now();
      final machine = MachineModel(
        id: 1,
        customerId: 10,
        machineType: 'ضاغط حلزوني',
        model: 'GA-37',
        manufactureYear: 2022,
        serialNumber: 'SN-12345',
        installDate: now,
        notes: 'ملاحظات تجريبية',
        source: 'ours',
        brand: 'Atlas Copco',
        capacity: '37 kW',
        createdAt: now,
      );

      final map = machine.toMap();
      final fromMap = MachineModel.fromMap(map);

      expect(fromMap.id, 1);
      expect(fromMap.customerId, 10);
      expect(fromMap.machineType, 'ضاغط حلزوني');
      expect(fromMap.model, 'GA-37');
      expect(fromMap.manufactureYear, 2022);
      expect(fromMap.serialNumber, 'SN-12345');
      expect(fromMap.source, 'ours');
      expect(fromMap.isOurs, isTrue);
      expect(fromMap.brand, 'Atlas Copco');
      expect(fromMap.capacity, '37 kW');

      // Test minimal creation with only type + model
      final minimalMachine = MachineModel(
        customerId: 5,
        machineType: 'مجفف',
        model: 'FX-5',
        createdAt: now,
      );
      expect(minimalMachine.source, 'other');
      expect(minimalMachine.brand, isNull);
      expect(minimalMachine.capacity, isNull);
      expect(minimalMachine.sourceDisplayName, 'من مورد آخر');

      final minimalMap = minimalMachine.toMap();
      final fromMinimal = MachineModel.fromMap(minimalMap);
      expect(fromMinimal.source, 'other');
      expect(fromMinimal.brand, isNull);
      expect(fromMinimal.capacity, isNull);

      // Year validation
      expect(ValidationService.validateManufactureYear(null), isNull);
      expect(ValidationService.validateManufactureYear(''), isNull);
      expect(ValidationService.validateManufactureYear('2020'), isNull);
      expect(ValidationService.validateManufactureYear('1940'), isNotNull);
      expect(ValidationService.validateManufactureYear('2099'), isNotNull);
    });

    test('MachineRepository CRUD, Search, and Cascade on Customer Delete', () async {
      final tempDir = Directory.systemTemp.createTempSync('machine_repo_test_');
      final dbPath = p.join(tempDir.path, 'gomaa_test.db');

      final db = await openDatabase(
        dbPath,
        version: 10,
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
            CREATE TABLE customer_machines (
              id               INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id      INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
              machine_type     TEXT    NOT NULL,
              model            TEXT    NOT NULL,
              manufacture_year INTEGER,
              serial_number    TEXT,
              install_date     TEXT,
              notes            TEXT,
              created_at       TEXT    NOT NULL
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
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      // Insert customer
      final custId = await db.insert('customers', {
        'name': 'مصنع الأمل',
        'mobilePhone': '01012345678',
        'companyName': 'شركة الأمل الصناعية',
      });
      expect(custId, isPositive);

      // Insert machine
      final machineId = await db.insert('customer_machines', {
        'customer_id': custId,
        'machine_type': 'ضاغط حلزوني',
        'model': 'Atlas Copco GA-30',
        'manufacture_year': 2020,
        'serial_number': 'AC-987654',
        'install_date': '2021-05-10T00:00:00.000',
        'notes': 'مركب بالورشة الرئيسية',
        'created_at': DateTime.now().toIso8601String(),
      });
      expect(machineId, isPositive);

      // Verify query
      final rows = await db.query(
        'customer_machines',
        where: 'customer_id = ?',
        whereArgs: [custId],
      );
      expect(rows.length, 1);
      expect(rows.first['model'], 'Atlas Copco GA-30');

      // Test cascade delete
      await db.delete('customers', where: 'id = ?', whereArgs: [custId]);
      final remainingMachines = await db.query('customer_machines');
      expect(remainingMachines.isEmpty, isTrue, reason: 'Deleting customer must CASCADE delete machines');

      await db.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}
