import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/inventory/inventory_cubit.dart';
import 'package:gomaa_management/models/inventory_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'inventory_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
          'المخزون',
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
                hintText: 'ابحث بالاسم أو الموديل أو الفئة...',
                hintStyle:
                    const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.primaryAccent),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.white,
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
              onChanged: (v) =>
                  context.read<InventoryCubit>().searchInventory(v),
            ),
          ),
          Expanded(
            child: BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) {
                if (state is InventoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InventoryError) {
                  return Center(child: Text(state.message));
                }
                final items = state is InventoryLoaded
                    ? state.items
                    : <InventoryModel>[];
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: 'لا توجد أصناف في المخزون',
                  );
                }
                return LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth > 600) {
                    final count = (constraints.maxWidth / 300).floor();
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        childAspectRatio: 1.4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) =>
                          _itemCard(context, items[i]),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) =>
                        _itemCard(context, items[i]),
                  );
                });
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
                builder: (_) => const InventoryFormScreen()),
          );
          if (context.mounted) {
            context.read<InventoryCubit>().loadInventory();
          }
        },
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'إضافة صنف',
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

  Widget _itemCard(BuildContext context, InventoryModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = item.quantity <= 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: AppColors.primary.withValues(alpha: 0.07),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventoryFormScreen(item: item),
            ),
          );
          if (context.mounted) {
            context.read<InventoryCubit>().loadInventory();
          }
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
                // Header row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      hoverColor:
                          AppColors.error.withValues(alpha: 0.1),
                      onPressed: () => ConfirmDeleteDialog.show(
                        context,
                        title: 'حذف الصنف',
                        content:
                            'هل تريد حذف "${item.name}" من المخزون؟',
                        onDelete: () => context
                            .read<InventoryCubit>()
                            .deleteItem(item.id!),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        item.name,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primaryAccent, size: 20),
                  ],
                ),
                if (item.model.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.model,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.darkGrey),
                  ),
                ],
                const Divider(height: 14),
                // Quantity badge + category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category chip
                    if (item.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.primary),
                        ),
                      ),
                    // Quantity
                    Row(
                      children: [
                        Text(
                          '${item.quantity} قطعة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isLowStock
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isLowStock
                              ? Icons.warning_amber_outlined
                              : Icons.check_circle_outline,
                          size: 16,
                          color: isLowStock
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Prices
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'بيع: ${item.sellingPrice.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.success),
                    ),
                    Text(
                      'شراء: ${item.purchasePrice.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.darkGrey),
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
