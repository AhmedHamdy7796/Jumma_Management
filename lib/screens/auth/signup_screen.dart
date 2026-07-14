import 'package:flutter/material.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/routes/routes.dart';

import 'package:gomaa_management/repositories/auth_repository.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Use the email field as the unique username
      final success = await _authRepository.signup(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم إنشاء الحساب بنجاح!',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.mainNavigation,
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'اسم المستخدم (البريد) مسجل بالفعل مسبقاً!',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.signup),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.name,
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppStrings.enterName;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.email,
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppStrings.enterEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.password,
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppStrings.enterPassword;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        labelText: AppStrings.confirmPassword,
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.enterConfirmPassword;
                        }
                        if (value != _passwordController.text) {
                          return AppStrings.passwordsNoMatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.white)
                          : const Text(
                              AppStrings.signup,
                              style: TextStyle(fontSize: 18, fontFamily: 'Cairo'),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, Routes.login);
                      },
                      child: const Text(
                        AppStrings.haveAccount,
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
