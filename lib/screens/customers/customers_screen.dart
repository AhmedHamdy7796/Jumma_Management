import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/customer/customer_cubit.dart';
import 'package:gomaa_management/cubits/customer/customer_state.dart';
import 'package:gomaa_management/models/customer_model.dart';
import 'customer_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/info_row.dart';
import 'package:gomaa_management/core/widgets/amount_chip.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.customersManagement,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: AppStrings.searchCustomer,
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryAccent),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkGrey.withValues(alpha: 0.3) : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                ),
              ),
              onChanged: (value) {
                context.read<CustomerCubit>().searchCustomers(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CustomerError) {
                  return Center(child: Text(state.message));
                }

                List<CustomerModel> customers = [];
                if (state is CustomerLoaded) {
                  customers = state.customers;
                }

                if (customers.isEmpty) {
                  if (state is! CustomerLoading) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      message: AppStrings.noCustomers,
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
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          AppStrings.addCustomer,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerFormScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                isDark ? AppColors.cardDark : AppColors.white,
                isDark ? AppColors.cardDark.withValues(alpha: 0.9) : AppColors.lightGrey.withValues(alpha: 0.4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      hoverColor: AppColors.error.withValues(alpha: 0.1),
                      onPressed: () => ConfirmDeleteDialog.show(
                        context,
                        title: AppStrings.confirmDeleteTitle,
                        content: '${AppStrings.confirmDeleteMessage} ${customer.name}؟',
                        onDelete: () {
                          context.read<CustomerCubit>().deleteCustomer(customer.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                AppStrings.deleteSuccess,
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      child: Text(
                        customer.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.person_pin, color: AppColors.primaryAccent),
                  ],
                ),
                const Divider(height: 16),
                InfoRow(icon: Icons.phone_android_outlined, text: customer.mobilePhone),
                const SizedBox(height: 4),
                InfoRow(icon: Icons.calendar_today_outlined, text: DateFormatter.toDisplay(customer.date)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AmountChip(
                        label: AppStrings.amount,
                        amount: customer.amount,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AmountChip(
                        label: AppStrings.paid,
                        amount: customer.paidAmount,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AmountChip(
                        label: AppStrings.remaining,
                        amount: customer.remainingBalance,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
