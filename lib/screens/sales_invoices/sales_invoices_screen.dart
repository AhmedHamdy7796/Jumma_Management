import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/sales_invoice/sales_invoice_cubit.dart';
import 'package:gomaa_management/cubits/customer/customer_cubit.dart';
import 'package:gomaa_management/cubits/customer/customer_state.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/empty_state.dart';
import 'sales_invoice_form_screen.dart';
import 'sales_invoice_detail_screen.dart';

class SalesInvoicesScreen extends StatefulWidget {
  const SalesInvoicesScreen({super.key});

  @override
  State<SalesInvoicesScreen> createState() => _SalesInvoicesScreenState();
}

class _SalesInvoicesScreenState extends State<SalesInvoicesScreen> {
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
          'الفواتير',
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
                hintText: 'ابحث باسم العميل أو رقم الفاتورة أو اسم الصنف...',
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
              onChanged: (value) {
                context
                    .read<SalesInvoiceCubit>()
                    .searchInvoices(value);
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SalesInvoiceCubit, SalesInvoiceState>(
              builder: (context, state) {
                if (state is SalesInvoiceLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SalesInvoiceError) {
                  return Center(child: Text(state.message));
                }
                final invoices = state is SalesInvoiceLoaded
                    ? state.invoices
                    : <SalesInvoiceModel>[];
                if (invoices.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'لا توجد فواتير مبيعات',
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      final count = (constraints.maxWidth / 340).floor();
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          mainAxisExtent: 200, // fixed height — no overflow
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: invoices.length,
                        itemBuilder: (context, i) =>
                            _invoiceCard(context, invoices[i]),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: invoices.length,
                      itemBuilder: (context, i) =>
                          _invoiceCard(context, invoices[i]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewInvoiceDialog(context),
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'فاتورة جديدة',
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

  void _showNewInvoiceDialog(BuildContext context) {
    // Load customers to let user pick one
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _CustomerPickerSheet(onPicked: (customerId, customerName) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SalesInvoiceFormScreen(
                  customerId: customerId,
                  customerName: customerName),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<SalesInvoiceCubit>().loadAll();
            }
          });
        });
      },
    );
  }

  Widget _invoiceCard(BuildContext context, SalesInvoiceModel invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SalesInvoiceDetailScreen(invoice: invoice),
            ),
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
                        color: AppColors.primaryAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_outlined, color: AppColors.primaryAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.itemName,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (invoice.customerName.isNotEmpty)
                            Text(
                              invoice.customerName,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (invoice.model.isNotEmpty)
                            Text(
                              'موديل: ${invoice.model}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.darkGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormatter.toDisplay(invoice.date),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // ── Amount chips ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _chip('${invoice.totalAmount.toStringAsFixed(0)} ج.م', 'الإجمالي', AppColors.primaryAccent),
                    _chip('${invoice.paidAmount.toStringAsFixed(0)} ج.م', 'مدفوع', AppColors.success),
                    _chip('${invoice.remainingBalance.toStringAsFixed(0)} ج.م', 'متبقي',
                        invoice.remainingBalance > 0 ? AppColors.error : AppColors.success),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12)),
        Text(label,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
      ],
    );
  }
}

// ─── Customer picker bottom sheet ─────────────────────────────────────────────

class _CustomerPickerSheet extends StatelessWidget {
  final void Function(int customerId, String customerName) onPicked;
  const _CustomerPickerSheet({required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            'اختر العميل',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const Divider(),
          BlocBuilder<CustomerCubit, CustomerState>(
            builder: (ctx, state) {
              if (state is CustomerLoaded) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.customers.length,
                    itemBuilder: (_, i) {
                      final c = state.customers[i];
                      return ListTile(
                        title: Text(c.name,
                            style:
                                const TextStyle(fontFamily: 'Cairo')),
                        subtitle: Text(c.mobilePhone,
                            style: const TextStyle(fontFamily: 'Cairo')),
                        leading: const Icon(Icons.person_outline,
                            color: AppColors.primaryAccent),
                        onTap: () => onPicked(c.id!, c.name),
                      );
                    },
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
