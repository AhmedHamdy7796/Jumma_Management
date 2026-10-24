import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/sales_invoice/sales_invoice_cubit.dart';
import 'package:gomaa_management/cubits/inventory/inventory_cubit.dart';
import 'package:gomaa_management/cubits/machine/machine_cubit.dart';
import 'package:gomaa_management/models/customer_model.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/models/machine_model.dart';
import 'package:gomaa_management/repositories/sales_invoice_repository.dart';
import 'package:gomaa_management/repositories/machine_repository.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'customer_form_screen.dart';
import '../sales_invoices/sales_invoice_form_screen.dart';
import '../sales_invoices/sales_invoice_detail_screen.dart';
import '../machines/machine_form_dialog.dart';
import '../machines/machine_detail_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Capture the global cubits BEFORE local BlocProviders shadow them.
    final globalSalesCubit = context.read<SalesInvoiceCubit>();
    final globalMachineCubit = context.read<MachineCubit>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => SalesInvoiceCubit(
            SalesInvoiceRepository(),
            onInventoryChanged: () {
              if (ctx.mounted) {
                ctx.read<InventoryCubit>().loadInventory();
              }
            },
            onDataChanged: () {
              if (!globalSalesCubit.isClosed) globalSalesCubit.loadAll();
            },
          )..loadForCustomer(customer.id!),
        ),
        BlocProvider(
          create: (ctx) => MachineCubit(
            MachineRepository(),
            onDataChanged: () {
              if (!globalMachineCubit.isClosed) globalMachineCubit.loadAll();
            },
          )..loadForCustomer(customer.id!),
        ),
      ],
      child: _CustomerDetailView(customer: customer),
    );
  }
}

class _CustomerDetailView extends StatelessWidget {
  final CustomerModel customer;

