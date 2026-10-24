import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/models/customer_balance_summary.dart';
import 'package:gomaa_management/core/utils/invoice_calculator.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Customer Balance Aggregate Query Tests', () {
    late Directory tempDir;
    late Database db;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('balance_test_');
      final dbPath = p.join(tempDir.path, 'balance_test.db');
      db = await openDatabase(
        dbPath,
        version: 1,
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
            CREATE TABLE sales_invoices (
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
        },
      );
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Aggregate SQL query computes totalInvoiced, totalPaid, totalRemaining', () async {
      final customerId = await db.insert('customers', {
        'name': 'عميل اختبار الحسابات',
        'mobilePhone': '01009998888',
        'notes': '',
      });
      expect(customerId, isPositive);

      // Function executing the aggregate query
      Future<CustomerBalanceSummary> getSummary(int cId) async {
        final result = await db.rawQuery(
          '''
          SELECT
            COALESCE(SUM(${SalesInvoiceColumns.totalAmount}), 0) AS totalInvoiced,
            COALESCE(SUM(${SalesInvoiceColumns.paidAmount}), 0) AS totalPaid,
            COALESCE(SUM(${SalesInvoiceColumns.remainingBalance}), 0) AS totalRemaining
          FROM ${TableNames.salesInvoices}
          WHERE ${SalesInvoiceColumns.customerId} = ?
          ''',
          [cId],
        );
        if (result.isNotEmpty) {
          final row = result.first;
          final totalInvoiced = InvoiceCalculator.roundMoney((row['totalInvoiced'] as num).toDouble());
          final totalPaid = InvoiceCalculator.roundMoney((row['totalPaid'] as num).toDouble());
          final totalRemaining = InvoiceCalculator.roundMoney((row['totalRemaining'] as num).toDouble());
          return CustomerBalanceSummary(
            totalInvoiced: totalInvoiced,
            totalPaid: totalPaid,
            totalRemaining: totalRemaining,
          );
        }
        return CustomerBalanceSummary.zero;
      }

      // Initial state is zero
      final initial = await getSummary(customerId);
      expect(initial.totalInvoiced, 0.0);
      expect(initial.totalPaid, 0.0);
      expect(initial.totalRemaining, 0.0);

      // Add invoice 1: 1000 total, 400 paid, 600 remaining
      await db.insert('sales_invoices', {
        'customerId': customerId,
        'itemName': 'صنف 1',
        'model': 'M1',
        'quantity': 1,
        'price': 1000.0,
        'totalAmount': 1000.0,
        'paidAmount': 400.0,
        'remainingBalance': 600.0,
        'date': DateTime.now().toIso8601String(),
        'notes': '',
      });

      // Add invoice 2: 500 total, 500 paid, 0 remaining
      await db.insert('sales_invoices', {
        'customerId': customerId,
        'itemName': 'صنف 2',
        'model': 'M2',
        'quantity': 2,
        'price': 250.0,
        'totalAmount': 500.0,
        'paidAmount': 500.0,
        'remainingBalance': 0.0,
        'date': DateTime.now().toIso8601String(),
        'notes': '',
      });

      // Assert aggregate result
      final summary = await getSummary(customerId);
      expect(summary.totalInvoiced, 1500.0);
      expect(summary.totalPaid, 900.0);
      expect(summary.totalRemaining, 600.0);
    });
  });
}
