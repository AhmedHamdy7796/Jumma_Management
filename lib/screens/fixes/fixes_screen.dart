import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/fix/fix_cubit.dart';
import 'package:gomaa_management/cubits/fix/fix_state.dart';
import 'package:gomaa_management/models/fix_model.dart';
import 'fix_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/info_row.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'package:gomaa_management/core/widgets/summary_card.dart';

class FixesScreen extends StatefulWidget {
  const FixesScreen({super.key});

  @override
  State<FixesScreen> createState() => _FixesScreenState();
}

class _FixesScreenState extends State<FixesScreen> {
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
          AppStrings.fixesManagement,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          BlocBuilder<FixCubit, FixState>(
            builder: (context, state) {
              int pendingCount = 0;
              int inProgressCount = 0;
              int completedCount = 0;
              double totalCost = 0;

              if (state is FixLoaded) {
                pendingCount = state.pendingCount;
                inProgressCount = state.inProgressCount;
                completedCount = state.completedCount;
                totalCost = state.totalCost;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: AppStrings.pending,
                            amount: pendingCount.toDouble(),
                            color: AppColors.orange,
                            currency: 'عمليات',
                            icon: Icons.hourglass_empty_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            title: AppStrings.inProgress,
                            amount: inProgressCount.toDouble(),
                            color: AppColors.blue,
                            currency: 'عمليات',
                            icon: Icons.engineering_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            title: AppStrings.completed,
                            amount: completedCount.toDouble(),
                            color: AppColors.success,
                            currency: 'عمليات',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppStrings.totalCost,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.lightGrey : AppColors.darkGrey,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalCost.toStringAsFixed(2)} ${AppStrings.currency}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
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
                hintText: AppStrings.searchFix,
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
                context.read<FixCubit>().searchFixes(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<FixCubit, FixState>(
              builder: (context, state) {
                if (state is FixLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is FixError) {
                  return Center(child: Text(state.message));
                }

                List<FixModel> fixes = [];
                if (state is FixLoaded) {
                  fixes = state.fixes;
                }

                if (fixes.isEmpty) {
                  if (state is! FixLoading) {
                    return const EmptyState(
                      icon: Icons.build_outlined,
                      message: AppStrings.noFixes,
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
                          mainAxisExtent: 320, // fixed height — no overflow
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: fixes.length,
                        itemBuilder: (context, index) {
                          return _buildFixCard(
                            context,
                            fixes[index],
                          );
                        },
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: fixes.length,
                      itemBuilder: (context, index) {
                        return _buildFixCard(
                          context,
                          fixes[index],
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
            MaterialPageRoute(builder: (context) => const FixFormScreen()),
          );
        },
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          AppStrings.addFix,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildFixCard(BuildContext context, FixModel fix) {
    Color statusColor;
    String statusText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (fix.status) {
      case 'pending':
        statusColor = AppColors.orange;
        statusText = AppStrings.pending;
        break;
      case 'in_progress':
        statusColor = AppColors.blue;
        statusText = AppStrings.inProgress;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusText = AppStrings.completed;
        break;
      default:
        statusColor = AppColors.grey;
        statusText = '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FixFormScreen(fix: fix)),
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
              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.precision_manufacturing_outlined, color: AppColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fix.machineName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'موديل: ${fix.model}',
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
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      splashRadius: 20,
                      onPressed: () => ConfirmDeleteDialog.show(
                        context,
                        title: AppStrings.confirmDeleteTitle,
                        content: '${AppStrings.confirmDeleteMessage} ${fix.machineName}؟',
                        onDelete: () {
                          context.read<FixCubit>().deleteFix(fix.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text(AppStrings.deleteSuccess, style: TextStyle(fontFamily: 'Cairo'))),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // ── Details ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    InfoRow(icon: Icons.dry_cleaning_outlined, text: '${AppStrings.dryer}: ${fix.dryerType}'),
                    const SizedBox(height: 6),
                    InfoRow(icon: Icons.production_quantity_limits, text: '${AppStrings.quantity}: ${fix.quantity}'),
                    const SizedBox(height: 6),
                    InfoRow(icon: Icons.error_outline, text: '${AppStrings.issue}: ${fix.issue}'),
                    const SizedBox(height: 6),
                    InfoRow(icon: Icons.calendar_today_outlined, text: DateFormatter.toDisplay(fix.date)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // ── Cost chip ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(
                      '${AppStrings.cost}: ${fix.cost.toStringAsFixed(2)} ${AppStrings.currency}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.purple,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
