import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/features/customer/data/models/customer.dart';
import 'package:gomaa_management/core/services/database_helper.dart';
import 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  CustomerCubit() : super(CustomerInitial());

  List<Customer> _allCustomers = [];

  Future<void> loadCustomers() async {
    emit(CustomerLoading());
    try {
      _allCustomers = await DatabaseHelper.instance.getAllCustomers();
      emit(CustomerLoaded(_allCustomers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      await DatabaseHelper.instance.createCustomer(customer);
      loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await DatabaseHelper.instance.updateCustomer(customer);
      loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await DatabaseHelper.instance.deleteCustomer(id);
      loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void searchCustomers(String query) {
    if (state is! CustomerLoaded && state is! CustomerInitial) return;

    if (query.isEmpty) {
      emit(CustomerLoaded(_allCustomers));
      return;
    }

    final filtered = _allCustomers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          customer.mobilePhone.contains(query);
    }).toList();

    emit(CustomerLoaded(filtered));
  }
}
