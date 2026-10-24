import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/search/search_cubit.dart';
import 'package:gomaa_management/models/search_result_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/screens/customers/customer_form_screen.dart';
import 'package:gomaa_management/screens/purchases/purchase_form_screen.dart';
import 'package:gomaa_management/screens/fixes/fix_form_screen.dart';
import 'package:gomaa_management/screens/inventory/inventory_form_screen.dart';
import 'package:gomaa_management/screens/machines/machine_detail_screen.dart';
import 'package:gomaa_management/repositories/customer_repository.dart';
import 'package:gomaa_management/repositories/purchase_repository.dart';
import 'package:gomaa_management/repositories/fix_repository.dart';
import 'package:gomaa_management/repositories/inventory_repository.dart';
import 'package:gomaa_management/repositories/machine_repository.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToDetail(BuildContext context, SearchResultModel result) async {
    final navigator = Navigator.of(context);
    Widget? targetScreen;

    if (result.entityType == AuditEntityType.customer) {
      final cust = await CustomerRepository().getById(result.entityId);
      targetScreen = CustomerFormScreen(customer: cust);
    } else if (result.entityType == AuditEntityType.purchase) {
      final purch = await PurchaseRepository().getById(result.entityId);
      targetScreen = PurchaseFormScreen(purchase: purch);
    } else if (result.entityType == AuditEntityType.fix) {
      final fx = await FixRepository().getById(result.entityId);
      targetScreen = FixFormScreen(fix: fx);
    } else if (result.entityType == AuditEntityType.customerMachine) {
      final machine = await MachineRepository().getById(result.entityId);
      if (machine != null) {
        final cust = await CustomerRepository().getById(machine.customerId);
        targetScreen = MachineDetailScreen(
          machine: machine,
          customerName: cust?.name ?? 'عميل',
        );
      }
    } else {
      final item = await InventoryRepository().getById(result.entityId);
      targetScreen = InventoryFormScreen(item: item);
    }

    if (targetScreen != null && mounted) {
      navigator.push(
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'البحث الشامل في النظام',
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
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم عميل، صنف، ماكينة، صيانة، إلخ...',
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.cardDark
                    : Colors.grey.shade100,
              ),
              onChanged: (value) {
                context.read<SearchCubit>().performSearch(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchError) {
                  return Center(child: Text(state.message));
                }

                List<SearchResultModel> results = [];
                if (state is SearchLoaded) {
                  results = state.results;
                }

                if (results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_outlined,
                    message: 'اكتب كلمة البحث للبدء أو ابحث عن كلمة أخرى',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final res = results[index];
                    String arabType = '';
                    switch (res.entityType) {
                      case AuditEntityType.customer:
                        arabType = 'عميل';
                        break;
                      case AuditEntityType.purchase:
                        arabType = 'فاتورة مشترى';
                        break;
                      case AuditEntityType.fix:
                        arabType = 'صيانة خارجية';
                        break;
                      case AuditEntityType.inventory:
                        arabType = 'صنف بالمخزون';
                        break;
                      case AuditEntityType.customerMachine:
                        arabType = 'ماكينة عميل';
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => _navigateToDetail(context, res),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.1),
                          child: Icon(res.icon, color: AppColors.primaryAccent),
                        ),
                        title: Text(
                          res.title,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          res.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            arabType,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: AppColors.teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
