import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:gomaa_management/features/fix/presentation/cubit/fix_cubit.dart';
import 'package:gomaa_management/features/fix/presentation/cubit/fix_state.dart';
import 'package:gomaa_management/features/fix/data/models/fix.dart';
import 'fix_form_screen.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.fixesManagement,
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Column(
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
                    color: AppColors.primaryOp10,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                AppStrings.pending,
                                pendingCount.toString(),
                                AppColors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryCard(
                                AppStrings.inProgress,
                                inProgressCount.toString(),
                                AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryCard(
                                AppStrings.completed,
                                completedCount.toString(),
                                AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
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
                                AppStrings.totalCost,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkGrey,
                                  fontFamily: 'Arial',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${totalCost.toStringAsFixed(2)} ${AppStrings.currency}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.purple,
                                  fontFamily: 'Arial',
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
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchFix,
                    hintStyle: const TextStyle(fontFamily: 'Arial'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
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

                    List<Fix> fixes = [];
                    if (state is FixLoaded) {
                      fixes = state.fixes;
                    }

                    if (fixes.isEmpty) {
                      if (state is! FixLoading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.build_outlined,
                                size: 100,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.noFixes,
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

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          int crossAxisCount = (constraints.maxWidth / 350)
                              .floor();
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: fixes.length,
                            itemBuilder: (context, index) {
                              return _buildFixCard(
                                context,
                                fixes[index],
                                isGrid: true,
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
                              isGrid: false,
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FixFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          AppStrings.addFix,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
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
              fontSize: 10,
              color: AppColors.darkGrey,
              fontFamily: 'Arial',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(
                fontSize: 20,
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

  Widget _buildFixCard(BuildContext context, Fix fix, {bool isGrid = false}) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    Color statusColor;
    String statusText;

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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FixFormScreen(fix: fix)),
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
                    onPressed: () => _showDeleteDialog(context, fix),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      fix.machineName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.precision_manufacturing,
                    color: AppColors.teal,
                  ),
                ],
              ),
              const Divider(),
              _buildInfoRow(
                Icons.model_training,
                '${AppStrings.model}: ${fix.model}',
              ),
              _buildInfoRow(Icons.dry, '${AppStrings.dryer}: ${fix.dryerType}'),
              _buildInfoRow(
                Icons.production_quantity_limits,
                '${AppStrings.quantity}: ${fix.quantity}',
              ),
              _buildInfoRow(
                Icons.error_outline,
                '${AppStrings.issue}: ${fix.issue}',
              ),
              _buildInfoRow(Icons.calendar_today, dateFormat.format(fix.date)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${AppStrings.cost}: ${fix.cost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.purple,
                            fontFamily: 'Arial',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontFamily: 'Arial',
                          ),
                        ),
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

  void _showDeleteDialog(BuildContext context, Fix fix) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          AppStrings.confirmDeleteTitle,
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Arial'),
        ),
        content: Text(
          '${AppStrings.confirmDeleteMessage} ${fix.machineName}؟',
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
              context.read<FixCubit>().deleteFix(fix.id!);
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