  const _CustomerDetailView({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer.name,
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل بيانات العميل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CustomerFormScreen(customer: customer),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Info Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8)
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.person_pin, color: Colors.white, size: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (customer.companyName != null &&
                            customer.companyName!.isNotEmpty)
                          Text(
                            customer.companyName!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Cairo',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                _infoRow(Icons.phone_android_outlined, customer.mobilePhone),
                if (customer.address != null && customer.address!.isNotEmpty)
                  _infoRow(Icons.location_on_outlined, customer.address!),
                if (customer.notes.isNotEmpty)
                  _infoRow(Icons.notes_outlined, customer.notes),
              ],
            ),
          ),

          // Tab Controller for Invoices, Machines, Maintenance
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.darkGrey,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.receipt_long_outlined, size: 18),
                          text: 'الفواتير',
                        ),
                        Tab(
                          icon: Icon(Icons.precision_manufacturing_outlined, size: 18),
                          text: 'الماكينات',
                        ),
                        Tab(
                          icon: Icon(Icons.build_circle_outlined, size: 18),
                          text: 'الصيانة',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildInvoicesTab(context, isDark),
                        _buildMachinesTab(context, isDark),
                        _buildMaintenanceTab(context, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Balance Summary
        BlocBuilder<SalesInvoiceCubit, SalesInvoiceState>(
          builder: (context, state) {
            double totalAmount = 0;
            double totalPaid = 0;
            double totalRemaining = 0;
            if (state is SalesInvoiceLoaded) {
              for (final inv in state.invoices) {
                totalAmount += inv.totalAmount;
                totalPaid += inv.paidAmount;
                totalRemaining += inv.remainingBalance;
              }
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _balanceTile('المجموع', totalAmount, AppColors.primaryAccent),
                  const VerticalDivider(width: 1),
                  _balanceTile('المدفوع', totalPaid, AppColors.success),
                  const VerticalDivider(width: 1),
                  _balanceTile('المتبقي', totalRemaining, AppColors.error),
                ],
              ),
            );
          },
        ),

        // Invoices header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalesInvoiceFormScreen(
                        customerId: customer.id!,
                        customerName: customer.name,
                      ),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context
                          .read<SalesInvoiceCubit>()
                          .loadForCustomer(customer.id!);
                      context.read<InventoryCubit>().loadInventory();
                    }
                  });
                },
                icon: const Icon(Icons.add, color: AppColors.primaryAccent),
                label: const Text(
                  'فاتورة جديدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
              const Text(
                'الفواتير',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Invoices list
        Expanded(
          child: BlocBuilder<SalesInvoiceCubit, SalesInvoiceState>(
            builder: (context, state) {
              if (state is SalesInvoiceLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SalesInvoiceError) {
                return Center(child: Text(state.message));
              }
              if (state is SalesInvoiceLoaded && state.invoices.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: AppColors.darkGrey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'لا توجد فواتير لهذا العميل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final invoices = state is SalesInvoiceLoaded
                  ? state.invoices
                  : <SalesInvoiceModel>[];
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: invoices.length,
                itemBuilder: (context, index) =>
                    _invoiceCard(context, invoices[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMachinesTab(BuildContext context, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  MachineFormDialog.show(context, customerId: customer.id!);
                },
                icon: const Icon(Icons.add, color: AppColors.primaryAccent),
                label: const Text(
                  'ماكينة جديدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Text(
                'الماكينات المسجلة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<MachineCubit, MachineState>(
            builder: (context, state) {
              if (state is MachineLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is MachineError) {
                return Center(child: Text(state.message));
              }
              final machines =
                  state is MachineLoaded ? state.machines : <MachineModel>[];

              if (machines.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.precision_manufacturing_outlined,
                        size: 56,
                        color: AppColors.darkGrey,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد ماكينات مسجلة لهذا العميل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          MachineFormDialog.show(
                            context,
                            customerId: customer.id!,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'إضافة ماكينة الآن',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: machines.length,
                itemBuilder: (context, index) =>
                    _machineCard(context, machines[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTab(BuildContext context, bool isDark) {
    // To be extended in Item 4 with full summary
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.build_circle_outlined,
            size: 56,
            color: AppColors.darkGrey,
          ),
          SizedBox(height: 12),
          Text(
            'ملخص صيانة الماكينات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'سيتم عرض دورات استبدال قطع الغيار والمواعيد المستحقة هنا',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.darkGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _machineCard(BuildContext context, MachineModel machine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MachineDetailScreen(
                machine: machine,
                customerName: customer.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${machine.machineType} - ${machine.model}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (machine.serialNumber != null &&
                            machine.serialNumber!.isNotEmpty)
                          Text(
                            'رقم تسلسلي: ${machine.serialNumber}',
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
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.primaryAccent,
                    ),
                    splashRadius: 20,
                    tooltip: 'تعديل بيانات الماكينة',
                    onPressed: () {
                      MachineFormDialog.show(
                        context,
                        customerId: customer.id!,
                        machine: machine,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    splashRadius: 20,
                    tooltip: 'حذف الماكينة',
                    onPressed: () => ConfirmDeleteDialog.show(
                      context,
                      title: 'تأكيد حذف الماكينة',
                      content:
                          'هل أنت متأكد من حذف ماكينة ${machine.model}؟ سيتم حذف جميع سجلات قطع الغيار المرتبطة بها.',
                      onDelete: () {
                        context.read<MachineCubit>().deleteMachine(machine.id!);
                      },
                    ),
                  ),
                ],
              ),
              if (machine.manufactureYear != null ||
                  machine.installDate != null) ...[
                const Divider(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (machine.manufactureYear != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.darkGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'سنة الصنع: ${machine.manufactureYear}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    if (machine.installDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.darkGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تاريخ التركيب: ${DateFormatter.toDisplay(machine.installDate!)}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              if (machine.notes != null && machine.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'ملاحظات: ${machine.notes}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            style: const TextStyle(
                color: Colors.white70, fontFamily: 'Cairo', fontSize: 13),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _balanceTile(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${amount.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
        ],
      ),
    );
  }

  Widget _invoiceCard(BuildContext context, SalesInvoiceModel invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SalesInvoiceDetailScreen(invoice: invoice),
            ),
          ).then((_) {
            if (context.mounted) {
              context
                  .read<SalesInvoiceCubit>()
                  .loadForCustomer(customer.id!);
              context.read<InventoryCubit>().loadInventory();
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormatter.toDisplay(invoice.date),
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.darkGrey),
                  ),
                  Row(
                    children: [
                      Text(
                        invoice.itemName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.receipt_outlined,
                          size: 18, color: AppColors.primaryAccent),
                    ],
                  ),
                ],
              ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniChip('${invoice.totalAmount.toStringAsFixed(0)} ج.م',
                      'الإجمالي', AppColors.primaryAccent),
                  _miniChip('${invoice.paidAmount.toStringAsFixed(0)} ج.م',
                      'مدفوع', AppColors.success),
                  _miniChip(
                      '${invoice.remainingBalance.toStringAsFixed(0)} ج.م',
                      'متبقي',
                      AppColors.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
        Text(label,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 10)),
      ],
    );
  }
}
