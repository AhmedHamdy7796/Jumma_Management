
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/sales_invoice/sales_invoice_cubit.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/utils/invoice_pdf_generator.dart';
import 'package:gomaa_management/core/widgets/confirm_delete_dialog.dart';
import 'sales_invoice_form_screen.dart';

class SalesInvoiceDetailScreen extends StatelessWidget {
  final SalesInvoiceModel invoice;
  const SalesInvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
          // Print button
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة الفاتورة',
            onPressed: () async {
              try {
                await InvoicePdfGenerator.printInvoice(invoice: invoice);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ أثناء الطباعة: $e',
                          style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل الفاتورة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SalesInvoiceFormScreen(
                    customerId: invoice.customerId,
                    customerName: invoice.customerName.isNotEmpty
                        ? invoice.customerName
                        : 'العميل',
                    invoice: invoice,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'حذف الفاتورة',
            onPressed: () => ConfirmDeleteDialog.show(
              context,
              title: 'حذف الفاتورة',
              content: 'هل أنت متأكد من حذف هذه الفاتورة؟',
              onDelete: () {
                context
                    .read<SalesInvoiceCubit>()
                    .deleteInvoice(invoice.id!);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Invoice header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.75)
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
                      Text(
                        'رقم الفاتورة: #${invoice.id}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Cairo'),
                      ),
                      const Icon(Icons.receipt_long,
                          color: Colors.white70, size: 32),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    invoice.itemName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (invoice.model.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'موديل: ${invoice.model}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Cairo'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  _headerRow(Icons.calendar_today_outlined,
                      DateFormatter.toDisplay(invoice.date)),
                  _headerRow(Icons.numbers_outlined,
                      'الكمية: ${invoice.quantity}'),
                  _headerRow(Icons.attach_money,
                      'سعر الوحدة: ${invoice.price.toStringAsFixed(2)} ج.م'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Financial breakdown
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  _finRow('الإجمالي',
                      '${invoice.totalAmount.toStringAsFixed(2)} ج.م',
                      AppColors.primaryAccent),
                  const SizedBox(height: 12),
                  _finRow('المدفوع',
                      '${invoice.paidAmount.toStringAsFixed(2)} ج.م',
                      AppColors.success),
                  const SizedBox(height: 12),
                  _finRow('المتبقي',
                      '${invoice.remainingBalance.toStringAsFixed(2)} ج.م',
                      invoice.remainingBalance > 0
                          ? AppColors.error
                          : AppColors.success),
                ],
              ),
            ),

            if (invoice.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('ملاحظات',
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        SizedBox(width: 6),
                        Icon(Icons.notes_outlined,
                            color: AppColors.primary, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invoice.notes,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontFamily: 'Cairo', fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(text,
              style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Cairo',
                  fontSize: 13)),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _finRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color),
        ),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.darkGrey)),
      ],
    );
  }
}
