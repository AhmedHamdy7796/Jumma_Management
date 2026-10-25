import 'package:gomaa_management/database/database_constants.dart';

/// Pure data model representing company details mapped for PDF generation.
///
/// Empty or whitespace-only optional fields are normalized to `null` so
/// that the PDF generator can omit them cleanly.
class CompanyPdfData {
  final String companyName;
  final String? companyPhone;
  final String? companyAddress;
  final String? taxNumber;
  final String? footerNote;
  final String? logoPath;
  final String currencySymbol;

  const CompanyPdfData({
    required this.companyName,
    this.companyPhone,
    this.companyAddress,
    this.taxNumber,
    this.footerNote,
    this.logoPath,
    this.currencySymbol = 'ج.م',
  });

  /// Factory that extracts and normalizes company settings from key-value map.
  factory CompanyPdfData.fromSettings(Map<String, String> settings) {
    final name = settings[SettingsKeys.companyName]?.trim();
    final phone = settings[SettingsKeys.companyPhone]?.trim();
    final address = settings[SettingsKeys.companyAddress]?.trim();
    final tax = settings[SettingsKeys.companyTaxNumber]?.trim();
    final footer = settings[SettingsKeys.invoiceFooterNote]?.trim();
    final logo = settings[SettingsKeys.companyLogoPath]?.trim();
    final currency = settings[SettingsKeys.currencySymbol]?.trim();

    return CompanyPdfData(
      companyName: (name != null && name.isNotEmpty) ? name : 'مؤسسة جمعة',
      companyPhone: (phone != null && phone.isNotEmpty) ? phone : null,
      companyAddress: (address != null && address.isNotEmpty) ? address : null,
      taxNumber: (tax != null && tax.isNotEmpty) ? tax : null,
      footerNote: (footer != null && footer.isNotEmpty) ? footer : null,
      logoPath: (logo != null && logo.isNotEmpty) ? logo : null,
      currencySymbol: (currency != null && currency.isNotEmpty) ? currency : 'ج.م',
    );
  }
}
