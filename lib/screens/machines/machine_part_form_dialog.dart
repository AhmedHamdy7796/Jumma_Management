import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/utils/date_formatter.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/cubits/inventory/inventory_cubit.dart';
import 'package:gomaa_management/cubits/machine_part/machine_part_cubit.dart';
import 'package:gomaa_management/models/inventory_model.dart';
import 'package:gomaa_management/models/machine_part_model.dart';
import 'package:gomaa_management/services/validation_service.dart';

class MachinePartFormDialog extends StatefulWidget {
  final int machineId;
  final MachinePartModel? part;

  const MachinePartFormDialog({
    super.key,
    required this.machineId,
    this.part,
  });

  static Future<void> show(
    BuildContext context, {
    required int machineId,
    MachinePartModel? part,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<MachinePartCubit>()),
          BlocProvider.value(value: context.read<InventoryCubit>()),
        ],
        child: MachinePartFormDialog(
          machineId: machineId,
          part: part,
        ),
      ),
    );
  }

  @override
  State<MachinePartFormDialog> createState() => _MachinePartFormDialogState();
}

class _MachinePartFormDialogState extends State<MachinePartFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _hoursController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _deductQtyController = TextEditingController(text: '1');

  DateTime _replacedDate = DateTime.now();
  DateTime? _nextDueDate;
  InventoryModel? _selectedInventoryItem;
  bool _isSaving = false;

  final List<String> _commonParts = [
    'فاصل زيت',
    'فلتر زيت',
    'فلتر هواء',
    'زيت كمبروسر',
    'بلف سحب',
    'سير إدارة',
  ];

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().loadInventory();

    if (widget.part != null) {
      final p = widget.part!;
      _nameController.text = p.partName;
      _numberController.text = p.partNumber ?? '';
      _hoursController.text = p.runningHoursAtReplacement?.toString() ?? '';
      _costController.text = p.cost?.toString() ?? '';
      _notesController.text = p.notes ?? '';
      _replacedDate = p.replacedDate;
      _nextDueDate = p.nextDueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _hoursController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _deductQtyController.dispose();
    super.dispose();
  }

  Future<void> _pickReplacedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _replacedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _replacedDate = picked);
    }
  }

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? _replacedDate.add(const Duration(days: 90)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final deductQty = int.tryParse(_deductQtyController.text.trim()) ?? 1;

    // Warning check if stock is insufficient (like Sales Invoices)
    if (_selectedInventoryItem != null && widget.part == null) {
      final available = _selectedInventoryItem!.quantity;
      if (available < deductQty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  'تنبيه نقص المخزون',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Text(
              'الكمية المتاحة في المخزون ($available) أقل من الكمية المطلوب خصمها ($deductQty) لصنف "${_selectedInventoryItem!.name}".\n\nهل ترغب في المتابعة وإتمام العملية بالرغم من ذلك؟',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('متابعة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final hours = double.tryParse(_hoursController.text.trim());
      final cost = double.tryParse(_costController.text.trim());
      final partNum = _numberController.text.trim();
      final notes = _notesController.text.trim();

      if (widget.part == null) {
        final newPart = MachinePartModel(
          machineId: widget.machineId,
          partName: _nameController.text.trim(),
          partNumber: partNum.isNotEmpty ? partNum : null,
          replacedDate: _replacedDate,
          runningHoursAtReplacement: hours,
          nextDueDate: _nextDueDate,
          cost: cost,
          notes: notes.isNotEmpty ? notes : null,
          createdAt: DateTime.now(),
        );

        if (!mounted) return;
        await context.read<MachinePartCubit>().addPartReplacement(
          newPart,
          inventoryItemId: _selectedInventoryItem?.id,
          quantityToDeduct: _selectedInventoryItem != null ? deductQty : 0,
        );
      } else {
        final updatedPart = widget.part!.copyWith(
          partName: _nameController.text.trim(),
          partNumber: partNum.isNotEmpty ? partNum : null,
          replacedDate: _replacedDate,
          runningHoursAtReplacement: hours,
          nextDueDate: _nextDueDate,
          cost: cost,
          notes: notes.isNotEmpty ? notes : null,
        );

        if (!mounted) return;
        await context.read<MachinePartCubit>().updatePart(updatedPart);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.part == null
                  ? 'تم تسجيل استبدال القطعة بنجاح'
                  : 'تم تحديث سجل استبدال القطعة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
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
    final isEdit = widget.part != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
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
                      child: const Icon(Icons.settings_suggest, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEdit ? 'تعديل سجل استبدال قطعة الغيار' : 'تسجيل استبدال قطعة غيار جديدة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
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
                const Divider(height: 20),

                // Form list
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Part Name Field
                      CustomTextField(
                        controller: _nameController,
                        label: 'اسم القطعة *',
                        hint: 'مثال: فاصل زيت، فلتر زيت',
                        validator: (v) => ValidationService.validateRequired(v, 'اسم القطعة مطلوب'),
                      ),
                      const SizedBox(height: 8),

                      // Quick pick chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _commonParts.map((name) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ActionChip(
                                label: Text(
                                  name,
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                                ),
                                onPressed: () {
                                  setState(() => _nameController.text = name);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Part Number
                      CustomTextField(
                        controller: _numberController,
                        label: 'رقم القطعة (Part Number)',
                        hint: 'مثال: 1622-0871-00',
                      ),
                      const SizedBox(height: 16),

                      // Replaced Date Picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkGrey.withValues(alpha: 0.3) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event, size: 18, color: AppColors.primaryAccent),
                                const SizedBox(width: 10),
                                Text(
                                  'تاريخ الاستبدال: ${DateFormatter.toDisplay(_replacedDate)}',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _pickReplacedDate,
                              child: const Text('تغيير', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Running hours & Cost in a row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _hoursController,
                              label: 'ساعات التشغيل',
                              hint: 'مثال: 4500',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _costController,
                              label: 'التكلفة (ج.م)',
                              hint: 'مثال: 1800',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Next Due Date Picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkGrey.withValues(alpha: 0.3) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notification_important_outlined, size: 18, color: AppColors.warning),
                                const SizedBox(width: 10),
                                Text(
                                  _nextDueDate == null
                                      ? 'الموعد القادم للاستبدال: غير محدد'
                                      : 'الموعد القادم: ${DateFormatter.toDisplay(_nextDueDate!)}',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_nextDueDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    splashRadius: 16,
                                    onPressed: () => setState(() => _nextDueDate = null),
                                  ),
                                TextButton(
                                  onPressed: _pickNextDueDate,
                                  child: Text(_nextDueDate == null ? 'تحديد' : 'تغيير', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // OPTIONAL Stock Link section (Only on new record)
                      if (!isEdit) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black12 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primaryAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'ربط بصنف من المخزون (اختياري)',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BlocBuilder<InventoryCubit, InventoryState>(
                                builder: (context, state) {
                                  List<InventoryModel> items = [];
                                  if (state is InventoryLoaded) {
                                    items = state.items;
                                  }

                                  return DropdownButtonFormField<InventoryModel?>(
                                    initialValue: _selectedInventoryItem,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      hintText: 'اختر صنفاً لخصم الكمية المستخدمة تلقائياً',
                                      hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                                    ),
                                    items: [
                                      const DropdownMenuItem<InventoryModel?>(
                                        value: null,
                                        child: Text('بدون ربط بالمخزون', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                                      ),
                                      ...items.map((item) {
                                        return DropdownMenuItem<InventoryModel?>(
                                          value: item,
                                          child: Text(
                                            '${item.name} (${item.model}) - متاح: ${item.quantity}',
                                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedInventoryItem = val;
                                        if (val != null) {
                                          if (_nameController.text.isEmpty) {
                                            _nameController.text = val.name;
                                          }
                                          if (_numberController.text.isEmpty && val.model.isNotEmpty) {
                                            _numberController.text = val.model;
                                          }
                                          if (_costController.text.isEmpty && val.sellingPrice > 0) {
                                            _costController.text = val.sellingPrice.toString();
                                          }
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                              if (_selectedInventoryItem != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('الكمية المستهلكة من المخزون: ', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _deductQtyController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

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
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: isEdit ? 'حفظ التعديل' : 'تسجيل الاستبدال',
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
