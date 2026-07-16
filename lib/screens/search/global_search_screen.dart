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
import 'package:gomaa_management/repositories/customer_repository.dart';
import 'package:gomaa_management/repositories/purchase_repository.dart';
import 'package:gomaa_management/repositories/fix_repository.dart';
import 'package:gomaa_management/repositories/inventory_repository.dart';

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
    Widget targetScreen;
    if (result.entityType == AuditEntityType.customer) {
      final cust = await CustomerRepository().getById(result.entityId);
      targetScreen = CustomerFormScreen(customer: cust);
    } else if (result.entityType == AuditEntityType.purchase) {
      final purch = await PurchaseRepository().getById(result.entityId);
      targetScreen = PurchaseFormScreen(purchase: purch);
    } else if (result.entityType == AuditEntityType.fix) {
      final fx = await FixRepository().getById(result.entityId);
      targetScreen = FixFormScreen(fix: fx);
    } else {
      final item = await InventoryRepository().getById(result.entityId);
      targetScreen = InventoryFormScreen(item: item);
    }

    if (mounted) {
      navigator.push(
        MaterialPageRoute(builder: (context) => targetScreen),
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
                hintText: 'ابحث عن اسم عميل، صنف، صيانة، إلخ...',
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
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Icon(res.icon, color: AppColors.primary),
                        title: Text(
                          res.title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                        ),
                        subtitle: Text(
                          '${res.subtitle} | $arabType',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                        ),
                        onTap: () => _navigateToDetail(context, res),
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
