import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:gomaa_management/cubits/backup/backup_cubit.dart';
import 'package:gomaa_management/cubits/settings/settings_cubit.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/database/migration_manager.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/screens/audit_log/audit_log_screen.dart';
import 'package:gomaa_management/screens/settings/users_management_tab.dart';
import 'package:gomaa_management/services/backup_service.dart';
import 'package:gomaa_management/services/validation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Company tab form & controllers
  final _companyFormKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _currencyController = TextEditingController();
  final _companyTaxNumberController = TextEditingController();
  final _invoiceFooterNoteController = TextEditingController();
  String? _logoRelativePath;
  String? _appDocsDirPath;

  bool _controllersInitialized = false;
  bool _isSavingCompany = false;

  // Track initial values to detect unsaved changes
  String _initialCompanyName = '';
  String _initialCompanyPhone = '';
  String _initialCompanyAddress = '';
  String _initialCurrency = '';
  String _initialCompanyTaxNumber = '';
  String _initialInvoiceFooterNote = '';
  String? _initialLogoRelativePath;

  // Drive settings tab controllers
  final _driveFolderController = TextEditingController();
  final _driveKeepCountController = TextEditingController();
  bool _driveControllersInitialized = false;

  // ── Local state for "last backup" info (refreshed after each operation) ───
  String? _localBackupsPath;

  bool get _hasUnsavedCompanyChanges {
    return _companyNameController.text.trim() != _initialCompanyName.trim() ||
        _companyPhoneController.text.trim() != _initialCompanyPhone.trim() ||
        _companyAddressController.text.trim() != _initialCompanyAddress.trim() ||
        _currencyController.text.trim() != _initialCurrency.trim() ||
        _companyTaxNumberController.text.trim() != _initialCompanyTaxNumber.trim() ||
        _invoiceFooterNoteController.text.trim() != _initialInvoiceFooterNote.trim() ||
        _logoRelativePath != _initialLogoRelativePath;
  }

  void _syncInitialCompanyValues() {
    _initialCompanyName = _companyNameController.text;
    _initialCompanyPhone = _companyPhoneController.text;
    _initialCompanyAddress = _companyAddressController.text;
    _initialCurrency = _currencyController.text;
    _initialCompanyTaxNumber = _companyTaxNumberController.text;
    _initialInvoiceFooterNote = _invoiceFooterNoteController.text;
    _initialLogoRelativePath = _logoRelativePath;
  }

  void _resetCompanyToInitial() {
    _companyNameController.text = _initialCompanyName;
    _companyPhoneController.text = _initialCompanyPhone;
    _companyAddressController.text = _initialCompanyAddress;
    _currencyController.text = _initialCurrency;
    _companyTaxNumberController.text = _initialCompanyTaxNumber;
    _invoiceFooterNoteController.text = _initialInvoiceFooterNote;
    setState(() {
      _logoRelativePath = _initialLogoRelativePath;
    });
  }

  Future<bool> _showDiscardConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تغييرات غير محفوظة',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'لديك تعديلات غير محفوظة في بيانات الشركة. هل تريد تجاهل هذه التغييرات والمتابعة؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('البقاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تجاهل التغييرات', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _handleTabSelection() async {
    if (_tabController.indexIsChanging) {
      if (_currentTabIndex == 0 && _tabController.index != 0 && _hasUnsavedCompanyChanges) {
        final targetIndex = _tabController.index;
        _tabController.index = 0;
        final shouldDiscard = await _showDiscardConfirmDialog();
        if (shouldDiscard && mounted) {
          _resetCompanyToInitial();
          _currentTabIndex = targetIndex;
          _tabController.animateTo(targetIndex);
        }
      } else {
        _currentTabIndex = _tabController.index;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    context.read<SettingsCubit>().loadSettings();
    _loadAppDocsDir();
    _loadLocalBackupsPath();
  }

  Future<void> _loadAppDocsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) setState(() => _appDocsDirPath = dir.path);
  }

  Future<void> _loadLocalBackupsPath() async {
    final dir = await BackupService().localBackupsDir;
    if (mounted) setState(() => _localBackupsPath = dir.path);
  }

  void _initCompanyControllers(Map<String, String> settings) {
    _companyNameController.text = settings[SettingsKeys.companyName] ?? '';
    _companyPhoneController.text = settings[SettingsKeys.companyPhone] ?? '';
    _companyAddressController.text = settings[SettingsKeys.companyAddress] ?? '';
    _currencyController.text = settings[SettingsKeys.currencySymbol] ?? 'ج.م';
    _companyTaxNumberController.text = settings[SettingsKeys.companyTaxNumber] ?? '';
    _invoiceFooterNoteController.text = settings[SettingsKeys.invoiceFooterNote] ?? '';
    _logoRelativePath = settings[SettingsKeys.companyLogoPath];
    _syncInitialCompanyValues();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _currencyController.dispose();
    _companyTaxNumberController.dispose();
    _invoiceFooterNoteController.dispose();
    _driveFolderController.dispose();
    _driveKeepCountController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<BackupCubit, BackupState>(
      listener: _onBackupState,
      child: PopScope(
        canPop: !_hasUnsavedCompanyChanges,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _showDiscardConfirmDialog();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'الإعدادات والنسخ الاحتياطي',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: const [
                Tab(text: 'إعدادات الشركة'),
                Tab(text: 'النسخ الاحتياطي'),
                Tab(text: 'Google Drive'),
                Tab(text: 'إدارة المستخدمين'),
              ],
            ),
          ),
          body: BlocConsumer<SettingsCubit, SettingsState>(
            listener: (context, state) {
              if (state is SettingsLoaded) {
                if (!_controllersInitialized) {
                  _initCompanyControllers(state.settings);
                  _controllersInitialized = true;
                }
                if (!_driveControllersInitialized) {
                  _driveFolderController.text =
                      state.settings[SettingsKeys.driveFolderName] ?? 'Gomaa Backups';
                  _driveKeepCountController.text =
                      state.settings[SettingsKeys.driveKeepCount] ?? '10';
                  _driveControllersInitialized = true;
                }
              }
            },
            builder: (context, state) {
              if (state is SettingsLoading && !_controllersInitialized) {
                return const Center(child: CircularProgressIndicator());
              }

              Map<String, String> settings = {};
              if (state is SettingsLoaded) {
                settings = state.settings;
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildCompanyTab(settings),
                  _buildLocalBackupTab(settings),
                  _buildDriveTab(settings),
                  const UsersManagementTab(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BlocListener handler
  // ─────────────────────────────────────────────────────────────────────────

  void _onBackupState(BuildContext context, BackupState state) {
    if (state is BackupSuccess) {
      // Persist last backup timestamp and kind.
      final settingsCubit = context.read<SettingsCubit>();
      settingsCubit.updateAllSettings({
        SettingsKeys.lastBackupAt: DateTime.now().toIso8601String(),
        SettingsKeys.lastBackupKind: state.kind,
        SettingsKeys.lastBackupError: '',
      });

      final sizeKb = (state.sizeBytes / 1024).toStringAsFixed(1);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('تم الحفظ بنجاح', style: TextStyle(fontFamily: 'Cairo')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تم إنشاء النسخة الاحتياطية:',
                  style: TextStyle(fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              SelectableText(
                state.filePath,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Text('الحجم: $sizeKb KB',
                  style: const TextStyle(fontFamily: 'Cairo')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: state.filePath));
                Navigator.pop(context);
              },
              child: const Text('نسخ المسار'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } else if (state is RestoreSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت استعادة البيانات بنجاح! أُعيد تحميل جميع البيانات.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      context.read<SettingsCubit>().loadSettings();
      _controllersInitialized = false;
      _driveControllersInitialized = false;
    } else if (state is BackupError) {
      // Persist last error.
      context.read<SettingsCubit>().updateSetting(
            SettingsKeys.lastBackupError,
            state.message,
          );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('خطأ', style: TextStyle(fontFamily: 'Cairo')),
            ],
          ),
          content: Text(state.message,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: Company Actions & Tab
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickCompanyLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final error = ValidationService.validateLogoFile(
        fileName: file.name,
        byteLength: file.size,
      );
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final originalPath = file.path;
      if (originalPath == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final logosDir = Directory(p.join(appDir.path, 'logos'));
      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }
      final ext = p.extension(file.name).toLowerCase();
      final targetRelative = 'logos/company_logo$ext';
      final targetFile = File(p.join(appDir.path, targetRelative));
      await File(originalPath).copy(targetFile.path);

      if (mounted) {
        setState(() {
          _logoRelativePath = targetRelative;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الشعار: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeCompanyLogo() {
    setState(() {
      _logoRelativePath = null;
    });
  }

  Future<void> _saveCompanySettings() async {
    if (!(_companyFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSavingCompany = true);
    try {
      final Map<String, String> updatedSettings = {
        SettingsKeys.companyName: _companyNameController.text.trim(),
        SettingsKeys.companyPhone: _companyPhoneController.text.trim(),
        SettingsKeys.companyAddress: _companyAddressController.text.trim(),
        SettingsKeys.currencySymbol: _currencyController.text.trim(),
        SettingsKeys.companyTaxNumber: _companyTaxNumberController.text.trim(),
        SettingsKeys.invoiceFooterNote: _invoiceFooterNoteController.text.trim(),
        SettingsKeys.companyLogoPath: _logoRelativePath ?? '',
      };

      await context.read<SettingsCubit>().updateAllSettings(updatedSettings);
      _syncInitialCompanyValues();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعدادات بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حفظ الإعدادات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingCompany = false);
      }
    }
  }

  Widget _buildCompanyTab(Map<String, String> settings) {
    File? logoFile;
    if (_logoRelativePath != null && _logoRelativePath!.isNotEmpty) {
      if (p.isAbsolute(_logoRelativePath!)) {
        logoFile = File(_logoRelativePath!);
      } else if (_appDocsDirPath != null) {
        logoFile = File(p.join(_appDocsDirPath!, _logoRelativePath!));
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _companyFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.darkGrey.withValues(alpha: 0.2)
                    : Colors.blueGrey.shade200,
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.business, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'بيانات الشركة (تظهر في الفواتير المطبوعة)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Logo Picker & Preview Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkGrey.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'شعار الشركة (اختياري - يظهر في رأس الفاتورة)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: (logoFile != null && logoFile.existsSync())
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.file(logoFile, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey, size: 30),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                _isSavingCompany ? null : _pickCompanyLogo,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: Text(
                              logoFile != null && logoFile.existsSync()
                                  ? 'تغيير الشعار'
                                  : 'اختيار شعار الشركة',
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          if (logoFile != null && logoFile.existsSync()) ...[
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed:
                                  _isSavingCompany ? null : _removeCompanyLogo,
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              label: const Text(
                                'حذف الشعار',
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: AppColors.error),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'اسم الشركة *',
            controller: _companyNameController,
            validator: ValidationService.validateCompanyName,
            icon: Icons.store,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'رقم هاتف الشركة',
            controller: _companyPhoneController,
            keyboardType: TextInputType.phone,
            validator: ValidationService.validateCompanyPhone,
            icon: Icons.phone,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'عنوان الشركة',
            controller: _companyAddressController,
            icon: Icons.location_on,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'رمز العملة المستخدمة في التطبيق *',
            controller: _currencyController,
            validator: ValidationService.validateCurrencySymbol,
            icon: Icons.monetization_on,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'الرقم الضريبي / السجل التجاري (اختياري)',
            controller: _companyTaxNumberController,
            icon: Icons.badge,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'ملاحظة أسفل الفاتورة (اختياري، مثلاً شروط أو كلمة شكر)',
            controller: _invoiceFooterNoteController,
            maxLines: 3,
            icon: Icons.notes,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'حفظ الإعدادات',
            isLoading: _isSavingCompany,
            onPressed: _saveCompanySettings,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.darkGrey.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: const [
                    Text(
                      'إصدار التطبيق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1.0.0+1',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 32,
                  child: VerticalDivider(),
                ),
                Column(
                  children: const [
                    Text(
                      'إصدار قاعدة البيانات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'v${MigrationManager.currentVersion}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: Local Backup  (Item 1b + Item 2)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLocalBackupTab(Map<String, String> settings) {
    final lastBackupRaw = settings[SettingsKeys.lastBackupAt];
    final lastBackupKind = settings[SettingsKeys.lastBackupKind] ?? 'local';
    final lastError = settings[SettingsKeys.lastBackupError] ?? '';
    String lastBackupLabel = 'لم يتم إجراء نسخة احتياطية بعد';
    bool showReminder = false;

    if (lastBackupRaw != null && lastBackupRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(lastBackupRaw);
        final diff = DateTime.now().difference(dt);
        showReminder = diff.inHours >= 24;
        final kindLabel = lastBackupKind == 'drive' ? '(Drive)' : '(محلي)';
        lastBackupLabel =
            'آخر نسخة: ${_formatDt(dt)} $kindLabel';
      } catch (_) {}
    } else {
      showReminder = true;
    }

    return BlocBuilder<BackupCubit, BackupState>(
      builder: (context, state) {
        final isWorking = state is BackupLoading;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Reminder banner ─────────────────────────────────────────────
            if (showReminder)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تذكير: مضى أكثر من يوم منذ آخر نسخة احتياطية.',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Last backup info ─────────────────────────────────────────────
            _infoCard(
              icon: Icons.history,
              text: lastBackupLabel,
              color: showReminder ? Colors.orange : Colors.green,
            ),

            // ── Last error (if any) ──────────────────────────────────────────
            if (lastError.isNotEmpty)
              _infoCard(
                icon: Icons.error_outline,
                text: 'آخر خطأ: $lastError',
                color: Colors.red,
              ),

            // ── Local backups folder ─────────────────────────────────────────
            if (_localBackupsPath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.folder_open,
                        size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'مجلد النسخ المحلية: $_localBackupsPath',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.blueGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 24),
            const Text(
              'إنشاء نسخة احتياطية',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 12),

            // ── Backup with picker ───────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('نسخ احتياطي — اختر المجلد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isWorking
                  ? null
                  : () =>
                      context.read<BackupCubit>().createBackupWithPicker(),
            ),
            const SizedBox(height: 10),

            // ── Backup to default folder ─────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('نسخ احتياطي — المجلد الافتراضي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed:
                  isWorking ? null : () => context.read<BackupCubit>().createLocalBackup(),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // ── Restore ──────────────────────────────────────────────────────
            const Text(
              'استعادة البيانات',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'تحذير: الاستعادة ستُحل محل قاعدة البيانات الحالية بالكامل. '
                'سيتم التحقق من سلامة الملف قبل الاستبدال، '
                'وسيُحفظ تلقائياً نسخة احتياطية من الوضع الحالي.',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontFamily: 'Cairo', fontSize: 12, color: Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings_backup_restore),
              label: const Text('استعادة من ملف .db'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isWorking ? null : () => _confirmRestore(context),
            ),
            const SizedBox(height: 32),

            // ── Audit log ────────────────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.assignment),
              label: const Text('عرض سجل تدقيق العمليات (Audit Logs)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AuditLogScreen()),
                );
              },
            ),

            if (isWorking)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الاستعادة',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo')),
        content: const Text(
          'سيتم فتح نافذة لاختيار ملف .db.\n'
          'سيتحقق التطبيق من سلامة الملف قبل الاستبدال.\n'
          'تأكيد؟',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<BackupCubit>().restoreWithPicker();
            },
            child: const Text('اختر الملف واستعد',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tab: Google Drive  (Item 3 / 3b — settings only; upload is a stub)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDriveTab(Map<String, String> settings) {
    final driveEnabled =
        (settings[SettingsKeys.driveEnabled] ?? 'false') == 'true';
    final frequency =
        settings[SettingsKeys.driveBackupFrequency] ?? 'daily';
    final wifiOnly =
        (settings[SettingsKeys.driveWifiOnly] ?? 'false') == 'true';
    final lastDriveBackup = settings[SettingsKeys.lastDriveBackupAt];
    String lastDriveLabel = 'لم يتم رفع على Drive بعد';
    if (lastDriveBackup != null && lastDriveBackup.isNotEmpty) {
      try {
        lastDriveLabel = 'آخر رفع: ${_formatDt(DateTime.parse(lastDriveBackup))}';
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Notice ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text('Google Drive — قيد الإعداد',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700)),
              ]),
              const SizedBox(height: 6),
              const Text(
                'لتفعيل رفع النسخ على Google Drive يجب إعداد مشروع Google Cloud '
                'مع OAuth 2.0 وإضافة الحزمتين google_sign_in و googleapis. '
                'راجع تقرير CHANGES_REPORT_PHASE2.md للتعليمات التفصيلية.',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Connection status (stub) ────────────────────────────────────────
        _sectionTitle('حالة الاتصال بـ Google'),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              driveEnabled ? Icons.cloud_done : Icons.cloud_off,
              color: driveEnabled ? Colors.green : Colors.grey,
            ),
            title: Text(
              driveEnabled ? 'متصل' : 'غير متصل',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            subtitle: Text(
              driveEnabled
                  ? 'الحساب: (يظهر بعد الاتصال)'
                  : 'لم يتم ربط حساب Google بعد',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'تكامل Google Drive يحتاج إعداد OAuth — راجع التقرير'),
                ));
              },
              child: Text(driveEnabled ? 'قطع الاتصال' : 'ربط حساب Google',
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Drive folder name ───────────────────────────────────────────────
        _sectionTitle('اسم مجلد النسخ على Drive'),
        TextField(
          controller: _driveFolderController,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Gomaa Backups',
            hintStyle: const TextStyle(fontFamily: 'Cairo'),
          ),
          onChanged: (v) {
            if (v.trim().isNotEmpty) {
              context
                  .read<SettingsCubit>()
                  .updateSetting(SettingsKeys.driveFolderName, v.trim());
            }
          },
        ),
        const SizedBox(height: 16),

        // ── Auto-backup frequency ───────────────────────────────────────────
        _sectionTitle('تردد النسخ التلقائي على Drive'),
        DropdownButtonFormField<String>(
          initialValue: frequency,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: const [
            DropdownMenuItem(
                value: 'off',
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('معطّل', style: TextStyle(fontFamily: 'Cairo')))),
            DropdownMenuItem(
                value: 'on_close',
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('عند إغلاق التطبيق',
                        style: TextStyle(fontFamily: 'Cairo')))),
            DropdownMenuItem(
                value: 'daily',
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('يومياً',
                        style: TextStyle(fontFamily: 'Cairo')))),
            DropdownMenuItem(
                value: 'every_3_days',
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('كل 3 أيام',
                        style: TextStyle(fontFamily: 'Cairo')))),
            DropdownMenuItem(
                value: 'weekly',
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('أسبوعياً',
                        style: TextStyle(fontFamily: 'Cairo')))),
            DropdownMenuItem(
                value: 'biweekly',
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('كل أسبوعين',
                        style: TextStyle(fontFamily: 'Cairo')))),
          ],
          onChanged: (val) {
            if (val != null) {
              context
                  .read<SettingsCubit>()
                  .updateSetting(SettingsKeys.driveBackupFrequency, val);
            }
          },
        ),
        const SizedBox(height: 16),

        // ── Number of backups to keep on Drive ─────────────────────────────
        _sectionTitle('عدد النسخ المحفوظة على Drive (3–60)'),
        TextField(
          controller: _driveKeepCountController,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: '10',
            hintStyle: const TextStyle(fontFamily: 'Cairo'),
          ),
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 3 && n <= 60) {
              context
                  .read<SettingsCubit>()
                  .updateSetting(SettingsKeys.driveKeepCount, v);
            }
          },
        ),
        const SizedBox(height: 16),

        // ── Wi-Fi only ──────────────────────────────────────────────────────
        if (Platform.isAndroid || Platform.isIOS)
          SwitchListTile(
            value: wifiOnly,
            title: const Text('رفع على Wi-Fi فقط',
                style: TextStyle(fontFamily: 'Cairo')),
            onChanged: (v) {
              context
                  .read<SettingsCubit>()
                  .updateSetting(SettingsKeys.driveWifiOnly, v.toString());
            },
          ),

        // ── Last Drive backup ───────────────────────────────────────────────
        _infoCard(
          icon: Icons.cloud_upload_outlined,
          text: lastDriveLabel,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),

        // ── Backup now (stub) ───────────────────────────────────────────────
        ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: const Text('رفع نسخة احتياطية على Drive الآن'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'تكامل Google Drive يحتاج إعداد OAuth — راجع التقرير'),
            ));
          },
        ),
        const SizedBox(height: 10),

        // ── Local + Drive in one tap (stub) ────────────────────────────────
        ElevatedButton.icon(
          icon: const Icon(Icons.backup),
          label: const Text('نسخ محلي + رفع على Drive'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            // First create local backup (fully functional)
            context.read<BackupCubit>().createLocalBackup();
            // Then show Drive notice
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'النسخة المحلية جاري إنشاؤها. Drive يحتاج إعداد OAuth — راجع التقرير.'),
            ));
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13),
      ),
    );
  }

  Widget _infoCard(
      {required IconData icon,
      required String text,
      required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontFamily: 'Cairo', fontSize: 12, color: color))),
        ],
      ),
    );
  }

  String _formatDt(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
