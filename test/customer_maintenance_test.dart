import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/models/maintenance_record_model.dart';
import 'package:gomaa_management/models/maintenance_schedule_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Customer Maintenance and Global Search Tests', () {
    test('MaintenanceRecordModel and ScheduleModel serialization with customerId', () {
      final now = DateTime.now();

      final record = MaintenanceRecordModel(
        equipmentId: 10,
        customerId: 25,
        customerName: 'شركة الأمل الصناعية',
        technicianName: 'م. أحمد',
        startDate: now,
        issueDescription: 'تسريب هواء',
        status: 'closed',
      );

      final map = record.toMap();
      expect(map[MaintenanceRecordColumns.customerId], 25);
      expect(map[MaintenanceRecordColumns.equipmentId], 10);

      final parsed = MaintenanceRecordModel.fromMap({
        ...map,
        'customerName': 'شركة الأمل الصناعية',
      });
      expect(parsed.customerId, 25);
      expect(parsed.customerName, 'شركة الأمل الصناعية');

      final sched = MaintenanceScheduleModel(
        equipmentId: 10,
        customerId: 25,
        customerName: 'شركة الأمل الصناعية',
        scheduledDate: now.add(const Duration(days: 30)),
        type: 'preventive',
      );
      final sMap = sched.toMap();
      expect(sMap[MaintenanceScheduleColumns.customerId], 25);

      final parsedSched = MaintenanceScheduleModel.fromMap({
        ...sMap,
        'customerName': 'شركة الأمل الصناعية',
      });
      expect(parsedSched.customerId, 25);
      expect(parsedSched.customerName, 'شركة الأمل الصناعية');
    });

    test('Customer joins populate customerName and Global Search queries machines', () async {
      final tempDir = Directory.systemTemp.createTempSync('maint_test_');
      final dbPath = p.join(tempDir.path, 'maint_test.db');

      final db = await openDatabase(
        dbPath,
        version: 10,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              mobilePhone TEXT NOT NULL,
              companyName TEXT,
              address TEXT,
              notes TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE customer_machines (
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
            CREATE TABLE maintenance_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              equipmentId INTEGER NOT NULL,
              customerId INTEGER REFERENCES customers(id) ON DELETE SET NULL,
              technicianName TEXT NOT NULL,
              startDate TEXT NOT NULL,
              endDate TEXT,
              issueDescription TEXT NOT NULL,
              workDone TEXT NOT NULL DEFAULT '',
              cost REAL NOT NULL DEFAULT 0,
              status TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');

          await db.execute('''
            CREATE TABLE maintenance_schedule (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              equipmentId INTEGER NOT NULL,
              customerId INTEGER REFERENCES customers(id) ON DELETE SET NULL,
              scheduledDate TEXT NOT NULL,
              type TEXT NOT NULL,
              reminderEnabled INTEGER NOT NULL DEFAULT 1,
              completedAt TEXT,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
        },
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      // Insert customer
      final custId = await db.insert('customers', {
        'name': 'مصنع النور للبلاستيك',
        'mobilePhone': '01012345678',
      });

      // Insert customer machine
      final machId = await db.insert('customer_machines', {
        'customer_id': custId,
        'machine_type': 'ضاغط حلزوني',
        'model': 'Atlas Copco GA 37 VSD',
        'serial_number': 'SN-VSD-998811',
        'created_at': DateTime.now().toIso8601String(),
      });
      expect(machId, isPositive);

      // Insert maintenance record linked to customer
      await db.insert('maintenance_records', {
        'equipmentId': 1,
        'customerId': custId,
        'technicianName': 'م. سامي',
        'startDate': DateTime.now().toIso8601String(),
        'issueDescription': 'فحص دوري شامل',
        'status': 'closed',
      });

      // Insert schedule linked to customer
      await db.insert('maintenance_schedule', {
        'equipmentId': 1,
        'customerId': custId,
        'scheduledDate': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
        'type': 'preventive',
      });

      // Test Maintenance Record Join
      final recordMaps = await db.rawQuery('''
        SELECT mr.*, c.name AS customerName
        FROM maintenance_records mr
        LEFT JOIN customers c ON mr.customerId = c.id
        ORDER BY mr.startDate DESC
      ''');
      expect(recordMaps.length, 1);
      final recordModel = MaintenanceRecordModel.fromMap(recordMaps.first);
      expect(recordModel.customerName, 'مصنع النور للبلاستيك');
      expect(recordModel.customerId, custId);

      // Test Maintenance Schedule Join
      final scheduleMaps = await db.rawQuery('''
        SELECT ms.*, c.name AS customerName
        FROM maintenance_schedule ms
        LEFT JOIN customers c ON ms.customerId = c.id
        ORDER BY ms.scheduledDate ASC
      ''');
      expect(scheduleMaps.length, 1);
      final scheduleModel = MaintenanceScheduleModel.fromMap(scheduleMaps.first);
      expect(scheduleModel.customerName, 'مصنع النور للبلاستيك');
      expect(scheduleModel.customerId, custId);

      // Test Global Search Query for Customer Machines
      const query = '%Atlas%';
      final searchResults = await db.rawQuery('''
        SELECT 'customer_machine' AS type, id, model AS title, COALESCE(serial_number, '') AS subtitle
        FROM customer_machines
        WHERE model LIKE ? OR serial_number LIKE ?
      ''', [query, query]);

      expect(searchResults.length, 1);
      expect(searchResults.first['type'], 'customer_machine');
      expect(searchResults.first['title'], 'Atlas Copco GA 37 VSD');
      expect(searchResults.first['subtitle'], 'SN-VSD-998811');

      await db.close();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });
}
