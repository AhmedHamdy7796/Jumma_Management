import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gomaa_management/cubits/backup/backup_cubit.dart';
import 'package:gomaa_management/cubits/settings/settings_cubit.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/widgets/custom_text_field.dart';
import 'package:gomaa_management/core/widgets/custom_button.dart';
import 'package:gomaa_management/screens/audit_log/audit_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _companyNameController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _currencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _pickBackupDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (mounted) {
        context.read<SettingsCubit>().updateSetting(SettingsKeys.backupFolderPath, selectedDirectory);
      }
    }
  }

  Future<void> _pickRestoreFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      if (mounted) {
        _showRestoreConfirmation(selectedDirectory);
      }
    }
  }

  void _showRestoreConfirmation(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد استعادة النسخة الاحتياطية', textAlign: TextAlign.right),
        content: const Text(
          'تحذير: سيتم استبدال قاعدة البيانات الحالية والصور بالكامل ببيانات النسخة الاحتياطية المحددة. لا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BackupCubit>().restoreBackup(path);
            },
            child: const Text('تأكيد الاستعادة', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BackupCubit, BackupState>(
      listener: (context, state) {
        if (state is BackupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إنشاء النسخة الاحتياطية بنجاح في: ${state.path}')),
          );
        } else if (state is RestoreSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت استعادة البيانات بنجاح!')),
          );
          // Reload app configs
          context.read<SettingsCubit>().loadSettings();
        } else if (state is BackupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${state.message}'), backgroundColor: AppColors.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'الإعدادات والنسخ الاحتياطي',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Arial'),
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
            tabs: const [
              Tab(text: 'إعدادات الشركة'),
              Tab(text: 'النسخ الاحتياطي والأمان'),
            ],
          ),
        ),
        body: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, String> settings = {};
            if (state is SettingsLoaded) {
              settings = state.settings;
              _companyNameController.text = settings[SettingsKeys.companyName] ?? '';
              _companyPhoneController.text = settings[SettingsKeys.companyPhone] ?? '';
              _companyAddressController.text = settings[SettingsKeys.companyAddress] ?? '';
              _currencyController.text = settings[SettingsKeys.currencySymbol] ?? 'ج.م';
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildCompanyTab(settings),
                _buildBackupTab(settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanyTab(Map<String, String> settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CustomTextField(label: 'اسم الشركة', controller: _companyNameController),
        CustomTextField(label: 'رقم هاتف الشركة', controller: _companyPhoneController),
        CustomTextField(label: 'عنوان الشركة', controller: _companyAddressController),
        CustomTextField(label: 'رمز العملة المستخدمة في التطبيق', controller: _currencyController),
        const SizedBox(height: 24),
        CustomButton(
          text: 'حفظ الإعدادات',
          onPressed: () {
            context.read<SettingsCubit>().updateAllSettings({
              SettingsKeys.companyName: _companyNameController.text,
              SettingsKeys.companyPhone: _companyPhoneController.text,
              SettingsKeys.companyAddress: _companyAddressController.text,
              SettingsKeys.currencySymbol: _currencyController.text,
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupTab(Map<String, String> settings) {
    final folderPath = settings[SettingsKeys.backupFolderPath] ?? 'لم يتم التحديد بعد';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('مجلد حفظ النسخ الاحتياطية', textAlign: TextAlign.right),
          subtitle: Text(folderPath, textAlign: TextAlign.right),
          trailing: const Icon(Icons.folder_open),
          onTap: _pickBackupDirectory,
        ),
        const Divider(),
        const SizedBox(height: 16),
        BlocBuilder<BackupCubit, BackupState>(
          builder: (context, state) {
            final isWorking = state is BackupLoading;
            return Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.backup),
                  label: const Text('إنشاء نسخة احتياطية الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isWorking
                      ? null
                      : () {
                          if (folderPath == 'لم يتم التحديد بعد') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('الرجاء اختيار مجلد النسخ الاحتياطي أولاً')),
                            );
                            return;
                          }
                          context.read<BackupCubit>().createBackup(folderPath);
                        },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('استعادة البيانات من مجلد نسخة احتياطية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isWorking ? null : _pickRestoreFolder,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.assignment),
          label: const Text('عرض سجل تدقيق العمليات (Audit Logs)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AuditLogScreen()),
            );
          },
        ),
      ],
    );
  }
}
