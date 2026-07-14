import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/cubits/maintenance/maintenance_cubit.dart';
import 'package:gomaa_management/cubits/equipment/equipment_cubit.dart';
import 'package:gomaa_management/models/maintenance_record_model.dart';
import 'package:gomaa_management/models/maintenance_schedule_model.dart';
import 'package:gomaa_management/models/equipment_model.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/services/validation_service.dart';

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({super.key});

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _techController = TextEditingController();
  final _issueController = TextEditingController();
  final _workDoneController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedEquipmentId;
  String _maintType = 'preventive'; // 'preventive' | 'record'
  String _scheduleType = 'preventive'; // 'preventive' | 'inspection' | 'calibration'
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<EquipmentCubit>().loadEquipment();
  }

  @override
  void dispose() {
    _techController.dispose();
    _issueController.dispose();
    _workDoneController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate() || _selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الجهاز والمعدّة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_maintType == 'preventive') {
        // Create schedule item
        final item = MaintenanceScheduleModel(
          equipmentId: _selectedEquipmentId!,
          scheduledDate: _selectedDate,
          type: _scheduleType,
          notes: _notesController.text,
        );
        await context.read<MaintenanceCubit>().addScheduleItem(item);
      } else {
        // Create log record
        final record = MaintenanceRecordModel(
          equipmentId: _selectedEquipmentId!,
          technicianName: _techController.text,
          startDate: _selectedDate,
          issueDescription: _issueController.text,
          workDone: _workDoneController.text,
          cost: double.tryParse(_costController.text) ?? 0,
          status: 'closed',
          notes: _notesController.text,
        );
        await context.read<MaintenanceCubit>().addRecord(record);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.addSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.error), backgroundColor: AppColors.error),
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
        title: const Text('إضافة عملية صيانة', style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold)),
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
            // Select Maintenance Form Intent Type
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DropdownButtonFormField<String>(
                value: _maintType,
                decoration: const InputDecoration(
                  labelText: 'نوع العملية',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'preventive', child: Text('جدولة صيانة دورية وقائية')),
                  DropdownMenuItem(value: 'record', child: Text('تسجيل عملية صيانة منفذة بالفعل')),
                ],
                onChanged: (value) {
                  setState(() {
                    _maintType = value!;
                  });
                },
              ),
            ),
            // Equipment Selector Dropdown
            BlocBuilder<EquipmentCubit, EquipmentState>(
              builder: (context, state) {
                List<EquipmentModel> items = [];
                if (state is EquipmentLoaded) {
                  items = state.equipment;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DropdownButtonFormField<int>(
                    value: _selectedEquipmentId,
                    decoration: const InputDecoration(
                      labelText: 'اختر الجهاز/المعدة المعنية',
                      border: OutlineInputBorder(),
                    ),
                    items: items.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.id,
                        child: Text(e.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEquipmentId = value;
                      });
                    },
                    validator: (val) => val == null ? 'الرجاء اختيار الجهاز' : null,
                  ),
                );
              },
            ),
            if (_maintType == 'preventive') ...[
              DropdownButtonFormField<String>(
                value: _scheduleType,
                decoration: const InputDecoration(
                  labelText: 'نوع الصيانة المجدولة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'preventive', child: Text('صيانة وقائية')),
                  DropdownMenuItem(value: 'inspection', child: Text('فحص واختبار')),
                  DropdownMenuItem(value: 'calibration', child: Text('معايرة وضبط')),
                ],
                onChanged: (value) {
                  setState(() {
                    _scheduleType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              CustomTextField(
                label: 'اسم فني الصيانة',
                controller: _techController,
                validator: ValidationService.validateName,
              ),
              CustomTextField(
                label: 'وصف العطل أو المشكلة',
                controller: _issueController,
                validator: (val) => ValidationService.validateRequired(val, 'الرجاء كتابة المشكلة'),
              ),
              CustomTextField(
                label: 'تفاصيل ما تم إنجازه وصيانته',
                controller: _workDoneController,
              ),
              CustomTextField(
                label: 'التكلفة الإجمالية للصيانة',
                controller: _costController,
                keyboardType: TextInputType.number,
                validator: ValidationService.validateAmount,
              ),
            ],
            CustomTextField(
              label: 'التاريخ المجدول / تاريخ البدء',
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
              text: AppStrings.add,
              onPressed: _saveMaintenance,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
