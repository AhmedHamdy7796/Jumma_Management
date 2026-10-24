import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/sales_invoice/sales_invoice_cubit.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/utils/invoice_calculator.dart';
import 'package:gomaa_management/core/utils/invoice_pdf_generator.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'sales_invoice_form_screen.dart';

class SalesInvoiceDetailScreen extends StatefulWidget {
  final SalesInvoiceModel invoice;

  const SalesInvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<SalesInvoiceDetailScreen> createState() =>
      _SalesInvoiceDetailScreenState();
}

class _SalesInvoiceDetailScreenState extends State<SalesInvoiceDetailScreen> {
  late SalesInvoiceModel _currentInvoice;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _currentInvoice = widget.invoice;
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.push<SalesInvoiceModel?>(
      context,
      MaterialPageRoute(
        builder: (_) => SalesInvoiceFormScreen(
          customerId: _currentInvoice.customerId,
          customerName: _currentInvoice.customerName.isNotEmpty
              ? _currentInvoice.customerName
              : 'العميل',
          invoice: _currentInvoice,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _currentInvoice = updated);
    } else if (mounted && _currentInvoice.id != null) {
      // Reload fresh record from database if form returned without explicit model
      final fresh = await context
          .read<SalesInvoiceCubit>()
          .getInvoiceById(_currentInvoice.id!);
      if (fresh != null && mounted) {
        setState(() => _currentInvoice = fresh);
      }
    }
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await InvoicePdfGenerator.printInvoice(invoice: _currentInvoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء طباعة الفاتورة: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _handleDelete() {
    ConfirmDeleteDialog.show(
      context,
      title: 'حذف الفاتورة',
      content: 'هل أنت متأكد من حذف هذه الفاتورة؟ سيتم استرجاع الكميات المباعة للمخزون.',
      onDelete: () async {
        final success = await context
            .read<SalesInvoiceCubit>()
            .deleteInvoice(_currentInvoice.id!);
        if (mounted) {
          if (success) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'فشل حذف الفاتورة، يرجى المحاولة لاحقاً',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<SalesInvoiceCubit, SalesInvoiceState>(
      listener: (context, state) {
        if (state is SalesInvoiceLoaded) {
          final found = state.invoices
              .where((inv) => inv.id == _currentInvoice.id)
              .firstOrNull;
          if (found != null && found != _currentInvoice) {
            setState(() => _currentInvoice = found);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تفاصيل الفاتورة',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: _isPrinting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print_outlined),
              tooltip: 'طباعة الفاتورة',
              onPressed: _isPrinting ? null : _handlePrint,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'تعديل الفاتورة',
              onPressed: _handleEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'حذف الفاتورة',
              onPressed: _handleDelete,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InvoiceHeaderCard(invoice: _currentInvoice),
              const SizedBox(height: 16),
              _CustomerInfoBanner(invoice: _currentInvoice, isDark: isDark),
              const SizedBox(height: 16),
              _ItemsBreakdownCard(invoice: _currentInvoice, isDark: isDark),
              const SizedBox(height: 16),
              _FinancialBreakdownCard(invoice: _currentInvoice, isDark: isDark),
              if (_currentInvoice.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _NotesCard(notes: _currentInvoice.notes, isDark: isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private Component Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceHeaderCard extends StatelessWidget {
  final SalesInvoiceModel invoice;

  const _InvoiceHeaderCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رقم الفاتورة: #${invoice.id ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const Icon(Icons.receipt_long, color: Colors.white70, size: 28),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'تاريخ الإصدار: ${DateFormatter.toDisplay(invoice.date)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerInfoBanner extends StatelessWidget {
  final SalesInvoiceModel invoice;
  final bool isDark;

  const _CustomerInfoBanner({required this.invoice, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'العميل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.darkGrey,
                  ),
                ),
                Text(
                  invoice.customerName.isNotEmpty
                      ? invoice.customerName
                      : 'عميل نقدي',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (invoice.customerAddress.isNotEmpty)
                  Text(
                    invoice.customerAddress,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.darkGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsBreakdownCard extends StatelessWidget {
  final SalesInvoiceModel invoice;
  final bool isDark;

  const _ItemsBreakdownCard({required this.invoice, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lineTotal = InvoiceCalculator.roundMoney(invoice.price * invoice.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'بنود الفاتورة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    ),
                    if (invoice.model.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'الموديل: ${invoice.model}',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    InvoiceCalculator.formatMoney(lineTotal),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${invoice.quantity} × ${InvoiceCalculator.formatMoney(invoice.price)}',
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
      ),
    );
  }
}

class _FinancialBreakdownCard extends StatelessWidget {
  final SalesInvoiceModel invoice;
  final bool isDark;

  const _FinancialBreakdownCard({required this.invoice, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasRemaining = invoice.remainingBalance > 0;
    final isOverpaid = InvoiceCalculator.isOverpaid(
      totalAmount: invoice.totalAmount,
      paid: invoice.paidAmount,
    );
    final overpaidCredit = InvoiceCalculator.overpaidAmount(
      totalAmount: invoice.totalAmount,
      paid: invoice.paidAmount,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الملخص المالي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
          const Divider(height: 20),
          _FinSummaryRow(
            label: 'إجمالي الفاتورة',
            value: InvoiceCalculator.formatMoney(invoice.totalAmount),
            color: AppColors.primaryAccent,
          ),
          const SizedBox(height: 12),
          _FinSummaryRow(
            label: 'المبلغ المدفوع',
            value: InvoiceCalculator.formatMoney(invoice.paidAmount),
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _FinSummaryRow(
            label: 'المبلغ المتبقي',
            value: InvoiceCalculator.formatMoney(invoice.remainingBalance),
            color: hasRemaining ? AppColors.error : AppColors.success,
          ),
          if (isOverpaid) ...[
            const SizedBox(height: 12),
            _FinSummaryRow(
              label: 'رصيد دائن زائد (overpayment)',
              value: InvoiceCalculator.formatMoney(overpaidCredit),
              color: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }
}

class _FinSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinSummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.darkGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  final bool isDark;

  const _NotesCard({required this.notes, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'ملاحظات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
        ],
      ),
    );
  }
}
