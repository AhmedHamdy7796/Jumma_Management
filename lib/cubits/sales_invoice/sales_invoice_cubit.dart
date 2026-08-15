import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/repositories/interfaces/i_sales_invoice_repository.dart';

// ─── States ────────────────────────────────────────────────────────────────

abstract class SalesInvoiceState extends Equatable {
  const SalesInvoiceState();

  @override
  List<Object?> get props => [];
}

class SalesInvoiceInitial extends SalesInvoiceState {}

class SalesInvoiceLoading extends SalesInvoiceState {}

class SalesInvoiceLoaded extends SalesInvoiceState {
  final List<SalesInvoiceModel> invoices;
  const SalesInvoiceLoaded(this.invoices);

  @override
  List<Object?> get props => [invoices];
}

class SalesInvoiceError extends SalesInvoiceState {
  final String message;
  const SalesInvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ─────────────────────────────────────────────────────────────────

class SalesInvoiceCubit extends Cubit<SalesInvoiceState> {
  final ISalesInvoiceRepository _repo;
  List<SalesInvoiceModel> _allInvoices = [];

  SalesInvoiceCubit(this._repo) : super(SalesInvoiceInitial());

  Future<void> loadAll() async {
    emit(SalesInvoiceLoading());
    try {
      _allInvoices = await _repo.getAll();
      emit(SalesInvoiceLoaded(List.from(_allInvoices)));
    } catch (e) {
      emit(SalesInvoiceError(e.toString()));
    }
  }

  Future<void> loadForCustomer(int customerId) async {
    emit(SalesInvoiceLoading());
    try {
      final invoices = await _repo.getByCustomer(customerId);
      emit(SalesInvoiceLoaded(invoices));
    } catch (e) {
      emit(SalesInvoiceError(e.toString()));
    }
  }

  Future<void> addInvoice(SalesInvoiceModel invoice) async {
    try {
      await _repo.create(invoice);
      await loadAll();
    } catch (e) {
      emit(SalesInvoiceError(e.toString()));
    }
  }

  Future<void> updateInvoice(SalesInvoiceModel invoice) async {
    try {
      await _repo.update(invoice);
      await loadAll();
    } catch (e) {
      emit(SalesInvoiceError(e.toString()));
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _repo.delete(id);
      await loadAll();
    } catch (e) {
      emit(SalesInvoiceError(e.toString()));
    }
  }

  void searchInvoices(String query) {
    if (query.isEmpty) {
      emit(SalesInvoiceLoaded(List.from(_allInvoices)));
      return;
    }
    final q = query.toLowerCase().trim();
    final filtered = _allInvoices.where((inv) {
      return inv.itemName.toLowerCase().contains(q) ||
          inv.model.toLowerCase().contains(q) ||
          inv.notes.toLowerCase().contains(q) ||
          inv.customerName.toLowerCase().contains(q) ||
          (inv.id?.toString() ?? '').contains(q);
    }).toList();
    emit(SalesInvoiceLoaded(filtered));
  }
}
