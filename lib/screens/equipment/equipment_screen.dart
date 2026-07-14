import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/equipment/equipment_cubit.dart';
import 'package:gomaa_management/models/equipment_model.dart';
import 'equipment_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/info_row.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
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
          'إدارة الأجهزة والمعدات',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'بحث عن جهاز أو معدة...',
                hintStyle: const TextStyle(fontFamily: 'Arial'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                context.read<EquipmentCubit>().searchEquipment(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<EquipmentCubit, EquipmentState>(
              builder: (context, state) {
                if (state is EquipmentLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is EquipmentError) {
                  return Center(child: Text(state.message));
                }

                List<EquipmentModel> items = [];
                if (state is EquipmentLoaded) {
                  items = state.equipment;
                }

                if (items.isEmpty) {
                  if (state is! EquipmentLoading) {
                    return const EmptyState(
                      icon: Icons.precision_manufacturing_outlined,
                      message: 'لا توجد أجهزة مضافة حالياً',
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
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildEquipmentCard(context, items[index]);
                        },
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildEquipmentCard(context, items[index]);
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
            MaterialPageRoute(builder: (context) => const EquipmentFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة جهاز',
          style: TextStyle(fontFamily: 'Arial'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEquipmentCard(BuildContext context, EquipmentModel item) {
    Color statusColor;
    switch (item.currentStatus) {
      case 'active':
        statusColor = AppColors.success;
        break;
      case 'maintenance':
        statusColor = AppColors.orange;
        break;
      case 'retired':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentFormScreen(equipment: item),
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
                    onPressed: () => ConfirmDeleteDialog.show(
                      context,
                      title: AppStrings.confirmDeleteTitle,
                      content: 'هل أنت متأكد من حذف الجهاز: ${item.name}؟ ستُحذف جميع سجلات الصيانة التابعة له.',
                      onDelete: () {
                        context.read<EquipmentCubit>().deleteEquipment(item.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              AppStrings.deleteSuccess,
                              style: TextStyle(fontFamily: 'Arial'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      item.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.precision_manufacturing, color: AppColors.primary),
                ],
              ),
              const Divider(),
              InfoRow(icon: Icons.settings, text: '${AppStrings.model}: ${item.model}'),
              if (item.serialNumber != null && item.serialNumber!.isNotEmpty)
                InfoRow(icon: Icons.tag, text: 'الرقم التسلسلي: ${item.serialNumber}'),
              InfoRow(icon: Icons.category, text: 'التصنيف: ${item.category}'),
              if (item.purchaseDate != null)
                InfoRow(icon: Icons.calendar_today, text: 'تاريخ الشراء: ${DateFormatter.toDisplay(item.purchaseDate!)}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.currentStatus == 'active'
                          ? 'نشط'
                          : item.currentStatus == 'maintenance'
                              ? 'تحت الصيانة'
                              : 'مستبعد',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
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
}
