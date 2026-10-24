import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/sales_invoice/sales_invoice_cubit.dart';
import 'package:gomaa_management/cubits/inventory/inventory_cubit.dart';
import 'package:gomaa_management/repositories/inventory_repository.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/invoice_calculator.dart';
import 'package:gomaa_management/services/validation_service.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';

class SalesInvoiceFormScreen extends StatefulWidget {
  final int customerId;
  final String customerName;
  final SalesInvoiceModel? invoice; // null = create, non-null = edit

  const SalesInvoiceFormScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.invoice,
  });

  @override
  State<SalesInvoiceFormScreen> createState() => _SalesInvoiceFormScreenState();
}

class _InvoiceCalculatedTotals {
  final double total;
  final double paid;
  final double remaining;
  final bool isOverpaid;
  final double overpaidAmount;

  const _InvoiceCalculatedTotals({
    required this.total,
    required this.paid,
    required this.remaining,
    required this.isOverpaid,
    required this.overpaidAmount,
  });
}

class _SalesInvoiceFormScreenState extends State<SalesInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  late final ValueNotifier<_InvoiceCalculatedTotals> _totalsNotifier;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final inv = widget.invoice!;
      _itemNameController.text = inv.itemName;
      _modelController.text = inv.model;
      _quantityController.text = inv.quantity.toString();
      _priceController.text = inv.price.toStringAsFixed(2);
      _paidController.text = inv.paidAmount.toStringAsFixed(2);
      _notesController.text = inv.notes;
      _date = inv.date;
    }

    _totalsNotifier = ValueNotifier<_InvoiceCalculatedTotals>(_computeTotals());

    // Lightweight listener: updates only the totals card, NO full-page rebuilds
    _priceController.addListener(_onInputChanged);
    _quantityController.addListener(_onInputChanged);
    _paidController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    _totalsNotifier.value = _computeTotals();
  }

  _InvoiceCalculatedTotals _computeTotals() {
    final price = InvoiceCalculator.parseMoney(_priceController.text);
    final qty = InvoiceCalculator.parseQuantity(_quantityController.text);
    final paid = InvoiceCalculator.parseMoney(_paidController.text);
    final total = InvoiceCalculator.total(price: price, quantity: qty);
    final remaining = InvoiceCalculator.remaining(totalAmount: total, paid: paid);
    final isOverpaid = InvoiceCalculator.isOverpaid(totalAmount: total, paid: paid);
    final overpaidAmount = InvoiceCalculator.overpaidAmount(totalAmount: total, paid: paid);

    return _InvoiceCalculatedTotals(
      total: total,
      paid: paid,
      remaining: remaining,
      isOverpaid: isOverpaid,
      overpaidAmount: overpaidAmount,
    );
  }

  @override
  void dispose() {
    _priceController.removeListener(_onInputChanged);
    _quantityController.removeListener(_onInputChanged);
    _paidController.removeListener(_onInputChanged);
    _totalsNotifier.dispose();

    _itemNameController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_isLoading) return; // Prevent double-submit

    // 1. Validation check
    if (!_formKey.currentState!.validate()) return;
    if (widget.customerId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطأ: يجب تحديد عميل صالح لإنشاء الفاتورة',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final price = InvoiceCalculator.parseMoney(_priceController.text);
    final qty = InvoiceCalculator.parseQuantity(_quantityController.text);
    final paid = InvoiceCalculator.parseMoney(_paidController.text);
    final total = InvoiceCalculator.total(price: price, quantity: qty);
    final remaining = InvoiceCalculator.remaining(totalAmount: total, paid: paid);
    final itemName = _itemNameController.text.trim();
    final model = _modelController.text.trim();

    // 2. Overpayment check and user confirmation
    if (InvoiceCalculator.isOverpaid(totalAmount: total, paid: paid)) {
      final overpaid = InvoiceCalculator.overpaidAmount(totalAmount: total, paid: paid);
      final proceedOverpayment = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.blueAccent, size: 28),
              SizedBox(width: 8),
              Text(
                'تنبيه زيادة المبلغ المدفوع',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'المبلغ المدفوع (${InvoiceCalculator.formatMoney(paid)}) أكبر من إجمالي الفاتورة (${InvoiceCalculator.formatMoney(total)}) بمقدار ${InvoiceCalculator.formatMoney(overpaid)}.\n\nهل ترغب في تسجيل المبلغ الزائد كرصيد دائن للعميل والمتابعة؟',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تعديل المبلغ', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'متابعة وتسجيل كرصيد دائن',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (proceedOverpayment != true) return;
    }

    // 3. Low-stock warning check
    final inventoryRepo = InventoryRepository();
    final invItem = await inventoryRepo.getByNameAndModel(itemName, model);
    final availableQty = invItem?.quantity ?? 0;
    final oldQty = widget.invoice != null &&
            widget.invoice!.itemName.trim() == itemName &&
            widget.invoice!.model.trim() == model
        ? widget.invoice!.quantity
        : 0;
    final effectiveAvailable = availableQty + oldQty;

    if (effectiveAvailable < qty) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                'تنبيه نقص المخزون',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'الكمية المتاحة في المخزون ($availableQty) أقل من الكمية المطلوب بيعها ($qty).\n\nهل ترغب في المتابعة وإتمام الفاتورة بالرغم من ذلك؟',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'متابعة وإتمام البيع',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    SalesInvoiceModel invoice = SalesInvoiceModel(
      id: widget.invoice?.id,
      customerId: widget.customerId,
      customerName: widget.customerName,
      itemName: itemName,
      model: model,
      quantity: qty,
      price: price,
      totalAmount: total,
      paidAmount: paid,
      remainingBalance: remaining,
      date: _date,
      notes: _notesController.text.trim(),
    );

    try {
      if (_isEditing) {
        final success = await context.read<SalesInvoiceCubit>().updateInvoice(invoice);
        if (!success) throw Exception('فشل تحديث الفاتورة');
      } else {
        final newId = await context.read<SalesInvoiceCubit>().addInvoice(invoice);
        if (newId == null) throw Exception('فشل إنشاء الفاتورة');
        invoice = invoice.copyWith(id: newId);
      }

      if (mounted) {
        context.read<InventoryCubit>().loadInventory();
        Navigator.pop(context, invoice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الفاتورة' : 'فاتورة بيع جديدة',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CustomerInfoBanner(customerName: widget.customerName),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'بيانات الصنف', icon: Icons.inventory_2_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _itemNameController,
                label: 'اسم الصنف / الجهاز',
                hint: 'مثال: كمبريسور هواء',
                icon: Icons.precision_manufacturing_outlined,
                validator: (val) => ValidationService.validateRequiredField(val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'الكمية',
                      hint: '1',
                      icon: Icons.numbers_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'مطلوب';
                        }
                        final q = int.tryParse(val.trim());
                        if (q == null || q <= 0) {
                          return 'أكبر من 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _modelController,
                      label: 'الموديل (اختياري)',
                      hint: 'مثال: AIR-2000',
                      icon: Icons.tag_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SectionHeader(title: 'بيانات الدفع والأسعار', icon: Icons.payments_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'السعر للوحدة',
                hint: '0.00',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'مطلوب';
                  }
                  final p = double.tryParse(val.replaceAll(',', '').trim());
                  if (p == null || p < 0) {
                    return 'أدخل سعراً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _paidController,
                label: 'المبلغ المدفوع حالياً',
                hint: '0.00',
                icon: Icons.paid_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final p = double.tryParse(val.replaceAll(',', '').trim());
                    if (p == null || p < 0) {
                      return 'أدخل مبلغاً صحيحاً';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Live calculated summary with ValueNotifier
              ValueListenableBuilder<_InvoiceCalculatedTotals>(
                valueListenable: _totalsNotifier,
                builder: (context, totals, _) {
                  return _InvoiceTotalsSummaryCard(totals: totals, isDark: isDark);
                },
              ),

              const SizedBox(height: 16),
              _DateSelectionTile(date: _date, onPickDate: _pickDate),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات الفاتورة (اختياري)',
                hint: 'أي شروط أو تفاصيل إضافية...',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: _isEditing ? 'حفظ التعديلات' : 'إنشاء الفاتورة',
                icon: _isEditing ? Icons.save_outlined : Icons.receipt_outlined,
                isLoading: _isLoading,
                onPressed: () => _save(),
              ),
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

class _CustomerInfoBanner extends StatelessWidget {
  final String customerName;

  const _CustomerInfoBanner({required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            customerName,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.person_pin,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppColors.primary, size: 18),
      ],
    );
  }
}

class _InvoiceTotalsSummaryCard extends StatelessWidget {
  final _InvoiceCalculatedTotals totals;
  final bool isDark;

  const _InvoiceTotalsSummaryCard({required this.totals, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: totals.isOverpaid
              ? Colors.purple.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryColumn(
                label: 'الإجمالي',
                value: InvoiceCalculator.formatMoney(totals.total),
                color: AppColors.primaryAccent,
              ),
              _SummaryColumn(
                label: 'المدفوع',
                value: InvoiceCalculator.formatMoney(totals.paid),
                color: AppColors.success,
              ),
              _SummaryColumn(
                label: 'المتبقي',
                value: InvoiceCalculator.formatMoney(totals.remaining),
                color: totals.remaining > 0 ? AppColors.error : AppColors.success,
              ),
            ],
          ),
          if (totals.isOverpaid) ...[
            const SizedBox(height: 8),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.purple, size: 16),
                const SizedBox(width: 6),
                Text(
                  'رصيد دائن زائد: ${InvoiceCalculator.formatMoney(totals.overpaidAmount)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }
}

class _DateSelectionTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPickDate;

  const _DateSelectionTile({required this.date, required this.onPickDate});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primaryAccent,
              size: 20,
            ),
            Text(
              'تاريخ الفاتورة: ${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
