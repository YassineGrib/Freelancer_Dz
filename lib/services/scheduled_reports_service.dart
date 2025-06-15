import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../services/export_service.dart';

enum ScheduleFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
}

extension ScheduleFrequencyExtension on ScheduleFrequency {
  String get displayName {
    switch (this) {
      case ScheduleFrequency.daily:
        return 'Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.monthly:
        return 'Monthly';
      case ScheduleFrequency.quarterly:
        return 'Quarterly';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleFrequency.daily:
        return Icons.today;
      case ScheduleFrequency.weekly:
        return Icons.view_week;
      case ScheduleFrequency.monthly:
        return Icons.calendar_month;
      case ScheduleFrequency.quarterly:
        return Icons.calendar_view_month;
    }
  }
}

class ScheduledReportModel {
  final String id;
  final String name;
  final ReportType reportType;
  final ScheduleFrequency frequency;
  final List<String> emailRecipients;
  final ExportFormat exportFormat;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSent;
  final DateTime? nextScheduled;

  ScheduledReportModel({
    required this.id,
    required this.name,
    required this.reportType,
    required this.frequency,
    required this.emailRecipients,
    required this.exportFormat,
    required this.isActive,
    required this.createdAt,
    this.lastSent,
    this.nextScheduled,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reportType': reportType.name,
      'frequency': frequency.name,
      'emailRecipients': emailRecipients,
      'exportFormat': exportFormat.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastSent': lastSent?.toIso8601String(),
      'nextScheduled': nextScheduled?.toIso8601String(),
    };
  }

  factory ScheduledReportModel.fromJson(Map<String, dynamic> json) {
    return ScheduledReportModel(
      id: json['id'] as String,
      name: json['name'] as String,
      reportType: ReportType.values.firstWhere((e) => e.name == json['reportType']),
      frequency: ScheduleFrequency.values.firstWhere((e) => e.name == json['frequency']),
      emailRecipients: List<String>.from(json['emailRecipients'] as List),
      exportFormat: ExportFormat.values.firstWhere((e) => e.name == json['exportFormat']),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSent: json['lastSent'] != null ? DateTime.parse(json['lastSent'] as String) : null,
      nextScheduled: json['nextScheduled'] != null ? DateTime.parse(json['nextScheduled'] as String) : null,
    );
  }

  ScheduledReportModel copyWith({
    String? id,
    String? name,
    ReportType? reportType,
    ScheduleFrequency? frequency,
    List<String>? emailRecipients,
    ExportFormat? exportFormat,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSent,
    DateTime? nextScheduled,
  }) {
    return ScheduledReportModel(
      id: id ?? this.id,
      name: name ?? this.name,
      reportType: reportType ?? this.reportType,
      frequency: frequency ?? this.frequency,
      emailRecipients: emailRecipients ?? this.emailRecipients,
      exportFormat: exportFormat ?? this.exportFormat,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSent: lastSent ?? this.lastSent,
      nextScheduled: nextScheduled ?? this.nextScheduled,
    );
  }
}

class ScheduledReportsService {
  static final ScheduledReportsService _instance = ScheduledReportsService._internal();
  factory ScheduledReportsService() => _instance;
  ScheduledReportsService._internal();

  final List<ScheduledReportModel> _scheduledReports = [];
  final ReportsService _reportsService = ReportsService();
  final ExportService _exportService = ExportService();

  // Get all scheduled reports
  List<ScheduledReportModel> getScheduledReports() {
    return List.unmodifiable(_scheduledReports);
  }

  // Add a new scheduled report
  Future<void> addScheduledReport(ScheduledReportModel report) async {
    _scheduledReports.add(report);
    await _saveScheduledReports();
  }

