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
import 'package:gomaa_management/core/widgets/amount_chip.dart';
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
                        itemCount: purchases.length,
                        itemBuilder: (context, index) {
                          return _buildPurchaseCard(
                            context,
                            purchases[index],
                          );
                        },
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
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
                        content: '${AppStrings.confirmDeleteMessage} ${purchase.machineName}؟',
                        onDelete: () {
                          context.read<PurchaseCubit>().deletePurchase(purchase.id!);
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
                        purchase.machineName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (imgFile != null && imgFile.existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          imgFile,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.primaryAccent,
                                size: 26,
                              ),
                        ),
                      )
                    else
                      const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryAccent, size: 26),
                  ],
                ),
                const Divider(height: 16),
                InfoRow(icon: Icons.settings_outlined, text: purchase.model),
                const SizedBox(height: 4),
                InfoRow(
                  icon: Icons.production_quantity_limits,
                  text: '${AppStrings.quantity}: ${purchase.quantity}',
                ),
                const SizedBox(height: 4),
                InfoRow(
                  icon: Icons.attach_money,
                  text: '${AppStrings.price}: ${purchase.price.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 4),
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormatter.toDisplay(purchase.date),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AmountChip(
                        label: AppStrings.total,
                        amount: purchase.totalAmount,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AmountChip(
                        label: AppStrings.paid,
                        amount: purchase.paidAmount,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AmountChip(
                        label: AppStrings.remaining,
                        amount: purchase.remainingBalance,
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
