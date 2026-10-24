import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gomaa_management/core/utils/invoice_calculator.dart';
import 'package:gomaa_management/database/database_constants.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';
import 'package:gomaa_management/repositories/settings_repository.dart';

/// Generates and prints a professional Arabic invoice PDF
/// using company settings, dynamic totals, and Arabic font caching.
class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  // Brand colours matching company aesthetic
  static const _headerBg = PdfColor.fromInt(0xFF1A2B4A); // dark navy
  static const _gold = PdfColor.fromInt(0xFFB8972E);
  static const _lightBg = PdfColor.fromInt(0xFFF9F7F4); // warm cream
  static const _tableLine = PdfColor.fromInt(0xFFE2DDD5);
  static const _bodyText = PdfColor.fromInt(0xFF2C2C2C);
  static const _grey = PdfColor.fromInt(0xFF777777);
  static const _alertRed = PdfColor.fromInt(0xFFD32F2F);
  static const _successGreen = PdfColor.fromInt(0xFF2E7D32);

  // Cached fonts for rapid rendering without re-fetching
  static pw.Font? _cachedRegular;
  static pw.Font? _cachedBold;

  /// Loads Arabic fonts once and keeps them cached in memory.
  static Future<void> preloadFonts() async {
    try {
      _cachedRegular ??= await PdfGoogleFonts.cairoRegular();
      _cachedBold ??= await PdfGoogleFonts.cairoBold();
    } catch (_) {
      // Cairo fallback handled during generation
    }
  }

  /// Prints or previews the invoice using the system print dialog.
  static Future<void> printInvoice({
    required SalesInvoiceModel invoice,
    Map<String, String>? settings,
  }) async {
    // 1. Fetch settings if not provided
    final resolvedSettings = settings ??
        await SettingsRepository().getAllSettings().catchError((_) => <String, String>{});

    // 2. Build the PDF document
    final doc = await _buildDocument(
      invoice: invoice,
      settings: resolvedSettings,
    );

    // 3. Hand off to system printing
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'فاتورة_${invoice.id ?? 0}_${invoice.customerName.replaceAll(' ', '_')}',
    );
  }

  static Future<pw.Document> _buildDocument({
    required SalesInvoiceModel invoice,
    required Map<String, String> settings,
  }) async {
    final doc = pw.Document();

    // Ensure fonts are loaded
    await preloadFonts();
    final arabicFont = _cachedRegular ?? pw.Font.helvetica();
    final arabicBold = _cachedBold ?? pw.Font.helveticaBold();

    // Company Settings from database
    final companyName = (settings[SettingsKeys.companyName]?.trim().isNotEmpty == true)
        ? settings[SettingsKeys.companyName]!.trim()
        : 'مؤسسة جمعة';
    final companyPhone = settings[SettingsKeys.companyPhone]?.trim() ?? '';
    final companyAddress = settings[SettingsKeys.companyAddress]?.trim() ?? '';
    final customLogoPath = settings[SettingsKeys.companyLogoPath]?.trim();

    // Try loading logo: custom file first, then asset fallback
    pw.ImageProvider? logoImage;
    if (customLogoPath != null && customLogoPath.isNotEmpty) {
      try {
        final file = File(customLogoPath);
        if (file.existsSync()) {
          logoImage = pw.MemoryImage(await file.readAsBytes());
        }
      } catch (_) {
        logoImage = null;
      }
    }
    if (logoImage == null) {
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }
    }

    final invoiceNumber = (invoice.id ?? 0).toString().padLeft(4, '0');
    final dateStr = _formatDate(invoice.date);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────────
            _buildHeader(companyName, companyPhone, companyAddress, logoImage, arabicFont, arabicBold),

            // ── Gold separator ──────────────────────────────────────────
            pw.Container(height: 4, color: _gold),

            // ── Body ────────────────────────────────────────────────────
            pw.Expanded(
              child: pw.Container(
                color: _lightBg,
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Invoice metadata & customer metadata
                    _buildInfoSection(
                      invoice,
                      invoiceNumber,
                      dateStr,
                      arabicFont,
                      arabicBold,
                    ),

                    pw.SizedBox(height: 18),

                    // Items table
                    _buildItemsTable(invoice, arabicFont, arabicBold),

                    pw.SizedBox(height: 16),

                    // Financial summary block: Total, Paid, Remaining
                    _buildFinancialSummaryBlock(invoice, arabicFont, arabicBold),

                    // Notes (if present)
                    if (invoice.notes.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      _buildNotesSection(invoice, arabicFont, arabicBold),
                    ],

                    pw.Spacer(),

                    // Signatures
                    _buildSignatureRow(arabicFont),

                    pw.SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            _buildFooter(companyAddress, companyPhone, arabicFont, arabicBold),
          ],
        ),
      ),
    );

    return doc;
  }

  // ─────────────────────────────────────────── Header ──
  static pw.Widget _buildHeader(
    String companyName,
    String companyPhone,
    String companyAddress,
    pw.ImageProvider? logoImage,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    return pw.Container(
      color: _headerBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // "فاتورة مبيعات" label
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'فاتورة مبيعات',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: arabicBold,
                  fontSize: 26,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'SALES INVOICE',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 10,
                  color: _gold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          // Company info + Logo
          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    companyName,
                    textDirection: pw.TextDirection.rtl,
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 17,
                      color: PdfColors.white,
                    ),
                  ),
                  if (companyPhone.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'هاتف: $companyPhone',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(width: 12),
              if (logoImage != null)
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 2),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.ClipOval(child: pw.Image(logoImage)),
                )
              else
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 2),
                    shape: pw.BoxShape.circle,
                    color: _gold,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'ج',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 24,
                        color: _headerBg,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────── Info section ──
  static pw.Widget _buildInfoSection(
    SalesInvoiceModel invoice,
    String invoiceNumber,
    String dateStr,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Customer info
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('بيانات العميل',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: arabicBold, fontSize: 11, color: _gold)),
              pw.Divider(color: _gold, thickness: 0.8),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.customerName.isNotEmpty ? invoice.customerName : 'عميل نقدي',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: arabicBold, fontSize: 13, color: _bodyText),
              ),
              if (invoice.customerAddress.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                _infoLabelRow('العنوان', invoice.customerAddress, arabicFont),
              ],
            ],
          ),
        ),

        pw.SizedBox(width: 32),

        // Invoice metadata
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('بيانات الفاتورة',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(font: arabicBold, fontSize: 11, color: _gold)),
              pw.Divider(color: _gold, thickness: 0.8),
              pw.SizedBox(height: 4),
              _infoLabelRow('رقم الفاتورة', '#$invoiceNumber', arabicBold),
              pw.SizedBox(height: 3),
              _infoLabelRow('تاريخ الفاتورة', dateStr, arabicFont),
              if (invoice.model.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                _infoLabelRow('الموديل', invoice.model, arabicFont),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoLabelRow(
    String label,
    String value,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(value,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: font, fontSize: 11, color: _bodyText)),
        pw.SizedBox(width: 6),
        pw.Text('$label :',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: font, fontSize: 11, color: _grey)),
      ],
    );
  }

  // ─────────────────────────────────────────── Table ──
  static pw.Widget _buildItemsTable(
    SalesInvoiceModel invoice,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    const headers = ['الإجمالي', 'الكمية', 'سعر الوحدة', 'اسم الصنف والموديل', 'م'];
    final colWidths = [
      const pw.FlexColumnWidth(1.5),
      const pw.FlexColumnWidth(0.9),
      const pw.FlexColumnWidth(1.4),
      const pw.FlexColumnWidth(3.2),
      const pw.FlexColumnWidth(0.6),
    ];

    final rows = <pw.TableRow>[];

    // Data row
    final lineTotal = InvoiceCalculator.roundMoney(invoice.price * invoice.quantity);
    final itemDisplayName = invoice.itemName +
        (invoice.model.isNotEmpty ? ' (${invoice.model})' : '');

    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.white),
      children: [
        _tableCell(InvoiceCalculator.formatMoney(lineTotal), arabicBold),
        _tableCell(invoice.quantity.toString(), arabicFont),
        _tableCell(InvoiceCalculator.formatMoney(invoice.price), arabicFont),
        _tableCell(itemDisplayName, arabicBold),
        _tableCell('1', arabicFont),
      ],
    ));

    // Pad with empty rows to keep the aesthetic clean like formal printed vouchers
    for (int i = 2; i <= 5; i++) {
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color: i.isEven ? const PdfColor.fromInt(0xFFFAF7F2) : PdfColors.white,
        ),
        children: [
          _tableCell('', arabicFont),
          _tableCell('', arabicFont),
          _tableCell('', arabicFont),
          _tableCell('', arabicFont),
          _tableCell(i.toString(), arabicFont),
        ],
      ));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _tableLine, width: 0.6),
      columnWidths: {
        0: colWidths[0],
        1: colWidths[1],
        2: colWidths[2],
        3: colWidths[3],
        4: colWidths[4],
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: headers.map((h) => _tableHeader(h, arabicBold)).toList(),
        ),
        ...rows,
      ],
    );
  }

  static pw.Widget _tableHeader(String text, pw.Font arabicBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 10, color: _bodyText),
      ),
    );
  }

  // ──────────────────────────── Financial Summary Block ──
  static pw.Widget _buildFinancialSummaryBlock(
    SalesInvoiceModel invoice,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    final hasRemaining = invoice.remainingBalance > 0;
    final isOverpaid = InvoiceCalculator.isOverpaid(
      totalAmount: invoice.totalAmount,
      paid: invoice.paidAmount,
    );
    final overpaidAmount = InvoiceCalculator.overpaidAmount(
      totalAmount: invoice.totalAmount,
      paid: invoice.paidAmount,
    );

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 260,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _tableLine, width: 0.8),
        ),
        child: pw.Column(
          children: [
            _financialSummaryRow('الإجمالي', InvoiceCalculator.formatMoney(invoice.totalAmount), arabicBold, _headerBg),
            pw.SizedBox(height: 6),
            _financialSummaryRow('المدفوع', InvoiceCalculator.formatMoney(invoice.paidAmount), arabicFont, _successGreen),
            pw.Divider(color: _tableLine, thickness: 0.6),
            _financialSummaryRow(
              'المتبقي',
              InvoiceCalculator.formatMoney(invoice.remainingBalance),
              arabicBold,
              hasRemaining ? _alertRed : _successGreen,
              isHighlighted: hasRemaining,
            ),
            if (isOverpaid) ...[
              pw.SizedBox(height: 4),
              _financialSummaryRow(
                'رصيد دائن (overpayment)',
                InvoiceCalculator.formatMoney(overpaidAmount),
                arabicBold,
                PdfColors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _financialSummaryRow(
    String label,
    String value,
    pw.Font font,
    PdfColor color, {
    bool isHighlighted = false,
  }) {
    final content = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: font, fontSize: isHighlighted ? 12 : 11, color: color),
        ),
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: font, fontSize: 11, color: _bodyText),
        ),
      ],
    );

    if (isHighlighted) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFDE8E8),
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: _alertRed, width: 0.8),
        ),
        child: content,
      );
    }
    return content;
  }

  // ─────────────────────────────────────────── Notes ──
  static pw.Widget _buildNotesSection(
    SalesInvoiceModel invoice,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('ملاحظات الفاتورة',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicBold, fontSize: 10, color: _gold)),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: _tableLine, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            invoice.notes,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicFont, fontSize: 10, color: _bodyText),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────── Signatures ──
  static pw.Widget _buildSignatureRow(pw.Font arabicFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBlock('توقيع المستلم', arabicFont),
        _signatureBlock('توقيع وختم الإدارة', arabicFont),
      ],
    );
  }

  static pw.Widget _signatureBlock(String label, pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 140, height: 0.8, color: _grey),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: arabicFont, fontSize: 9, color: _grey),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────── Footer ──
  static pw.Widget _buildFooter(
    String address,
    String phone,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    final details = <String>[];
    if (address.isNotEmpty) details.add(address);
    if (phone.isNotEmpty) details.add('هاتف: $phone');

    return pw.Container(
      color: _headerBg,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 32),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'شكراً لتعاملكم معنا',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.white),
          ),
          if (details.isNotEmpty)
            pw.Text(
              details.join('  •  '),
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.white),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
