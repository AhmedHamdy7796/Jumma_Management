import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gomaa_management/features/fix/data/models/fix.dart';
import 'package:gomaa_management/features/fix/presentation/cubit/fix_cubit.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

class FixFormScreen extends StatefulWidget {
  final Fix? fix;

  const FixFormScreen({super.key, this.fix});

  @override
  State<FixFormScreen> createState() => _FixFormScreenState();
}

class _FixFormScreenState extends State<FixFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _machineNameController = TextEditingController();
  final _modelController = TextEditingController();
  final _dryerTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _issueController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  String _status = 'pending';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.fix != null) {
      _machineNameController.text = widget.fix!.machineName;
      _modelController.text = widget.fix!.model;
      _dryerTypeController.text = widget.fix!.dryerType;
      _quantityController.text = widget.fix!.quantity.toString();
      _issueController.text = widget.fix!.issue;
      _costController.text = widget.fix!.cost.toString();
      _notesController.text = widget.fix!.notes;
      _status = widget.fix!.status;
      _selectedDate = widget.fix!.date;
    }
  }

  @override
  void dispose() {
    _machineNameController.dispose();
    _modelController.dispose();
    _dryerTypeController.dispose();
    _quantityController.dispose();
    _issueController.dispose();
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

  Future<void> _saveFix() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final fix = Fix(
      id: widget.fix?.id,
      machineName: _machineNameController.text,
      model: _modelController.text,
      dryerType: _dryerTypeController.text,
      quantity: int.parse(_quantityController.text),
      issue: _issueController.text,
      status: _status,
      cost: double.parse(_costController.text),
      date: _selectedDate,
      notes: _notesController.text,
    );

    try {
      if (widget.fix == null) {
        await context.read<FixCubit>().addFix(fix);
      } else {
        await context.read<FixCubit>().updateFix(fix);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fix == null
                  ? AppStrings.addSuccess
                  : AppStrings.updateSuccess,
              style: const TextStyle(fontFamily: 'Arial'),
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
          widget.fix == null ? AppStrings.addFix : AppStrings.editFix,
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
              label: AppStrings.machineName,
              controller: _machineNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterMachineName;
                }
                return null;
              },
            ),
            CustomTextField(
              label: AppStrings.model,
              controller: _modelController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterModel;
                }
                return null;
              },
            ),
            CustomTextField(
              label: AppStrings.dryer,
              controller: _dryerTypeController,
            ),
            CustomTextField(
              label: AppStrings.quantity,
              controller: _quantityController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterQuantity;
                }
                if (int.tryParse(value) == null) {
                  return AppStrings.enterValidNumber;
                }
                return null;
              },
            ),
            CustomTextField(
              label: AppStrings.issue,
              controller: _issueController,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterIssue;
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    AppStrings.status,
                    style: TextStyle(fontSize: 16, fontFamily: 'Arial'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text(
                          AppStrings.pending,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontFamily: 'Arial'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text(
                          AppStrings.inProgress,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontFamily: 'Arial'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text(
                          AppStrings.completed,
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
              label: AppStrings.cost,
              controller: _costController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterCost;
                }
                if (double.tryParse(value) == null) {
                  return AppStrings.enterValidNumber;
                }
                return null;
              },
            ),
            CustomTextField(
              label: AppStrings.date,
              controller: TextEditingController(
                text: DateFormat('yyyy/MM/dd').format(_selectedDate),
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
              text: widget.fix == null ? AppStrings.add : AppStrings.update,
              onPressed: _saveFix,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
