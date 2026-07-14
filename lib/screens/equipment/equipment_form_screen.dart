import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/equipment/equipment_cubit.dart';
import 'package:gomaa_management/models/equipment_model.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/services/validation_service.dart';

class EquipmentFormScreen extends StatefulWidget {
  final EquipmentModel? equipment;

  const EquipmentFormScreen({super.key, this.equipment});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  String _status = 'active';
  DateTime? _purchaseDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _nameController.text = widget.equipment!.name;
      _modelController.text = widget.equipment!.model;
      _serialController.text = widget.equipment!.serialNumber ?? '';
      _categoryController.text = widget.equipment!.category;
      _priceController.text = widget.equipment!.purchasePrice.toString();
      _locationController.text = widget.equipment!.location ?? '';
      _notesController.text = widget.equipment!.notes;
      _status = widget.equipment!.currentStatus;
      _purchaseDate = widget.equipment!.purchaseDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final item = EquipmentModel(
      id: widget.equipment?.id,
      name: _nameController.text,
      model: _modelController.text,
      serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text,
      category: _categoryController.text,
      purchasePrice: double.tryParse(_priceController.text) ?? 0,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text,
      notes: _notesController.text,
      currentStatus: _status,
      purchaseDate: _purchaseDate,
    );

    try {
      if (widget.equipment == null) {
        await context.read<EquipmentCubit>().addEquipment(item);
      } else {
        await context.read<EquipmentCubit>().updateEquipment(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              AppStrings.addSuccess,
              style: TextStyle(fontFamily: 'Arial'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              AppStrings.error,
              style: TextStyle(fontFamily: 'Arial'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.equipment == null ? 'إضافة جهاز جديد' : 'تعديل بيانات الجهاز',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Arial',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              label: 'اسم الجهاز/المعدة',
              controller: _nameController,
              validator: ValidationService.validateName,
            ),
            CustomTextField(
              label: AppStrings.model,
              controller: _modelController,
              validator: (value) => ValidationService.validateRequired(value, 'الرجاء إدخال الموديل'),
            ),
            CustomTextField(
              label: 'الرقم التسلسلي (اختياري)',
              controller: _serialController,
            ),
            CustomTextField(
              label: 'التصنيف (مثال: مجففات، غسالات)',
              controller: _categoryController,
              validator: (value) => ValidationService.validateRequired(value, 'الرجاء إدخال التصنيف'),
            ),
            CustomTextField(
              label: 'سعر الشراء (اختياري)',
              controller: _priceController,
              keyboardType: TextInputType.number,
            ),
            CustomTextField(
              label: 'الموقع/المستودع (اختياري)',
              controller: _locationController,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'حالة الجهاز',
                    style: TextStyle(fontSize: 16, fontFamily: 'Arial'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text(
                          'نشط (يعمل)',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontFamily: 'Arial'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text(
                          'تحت الصيانة',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontFamily: 'Arial'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'retired',
                        child: Text(
                          'مستبعد/خارج الخدمة',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontFamily: 'Arial'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            CustomTextField(
              label: 'تاريخ الشراء',
              controller: TextEditingController(
                text: _purchaseDate != null ? DateFormatter.toDisplay(_purchaseDate!) : '',
              ),
              readOnly: true,
              onTap: _selectDate,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            CustomTextField(
              label: AppStrings.notes,
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: widget.equipment == null ? AppStrings.add : AppStrings.update,
              onPressed: _saveEquipment,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
