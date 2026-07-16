import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/customer/customer_cubit.dart';
import 'package:gomaa_management/cubits/customer/customer_state.dart';
import 'package:gomaa_management/models/customer_model.dart';
import 'customer_form_screen.dart';
import 'customer_detail_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
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
                hintText: 'ابحث بالاسم أو الهاتف أو الشركة...',
                hintStyle:
                    const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.primaryAccent),
                filled: true,
                fillColor:
                    isDark ? AppColors.cardDark : AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.darkGrey.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.primaryAccent, width: 2),
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
                  return const EmptyState(
                    icon: Icons.people_outline,
                    message: AppStrings.noCustomers,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      int crossAxisCount =
                          (constraints.maxWidth / 350).floor();
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: customers.length,
                        itemBuilder: (context, index) =>
                            _buildCustomerCard(context, customers[index]),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) =>
                          _buildCustomerCard(context, customers[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CustomerFormScreen()),
          );
          if (context.mounted) {
            context.read<CustomerCubit>().loadCustomers();
          }
        },
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          AppStrings.addCustomer,
          style:
              TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CustomerDetailScreen(customer: customer),
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
                isDark
                    ? AppColors.cardDark.withValues(alpha: 0.9)
                    : AppColors.lightGrey.withValues(alpha: 0.4),
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
                // Header row with icon, name and delete
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      hoverColor:
                          AppColors.error.withValues(alpha: 0.1),
                      onPressed: () => ConfirmDeleteDialog.show(
                        context,
                        title: AppStrings.confirmDeleteTitle,
                        content:
                            '${AppStrings.confirmDeleteMessage} ${customer.name}؟',
                        onDelete: () {
                          context
                              .read<CustomerCubit>()
                              .deleteCustomer(customer.id!);
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
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.primaryAccent),
                      hoverColor:
                          AppColors.primaryAccent.withValues(alpha: 0.1),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CustomerFormScreen(customer: customer),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Expanded(
                      child: Text(
                        customer.name,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.person_pin,
                        color: AppColors.primaryAccent),
                  ],
                ),
                const Divider(height: 12),
                // Phone
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      customer.mobilePhone,
                      style: const TextStyle(
                          fontFamily: 'Cairo', fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.phone_android_outlined,
                        size: 16, color: AppColors.primaryAccent),
                  ],
                ),
                if (customer.companyName != null &&
                    customer.companyName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        customer.companyName!,
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppColors.darkGrey),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.business_outlined,
                          size: 16, color: AppColors.darkGrey),
                    ],
                  ),
                ],
                if (customer.address != null &&
                    customer.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          customer.address!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.darkGrey),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.darkGrey),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'عرض التفاصيل والفواتير',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
