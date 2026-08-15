import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/cubits/purchase/purchase_cubit.dart';
import 'package:gomaa_management/cubits/purchase/purchase_state.dart';
import 'package:gomaa_management/models/purchase_model.dart';
import 'purchase_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/info_row.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'package:gomaa_management/core/widgets/summary_card.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _appSupportDir;

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  Future<void> _initDir() async {
    final dir = await getApplicationSupportDirectory();
    setState(() {
      _appSupportDir = dir.path;
    });
  }

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
          AppStrings.purchasesManagement,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: AppStrings.total,
                        amount: totalAmount,
                        color: AppColors.primaryAccent,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: AppStrings.paid,
                        amount: totalPaid,
                        color: AppColors.success,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: AppStrings.remaining,
                        amount: totalRemaining,
                        color: AppColors.error,
                        icon: Icons.info_outline,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: AppStrings.searchPurchase,
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

                List<PurchaseModel> purchases = [];
                if (state is PurchaseLoaded) {
                  purchases = state.purchases;
                }

                if (purchases.isEmpty) {
                  if (state is! PurchaseLoading) {
                    return const EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      message: AppStrings.noPurchases,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Desktop/Large screen view
                    if (width > 600) {
                      // Adjust item width based on available screen space
                      int crossAxisCount = (width / 360).floor();
                      if (crossAxisCount < 1) crossAxisCount = 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent: 290, // Fixed pixel height — no overflow on resize
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: purchases.length,
                        itemBuilder: (context, index) {
                          return _buildPurchaseCard(
                            context,
                            purchases[index],
                          );
                        },
                      );
                    }
                    // Mobile view
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: purchases.length,
                      itemBuilder: (context, index) {
                        return _buildPurchaseCard(
                          context,
                          purchases[index],
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

  Widget _buildPurchaseCard(BuildContext context, PurchaseModel purchase) {
    File? imgFile;
    if (purchase.imagePath != null && _appSupportDir != null) {
      imgFile = File(p.join(_appSupportDir!, purchase.imagePath!));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PurchaseFormScreen(purchase: purchase),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? AppColors.cardDark : AppColors.white,
            border: Border.all(
              color: isDark ? AppColors.darkGrey.withValues(alpha: 0.2) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(
                  children: [
                    // Product image / icon
                    if (imgFile != null && imgFile.existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          imgFile,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                      ),
                    const SizedBox(width: 12),
                    // Name and model
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            purchase.machineName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            purchase.model,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.darkGrey,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      splashRadius: 20,
                      onPressed: () => ConfirmDeleteDialog.show(
                        context,
                        title: AppStrings.confirmDeleteTitle,
                        content: '${AppStrings.confirmDeleteMessage} ${purchase.machineName}؟',
                        onDelete: () {
                          context.read<PurchaseCubit>().deletePurchase(purchase.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.deleteSuccess, style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // ── Details ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    InfoRow(
                      icon: Icons.production_quantity_limits,
                      text: '${AppStrings.quantity}: ${purchase.quantity}',
                    ),
                    const SizedBox(height: 6),
                    InfoRow(
                      icon: Icons.attach_money,
                      text: '${AppStrings.price}: ${purchase.price.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 6),
                    InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: DateFormatter.toDisplay(purchase.date),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // ── Amount row — same style as invoice card ─────────────────
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _amountColumn(
                        '${purchase.totalAmount.toStringAsFixed(0)} ج.م',
                        'الإجمالي',
                        AppColors.primaryAccent,
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: _amountColumn(
                        '${purchase.paidAmount.toStringAsFixed(0)} ج.م',
                        'مدفوع',
                        AppColors.success,
                      ),
                    ),
                    VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: _amountColumn(
                        '${purchase.remainingBalance.toStringAsFixed(0)} ج.م',
                        'الباقي',
                        purchase.remainingBalance > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _amountColumn(String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
