import 'package:gomaa_management/models/customer_model.dart';

/// Repository interface for Customer operations.
/// Exposes standard CRUD operations and a search method.
abstract class ICustomerRepository {
  /// Retrieves all customer records, ordered by date descending.
  Future<List<CustomerModel>> getAll();

  /// Retrieves a specific customer by ID. Returns null if not found.
  Future<CustomerModel?> getById(int id);

  /// Inserts a new customer record. Returns the new ID.
  Future<int> create(CustomerModel customer);

  /// Updates an existing customer record. Returns the number of rows affected.
  Future<int> update(CustomerModel customer);

  /// Deletes a customer by ID. Returns the number of rows affected.
  Future<int> delete(int id);

  /// Searches customers by name or mobile phone.
  Future<List<CustomerModel>> search(String query);
}
