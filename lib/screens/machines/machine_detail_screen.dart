import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/cubits/inventory/inventory_cubit.dart';
import 'package:gomaa_management/cubits/machine_part/machine_part_cubit.dart';
import 'package:gomaa_management/models/machine_model.dart';
import 'package:gomaa_management/models/machine_part_model.dart';
import 'package:gomaa_management/repositories/machine_part_repository.dart';
import 'machine_part_form_dialog.dart';

class MachineDetailScreen extends StatelessWidget {
  final MachineModel machine;
  final String customerName;

  const MachineDetailScreen({
    super.key,
    required this.machine,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MachinePartCubit(
        MachinePartRepository(),
        onInventoryChanged: () {
          if (ctx.mounted) {
            ctx.read<InventoryCubit>().loadInventory();
          }
        },
      )..loadForMachine(machine.id!),
      child: _MachineDetailView(
        machine: machine,
        customerName: customerName,
      ),
    );
  }
}

class _MachineDetailView extends StatelessWidget {
  final MachineModel machine;
  final String customerName;

  const _MachineDetailView({
    required this.machine,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${machine.machineType} - ${machine.model}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Machine Info Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${machine.brand != null && machine.brand!.isNotEmpty ? "${machine.brand} - " : ""}${machine.machineType} - ${machine.model}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'العميل: $customerName',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  machine.sourceDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    if (machine.brand != null && machine.brand!.isNotEmpty)
                      _metaItem(Icons.branding_watermark_outlined, 'الماركة: ${machine.brand}'),
                    if (machine.capacity != null && machine.capacity!.isNotEmpty)
                      _metaItem(Icons.speed, 'السعة: ${machine.capacity}'),
                    if (machine.serialNumber != null && machine.serialNumber!.isNotEmpty)
                      _metaItem(Icons.qr_code, 'سيريال: ${machine.serialNumber}'),
                    if (machine.manufactureYear != null)
                      _metaItem(Icons.calendar_today, 'صنع: ${machine.manufactureYear}'),
                    if (machine.installDate != null)
                      _metaItem(Icons.location_on, 'تركيب: ${DateFormatter.toDisplay(machine.installDate!)}'),
                  ],
                ),
                if (machine.notes != null && machine.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ملاحظات: ${machine.notes}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Parts replacement header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    MachinePartFormDialog.show(context, machineId: machine.id!);
                  },
                  icon: const Icon(Icons.add, color: AppColors.primaryAccent),
                  label: const Text(
                    'استبدال قطعة جديدة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  'سجل استبدال قطع الغيار',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Replacement history list (latest first)
          Expanded(
            child: BlocBuilder<MachinePartCubit, MachinePartState>(
              builder: (context, state) {
                if (state is MachinePartLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is MachinePartError) {
                  return Center(child: Text(state.message));
                }

                final parts = state is MachinePartLoaded ? state.parts : <MachinePartModel>[];

                if (parts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_toggle_off,
                    message: 'لا توجد سجلات استبدال قطع غيار مسجلة لهذه الماكينة',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: parts.length,
                  itemBuilder: (context, index) => _partCard(context, parts[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _partCard(BuildContext context, MachinePartModel part, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Part name, number, Edit, Delete
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_circle_outlined,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.partName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (part.partNumber != null && part.partNumber!.isNotEmpty)
                        Text(
                          'رقم القطعة: ${part.partNumber}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryAccent),
                  splashRadius: 20,
                  tooltip: 'تعديل السجل',
                  onPressed: () {
                    MachinePartFormDialog.show(context, machineId: machine.id!, part: part);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  splashRadius: 20,
                  tooltip: 'حذف السجل',
                  onPressed: () => ConfirmDeleteDialog.show(
                    context,
                    title: 'تأكيد الحذف',
                    content: 'هل أنت متأكد من حذف سجل استبدال "${part.partName}"؟',
                    onDelete: () {
                      context.read<MachinePartCubit>().deletePart(part.id!);
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 14),

            // Replacement details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.darkGrey),
                    const SizedBox(width: 4),
                    Text(
                      'تاريخ الاستبدال: ${DateFormatter.toDisplay(part.replacedDate)}',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                  ],
                ),
                if (part.runningHoursAtReplacement != null)
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 14, color: AppColors.darkGrey),
                      const SizedBox(width: 4),
                      Text(
                        '${part.runningHoursAtReplacement!.toStringAsFixed(0)} ساعة',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                if (part.cost != null && part.cost! > 0)
                  Text(
                    '${part.cost!.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Next Due Date Indicator Badge (Overdue = Red, Due within 14 days = Orange, Normal = Green)
            _buildDueDateBadge(part),

            if (part.notes != null && part.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'ملاحظات: ${part.notes}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.darkGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateBadge(MachinePartModel part) {
    if (part.nextDueDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: AppColors.darkGrey),
            SizedBox(width: 6),
            Text(
              'الموعد القادم: غير محدد',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.darkGrey),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    final days = part.daysUntilDue!;
    if (part.isOverdue) {
      bgColor = AppColors.error.withValues(alpha: 0.12);
      textColor = AppColors.error;
      icon = Icons.error_outline;
      final absDays = days.abs();
      label = 'استحقاق متأخر منذ $absDays ${absDays == 1 ? "يوم" : "أيام"} (${DateFormatter.toDisplay(part.nextDueDate!)})';
    } else if (part.isDueSoon) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange.shade800;
      icon = Icons.warning_amber_rounded;
      label = 'مستحق قريباً خلال $days ${days == 1 ? "يوم" : "أيام"} (${DateFormatter.toDisplay(part.nextDueDate!)})';
    } else {
      bgColor = AppColors.success.withValues(alpha: 0.12);
      textColor = AppColors.success;
      icon = Icons.check_circle_outline;
      label = 'الموعد القادم: ${DateFormatter.toDisplay(part.nextDueDate!)} (بعد $days يوماً)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
