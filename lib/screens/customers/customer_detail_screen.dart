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
import 'package:gomaa_management/core/utils/invoice_calculator.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'package:gomaa_management/models/customer_balance_summary.dart';
import 'customer_form_screen.dart';
import '../sales_invoices/sales_invoice_form_screen.dart';
import '../sales_invoices/sales_invoice_detail_screen.dart';
import '../machines/machine_form_dialog.dart';
import '../machines/machine_detail_screen.dart';
import 'package:gomaa_management/models/machine_part_model.dart';
import 'package:gomaa_management/repositories/machine_part_repository.dart';

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
        // Balance Summary (Aggregated via single SQL query)
        BlocBuilder<SalesInvoiceCubit, SalesInvoiceState>(
          builder: (context, state) {
            return FutureBuilder<CustomerBalanceSummary>(
              future: context
                  .read<SalesInvoiceCubit>()
                  .getCustomerBalanceSummary(customer.id!),
              builder: (context, snapshot) {
                final summary = snapshot.data ?? CustomerBalanceSummary.zero;
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
                      _balanceTile(
                        'إجمالي الفواتير',
                        summary.totalInvoiced,
                        AppColors.primaryAccent,
                      ),
                      const VerticalDivider(width: 1),
                      _balanceTile(
                        'إجمالي المدفوع',
                        summary.totalPaid,
                        AppColors.success,
                      ),
                      const VerticalDivider(width: 1),
                      _balanceTile(
                        'إجمالي المتبقي',
                        summary.totalRemaining,
                        summary.totalRemaining > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ],
                  ),
                );
              },
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        const Text(
                          'حدث خطأ أثناء تحميل الفواتير',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: AppColors.darkGrey),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => context
                              .read<SalesInvoiceCubit>()
                              .loadForCustomer(customer.id!),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة',
                              style: TextStyle(fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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
    return _CustomerMaintenanceSummaryTab(
      customerId: customer.id!,
      customerName: customer.name,
      isDark: isDark,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${machine.brand != null && machine.brand!.isNotEmpty ? "${machine.brand} - " : ""}${machine.machineType} - ${machine.model}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: machine.isOurs
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: machine.isOurs
                                    ? AppColors.primary.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              machine.sourceDisplayName,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: machine.isOurs ? AppColors.primary : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (machine.capacity != null && machine.capacity!.isNotEmpty)
                            Text(
                              'السعة: ${machine.capacity}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.primaryAccent,
                                fontWeight: FontWeight.w600,
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
            InvoiceCalculator.formatMoney(amount),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
          ),
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

class _CustomerMaintenanceSummaryTab extends StatefulWidget {
  final int customerId;
  final String customerName;
  final bool isDark;

  const _CustomerMaintenanceSummaryTab({
    required this.customerId,
    required this.customerName,
    required this.isDark,
  });

  @override
  State<_CustomerMaintenanceSummaryTab> createState() =>
      _CustomerMaintenanceSummaryTabState();
}

class _CustomerMaintenanceSummaryTabState
    extends State<_CustomerMaintenanceSummaryTab> {
  final _partRepository = MachinePartRepository();
  List<MachinePartModel>? _parts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() => _isLoading = true);
    try {
      final parts = await _partRepository.getByCustomerId(widget.customerId);
      if (mounted) {
        setState(() {
          _parts = parts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final parts = _parts ?? [];
    final overdueCount = parts.where((p) => p.isOverdue).length;
    final dueSoonCount = parts.where((p) => p.isDueSoon).length;
    final dueItems = parts.where((p) => p.isOverdue || p.isDueSoon).toList();

    return RefreshIndicator(
      onRefresh: _loadParts,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Stat Tiles ───────────────────────────────────────────
          BlocBuilder<MachineCubit, MachineState>(
            builder: (context, state) {
              final machines =
                  state is MachineLoaded ? state.machines : <MachineModel>[];
              final machineCount = machines.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.cardDark : AppColors.white,
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
                    _statItem('الماكينات', '$machineCount', AppColors.primary),
                    const VerticalDivider(width: 1),
                    _statItem('مستحقة فوراً', '$overdueCount', AppColors.error),
                    const VerticalDivider(width: 1),
                    _statItem('تقترب', '$dueSoonCount', AppColors.warning),
                    const VerticalDivider(width: 1),
                    _statItem('إجمالي القطع', '${parts.length}', AppColors.darkGrey),
                  ],
                ),
              );
            },
          ),

          // ── Upcoming / Overdue Due Items ─────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'التنبيهات والمواعيد المستحقة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          if (dueItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'جميع قطع الغيار بحالة جيدة ولا توجد مواعيد صيانة مستحقة حالياً.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...dueItems.map((item) {
              final isOverdue = item.isOverdue;
              final color = isOverdue ? AppColors.error : AppColors.warning;
              return BlocBuilder<MachineCubit, MachineState>(
                builder: (context, mState) {
                  final machines =
                      mState is MachineLoaded ? mState.machines : <MachineModel>[];
                  final machine = machines
                      .cast<MachineModel?>()
                      .firstWhere((m) => m?.id == item.machineId, orElse: () => null);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                    ),
                    child: ListTile(
                      onTap: machine != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MachineDetailScreen(
                                    machine: machine,
                                    customerName: widget.customerName,
                                  ),
                                ),
                              ).then((_) => _loadParts());
                            }
                          : null,
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(
                          isOverdue ? Icons.warning_amber_rounded : Icons.alarm,
                          color: color,
                        ),
                      ),
                      title: Text(
                        item.partName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${machine != null ? machine.model : "ماكينة #${item.machineId}"} | مستحق: ${DateFormatter.toDisplay(item.nextDueDate!)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOverdue ? 'مستحق الآن' : 'يقترب موعده',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

          // ── Latest Replacements ──────────────────────────────────
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'سجل استبدال القطع المسجلة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          if (parts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'لا توجد سجلات لقطع الغيار مسجلة لماكينات هذا العميل',
                  style:
                      TextStyle(fontFamily: 'Cairo', color: AppColors.darkGrey),
                ),
              ),
            )
          else
            ...parts.take(15).map((p) => BlocBuilder<MachineCubit, MachineState>(
                  builder: (context, mState) {
                    final machines = mState is MachineLoaded
                        ? mState.machines
                        : <MachineModel>[];
                    final machine = machines
                        .cast<MachineModel?>()
                        .firstWhere((m) => m?.id == p.machineId,
                            orElse: () => null);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: machine != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MachineDetailScreen(
                                      machine: machine,
                                      customerName: widget.customerName,
                                    ),
                                  ),
                                ).then((_) => _loadParts());
                              }
                            : null,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryAccent,
                          child: Icon(Icons.settings,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(
                          p.partName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${machine != null ? machine.model : "ماكينة #${p.machineId}"} • تاريخ الاستبدال: ${DateFormatter.toDisplay(p.replacedDate)}${p.runningHoursAtReplacement != null ? ' • ${p.runningHoursAtReplacement} ساعة' : ''}',
                          style: const TextStyle(
                              fontFamily: 'Cairo', fontSize: 12),
                        ),
                        trailing: (p.cost ?? 0) > 0
                            ? Text(
                                '${(p.cost ?? 0).toStringAsFixed(0)} ج.م',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                )),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }
}
