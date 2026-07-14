import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/customer_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_customer_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerModel> customers;
  const CustomerLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class CustomerCubit extends Cubit<CustomerState> {
  final ICustomerRepository _customerRepository;
  List<CustomerModel> _allCustomers = [];

  CustomerCubit(this._customerRepository) : super(CustomerInitial());

  Future<void> loadCustomers() async {
    emit(CustomerLoading());
    try {
      _allCustomers = await _customerRepository.getAll();
      emit(CustomerLoaded(List.from(_allCustomers)));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _customerRepository.create(customer);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _customerRepository.update(customer);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _customerRepository.delete(id);
      await loadCustomers();
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void searchCustomers(String query) {
    if (query.isEmpty) {
      emit(CustomerLoaded(List.from(_allCustomers)));
      return;
    }
    final filtered = _allCustomers.where((c) {
      final q = query.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.mobilePhone.toLowerCase().contains(q);
    }).toList();
    emit(CustomerLoaded(filtered));
  }
}
