import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/audit_log/audit_log_cubit.dart';
import 'package:gomaa_management/models/audit_log_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuditLogCubit>().loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سجل العمليات والتدقيق (Audit Logs)',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AuditLogCubit, AuditLogState>(
        builder: (context, state) {
          if (state is AuditLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AuditLogError) {
            return Center(child: Text(state.message));
          }

          List<AuditLogModel> logs = [];
          if (state is AuditLogLoaded) {
            logs = state.logs;
          }

          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              message: 'لا توجد سجلات تدقيق حالياً في النظام',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              IconData operationIcon = Icons.info_outline;
              Color opColor = Colors.grey;

              if (log.operation == 'add') {
                operationIcon = Icons.add_box_outlined;
                opColor = AppColors.success;
              } else if (log.operation == 'edit') {
                operationIcon = Icons.edit_note_outlined;
                opColor = AppColors.primary;
              } else if (log.operation == 'delete') {
                operationIcon = Icons.delete_forever_outlined;
                opColor = AppColors.error;
              } else if (log.operation == 'backup') {
                operationIcon = Icons.backup_outlined;
                opColor = Colors.purple;
              } else if (log.operation == 'restore') {
                operationIcon = Icons.settings_backup_restore_outlined;
                opColor = Colors.deepOrange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(operationIcon, color: opColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.description,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'التاريخ: ${DateFormatter.toDisplayWithTime(log.occurredAt)} | الموظف: ${log.username}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Arial'),
                            ),
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
      ),
    );
  }
}
