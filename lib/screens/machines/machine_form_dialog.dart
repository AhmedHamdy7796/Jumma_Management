import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/cubits/machine/machine_cubit.dart';
import 'package:gomaa_management/models/machine_model.dart';
import 'package:gomaa_management/services/validation_service.dart';

class MachineFormDialog extends StatefulWidget {
  final int customerId;
  final MachineModel? machine;

  const MachineFormDialog({
    super.key,
    required this.customerId,
    this.machine,
  });

  static Future<void> show(
    BuildContext context, {
    required int customerId,
    MachineModel? machine,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<MachineCubit>(),
        child: MachineFormDialog(
          customerId: customerId,
          machine: machine,
        ),
      ),
    );
  }

  @override
  State<MachineFormDialog> createState() => _MachineFormDialogState();
}

class _MachineFormDialogState extends State<MachineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _serialController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _installDate;
  bool _isSaving = false;

  final List<String> _commonTypes = [
    'ضاغط حلزوني',
    'ضاغط ترددي',
    'مجفف هواء',
    'خزان هواء',
    'طلمبة تفريغ',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.machine != null) {
      final m = widget.machine!;
      _typeController.text = m.machineType;
      _modelController.text = m.model;
      _yearController.text = m.manufactureYear?.toString() ?? '';
      _serialController.text = m.serialNumber ?? '';
      _notesController.text = m.notes ?? '';
      _installDate = m.installDate;
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _serialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickInstallDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _installDate ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _installDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final yearText = _yearController.text.trim();
      final year = yearText.isNotEmpty ? int.tryParse(yearText) : null;
      final serialText = _serialController.text.trim();
      final notesText = _notesController.text.trim();

      if (widget.machine == null) {
        final newMachine = MachineModel(
          customerId: widget.customerId,
          machineType: _typeController.text.trim(),
          model: _modelController.text.trim(),
          manufactureYear: year,
          serialNumber: serialText.isNotEmpty ? serialText : null,
          installDate: _installDate,
          notes: notesText.isNotEmpty ? notesText : null,
          createdAt: DateTime.now(),
        );
        await context.read<MachineCubit>().addMachine(newMachine);
      } else {
        final updatedMachine = widget.machine!.copyWith(
          machineType: _typeController.text.trim(),
          model: _modelController.text.trim(),
          manufactureYear: year,
          serialNumber: serialText.isNotEmpty ? serialText : null,
          installDate: _installDate,
          notes: notesText.isNotEmpty ? notesText : null,
        );
        await context.read<MachineCubit>().updateMachine(updatedMachine);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.machine == null
                  ? 'تمت إضافة الماكينة بنجاح'
                  : 'تم تحديث بيانات الماكينة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.machine != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'تعديل بيانات الماكينة' : 'إضافة ماكينة جديدة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Form fields
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Machine Type
                      CustomTextField(
                        controller: _typeController,
                        label: 'نوع الماكينة *',
                        hint: 'مثال: ضاغط حلزوني، مجفف هواء',
                        validator: (v) => ValidationService.validateRequired(
                          v,
                          'نوع الماكينة مطلوب',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick pick chips for type
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _commonTypes.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ActionChip(
                                label: Text(
                                  type,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _typeController.text = type);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Model
                      CustomTextField(
                        controller: _modelController,
                        label: 'الموديل (Model) *',
                        hint: 'مثال: GA-37, VFD-50',
                        validator: (v) => ValidationService.validateRequired(
                          v,
                          'موديل الماكينة مطلوب',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Manufacture Year
                      CustomTextField(
                        controller: _yearController,
                        label: 'سنة الصنع (اختياري)',
                        hint: 'مثال: 2021 (بين 1950 و ${DateTime.now().year})',
                        keyboardType: TextInputType.number,
                        validator: ValidationService.validateManufactureYear,
                      ),
                      const SizedBox(height: 16),

                      // Serial Number
                      CustomTextField(
                        controller: _serialController,
                        label: 'الرقم التسلسلي (Serial No)',
                        hint: 'مثال: SN-9823412',
                      ),
                      const SizedBox(height: 16),

                      // Install Date Tile
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkGrey.withValues(alpha: 0.3)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.primaryAccent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _installDate == null
                                      ? 'تاريخ التركيب بالموقع: غير محدد'
                                      : 'تاريخ التركيب: ${DateFormatter.toDisplay(_installDate!)}',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_installDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    splashRadius: 16,
                                    onPressed: () {
                                      setState(() => _installDate = null);
                                    },
                                  ),
                                TextButton(
                                  onPressed: _pickInstallDate,
                                  child: Text(
                                    _installDate == null ? 'تحديد' : 'تغيير',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      CustomTextField(
                        controller: _notesController,
                        label: 'ملاحظات إضافية',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'إلغاء',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: isEdit ? 'حفظ التعديل' : 'إضافة الماكينة',
                        isLoading: _isSaving,
                        onPressed: () {
                          _save();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
