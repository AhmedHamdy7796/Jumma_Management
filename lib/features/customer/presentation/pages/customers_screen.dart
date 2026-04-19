import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:gomaa_management/features/customer/presentation/cubit/customer_cubit.dart';
import 'package:gomaa_management/features/customer/presentation/cubit/customer_state.dart';
import 'package:gomaa_management/features/customer/data/models/customer.dart';
import 'customer_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.customersManagement,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary cards

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: AppStrings.searchCustomer,
                hintStyle: const TextStyle(fontFamily: 'Arial'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                context.read<CustomerCubit>().searchCustomers(value);
              },
            ),
          ),

          // Customer list
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CustomerError) {
                  return Center(child: Text(state.message));
                }

                List<Customer> customers = [];
                if (state is CustomerLoaded) {
                  customers = state.customers;
                }

                if (customers.isEmpty) {
                  if (state is! CustomerLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 100,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noCustomers,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontFamily: 'Arial',
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      int crossAxisCount = (constraints.maxWidth / 350).floor();
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          return _buildCustomerCard(
                            context,
                            customers[index],
                            isGrid: true,
                          );
                        },
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerCard(
                          context,
                          customers[index],
                          isGrid: false,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          AppStrings.addCustomer,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    Customer customer, {
    bool isGrid = false,
  }) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerFormScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _showDeleteDialog(context, customer),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      customer.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.person, color: AppColors.primary),
                ],
              ),
              const Divider(),

              _buildInfoRow(Icons.phone_android, customer.mobilePhone),
              _buildInfoRow(
                Icons.calendar_today,
                dateFormat.format(customer.date),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildAmountChip(
                      AppStrings.amount,
                      customer.amount,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildAmountChip(
                      AppStrings.paid,
                      customer.paidAmount,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildAmountChip(
                      AppStrings.remaining,
                      customer.remainingBalance,
                      AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Arial'),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildAmountChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$label: ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Arial',
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          AppStrings.confirmDeleteTitle,
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        content: Text(
          '${AppStrings.confirmDeleteMessage} ${customer.name}؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Arial'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(fontFamily: 'Arial'),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<CustomerCubit>().deleteCustomer(customer.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    AppStrings.deleteSuccess,
                    style: TextStyle(fontFamily: 'Arial'),
                  ),
                ),
              );
            },
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: AppColors.error, fontFamily: 'Arial'),
            ),
          ),
        ],
      ),
    );
  }
}