  // Update an existing scheduled report
  Future<void> updateScheduledReport(ScheduledReportModel report) async {
    final index = _scheduledReports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _scheduledReports[index] = report;
      await _saveScheduledReports();
    }
  }

  // Delete a scheduled report
  Future<void> deleteScheduledReport(String id) async {
    _scheduledReports.removeWhere((r) => r.id == id);
    await _saveScheduledReports();
  }

  // Toggle active status
  Future<void> toggleScheduledReport(String id) async {
    final index = _scheduledReports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _scheduledReports[index] = _scheduledReports[index].copyWith(
        isActive: !_scheduledReports[index].isActive,
      );
      await _saveScheduledReports();
    }
  }

  // Execute scheduled report
  Future<void> executeScheduledReport(String id) async {
    final report = _scheduledReports.firstWhere((r) => r.id == id);

    try {
      // Generate the report
      final filter = ReportFilterModel(
        type: report.reportType,
        period: _getReportPeriodForFrequency(report.frequency),
      );

      final reportData = await _reportsService.generateReport(filter);

      // Export the report
      String? filePath;
      switch (report.exportFormat) {
        case ExportFormat.pdf:
          filePath = await _exportService.exportToPDF(reportData);
          break;
        case ExportFormat.csv:
          filePath = await _exportService.exportToCSV(reportData);
          break;
        case ExportFormat.excel:
          throw Exception('Excel export not yet implemented');
      }

      if (filePath != null) {
        // Send email to recipients
        await _sendEmailWithAttachment(
          recipients: report.emailRecipients,
          subject: 'Scheduled Report: ${report.name}',
          body: _generateEmailBody(report, reportData),
          attachmentPath: filePath,
        );

        // Update last sent time
        final updatedReport = report.copyWith(
          lastSent: DateTime.now(),
          nextScheduled: _calculateNextScheduled(report.frequency),
        );
        await updateScheduledReport(updatedReport);
      }
    } catch (e) {
      throw Exception('Failed to execute scheduled report: $e');
    }
  }

  // Check for due reports and execute them
  Future<void> checkAndExecuteDueReports() async {
    final now = DateTime.now();
    final dueReports = _scheduledReports.where((report) =>
      report.isActive &&
      report.nextScheduled != null &&
      report.nextScheduled!.isBefore(now)
    ).toList();

    for (final report in dueReports) {
      try {
        await executeScheduledReport(report.id);
      } catch (e) {
        // Log error but continue with other reports
        debugPrint('Failed to execute scheduled report ${report.id}: $e');
      }
    }
  }

  // Helper methods
  ReportPeriod _getReportPeriodForFrequency(ScheduleFrequency frequency) {
    switch (frequency) {
      case ScheduleFrequency.daily:
        return ReportPeriod.today;
      case ScheduleFrequency.weekly:
        return ReportPeriod.thisWeek;
      case ScheduleFrequency.monthly:
        return ReportPeriod.lastMonth;
      case ScheduleFrequency.quarterly:
        return ReportPeriod.thisQuarter;
    }
  }

  DateTime _calculateNextScheduled(ScheduleFrequency frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case ScheduleFrequency.daily:
        return DateTime(now.year, now.month, now.day + 1, 9, 0); // 9 AM next day
      case ScheduleFrequency.weekly:
        return DateTime(now.year, now.month, now.day + 7, 9, 0); // 9 AM next week
      case ScheduleFrequency.monthly:
        return DateTime(now.year, now.month + 1, 1, 9, 0); // 9 AM first day of next month
      case ScheduleFrequency.quarterly:
        return DateTime(now.year, now.month + 3, 1, 9, 0); // 9 AM first day of next quarter
    }
  }

  String _generateEmailBody(ScheduledReportModel report, ReportDataModel reportData) {
    return '''
Hello,

Please find attached your scheduled ${report.reportType.displayName} report: ${report.name}

Report Summary:
${reportData.summary.entries.map((e) => '• ${_formatTitle(e.key)}: ${_formatValue(e.value)}').join('\n')}

This report was generated automatically on ${DateTime.now().toString().split('.')[0]}.

Best regards,
Freelancer Management System
''';
  }

  String _formatTitle(String title) {
    return title
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
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

  Future<void> _sendEmailWithAttachment({
    required List<String> recipients,
    required String subject,
    required String body,
    required String attachmentPath,
  }) async {
    // TODO: Implement actual email sending
    // This would typically use a service like SendGrid, AWS SES, or similar
    debugPrint('Sending email to: ${recipients.join(', ')}');
    debugPrint('Subject: $subject');
    debugPrint('Attachment: $attachmentPath');

    // Simulate email sending delay
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _saveScheduledReports() async {
    // TODO: Implement persistence (SharedPreferences, local database, etc.)
    debugPrint('Saving ${_scheduledReports.length} scheduled reports');
  }

  Future<void> _loadScheduledReports() async {
    // TODO: Implement loading from persistence
    debugPrint('Loading scheduled reports');
  }
}

