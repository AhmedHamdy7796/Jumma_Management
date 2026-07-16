import 'package:gomaa_management/core/resources/app_strings.dart';

/// Centralized validation rules for user input forms.
class ValidationService {
  /// Validates full name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterName;
    }
    return null;
  }

  /// Validates standard phone.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.phoneRequired;
    }
    final phone = value.trim();
    if (phone.length != 11) {
      return AppStrings.phoneInvalidLength;
    }
    if (!RegExp(r'^(010|011|012|015)').hasMatch(phone)) {
      return AppStrings.phoneInvalidStart;
    }
    return null;
  }

  /// Validates amount or cost.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterAmount;
    }
    final amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) {
      return AppStrings.enterValidNumber;
    }
    return null;
  }

  /// Generic required validation.
  static String? validateRequired(String? value, String errorMsg) {
    if (value == null || value.trim().isEmpty) {
      return errorMsg;
    }
    return null;
  }

  /// Generic required validation with default message.
  static String? validateRequiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// Validates generic numeric fields.
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.enterQuantity;
    }
    final qty = int.tryParse(value.trim());
    if (qty == null || qty <= 0) {
      return AppStrings.enterValidNumber;
    }
    return null;
  }
}
