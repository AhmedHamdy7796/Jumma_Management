import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/maintenance/maintenance_cubit.dart';
import 'package:gomaa_management/models/maintenance_record_model.dart';
import 'package:gomaa_management/models/maintenance_schedule_model.dart';
import 'maintenance_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/info_row.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الصيانة الدورية والوقائية',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'جدولة المهام'),
            Tab(text: 'سجلات عمليات الصيانة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab(),
          _buildRecordsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MaintenanceFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة مهمة صيانة',
          style: TextStyle(fontFamily: 'Arial'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildScheduleTab() {
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      builder: (context, state) {
        if (state is MaintenanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MaintenanceScheduleModel> schedule = [];
        if (state is MaintenanceLoaded) {
          schedule = state.schedule;
        }

        if (schedule.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_month_outlined,
            message: 'لا توجد عمليات صيانة مجدولة حالياً',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final item = schedule[index];
            final isCompleted = item.isCompleted;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : AppColors.white,
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // ── Header ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCompleted ? Icons.check_circle_outline : Icons.handyman_outlined,
                              color: isCompleted ? AppColors.success : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.type == 'preventive' ? 'وقائية' : item.type == 'inspection' ? 'فحص دوري' : 'معايرة',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'رقم المعدة: #${item.equipmentId}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!isCompleted)
                            TextButton.icon(
                              icon: const Icon(Icons.check, color: AppColors.success, size: 18),
                              label: const Text('إكمال', style: TextStyle(color: AppColors.success, fontFamily: 'Cairo', fontSize: 12)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                              onPressed: () {
                                context.read<MaintenanceCubit>().updateScheduleItem(
                                  item.copyWith(completedAt: DateTime.now()),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            splashRadius: 20,
                            onPressed: () => ConfirmDeleteDialog.show(
                              context,
                              title: AppStrings.confirmDeleteTitle,
                              content: 'هل أنت متأكد من حذف هذا الموعد المجدول؟',
                              onDelete: () {
                                context.read<MaintenanceCubit>().deleteScheduleItem(item.id!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    // ── Details ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.calendar_today, text: 'التاريخ المجدول: ${DateFormatter.toDisplay(item.scheduledDate)}'),
                          if (isCompleted) ...[
                            const SizedBox(height: 6),
                            InfoRow(icon: Icons.check_circle_outline, text: 'تمت بتاريخ: ${DateFormatter.toDisplay(item.completedAt!)}'),
                          ],
                          if (item.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            InfoRow(icon: Icons.notes, text: 'ملاحظات: ${item.notes}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecordsTab() {
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      builder: (context, state) {
        if (state is MaintenanceLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MaintenanceRecordModel> records = [];
        if (state is MaintenanceLoaded) {
          records = state.records;
        }

        if (records.isEmpty) {
          return const EmptyState(
            icon: Icons.history_outlined,
            message: 'لا توجد سجلات صيانة منفذة مسبقاً',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : AppColors.white,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkGrey.withValues(alpha: 0.2)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    // ── Header ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.engineering_outlined, color: AppColors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.technicianName,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'رقم المعدة: #${record.equipmentId}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            splashRadius: 20,
                            onPressed: () => ConfirmDeleteDialog.show(
                              context,
                              title: AppStrings.confirmDeleteTitle,
                              content: 'هل أنت متأكد من حذف هذا السجل بشكل نهائي؟',
                              onDelete: () {
                                context.read<MaintenanceCubit>().deleteRecord(record.id!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    // ── Details ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.error_outline, text: 'وصف المشكلة: ${record.issueDescription}'),
                          if (record.workDone.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            InfoRow(icon: Icons.check, text: 'ما تم إنجازه: ${record.workDone}'),
                          ],
                          const SizedBox(height: 6),
                          InfoRow(icon: Icons.calendar_today, text: 'تاريخ البدء: ${DateFormatter.toDisplay(record.startDate)}'),
                          if (record.endDate != null) ...[
                            const SizedBox(height: 6),
                            InfoRow(icon: Icons.calendar_today_outlined, text: 'تاريخ الانتهاء: ${DateFormatter.toDisplay(record.endDate!)}'),
                          ],
                          const SizedBox(height: 6),
                          InfoRow(icon: Icons.attach_money, text: 'التكلفة: ${record.cost.toStringAsFixed(2)} ${AppStrings.currency}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
