import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/customer/customer_cubit.dart';
import 'package:gomaa_management/models/customer_model.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/services/validation_service.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.customer!.name;
      _mobileController.text = widget.customer!.mobilePhone;
      _companyController.text = widget.customer!.companyName ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _notesController.text = widget.customer!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = CustomerModel(
      id: widget.customer?.id,
      name: _nameController.text.trim(),
      mobilePhone: _mobileController.text.trim(),
      companyName: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      if (_isEditing) {
        await context.read<CustomerCubit>().updateCustomer(customer);
      } else {
        await context.read<CustomerCubit>().addCustomer(customer);
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
          _isEditing ? 'تعديل بيانات العميل' : AppStrings.addCustomer,
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
              // Section header
              _sectionHeader('بيانات العميل الأساسية', Icons.person_outline),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'اسم العميل',
                hint: 'أدخل الاسم الكامل',
                icon: Icons.person_outline,
                validator: ValidationService.validateRequiredField,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _mobileController,
                label: 'رقم الهاتف',
                hint: 'مثال: 01012345678',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: ValidationService.validateRequiredField,
              ),
              const SizedBox(height: 16),
              _sectionHeader('بيانات الشركة / المصنع', Icons.business_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _companyController,
                label: 'اسم الشركة أو المصنع (اختياري)',
                hint: 'مثال: مصنع النور للصناعة',
                icon: Icons.factory_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'العنوان (اختياري)',
                hint: 'مثال: القاهرة، شارع الثورة',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _sectionHeader('ملاحظات', Icons.notes_outlined),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _notesController,
                label: 'ملاحظات (اختياري)',
                hint: 'أي معلومات إضافية عن العميل...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: _isEditing ? 'حفظ التعديلات' : 'إضافة العميل',
                icon: _isEditing ? Icons.save_outlined : Icons.add,
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
