import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/report_model.dart';

// Export action options
enum ExportAction {
  save,
  share,
  saveAndShare,
}

// Export result model
class ExportResult {
  final bool success;
  final String? filePath;
  final String message;

  ExportResult({
    required this.success,
    this.filePath,
    required this.message,
  });
}

// Extension for ExportAction display names
extension ExportActionExtension on ExportAction {
  String get displayName {
    switch (this) {
      case ExportAction.save:
        return 'Save to Device';
      case ExportAction.share:
        return 'Share';
      case ExportAction.saveAndShare:
        return 'Save & Share';
    }
  }

  String get description {
    switch (this) {
      case ExportAction.save:
        return 'Save the report to your device storage';
      case ExportAction.share:
        return 'Share the report via apps like email, messaging, etc.';
      case ExportAction.saveAndShare:
        return 'Save to device and share immediately';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportAction.save:
        return Icons.download;
      case ExportAction.share:
        return Icons.share;
      case ExportAction.saveAndShare:
        return Icons.save_alt;
    }
  }
}

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Check and request storage permissions based on Android version
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 13+ (API 33+) - Use scoped storage, no permission needed for app-specific directories
      if (androidInfo.version.sdkInt >= 33) {
        return true; // No permission needed for app-specific directories
      }
      // Android 11-12 (API 30-32) - Use MANAGE_EXTERNAL_STORAGE for broad access
      else if (androidInfo.version.sdkInt >= 30) {
        var permission = await Permission.manageExternalStorage.status;
        if (!permission.isGranted) {
          permission = await Permission.manageExternalStorage.request();
        }
        return permission.isGranted;
      }
      // Android 10 and below (API 29 and below) - Use legacy storage permissions
      else {
        var permission = await Permission.storage.status;
        if (!permission.isGranted) {
          permission = await Permission.storage.request();
        }
        return permission.isGranted;
      }
    }
    // iOS doesn't need storage permissions for app documents directory
    return true;
  }

  // Get user-friendly error message for permission issues
  String _getPermissionErrorMessage() {
    if (Platform.isAndroid) {
      return 'Storage permission is required to export reports. Please grant permission in Settings > Apps > Freelancer Mobile > Permissions > Storage.';
    }
    return 'Unable to access storage for exporting reports.';
  }

  // Open app settings for permission management
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  // Export report to PDF
  Future<String?> exportToPDF(ReportDataModel reportData) async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception(_getPermissionErrorMessage());
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildPDFHeader(reportData),
              pw.SizedBox(height: 20),
              _buildPDFSummary(reportData),
              pw.SizedBox(height: 20),
              _buildPDFDataTable(reportData),
            ];
          },
        ),
      );

      // Save PDF to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${reportData.fileName}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      throw Exception('Failed to export PDF: $e');
    }
  }

  // Export report to CSV
  Future<String?> exportToCSV(ReportDataModel reportData) async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception(_getPermissionErrorMessage());
      }

      // Prepare CSV data
      final csvData = <List<String>>[];

      // Add header
      if (reportData.data.isNotEmpty) {
        final headers = reportData.data.first.keys.toList();
        csvData.add(headers);

        // Add data rows
        for (final row in reportData.data) {
          final values =
              headers.map((header) => row[header]?.toString() ?? '').toList();
          csvData.add(values);
        }
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save CSV to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${reportData.fileName}.csv');
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  // Share report file
  Future<void> shareReport(String filePath, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sharing $title',
        subject: title,
      );
    } catch (e) {
      throw Exception('Failed to share report: $e');
    }
  }

  // Export with user choice: Save or Share
  Future<ExportResult> exportWithOptions(ReportDataModel reportData,
      ExportFormat format, ExportAction action) async {
    try {
      String? filePath;

      switch (format) {
        case ExportFormat.pdf:
          filePath = await exportToPDF(reportData);
          break;
        case ExportFormat.csv:
          filePath = await exportToCSV(reportData);
          break;
        case ExportFormat.excel:
          throw Exception('Excel export not yet implemented');
      }

      if (filePath != null) {
        switch (action) {
          case ExportAction.save:
            return ExportResult(
              success: true,
              filePath: filePath,
              message:
                  'Report saved successfully to: ${_getReadableFilePath(filePath)}',
            );
          case ExportAction.share:
            await shareReport(filePath, reportData.title);
            return ExportResult(
              success: true,
              filePath: filePath,
              message: 'Report shared successfully',
            );
          case ExportAction.saveAndShare:
            await shareReport(filePath, reportData.title);
            return ExportResult(
              success: true,
              filePath: filePath,
              message: 'Report saved and shared successfully',
            );
        }
      } else {
        return ExportResult(
          success: false,
          message: 'Failed to export report',
        );
      }
    } catch (e) {
      return ExportResult(
        success: false,
        message: 'Export failed: ${e.toString()}',
      );
    }
  }

  // Get user-friendly file path
  String _getReadableFilePath(String filePath) {
    if (Platform.isAndroid) {
      // Extract just the filename for Android
      final fileName = filePath.split('/').last;
      return 'Downloads/$fileName';
    }
    return filePath;
  }

  // Legacy method for backward compatibility
  Future<void> exportAndShare(
      ReportDataModel reportData, ExportFormat format) async {
    final result =
        await exportWithOptions(reportData, format, ExportAction.share);
    if (!result.success) {
      throw Exception(result.message);
    }
  }

  // PDF Helper methods
  pw.Widget _buildPDFHeader(ReportDataModel reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          reportData.title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          reportData.subtitle,
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Date Range: ${reportData.formattedDateRange}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.Text(
          'Generated: ${_formatDateTime(reportData.generatedAt)}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFSummary(ReportDataModel reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 20,
          runSpacing: 10,
          children: reportData.summary.entries.map((entry) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _formatTitle(entry.key),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    _formatValue(entry.value),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPDFDataTable(ReportDataModel reportData) {
    if (reportData.data.isEmpty) {
      return pw.Text('No data available');
    }

    final headers = reportData.data.first.keys.toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detailed Data',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: headers.map((header) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    _formatTitle(header),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            // Data rows
            ...reportData.data.take(50).map((row) {
              return pw.TableRow(
                children: headers.map((header) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      _formatValue(row[header]),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ],
        ),
        if (reportData.data.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'Note: Only first 50 rows shown. Export to CSV for complete data.',
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          ),
      ],
    );
  }

  // Helper methods
  String _formatTitle(String title) {
    return title
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ')
        .trim();
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    if (value is int) {
      return value.toString();
    }
    return value.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
