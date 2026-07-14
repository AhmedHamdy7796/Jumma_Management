import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:gomaa_management/cubits/purchase/purchase_cubit.dart';
import 'package:gomaa_management/models/purchase_model.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/services/image_storage_service.dart';
import 'package:gomaa_management/services/validation_service.dart';

class PurchaseFormScreen extends StatefulWidget {
  final PurchaseModel? purchase;

  const PurchaseFormScreen({super.key, this.purchase});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _machineNameController = TextEditingController();
  final _modelController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  bool _isLoading = false;
  final _imageStorageService = ImageStorageService();
  String? _appSupportDir;

  @override
  void initState() {
    super.initState();
    _initDir();
    if (widget.purchase != null) {
      _machineNameController.text = widget.purchase!.machineName;
      _modelController.text = widget.purchase!.model;
      _quantityController.text = widget.purchase!.quantity.toString();
      _priceController.text = widget.purchase!.price.toString();
      _paidController.text = widget.purchase!.paidAmount.toString();
      _notesController.text = widget.purchase!.notes;
      _selectedDate = widget.purchase!.date;
      _imagePath = widget.purchase!.imagePath;
    }
  }

  Future<void> _initDir() async {
    final dir = await getApplicationSupportDirectory();
    setState(() {
      _appSupportDir = dir.path;
    });
  }

  @override
  void dispose() {
    _machineNameController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  double get _remainingBalance {
    final paid = double.tryParse(_paidController.text) ?? 0;
    return _totalAmount - paid;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(AppStrings.pickFromGallery),
                onTap: () async {
                  final navigator = Navigator.of(sheetContext);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    final savedRelativePath = await _imageStorageService.saveImage(File(image.path), 'purchases');
                    setState(() {
                      _imagePath = savedRelativePath;
                    });
                  }
                  navigator.pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(AppStrings.takePhoto),
                onTap: () async {
                  final navigator = Navigator.of(sheetContext);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    final savedRelativePath = await _imageStorageService.saveImage(File(image.path), 'purchases');
                    setState(() {
                      _imagePath = savedRelativePath;
                    });
                  }
                  navigator.pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final purchase = PurchaseModel(
      id: widget.purchase?.id,
      machineName: _machineNameController.text,
      model: _modelController.text,
      quantity: int.parse(_quantityController.text),
      price: double.parse(_priceController.text),
      totalAmount: _totalAmount,
      paidAmount: double.parse(_paidController.text),
      remainingBalance: _remainingBalance,
      date: _selectedDate,
      notes: _notesController.text,
      imagePath: _imagePath,
    );

    try {
      if (widget.purchase == null) {
        await context.read<PurchaseCubit>().addPurchase(purchase);
      } else {
        await context.read<PurchaseCubit>().updatePurchase(purchase);
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
    File? imgFile;
    if (_imagePath != null && _appSupportDir != null) {
      imgFile = File(p.join(_appSupportDir!, _imagePath!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.purchase == null
              ? AppStrings.addPurchase
              : AppStrings.editPurchase,
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
            // Image Picker Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: imgFile != null && imgFile.existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.file(
                              imgFile,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.5,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _imagePath = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.addMachineImage,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontFamily: 'Arial',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: AppStrings.machineName,
              controller: _machineNameController,
              validator: ValidationService.validateName,
            ),
            CustomTextField(
              label: AppStrings.model,
              controller: _modelController,
              validator: (value) => ValidationService.validateRequired(value, AppStrings.enterModel),
            ),
            CustomTextField(
              label: AppStrings.quantity,
              controller: _quantityController,
              keyboardType: TextInputType.number,
              validator: ValidationService.validateQuantity,
            ),
            CustomTextField(
              label: AppStrings.price,
              controller: _priceController,
              keyboardType: TextInputType.number,
              validator: ValidationService.validateAmount,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryOp10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${AppStrings.total}: ${_totalAmount.toStringAsFixed(2)} ${AppStrings.currency}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ),
            CustomTextField(
              label: AppStrings.paid,
              controller: _paidController,
              keyboardType: TextInputType.number,
              validator: ValidationService.validateAmount,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successOp10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${AppStrings.remaining}: ${_remainingBalance.toStringAsFixed(2)} ${AppStrings.currency}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ),
            CustomTextField(
              label: AppStrings.date,
              controller: TextEditingController(
                text: DateFormatter.toDisplay(_selectedDate),
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
              text: widget.purchase == null
                  ? AppStrings.add
                  : AppStrings.update,
              onPressed: _savePurchase,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
