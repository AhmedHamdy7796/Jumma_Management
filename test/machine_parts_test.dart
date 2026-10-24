import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/models/machine_part_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Machine Parts and Replacement Tests', () {
    test('MachinePartModel overdue and due-soon indicators', () {
      final now = DateTime.now();

      // Overdue: 3 days ago
      final overduePart = MachinePartModel(
        machineId: 1,
        partName: 'فاصل زيت',
        replacedDate: now.subtract(const Duration(days: 180)),
        nextDueDate: now.subtract(const Duration(days: 3)),
        createdAt: now,
      );
      expect(overduePart.isOverdue, isTrue);
      expect(overduePart.isDueSoon, isFalse);

      // Due soon: in 5 days
      final dueSoonPart = MachinePartModel(
        machineId: 1,
        partName: 'فلتر زيت',
        replacedDate: now.subtract(const Duration(days: 90)),
        nextDueDate: now.add(const Duration(days: 5)),
        createdAt: now,
      );
      expect(dueSoonPart.isOverdue, isFalse);
      expect(dueSoonPart.isDueSoon, isTrue);

      // Distant future: in 45 days
      final futurePart = MachinePartModel(
        machineId: 1,
        partName: 'فلتر هواء',
        replacedDate: now,
        nextDueDate: now.add(const Duration(days: 45)),
        createdAt: now,
      );
      expect(futurePart.isOverdue, isFalse);
      expect(futurePart.isDueSoon, isFalse);

      // No due date
      final noDueDatePart = MachinePartModel(
        machineId: 1,
        partName: 'سير',
        replacedDate: now,
        createdAt: now,
      );
      expect(noDueDatePart.isOverdue, isFalse);
      expect(noDueDatePart.isDueSoon, isFalse);
    });

    test('Atomic inventory deduction on part replacement', () async {
      final tempDir = Directory.systemTemp.createTempSync('parts_test_');
      final dbPath = p.join(tempDir.path, 'gomaa_parts.db');

      final db = await openDatabase(
        dbPath,
        version: 10,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              mobilePhone TEXT NOT NULL,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE customer_machines (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
              machine_type TEXT NOT NULL,
              model TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE inventory (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              model TEXT NOT NULL DEFAULT '',
              quantity INTEGER NOT NULL DEFAULT 0,
              category TEXT NOT NULL DEFAULT '',
              purchasePrice REAL NOT NULL DEFAULT 0,
              sellingPrice REAL NOT NULL DEFAULT 0,
              notes TEXT NOT NULL DEFAULT ''
            )
          ''');
          await db.execute('''
            CREATE TABLE machine_parts (
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
          await db.execute('''
            CREATE TABLE audit_logs (
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
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );

      // Seed data
      final custId = await db.insert('customers', {'name': 'مصنع 1', 'mobilePhone': '01000000000'});
      final machineId = await db.insert('customer_machines', {
        'customer_id': custId,
        'machine_type': 'ضاغط حلزوني',
        'model': 'GA-37',
        'created_at': DateTime.now().toIso8601String(),
      });
      final invId = await db.insert('inventory', {
        'name': 'فلتر زيت أطلس',
        'model': '1622-0871',
        'quantity': 10,
        'purchasePrice': 500.0,
        'sellingPrice': 800.0,
      });

      // Part replacement with stock deduction of 2 units in 1 transaction
      await db.transaction((txn) async {
        await txn.insert('machine_parts', {
          'machine_id': machineId,
          'part_name': 'فلتر زيت أطلس',
          'part_number': '1622-0871',
          'replaced_date': DateTime.now().toIso8601String(),
          'cost': 800.0,
          'created_at': DateTime.now().toIso8601String(),
        });
        // Deduct 2
        final invRows = await txn.query('inventory', where: 'id = ?', whereArgs: [invId]);
        final curQty = invRows.first['quantity'] as int;
        await txn.update('inventory', {'quantity': curQty - 2}, where: 'id = ?', whereArgs: [invId]);
      });

      // Verify stock was reduced from 10 to 8
      final invCheck = await db.query('inventory', where: 'id = ?', whereArgs: [invId]);
      expect(invCheck.first['quantity'], 8);

      // Verify part record exists
      final partRows = await db.query('machine_parts', where: 'machine_id = ?', whereArgs: [machineId]);
      expect(partRows.length, 1);

      // Verify CASCADE delete: deleting machine removes parts
      await db.delete('customer_machines', where: 'id = ?', whereArgs: [machineId]);
      final partsAfterMachineDelete = await db.query('machine_parts');
      expect(partsAfterMachineDelete.isEmpty, isTrue);

      await db.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}
