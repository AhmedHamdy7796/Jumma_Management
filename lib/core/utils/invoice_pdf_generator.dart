import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gomaa_management/models/sales_invoice_model.dart';

/// Generates and prints a professional Arabic invoice PDF
/// matching the company template design.
class InvoicePdfGenerator {
  // Brand colours matching the design template
  static const _headerBg = PdfColor.fromInt(0xFF1A2B4A); // dark navy
  static const _gold = PdfColor.fromInt(0xFFB8972E);
  static const _lightBg = PdfColor.fromInt(0xFFF5F0E8); // warm cream
  static const _tableLine = PdfColor.fromInt(0xFFE0D8C8);
  static const _bodyText = PdfColor.fromInt(0xFF2C2C2C);
  static const _grey = PdfColor.fromInt(0xFF888888);

  /// Prints the invoice using the system print dialog.
  static Future<void> printInvoice({
    required SalesInvoiceModel invoice,
    String companyName = 'مؤسسة جمعة للاستيراد والتصدير',
    String companyLogoAsset = 'assets/images/logo.png',
  }) async {
    final doc = await _buildDocument(
      invoice: invoice,
      companyName: companyName,
      companyLogoAsset: companyLogoAsset,
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'فاتورة_${invoice.id ?? 0}_${invoice.customerName}',
    );
  }

