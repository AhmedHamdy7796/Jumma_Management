import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:gomaa_management/features/purchase/presentation/cubit/purchase_cubit.dart';
import 'package:gomaa_management/features/purchase/presentation/cubit/purchase_state.dart';
import 'package:gomaa_management/features/purchase/data/models/purchase.dart';
import 'purchase_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
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
          AppStrings.purchasesManagement,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              double totalAmount = 0;
              double totalPaid = 0;
              double totalRemaining = 0;

              if (state is PurchaseLoaded) {
                totalAmount = state.totalAmount;
                totalPaid = state.totalPaid;
                totalRemaining = state.totalRemaining;
              }

              return Container(
                color: AppColors.primaryOp10,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        AppStrings.total,
                        totalAmount,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        AppStrings.paid,
                        totalPaid,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryCard(
                        AppStrings.remaining,
                        totalRemaining,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: AppStrings.searchPurchase,
                hintStyle: const TextStyle(fontFamily: 'Arial'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                context.read<PurchaseCubit>().searchPurchases(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<PurchaseCubit, PurchaseState>(
              builder: (context, state) {
                if (state is PurchaseLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PurchaseError) {
                  return Center(child: Text(state.message));
                }

                List<Purchase> purchases = [];
                if (state is PurchaseLoaded) {
                  purchases = state.purchases;
                }

                if (purchases.isEmpty) {
                  if (state is! PurchaseLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 100,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.noPurchases,
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];
                    return _buildPurchaseCard(context, purchase);
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
            MaterialPageRoute(builder: (context) => const PurchaseFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          AppStrings.addPurchase,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'Arial',
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${amount.toStringAsFixed(2)} ${AppStrings.currency}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Arial',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(BuildContext context, Purchase purchase) {
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
              builder: (context) => PurchaseFormScreen(purchase: purchase),
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
                    onPressed: () => _showDeleteDialog(context, purchase),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      purchase.machineName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (purchase.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(purchase.imagePath!),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.shopping_bag,
                              color: AppColors.orange,
                            ),
                      ),
                    )
                  else
                    const Icon(Icons.shopping_bag, color: AppColors.orange),
                ],
              ),
              const Divider(),
              _buildInfoRow(Icons.settings, purchase.model),
              _buildInfoRow(
                Icons.production_quantity_limits,
                '${AppStrings.quantity}: ${purchase.quantity}',
              ),
              _buildInfoRow(
                Icons.attach_money,
                '${AppStrings.price}: ${purchase.price.toStringAsFixed(2)}',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                dateFormat.format(purchase.date),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildAmountChip(
                      AppStrings.total,
                      purchase.totalAmount,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildAmountChip(
                      AppStrings.paid,
                      purchase.paidAmount,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildAmountChip(
                      AppStrings.remaining,
                      purchase.remainingBalance,
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

  void _showDeleteDialog(BuildContext context, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          AppStrings.confirmDeleteTitle,
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        content: Text(
          '${AppStrings.confirmDeleteMessage} ${purchase.machineName}؟',
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
              context.read<PurchaseCubit>().deletePurchase(purchase.id!);
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
