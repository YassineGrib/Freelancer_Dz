import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/invoice_model.dart';
import '../models/project_model.dart';
import '../services/pdf_service.dart';

class PDFActionButtons extends StatefulWidget {
  final InvoiceModel? invoice;
  final ProjectModel? project;
  final VoidCallback? onPDFGenerated;

  const PDFActionButtons({
    super.key,
    this.invoice,
    this.project,
    this.onPDFGenerated,
  });

  @override
  State<PDFActionButtons> createState() => _PDFActionButtonsState();
}

class _PDFActionButtonsState extends State<PDFActionButtons> {
  final PDFService _pdfService = PDFService();
  bool _isGenerating = false;
  Uint8List? _lastGeneratedPDF;
  String? _lastFileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDF & Printing Options',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons row
          Row(
            children: [
              // Generate PDF button
              Expanded(
                child: _buildActionButton(
                  icon: FontAwesomeIcons.filePdf,
                  label: 'Generate PDF',
                  color: Colors.red,
                  onPressed: _isGenerating ? null : _generatePDF,
                ),
              ),
              const SizedBox(width: 8),

              // Preview button
              Expanded(
                child: _buildActionButton(
                  icon: FontAwesomeIcons.eye,
                  label: 'Preview',
                  color: Colors.blue,
                  onPressed: _lastGeneratedPDF != null ? _previewPDF : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Second row of buttons
          Row(
            children: [
              // Print button
              Expanded(
                child: _buildActionButton(
                  icon: FontAwesomeIcons.print,
                  label: 'Print',
                  color: Colors.green,
                  onPressed: _lastGeneratedPDF != null ? _printPDF : null,
                ),
              ),
              const SizedBox(width: 8),

              // Share button
              Expanded(
                child: _buildActionButton(
                  icon: FontAwesomeIcons.share,
                  label: 'Share',
                  color: Colors.orange,
                  onPressed: _lastGeneratedPDF != null ? _sharePDF : null,
                ),
              ),
            ],
          ),

          // Loading indicator
          if (_isGenerating) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Generating PDF...',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // PDF info
          if (_lastGeneratedPDF != null && _lastFileName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.circleCheck,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Ready: $_lastFileName',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Size: ${_pdfService.getPDFSizeInMB(_lastGeneratedPDF!).toStringAsFixed(2)} MB',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.green.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Future<void> _generatePDF() async {
    if (widget.invoice == null && widget.project == null) {
      _showErrorMessage('No invoice or project data available');
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      Uint8List pdfBytes;
      String fileName;

      if (widget.invoice != null) {
        // Validate invoice
        if (!_pdfService.validateInvoiceForPDF(widget.invoice!)) {
          _showErrorMessage('Invoice is missing required information');
          return;
        }

        pdfBytes = await _pdfService.generateInvoicePDF(widget.invoice!);
        fileName = _pdfService.getSuggestedFileName(widget.invoice!);
      } else {
        // Generate from project
        pdfBytes = await _pdfService.generateProjectInvoicePDF(widget.project!);
        fileName =
            'Project_Invoice_${widget.project!.projectName.replaceAll(' ', '_')}';
      }

      setState(() {
        _lastGeneratedPDF = pdfBytes;
        _lastFileName = fileName;
      });

      _showSuccessMessage('PDF generated successfully!');
      widget.onPDFGenerated?.call();
    } catch (e) {
      _showErrorMessage('Failed to generate PDF: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _previewPDF() async {
    if (_lastGeneratedPDF == null || _lastFileName == null) return;

    try {
      await _pdfService.previewPDF(_lastGeneratedPDF!, _lastFileName!);
    } catch (e) {
      _showErrorMessage('Failed to preview PDF: $e');
    }
  }

  Future<void> _printPDF() async {
    if (_lastGeneratedPDF == null || _lastFileName == null) return;

    try {
      // Check if printing is available
      final isAvailable = await _pdfService.isPrintingAvailable();
      if (!isAvailable) {
        _showErrorMessage('Printing is not available on this device');
        return;
      }

      await _pdfService.printPDF(_lastGeneratedPDF!, _lastFileName!);
      _showSuccessMessage('PDF sent to printer');
    } catch (e) {
      _showErrorMessage('Failed to print PDF: $e');
    }
  }

  Future<void> _sharePDF() async {
    if (_lastGeneratedPDF == null || _lastFileName == null) return;

    try {
      await _pdfService.sharePDF(_lastGeneratedPDF!, _lastFileName!);
    } catch (e) {
      _showErrorMessage('Failed to share PDF: $e');
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Compact version for smaller spaces
class CompactPDFButtons extends StatelessWidget {
  final InvoiceModel? invoice;
  final ProjectModel? project;
  final VoidCallback? onPDFGenerated;

  const CompactPDFButtons({
    super.key,
    this.invoice,
    this.project,
    this.onPDFGenerated,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _generateAndPreviewPDF(context),
          icon: const Icon(FontAwesomeIcons.filePdf, size: 18),
          tooltip: 'Generate PDF',
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            foregroundColor: Colors.red,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _generateAndPrintPDF(context),
          icon: const Icon(FontAwesomeIcons.print, size: 18),
          tooltip: 'Print',
          style: IconButton.styleFrom(
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            foregroundColor: Colors.green,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _generateAndSharePDF(context),
          icon: const Icon(FontAwesomeIcons.share, size: 18),
          tooltip: 'Share',
          style: IconButton.styleFrom(
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
            foregroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndPreviewPDF(BuildContext context) async {
    final pdfService = PDFService();

    try {
      Uint8List pdfBytes;
      String fileName;

      if (invoice != null) {
        if (!pdfService.validateInvoiceForPDF(invoice!)) {
          _showError(context, 'Invoice is missing required information');
          return;
        }
        pdfBytes = await pdfService.generateInvoicePDF(invoice!);
        fileName = pdfService.getSuggestedFileName(invoice!);
      } else if (project != null) {
        pdfBytes = await pdfService.generateProjectInvoicePDF(project!);
        fileName =
            'Project_Invoice_${project!.projectName.replaceAll(' ', '_')}';
      } else {
        _showError(context, 'No data available');
        return;
      }

      await pdfService.previewPDF(pdfBytes, fileName);
      onPDFGenerated?.call();
    } catch (e) {
      _showError(context, 'Failed to generate PDF: $e');
    }
  }

  Future<void> _generateAndPrintPDF(BuildContext context) async {
    final pdfService = PDFService();

    try {
      final isAvailable = await pdfService.isPrintingAvailable();
      if (!isAvailable) {
        _showError(context, 'Printing is not available on this device');
        return;
      }

      Uint8List pdfBytes;
      String fileName;

      if (invoice != null) {
        if (!pdfService.validateInvoiceForPDF(invoice!)) {
          _showError(context, 'Invoice is missing required information');
          return;
        }
        pdfBytes = await pdfService.generateInvoicePDF(invoice!);
        fileName = pdfService.getSuggestedFileName(invoice!);
      } else if (project != null) {
        pdfBytes = await pdfService.generateProjectInvoicePDF(project!);
        fileName =
            'Project_Invoice_${project!.projectName.replaceAll(' ', '_')}';
      } else {
        _showError(context, 'No data available');
        return;
      }

      await pdfService.printPDF(pdfBytes, fileName);
      _showSuccess(context, 'PDF sent to printer');
      onPDFGenerated?.call();
    } catch (e) {
      _showError(context, 'Failed to print PDF: $e');
    }
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    final pdfService = PDFService();

    try {
      Uint8List pdfBytes;
      String fileName;

      if (invoice != null) {
        if (!pdfService.validateInvoiceForPDF(invoice!)) {
          _showError(context, 'Invoice is missing required information');
          return;
        }
        pdfBytes = await pdfService.generateInvoicePDF(invoice!);
        fileName = pdfService.getSuggestedFileName(invoice!);
      } else if (project != null) {
        pdfBytes = await pdfService.generateProjectInvoicePDF(project!);
        fileName =
            'Project_Invoice_${project!.projectName.replaceAll(' ', '_')}';
      } else {
        _showError(context, 'No data available');
        return;
      }

      await pdfService.sharePDF(pdfBytes, fileName);
      onPDFGenerated?.call();
    } catch (e) {
      _showError(context, 'Failed to share PDF: $e');
    }
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
