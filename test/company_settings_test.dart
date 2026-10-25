import 'package:flutter_test/flutter_test.dart';
import 'package:gomaa_management/core/utils/company_pdf_data.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/services/validation_service.dart';

void main() {
  group('Company Settings Validation Tests', () {
    test('validateCompanyName requires non-empty trimmed value', () {
      expect(ValidationService.validateCompanyName(null), 'اسم الشركة مطلوب');
      expect(ValidationService.validateCompanyName(''), 'اسم الشركة مطلوب');
      expect(ValidationService.validateCompanyName('   '), 'اسم الشركة مطلوب');
      expect(ValidationService.validateCompanyName('مؤسسة جمعة'), isNull);
    });

    test('validateCompanyPhone allows empty or valid phone characters', () {
      expect(ValidationService.validateCompanyPhone(null), isNull);
      expect(ValidationService.validateCompanyPhone(''), isNull);
      expect(ValidationService.validateCompanyPhone('   '), isNull);
      expect(ValidationService.validateCompanyPhone('01012345678'), isNull);
      expect(ValidationService.validateCompanyPhone('+20 10 1234 5678'), isNull);
      expect(ValidationService.validateCompanyPhone('+20-10-1234-5678'), isNull);

      // Invalid characters
      expect(
        ValidationService.validateCompanyPhone('0101234abc'),
        'رقم الهاتف يجب أن يحتوي على أرقام وعلامات + و - ومسافات فقط',
      );
      expect(
        ValidationService.validateCompanyPhone('010@123#456'),
        'رقم الهاتف يجب أن يحتوي على أرقام وعلامات + و - ومسافات فقط',
      );
    });

    test('validateCurrencySymbol requires non-empty value with max 6 chars', () {
      expect(ValidationService.validateCurrencySymbol(null), 'رمز العملة مطلوب');
      expect(ValidationService.validateCurrencySymbol(''), 'رمز العملة مطلوب');
      expect(ValidationService.validateCurrencySymbol('   '), 'رمز العملة مطلوب');
      expect(ValidationService.validateCurrencySymbol('ج.م'), isNull);
      expect(ValidationService.validateCurrencySymbol('\$'), isNull);
      expect(ValidationService.validateCurrencySymbol('USD'), isNull);
      expect(ValidationService.validateCurrencySymbol('123456'), isNull);

      // Exceeds 6 chars
      expect(
        ValidationService.validateCurrencySymbol('1234567'),
        'رمز العملة يجب ألا يتجاوز 6 أحرف',
      );
      expect(
        ValidationService.validateCurrencySymbol('جنيه مصري'),
        'رمز العملة يجب ألا يتجاوز 6 أحرف',
      );
    });

    test('validateLogoFile checks extension and size threshold', () {
      // Valid cases
      expect(
        ValidationService.validateLogoFile(
          fileName: 'logo.png',
          byteLength: 500 * 1024,
        ),
        isNull,
      );
      expect(
        ValidationService.validateLogoFile(
          fileName: 'COMPANY_LOGO.JPG',
          byteLength: 1024 * 1024, // exactly 1MB
        ),
        isNull,
      );
      expect(
        ValidationService.validateLogoFile(
          fileName: 'photo.jpeg',
          byteLength: 200 * 1024,
        ),
        isNull,
      );

      // Invalid extension
      expect(
        ValidationService.validateLogoFile(
          fileName: 'invoice.pdf',
          byteLength: 100 * 1024,
        ),
        'يجب اختيار صورة بصيغة PNG أو JPG',
      );
      expect(
        ValidationService.validateLogoFile(
          fileName: 'vector.svg',
          byteLength: 100 * 1024,
        ),
        'يجب اختيار صورة بصيغة PNG أو JPG',
      );

      // Oversized (> 1MB)
      expect(
        ValidationService.validateLogoFile(
          fileName: 'big_logo.png',
          byteLength: (1024 * 1024) + 1,
        ),
        'حجم الصورة يجب ألا يتجاوز 1 ميجابايت',
      );
    });
  });

  group('Settings to PDF Header/Footer Mapping Tests', () {
    test('all settings fields provided and correctly mapped', () {
      final settings = {
        SettingsKeys.companyName: '  شركة جمعة للمعدات  ',
        SettingsKeys.companyPhone: '  +201012345678  ',
        SettingsKeys.companyAddress: '  القاهرة، مصر  ',
        SettingsKeys.companyTaxNumber: '  123-456-789  ',
        SettingsKeys.invoiceFooterNote: '  شكراً لتعاملكم الكريم معنا  ',
        SettingsKeys.companyLogoPath: '  logos/company_logo.png  ',
        SettingsKeys.currencySymbol: '  ج.م  ',
      };

      final data = CompanyPdfData.fromSettings(settings);

      expect(data.companyName, 'شركة جمعة للمعدات');
      expect(data.companyPhone, '+201012345678');
      expect(data.companyAddress, 'القاهرة، مصر');
      expect(data.taxNumber, '123-456-789');
      expect(data.footerNote, 'شكراً لتعاملكم الكريم معنا');
      expect(data.logoPath, 'logos/company_logo.png');
      expect(data.currencySymbol, 'ج.م');
    });

    test('empty or whitespace-only optional fields are gracefully omitted (null)', () {
      final settings = {
        SettingsKeys.companyName: 'مؤسسة التجارة',
        SettingsKeys.companyPhone: '   ',
        SettingsKeys.companyAddress: '',
        SettingsKeys.companyTaxNumber: '   ',
        SettingsKeys.invoiceFooterNote: '',
        SettingsKeys.companyLogoPath: '   ',
        SettingsKeys.currencySymbol: '',
      };

      final data = CompanyPdfData.fromSettings(settings);

      expect(data.companyName, 'مؤسسة التجارة');
      expect(data.companyPhone, isNull);
      expect(data.companyAddress, isNull);
      expect(data.taxNumber, isNull);
      expect(data.footerNote, isNull);
      expect(data.logoPath, isNull);
      expect(data.currencySymbol, 'ج.م'); // Default fallback
    });

    test('empty company name defaults to مؤسسة جمعة', () {
      final settings = <String, String>{};
      final data = CompanyPdfData.fromSettings(settings);

      expect(data.companyName, 'مؤسسة جمعة');
      expect(data.companyPhone, isNull);
      expect(data.companyAddress, isNull);
      expect(data.taxNumber, isNull);
      expect(data.footerNote, isNull);
      expect(data.logoPath, isNull);
      expect(data.currencySymbol, 'ج.م');
    });
  });
}
