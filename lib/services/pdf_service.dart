import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../models/invoice_model.dart';
import '../models/client_model.dart' as client_model;
import '../models/project_model.dart';
import '../models/business_profile_model.dart';
import '../services/settings_service.dart';
import '../services/business_profile_service.dart';
import '../utils/number_to_words.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final SettingsService _settingsService = SettingsService();
  final BusinessProfileService _businessProfileService = BusinessProfileService.instance;

  // Generate PDF for invoice
  Future<Uint8List> generateInvoicePDF(InvoiceModel invoice) async {
    final pdf = pw.Document();

    // Load fonts for Arabic support
    final arabicFont = await _loadArabicFont();
    final regularFont = await _loadRegularFont();

    // Get business profile for enhanced invoice
    final businessProfile = await _businessProfileService.getBusinessProfile();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildEnhancedHeader(invoice, businessProfile, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildClientInfo(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildEnhancedTotals(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 30),
            _buildEnhancedFooter(invoice, businessProfile, arabicFont, regularFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Load Arabic font
  Future<pw.Font> _loadArabicFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint('📄 Arabic font not found, using default: $e');
      return pw.Font.helvetica();
    }
  }

  // Load regular font
  Future<pw.Font> _loadRegularFont() async {
    return pw.Font.helvetica();
  }

  // Build enhanced PDF header with business profile information
  pw.Widget _buildEnhancedHeader(InvoiceModel invoice, BusinessProfileModel businessProfile, pw.Font arabicFont, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Company Info with Business Profile Data
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Company Name
                pw.Text(
                  businessProfile.companyName.isNotEmpty ? businessProfile.companyName : 'FreeLancer Business',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),

                // Tagline
                if (businessProfile.tagline != null && businessProfile.tagline!.isNotEmpty)
                  pw.Text(
                    businessProfile.tagline!,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 14,
                      color: PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),

                pw.SizedBox(height: 12),

                // Business Information
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // NiF ID
                      if (businessProfile.taxId != null && businessProfile.taxId!.isNotEmpty)
                        _buildBusinessInfoRow('NiF ID:', businessProfile.taxId!, regularFont),

                      // Card Number
                      if (businessProfile.registrationNumber != null && businessProfile.registrationNumber!.isNotEmpty)
                        _buildBusinessInfoRow('Card Number:', businessProfile.registrationNumber!, regularFont),

                      // Contact Info
                      if (businessProfile.email.isNotEmpty)
                        _buildBusinessInfoRow('Email:', businessProfile.email, regularFont),

                      if (businessProfile.phone.isNotEmpty)
                        _buildBusinessInfoRow('Phone:', businessProfile.phone, regularFont),

                      // Address
                      if (businessProfile.address.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            '${businessProfile.address}, ${businessProfile.city}, ${businessProfile.country}',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 20),

          // Invoice Title and QR Code
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Invoice Title
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'فاتورة',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 16,
                  color: PdfColors.grey600,
                ),
              ),

              pw.SizedBox(height: 20),

              // QR Code (if verification link exists)
              if (businessProfile.verificationLink != null && businessProfile.verificationLink!.isNotEmpty)
                _buildQRCode(businessProfile.verificationLink!, regularFont),
            ],
          ),
        ],
      ),
    );
  }

  // Build PDF header with company branding (legacy method for compatibility)
  pw.Widget _buildHeader(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Company Info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FreeLancer Business',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Professional Services',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Algeria',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),

          // Invoice Title
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'فاتورة',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 16,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build invoice information section
  pw.Widget _buildInvoiceInfo(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    final currency = _settingsService.getCurrencySymbol();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Invoice Number:', invoice.invoiceNumber, regularFont),
            _buildInfoRow('Issue Date:', _formatDate(invoice.issueDate), regularFont),
            if (invoice.dueDate != null)
              _buildInfoRow('Due Date:', _formatDate(invoice.dueDate!), regularFont),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildInfoRow('Status:', invoice.status.displayName, regularFont),
            _buildInfoRow('Currency:', currency, regularFont),
            if (invoice.projectId != null)
              _buildInfoRow('Project:', 'Project #${invoice.projectId}', regularFont),
          ],
        ),
      ],
    );
  }

  // Build client information section
  pw.Widget _buildClientInfo(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    if (invoice.clientName == null) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            invoice.clientName ?? 'Unknown Client',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (invoice.clientEmail != null && invoice.clientEmail!.isNotEmpty)
            pw.Text(
              invoice.clientEmail!,
              style: pw.TextStyle(font: regularFont, fontSize: 12),
            ),
          if (invoice.clientPhone != null && invoice.clientPhone!.isNotEmpty)
            pw.Text(
              invoice.clientPhone!,
              style: pw.TextStyle(font: regularFont, fontSize: 12),
            ),
          if (invoice.clientAddress != null && invoice.clientAddress!.isNotEmpty)
            pw.Text(
              invoice.clientAddress!,
              style: pw.TextStyle(font: regularFont, fontSize: 12),
            ),
        ],
      ),
    );
  }

  // Build items table
  pw.Widget _buildItemsTable(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    final currency = _settingsService.getCurrencySymbol();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell('Description', regularFont, isHeader: true),
            _buildTableCell('Qty', regularFont, isHeader: true),
            _buildTableCell('Rate', regularFont, isHeader: true),
            _buildTableCell('Amount', regularFont, isHeader: true),
          ],
        ),

        // Items
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.description, regularFont),
            _buildTableCell(item.quantity.toString(), regularFont),
            _buildTableCell('${item.unitPrice.toStringAsFixed(2)} $currency', regularFont),
            _buildTableCell('${item.total.toStringAsFixed(2)} $currency', regularFont),
          ],
        )),
      ],
    );
  }

  // Build totals section
  pw.Widget _buildTotals(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    final currency = _settingsService.getCurrencySymbol();

    return pw.Container(
      width: 250,
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal:', '${invoice.subtotal.toStringAsFixed(2)} $currency', regularFont),
          if (invoice.taxAmount != null && invoice.taxAmount! > 0)
            _buildTotalRow('Tax:', '${invoice.taxAmount!.toStringAsFixed(2)} $currency', regularFont),
          if (invoice.discount != null && invoice.discount! > 0)
            _buildTotalRow('Discount:', '-${invoice.discount!.toStringAsFixed(2)} $currency', regularFont),
          pw.Divider(color: PdfColors.grey400),
          _buildTotalRow(
            'Total:',
            '${invoice.total.toStringAsFixed(2)} $currency',
            regularFont,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  // Build footer
  pw.Widget _buildFooter(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            invoice.notes!,
            style: pw.TextStyle(font: regularFont, fontSize: 12),
          ),
          pw.SizedBox(height: 16),
        ],

        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),

        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 12,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey600,
          ),
        ),

        pw.Text(
          'شكراً لك على ثقتك',
          style: pw.TextStyle(
            font: arabicFont,
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  // Helper methods
  pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, String amount, pw.Font font, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              font: font,
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return _settingsService.formatDate(date);
  }

  // Build enhanced totals section with total in words
  pw.Widget _buildEnhancedTotals(InvoiceModel invoice, pw.Font arabicFont, pw.Font regularFont) {
    final currency = _settingsService.getCurrencySymbol();
    final currencyCode = invoice.currency.name.toUpperCase();
    final totalInWords = NumberToWords.convertToWords(invoice.total, currency: currencyCode);

    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Total in Words (Left side)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Total in Words:',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    totalInWords,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(width: 20),

          // Totals (Right side)
          pw.Container(
            width: 250,
            child: pw.Column(
              children: [
                _buildTotalRow('Subtotal:', '${invoice.subtotal.toStringAsFixed(2)} $currency', regularFont),
                if (invoice.taxAmount != null && invoice.taxAmount! > 0)
                  _buildTotalRow('Tax:', '${invoice.taxAmount!.toStringAsFixed(2)} $currency', regularFont),
                if (invoice.discount != null && invoice.discount! > 0)
                  _buildTotalRow('Discount:', '-${invoice.discount!.toStringAsFixed(2)} $currency', regularFont),
                pw.Divider(color: PdfColors.grey400, thickness: 2),
                _buildTotalRow(
                  'Total:',
                  '${invoice.total.toStringAsFixed(2)} $currency',
                  regularFont,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build enhanced footer with business profile information
  pw.Widget _buildEnhancedFooter(InvoiceModel invoice, BusinessProfileModel businessProfile, pw.Font arabicFont, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Notes section
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  invoice.notes!,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
        ],

        // Footer divider
        pw.Divider(color: PdfColors.grey300, thickness: 1),
        pw.SizedBox(height: 12),

        // Footer content
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Thank you message
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'شكراً لك على ثقتك',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),

                // Website if available
                if (businessProfile.website != null && businessProfile.website!.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text(
                      'Visit us: ${businessProfile.website}',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.blue600,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),

            // Business verification info
            if (businessProfile.verificationLink != null && businessProfile.verificationLink!.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Scan QR code for verification',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Business verification available online',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 8,
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  // Helper method to build business info rows
  pw.Widget _buildBusinessInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build QR code
  pw.Widget _buildQRCode(String data, pw.Font font) {
    return pw.Column(
      children: [
        pw.Container(
          width: 80,
          height: 80,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: data,
            width: 64,
            height: 64,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Verification',
          style: pw.TextStyle(
            font: font,
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  // Save PDF to device storage
  Future<String> savePDFToDevice(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);

      debugPrint('📄 PDF saved to: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('📄 Error saving PDF: $e');
      throw Exception('Failed to save PDF: $e');
    }
  }

  // Share PDF via system share dialog
  Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice: $fileName',
        subject: 'Invoice PDF',
      );

      debugPrint('📄 PDF shared: $fileName');
    } catch (e) {
      debugPrint('📄 Error sharing PDF: $e');
      throw Exception('Failed to share PDF: $e');
    }
  }

  // Open PDF with default viewer
  Future<void> openPDF(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open PDF: ${result.message}');
      }
      debugPrint('📄 PDF opened: $filePath');
    } catch (e) {
      debugPrint('📄 Error opening PDF: $e');
      throw Exception('Failed to open PDF: $e');
    }
  }

  // Print PDF directly
  Future<void> printPDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
      debugPrint('📄 PDF sent to printer: $fileName');
    } catch (e) {
      debugPrint('📄 Error printing PDF: $e');
      throw Exception('Failed to print PDF: $e');
    }
  }

  // Preview PDF before printing
  Future<void> previewPDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
        format: PdfPageFormat.a4,
      );
      debugPrint('📄 PDF preview shown: $fileName');
    } catch (e) {
      debugPrint('📄 Error previewing PDF: $e');
      throw Exception('Failed to preview PDF: $e');
    }
  }

  // Generate PDF for project invoice (auto-generated)
  Future<Uint8List> generateProjectInvoicePDF(ProjectModel project) async {
    // Create invoice from project data
    final totalValue = project.totalValue ?? 0.0;
    final invoice = InvoiceModel(
      id: 'proj_${project.id}',
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      clientId: project.clientId,
      projectId: project.id,
      type: InvoiceType.project,
      issueDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      items: [
        InvoiceItemModel(
          id: '1',
          description: project.projectName,
          quantity: 1,
          unitPrice: totalValue,
          total: totalValue,
        ),
      ],
      subtotal: totalValue,
      taxAmount: 0.0,
      discount: 0.0,
      total: totalValue,
      status: InvoiceStatus.draft,
      currency: _convertCurrency(project.currency),
      notes: project.description,
      clientName: project.client?.name ?? 'Unknown Client',
      clientEmail: project.client?.email ?? '',
      clientPhone: project.client?.phone ?? '',
      clientAddress: project.client?.address ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Use the enhanced PDF generation
    return generateInvoicePDF(invoice);
  }

  // Convert client currency to invoice currency
  Currency _convertCurrency(client_model.Currency clientCurrency) {
    switch (clientCurrency) {
      case client_model.Currency.da:
        return Currency.da;
      case client_model.Currency.usd:
        return Currency.usd;
      case client_model.Currency.eur:
        return Currency.eur;
    }
  }

  // Batch generate PDFs for multiple invoices
  Future<List<String>> batchGeneratePDFs(List<InvoiceModel> invoices) async {
    final List<String> filePaths = [];

    for (final invoice in invoices) {
      try {
        final pdfBytes = await generateInvoicePDF(invoice);
        final fileName = 'Invoice_${invoice.invoiceNumber}';
        final filePath = await savePDFToDevice(pdfBytes, fileName);
        filePaths.add(filePath);
      } catch (e) {
        debugPrint('📄 Error generating PDF for invoice ${invoice.invoiceNumber}: $e');
      }
    }

    return filePaths;
  }

  // Get PDF file size in MB
  double getPDFSizeInMB(Uint8List pdfBytes) {
    return pdfBytes.length / (1024 * 1024);
  }

  // Validate PDF generation requirements
  bool validateInvoiceForPDF(InvoiceModel invoice) {
    if (invoice.items.isEmpty) return false;
    if (invoice.clientName == null || invoice.clientName!.isEmpty) return false;
    if (invoice.invoiceNumber.isEmpty) return false;
    return true;
  }

  // Get suggested file name for invoice
  String getSuggestedFileName(InvoiceModel invoice) {
    final clientName = invoice.clientName?.replaceAll(' ', '_') ?? 'Unknown';
    final invoiceNumber = invoice.invoiceNumber.replaceAll(' ', '_');
    final date = _formatDate(invoice.issueDate).replaceAll('/', '-');

    return 'Invoice_${invoiceNumber}_${clientName}_$date';
  }

  // Check if printing is available on device
  Future<bool> isPrintingAvailable() async {
    try {
      return await Printing.info() != null;
    } catch (e) {
      debugPrint('📄 Error checking printing availability: $e');
      return false;
    }
  }

  // Get available paper formats
  List<PdfPageFormat> getAvailablePaperFormats() {
    return [
      PdfPageFormat.a4,
      PdfPageFormat.a5,
      PdfPageFormat.letter,
      PdfPageFormat.legal,
    ];
  }

  // Generate PDF with custom page format
  Future<Uint8List> generateInvoicePDFWithFormat(
    InvoiceModel invoice,
    PdfPageFormat pageFormat,
  ) async {
    final pdf = pw.Document();

    // Load fonts
    final arabicFont = await _loadArabicFont();
    final regularFont = await _loadRegularFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildClientInfo(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildItemsTable(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 20),
            _buildTotals(invoice, arabicFont, regularFont),
            pw.SizedBox(height: 30),
            _buildFooter(invoice, arabicFont, regularFont),
          ];
        },
      ),
    );

    return pdf.save();
  }
}

