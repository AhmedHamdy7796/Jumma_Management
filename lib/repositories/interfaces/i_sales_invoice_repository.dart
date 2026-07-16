import 'package:gomaa_management/models/sales_invoice_model.dart';

/// Repository interface for Sales Invoice operations.
abstract class ISalesInvoiceRepository {
  /// Retrieves all sales invoices, newest first.
  Future<List<SalesInvoiceModel>> getAll();

  /// Retrieves invoices belonging to a specific customer.
  Future<List<SalesInvoiceModel>> getByCustomer(int customerId);

  /// Retrieves a single invoice by ID. Returns null if not found.
  Future<SalesInvoiceModel?> getById(int id);

  /// Inserts a new invoice. Returns the new ID.
  Future<int> create(SalesInvoiceModel invoice);

  /// Updates an existing invoice. Returns the number of rows affected.
  Future<int> update(SalesInvoiceModel invoice);

  /// Deletes an invoice by ID. Returns the number of rows affected.
  Future<int> delete(int id);

  /// Searches invoices by item name, customer name (join), model or notes.
  Future<List<SalesInvoiceModel>> search(String query);

  /// Calculates the total remaining balance for a customer.
  Future<double> getCustomerBalance(int customerId);
}
