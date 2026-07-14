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
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
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
                            content: 'هل أنت متأكد من حذف هذا الموعد المجدول؟',
                            onDelete: () {
                              context.read<MaintenanceCubit>().deleteScheduleItem(item.id!);
                            },
                          ),
                        ),
                        if (!item.isCompleted)
                          TextButton.icon(
                            icon: const Icon(Icons.check, color: AppColors.success),
                            label: const Text('إكمال الصيانة', style: TextStyle(color: AppColors.success)),
                            onPressed: () {
                              context.read<MaintenanceCubit>().updateScheduleItem(
                                item.copyWith(completedAt: DateTime.now()),
                              );
                            },
                          ),
                        const Spacer(),
                        Text(
                          'نوع الصيانة: ${item.type == 'preventive' ? 'وقائية' : item.type == 'inspection' ? 'فحص دوري' : 'معايرة'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(),
                    InfoRow(icon: Icons.precision_manufacturing, text: 'رقم المعدة المجدولة: #${item.equipmentId}'),
                    InfoRow(icon: Icons.calendar_today, text: 'التاريخ المجدول: ${DateFormatter.toDisplay(item.scheduledDate)}'),
                    if (item.isCompleted)
                      InfoRow(icon: Icons.check_circle_outline, text: 'تمت الصيانة بتاريخ: ${DateFormatter.toDisplay(item.completedAt!)}'),
                    if (item.notes.isNotEmpty)
                      InfoRow(icon: Icons.notes, text: 'ملاحظات الجدولة: ${item.notes}'),
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
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
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
                            content: 'هل أنت متأكد من حذف هذا السجل بشكل نهائي؟',
                            onDelete: () {
                              context.read<MaintenanceCubit>().deleteRecord(record.id!);
                            },
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'الفني المسؤول: ${record.technicianName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(),
                    InfoRow(icon: Icons.precision_manufacturing, text: 'رقم المعدة: #${record.equipmentId}'),
                    InfoRow(icon: Icons.error_outline, text: 'وصف المشكلة: ${record.issueDescription}'),
                    if (record.workDone.isNotEmpty)
                      InfoRow(icon: Icons.check, text: 'ما تم إنجازه: ${record.workDone}'),
                    InfoRow(icon: Icons.calendar_today, text: 'تاريخ البدء: ${DateFormatter.toDisplay(record.startDate)}'),
                    if (record.endDate != null)
                      InfoRow(icon: Icons.calendar_today_outlined, text: 'تاريخ الانتهاء: ${DateFormatter.toDisplay(record.endDate!)}'),
                    InfoRow(icon: Icons.attach_money, text: 'التكلفة الإجمالية: ${record.cost.toStringAsFixed(2)} ${AppStrings.currency}'),
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
