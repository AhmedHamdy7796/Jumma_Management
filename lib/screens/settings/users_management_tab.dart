import 'package:flutter/material.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/repositories/auth_repository.dart';

class UsersManagementTab extends StatefulWidget {
  const UsersManagementTab({super.key});

  @override
  State<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<UsersManagementTab> {
  final AuthRepository _authRepository = AuthRepository();
  List<String> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await _authRepository.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المستخدمين: $e', textAlign: TextAlign.right),
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

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'إضافة مستخدم جديد',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: usernameController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            labelText: 'اسم المستخدم',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'الرجاء إدخال اسم المستخدم';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال كلمة المرور';
                            }
                            if (value.length < 4) {
                              return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء تأكيد كلمة المرور';
                            }
                            if (value != passwordController.text) {
                              return 'كلمتا المرور غير متطابقتين';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() {
                              isSaving = true;
                            });
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            try {
                              final username = usernameController.text.trim();
                              final success = await _authRepository.signup(
                                username,
                                passwordController.text,
                              );
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إضافة المستخدم بنجاح', textAlign: TextAlign.right),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                navigator.pop();
                                _loadUsers();
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('اسم المستخدم مسجل بالفعل مسبقاً!', textAlign: TextAlign.right),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('خطأ أثناء إضافة المستخدم: $e', textAlign: TextAlign.right),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            } finally {
                              setDialogState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(String username) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Cairo')),
          content: Text(
            'هل أنت متأكد من حذف المستخدم "$username"؟',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                try {
                  final success = await _authRepository.deleteUser(username);
                  if (success) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف المستخدم بنجاح', textAlign: TextAlign.right),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadUsers();
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('فشل حذف المستخدم!', textAlign: TextAlign.right),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('خطأ أثناء حذف المستخدم: $e', textAlign: TextAlign.right),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _users.isEmpty
            ? const Center(
                child: Text(
                  'لا يوجد مستخدمون حالياً',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final username = _users[index];
                  final isAdmin = username.toLowerCase() == 'admin';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        username,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      leading: isAdmin
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(username),
                            ),
                      trailing: isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'مدير النظام',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.grey),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مستخدم', style: TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }
}
