import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gomaa_management/features/customer/data/models/customer.dart';
import 'package:gomaa_management/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/features/purchase/presentation/cubit/purchase_cubit.dart';
import 'package:gomaa_management/features/purchase/presentation/cubit/purchase_state.dart';
import 'package:gomaa_management/features/purchase/data/models/purchase.dart';

import 'package:gomaa_management/core/helper/validators.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidController = TextEditingController();
  final _purchasesController = TextEditingController();
  final _modelController = TextEditingController();
  final _notesController = TextEditingController();

  String _transactionType = 'cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<PurchaseCubit>().loadPurchases();

    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _mobileController.text = widget.customer!.mobilePhone;
      _amountController.text = widget.customer!.amount.toString();
      _paidController.text = widget.customer!.paidAmount.toString();
      _purchasesController.text = widget.customer!.purchases;
      _modelController.text = widget.customer!.model;
      _notesController.text = widget.customer!.notes;
      _transactionType = widget.customer!.transactionType;
      _selectedDate = widget.customer!.date;
    } else {
      _transactionType = 'cash';
    }
  }

  Widget _buildPaymentMethodOption(String value, String label) {
    final isSelected = _transactionType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _transactionType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontFamily: 'Arial',
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _amountController.dispose();
    _paidController.dispose();
    _purchasesController.dispose();
    _modelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _remainingBalance {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final paid = double.tryParse(_paidController.text) ?? 0;
    return amount - paid;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final customer = Customer(
      id: widget.customer?.id,
      name: _nameController.text,
      mobilePhone: _mobileController.text,
      transactionType: _transactionType,
      purchases: _purchasesController.text,
      model: _modelController.text,
      amount: double.parse(_amountController.text),
      paidAmount: double.parse(_paidController.text),
      remainingBalance: _remainingBalance,
      date: _selectedDate,
      notes: _notesController.text,
    );

    try {
      if (widget.customer == null) {
        await context.read<CustomerCubit>().addCustomer(customer);
      } else {
        await context.read<CustomerCubit>().updateCustomer(customer);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.customer == null
                  ? AppStrings.addSuccess
                  : AppStrings.updateSuccess,
              style: const TextStyle(fontFamily: 'Arial'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              AppStrings.error,
              style: TextStyle(fontFamily: 'Arial'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer == null
              ? AppStrings.addCustomer
              : AppStrings.editCustomer,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Arial',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              label: AppStrings.name,
              controller: _nameController,
              validator: (value) => Validator.validateUserName(value ?? ''),
            ),
            CustomTextField(
              label: AppStrings.mobile,
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              validator: (value) => Validator.validatePhoneNumber(value ?? ''),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    AppStrings.paymentMethod,
                    style: TextStyle(fontSize: 16, fontFamily: 'Arial'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaymentMethodOption(
                        'instapay',
                        AppStrings.instapay,
                      ),
                      _buildPaymentMethodOption('bank', AppStrings.bankAccount),
                      _buildPaymentMethodOption('wallet', AppStrings.wallet),
                      _buildPaymentMethodOption('cash', AppStrings.cash),
                    ],
                  ),
                ],
              ),
            ),
            BlocBuilder<PurchaseCubit, PurchaseState>(
              builder: (context, state) {
                List<Purchase> purchases = [];
                if (state is PurchaseLoaded) {
                  purchases = state.purchases;
                }

                // If we are in edit mode and have a value properly set, ensure it's in the list or handle it
                // For simplicity, we just show the dropdown with available items.

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: AppStrings.purchases,
                      border: OutlineInputBorder(),
                    ),
                    // If the current text in controller matches one of the items, select it, else null
                    value:
                        _purchasesController.text.isNotEmpty &&
                            purchases.any(
                              (p) => p.machineName == _purchasesController.text,
                            )
                        ? _purchasesController.text
                        : null,
                    items: purchases.map((purchase) {
                      return DropdownMenuItem<String>(
                        value: purchase.machineName,
                        child: Text(purchase.machineName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _purchasesController.text = value;
                          // Auto-fill model
                          final selectedPurchase = purchases.firstWhere(
                            (p) => p.machineName == value,
                            orElse: () => purchases.first,
                          );
                          _modelController.text = selectedPurchase.model;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      return null;
                    },
                  ),
                );
              },
            ),
            CustomTextField(
              label: AppStrings.model,
              controller: _modelController,
            ),
            CustomTextField(
              label: AppStrings.amount,
              controller: _amountController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterAmount;
                }
                if (double.tryParse(value) == null) {
                  return AppStrings.enterValidNumber;
                }
                return null;
              },
            ),
            CustomTextField(
              label: AppStrings.paid,
              controller: _paidController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterAmount;
                }
                if (double.tryParse(value) == null) {
                  return AppStrings.enterValidNumber;
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  '${AppStrings.remaining}: ${_remainingBalance.toStringAsFixed(2)} ${AppStrings.currency}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ),
            CustomTextField(
              label: AppStrings.date,
              controller: TextEditingController(
                text: DateFormat('yyyy/MM/dd').format(_selectedDate),
              ),
              readOnly: true,
              onTap: _selectDate,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            CustomTextField(
              label: AppStrings.notes,
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: widget.customer == null
                  ? AppStrings.add
                  : AppStrings.update,
              onPressed: _saveCustomer,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
