import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/models/purchase_model.dart';
import 'package:gomaa_management/models/fix_model.dart';
import 'package:gomaa_management/repositories/sales_invoice_repository.dart';
import 'package:gomaa_management/repositories/purchase_repository.dart';
import 'package:gomaa_management/repositories/fix_repository.dart';

// Rich report structures
class CustomerReportData {
  final List<SalesInvoiceModel> items;
  final double totalTransactions;
  final double totalPaid;
  final double totalRemaining;
  CustomerReportData(
      this.items, this.totalTransactions, this.totalPaid, this.totalRemaining);
}

class PurchaseReportData {
  final List<PurchaseModel> items;
  final double totalAmount;
  final double totalPaid;
  final double totalRemaining;
  PurchaseReportData(
      this.items, this.totalAmount, this.totalPaid, this.totalRemaining);
}

class MaintenanceReportData {
  final List<FixModel> items;
  final double totalCost;
  final int totalJobs;
  MaintenanceReportData(this.items, this.totalCost, this.totalJobs);
}

class DailyReportData {
  final DateTime date;
  final CustomerReportData customers;
  final PurchaseReportData purchases;
  final MaintenanceReportData fixes;
  DailyReportData(this.date, this.customers, this.purchases, this.fixes);
}

class MonthlyReportData {
  final int year;
  final int month;
  final CustomerReportData customers;
  final PurchaseReportData purchases;
  final MaintenanceReportData fixes;
  MonthlyReportData(
      this.year, this.month, this.customers, this.purchases, this.fixes);
}

/// Abstract report data aggregator.
///
/// Plain Dart stubs to isolate PDF/Excel rendering engines.
class ReportService {
  final SalesInvoiceRepository _salesInvoiceRepository;
  final PurchaseRepository _purchaseRepository;
  final FixRepository _fixRepository;

  ReportService({
    SalesInvoiceRepository? salesInvoiceRepository,
    PurchaseRepository? purchaseRepository,
    FixRepository? fixRepository,
  })  : _salesInvoiceRepository =
            salesInvoiceRepository ?? SalesInvoiceRepository(),
        _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
        _fixRepository = fixRepository ?? FixRepository();

  Future<CustomerReportData> buildCustomerReport(
      {DateTime? from, DateTime? to}) async {
    var invoices = await _salesInvoiceRepository.getAll();
    if (from != null || to != null) {
      invoices = invoices.where((inv) {
        if (from != null && inv.date.isBefore(from)) return false;
        if (to != null && inv.date.isAfter(to)) return false;
        return true;
      }).toList();
    }
    final total = invoices.fold(0.0, (s, inv) => s + inv.totalAmount);
    final paid = invoices.fold(0.0, (s, inv) => s + inv.paidAmount);
    final remaining = invoices.fold(0.0, (s, inv) => s + inv.remainingBalance);
    return CustomerReportData(invoices, total, paid, remaining);
  }

  Future<PurchaseReportData> buildPurchaseReport(
      {DateTime? from, DateTime? to}) async {
    var purchases = await _purchaseRepository.getAll();
    if (from != null || to != null) {
      purchases = purchases.where((p) {
        if (from != null && p.date.isBefore(from)) return false;
        if (to != null && p.date.isAfter(to)) return false;
        return true;
      }).toList();
    }
    final total = purchases.fold(0.0, (s, p) => s + p.totalAmount);
    final paid = purchases.fold(0.0, (s, p) => s + p.paidAmount);
    final remaining = purchases.fold(0.0, (s, p) => s + p.remainingBalance);
    return PurchaseReportData(purchases, total, paid, remaining);
  }

  Future<MaintenanceReportData> buildMaintenanceReport(
      {DateTime? from, DateTime? to}) async {
    var fixes = await _fixRepository.getAll();
    if (from != null || to != null) {
      fixes = fixes.where((f) {
        if (from != null && f.date.isBefore(from)) return false;
        if (to != null && f.date.isAfter(to)) return false;
        return true;
      }).toList();
    }
    final totalCost = fixes.fold(0.0, (s, f) => s + f.cost);
    return MaintenanceReportData(fixes, totalCost, fixes.length);
  }

  Future<DailyReportData> buildDailyReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final customers = await buildCustomerReport(from: start, to: end);
    final purchases = await buildPurchaseReport(from: start, to: end);
    final fixes = await buildMaintenanceReport(from: start, to: end);

    return DailyReportData(date, customers, purchases, fixes);
  }

  Future<MonthlyReportData> buildMonthlyReport(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));

    final customers = await buildCustomerReport(from: start, to: end);
    final purchases = await buildPurchaseReport(from: start, to: end);
    final fixes = await buildMaintenanceReport(from: start, to: end);

    return MonthlyReportData(year, month, customers, purchases, fixes);
  }
}
