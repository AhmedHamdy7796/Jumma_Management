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

  /// Validates manufacture year: optional, but if entered must be between 1950 and current year.
  static String? validateManufactureYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final year = int.tryParse(value.trim());
    final currentYear = DateTime.now().year;
    if (year == null || year < 1950 || year > currentYear) {
      return 'سنة الصنع يجب أن تكون بين 1950 و $currentYear';
    }
    return null;
  }

  /// Validates company name: required, non-empty after trim.
  static String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم الشركة مطلوب';
    }
    return null;
  }

  /// Validates company phone: optional, but if entered must contain only digits, +, -, or spaces.
  static String? validateCompanyPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    final phoneRegex = RegExp(r'^[0-9+\-\s]+$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام وعلامات + و - ومسافات فقط';
    }
    return null;
  }

  /// Validates currency symbol: required, non-empty, max 6 chars.
  static String? validateCurrencySymbol(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رمز العملة مطلوب';
    }
    if (value.trim().length > 6) {
      return 'رمز العملة يجب ألا يتجاوز 6 أحرف';
    }
    return null;
  }

  /// Validates logo image file format and file size (max ~1 MB).
  static String? validateLogoFile({required String fileName, required int byteLength}) {
    final lower = fileName.toLowerCase();
    final isValidExtension = lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');
    if (!isValidExtension) {
      return 'يجب اختيار صورة بصيغة PNG أو JPG';
    }
    const maxSizeBytes = 1024 * 1024; // 1 MB
    if (byteLength > maxSizeBytes) {
      return 'حجم الصورة يجب ألا يتجاوز 1 ميجابايت';
    }
    return null;
  }
}