  static Future<pw.Document> _buildDocument({
    required SalesInvoiceModel invoice,
    required String companyName,
    required String companyLogoAsset,
  }) async {
    final doc = pw.Document();

    // Load Arabic font (Amiri supports full Arabic text in PDF)
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    // Try loading logo — silently fall back to icon if asset missing
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load(companyLogoAsset);
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final invoiceNumber =
        (invoice.id ?? 0).toString().padLeft(4, '0');
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
            _buildHeader(companyName, logoImage, arabicFont, arabicBold),

            // ── Gold separator ──────────────────────────────────────────
            pw.Container(height: 4, color: _gold),

            // ── Body ────────────────────────────────────────────────────
            pw.Expanded(
              child: pw.Container(
                color: _lightBg,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 32, vertical: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Invoice info + customer info side by side
                    _buildInfoSection(
                      invoice,
                      invoiceNumber,
                      dateStr,
                      arabicFont,
                      arabicBold,
                    ),

                    pw.SizedBox(height: 20),

                    // Items table
                    _buildItemsTable(invoice, arabicFont, arabicBold),

                    pw.SizedBox(height: 16),

                    // Total row
                    _buildTotalRow(invoice, arabicFont, arabicBold),

                    pw.SizedBox(height: 20),

                    // Notes
                    if (invoice.notes.isNotEmpty) ...[
                      _buildNotesSection(invoice, arabicFont, arabicBold),
                      pw.SizedBox(height: 20),
                    ],

                    // Signatures
                    _buildSignatureRow(arabicFont),

                    pw.Spacer(),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            _buildFooter(arabicBold),
          ],
        ),
      ),
    );

    return doc;
  }

  // ─────────────────────────────────────────── Header ──
  static pw.Widget _buildHeader(
    String companyName,
    pw.ImageProvider? logoImage,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    return pw.Container(
      color: _headerBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // "فاتورة" label on the left (RTL → displayed on right visually)
          pw.Text(
            'فاتورة',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicBold,
              fontSize: 28,
              color: PdfColors.white,
            ),
          ),
          // Company name + logo
          pw.Row(
            children: [
              pw.Text(
                companyName,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: arabicBold,
                  fontSize: 18,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(width: 12),
              if (logoImage != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 2),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.ClipOval(child: pw.Image(logoImage)),
                )
              else
                pw.Container(
                  width: 48,
                  height: 48,
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
                        fontSize: 22,
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
        // Customer info (right side in RTL)
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('فاتورة إلى',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: arabicBold, fontSize: 12, color: _gold)),
              pw.Divider(color: _gold, thickness: 0.8),
              pw.SizedBox(height: 6),
              pw.Text(
                invoice.customerName.isNotEmpty
                    ? invoice.customerName
                    : '─────────────────',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                    font: arabicBold, fontSize: 13, color: _bodyText),
              ),
              pw.SizedBox(height: 6),
              _infoLabelRow('العنوان',
                  invoice.customerAddress.isNotEmpty
                      ? invoice.customerAddress
                      : '──────────────────────',
                  arabicFont),
            ],
          ),
        ),

        pw.SizedBox(width: 40),

        // Invoice details (left side in RTL)
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('تفاصيل الفاتورة',
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(
                      font: arabicBold, fontSize: 12, color: _gold)),
              pw.Divider(color: _gold, thickness: 0.8),
              pw.SizedBox(height: 6),
              _infoLabelRow('رقم الفاتورة', invoiceNumber, arabicFont),
              pw.SizedBox(height: 4),
              _infoLabelRow('التاريخ', dateStr, arabicFont),
              if (invoice.model.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                _infoLabelRow('الموديل', invoice.model, arabicFont),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoLabelRow(
      String label, String value, pw.Font arabicFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(value,
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: arabicFont, fontSize: 11, color: _bodyText)),
        pw.SizedBox(width: 8),
        pw.Text('$label :',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: arabicFont, fontSize: 11, color: _grey)),
      ],
    );
  }

  // ─────────────────────────────────────────── Table ──
  static pw.Widget _buildItemsTable(
    SalesInvoiceModel invoice,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    const headers = ['المجموع', 'العدد', 'سعر القطعة', 'اسم الصنف', 'م'];
    final colWidths = [
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(1),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(3),
      pw.FlexColumnWidth(0.5),
    ];

    // Build 7 rows (first row has data, rest are empty like the template)
    final rows = <pw.TableRow>[];

    // Data row
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.white),
      children: [
        _tableCell(invoice.totalAmount.toStringAsFixed(2), arabicFont,
            italic: true),
        _tableCell(invoice.quantity.toString(), arabicFont, italic: true),
        _tableCell(invoice.price.toStringAsFixed(2), arabicFont, italic: true),
        _tableCell(
            invoice.itemName +
                (invoice.model.isNotEmpty ? ' - موديل ${invoice.model}' : ''),
            arabicFont,
            italic: true),
        _tableCell('1', arabicFont),
      ],
    ));

    // Empty rows (2..7)
    for (int i = 2; i <= 7; i++) {
      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(
          color:
              i.isEven ? const PdfColor.fromInt(0xFFF9F5EE) : PdfColors.white,
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
      border: pw.TableBorder.all(color: _tableLine, width: 0.5),
      columnWidths: {
        0: colWidths[0],
        1: colWidths[1],
        2: colWidths[2],
        3: colWidths[3],
        4: colWidths[4],
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: headers
              .map((h) => _tableHeader(h, arabicBold))
              .toList(),
        ),
        ...rows,
      ],
    );
  }

  static pw.Widget _tableHeader(String text, pw.Font arabicBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
            font: arabicBold, fontSize: 11, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font arabicFont,
      {bool italic = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: arabicFont,
          fontSize: 11,
          color: italic ? _grey : _bodyText,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        ),
      ),
    );
  }

  // ──────────────────────────────────────── Total row ──
  static pw.Widget _buildTotalRow(
    SalesInvoiceModel invoice,
    pw.Font arabicFont,
    pw.Font arabicBold,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _headerBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            invoice.totalAmount.toStringAsFixed(2),
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
                font: arabicBold, fontSize: 14, color: PdfColors.white),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Container(
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _headerBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'الإجمالي',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
                font: arabicBold, fontSize: 14, color: PdfColors.white),
          ),
        ),
      ],
    );
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
        pw.Text('ملاحظات',
            textDirection: pw.TextDirection.rtl,
            style:
                pw.TextStyle(font: arabicBold, fontSize: 12, color: _gold)),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: _tableLine, width: 1, style: pw.BorderStyle.dashed),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            invoice.notes,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicFont, fontSize: 11),
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
        _signatureBlock('ختم المؤسسة', arabicFont),
        _signatureBlock('توقيع المسؤول', arabicFont),
      ],
    );
  }

  static pw.Widget _signatureBlock(String label, pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 32),
        pw.Container(width: 140, height: 0.8, color: _bodyText),
        pw.SizedBox(height: 4),
        pw.Text(label,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
                font: arabicFont, fontSize: 10, color: _grey)),
      ],
    );
  }

  // ─────────────────────────────────────────── Footer ──
  static pw.Widget _buildFooter(pw.Font arabicBold) {
    return pw.Container(
      color: _headerBg,
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 32),
      child: pw.Center(
        child: pw.Text(
          'مع خالص الشكر لتعاملكم معنا',
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
              font: arabicBold, fontSize: 13, color: PdfColors.white),
        ),
      ),
    );
  }

  // ─────────────────────────────── Helpers ──
  static String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
