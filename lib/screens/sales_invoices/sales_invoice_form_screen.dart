import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/sales_invoice/sales_invoice_cubit.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
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

class _SalesInvoiceFormScreenState extends State<SalesInvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool get _isEditing => widget.invoice != null;

  double get _total =>
      (double.tryParse(_priceController.text) ?? 0) *
      (int.tryParse(_quantityController.text) ?? 1);

  double get _remaining =>
      _total - (double.tryParse(_paidController.text) ?? 0);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final inv = widget.invoice!;
      _itemNameController.text = inv.itemName;
      _modelController.text = inv.model;
      _quantityController.text = inv.quantity.toString();
      _priceController.text = inv.price.toString();
      _paidController.text = inv.paidAmount.toString();
      _notesController.text = inv.notes;
      _date = inv.date;
    }
    // Update total when price or quantity change
    _priceController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));
    _paidController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final price = double.parse(_priceController.text);
    final paid = double.tryParse(_paidController.text) ?? 0;
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final total = price * qty;
    final remaining = total - paid;

    final invoice = SalesInvoiceModel(
      id: widget.invoice?.id,
      customerId: widget.customerId,
      itemName: _itemNameController.text.trim(),
      model: _modelController.text.trim(),
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
        await context.read<SalesInvoiceCubit>().updateInvoice(invoice);
      } else {
        await context.read<SalesInvoiceCubit>().addInvoice(invoice);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
              // Customer info banner
              Container(
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
                      widget.customerName,
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
              ),
              const SizedBox(height: 20),
              _sectionHeader('بيانات الصنف', Icons.inventory_2_outlined),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _itemNameController,
                label: 'اسم الصنف / الجهاز',
                hint: 'مثال: كمبريسور هواء',
                icon: Icons.precision_manufacturing_outlined,
                validator: ValidationService.validateRequiredField,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'الكمية',
                      hint: '1',
                      icon: Icons.numbers_outlined,
                      keyboardType: TextInputType.number,
                      validator: ValidationService.validateRequiredField,
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
              const SizedBox(height: 20),
              _sectionHeader('بيانات الدفع', Icons.payments_outlined),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _priceController,
                label: 'السعر (للوحدة)',
                hint: 'مثال: 5000',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: ValidationService.validateRequiredField,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _paidController,
                label: 'المدفوع',
                hint: '0',
                icon: Icons.paid_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              // Auto-calculated summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : AppColors.lightGrey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryTile(
                      'الإجمالي',
                      '${_total.toStringAsFixed(2)} ج.م',
                      AppColors.primaryAccent,
                    ),
                    _summaryTile(
                      'المتبقي',
                      '${_remaining.toStringAsFixed(2)} ج.م',
                      _remaining > 0 ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Date picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                      ),
                      Text(
                        '${_date.day}/${_date.month}/${_date.year}',
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات (اختياري)',
                hint: 'أي معلومات إضافية...',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              CustomButton(
                label: _isEditing ? 'حفظ التعديلات' : 'إنشاء الفاتورة',
                icon: _isEditing ? Icons.save_outlined : Icons.receipt_outlined,
                isLoading: _isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AppColors.primary, size: 20),
      ],
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
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
        Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
      ],
    );
  }
}
