import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/inventory/inventory_cubit.dart';
import 'package:gomaa_management/models/inventory_model.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/services/validation_service.dart';

class InventoryFormScreen extends StatefulWidget {
  final InventoryModel? item;
  const InventoryFormScreen({super.key, this.item});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _categoryController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final it = widget.item!;
      _nameController.text = it.name;
      _modelController.text = it.model;
      _quantityController.text = it.quantity.toString();
      _categoryController.text = it.category;
      _purchasePriceController.text = it.purchasePrice.toString();
      _sellingPriceController.text = it.sellingPrice.toString();
      _locationController.text = it.location ?? '';
      _notesController.text = it.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final item = InventoryModel(
      id: widget.item?.id,
      name: _nameController.text.trim(),
      model: _modelController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 0,
      category: _categoryController.text.trim(),
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      if (_isEditing) {
        await context.read<InventoryCubit>().updateItem(item);
      } else {
        await context.read<InventoryCubit>().addItem(item);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الصنف' : 'إضافة صنف جديد',
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
              _sectionHeader('بيانات الصنف', Icons.inventory_2_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'اسم الصنف',
                hint: 'مثال: كمبريسور هواء',
                icon: Icons.precision_manufacturing_outlined,
                validator: ValidationService.validateRequiredField,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'الكمية',
                      hint: '0',
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
              const SizedBox(height: 16),
              CustomTextField(
                controller: _categoryController,
                label: 'الفئة / التصنيف',
                hint: 'مثال: مستلزمات إنتاج',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                label: 'الموقع / المستودع (اختياري)',
                hint: 'مثال: الرف B-3',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _sectionHeader('الأسعار', Icons.payments_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _sellingPriceController,
                      label: 'سعر البيع',
                      hint: '0.00',
                      icon: Icons.sell_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _purchasePriceController,
                      label: 'سعر الشراء',
                      hint: '0.00',
                      icon: Icons.shopping_cart_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionHeader('ملاحظات', Icons.notes_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات (اختياري)',
                hint: 'أي معلومات إضافية...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: _isEditing ? 'حفظ التعديلات' : 'إضافة للمخزون',
                icon: _isEditing ? Icons.save_outlined : Icons.add_box_outlined,
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
}
