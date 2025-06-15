import 'package:flutter/material.dart';

enum ReportType {
  client,
  payment,
  expense,
  tax,
  project,
  financial,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.client:
        return 'Client Reports';
      case ReportType.payment:
        return 'Payment Reports';
      case ReportType.expense:
        return 'Expense Reports';
      case ReportType.tax:
        return 'Tax Reports';
      case ReportType.project:
        return 'Project Reports';
      case ReportType.financial:
        return 'Financial Reports';
    }
  }

  String get description {
    switch (this) {
      case ReportType.client:
        return 'Client performance and payment history';
      case ReportType.payment:
        return 'Payment tracking and analysis';
      case ReportType.expense:
        return 'Business expense breakdown';
      case ReportType.tax:
        return 'Tax calculations and payments';
      case ReportType.project:
        return 'Project progress and profitability';
      case ReportType.financial:
        return 'Overall financial performance';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportType.client:
        return Icons.people;
      case ReportType.payment:
        return Icons.payment;
      case ReportType.expense:
        return Icons.receipt_long;
      case ReportType.tax:
        return Icons.account_balance;
      case ReportType.project:
        return Icons.work;
      case ReportType.financial:
        return Icons.analytics;
    }
  }

  Color get color {
    switch (this) {
      case ReportType.client:
        return Colors.blue;
      case ReportType.payment:
        return Colors.green;
      case ReportType.expense:
        return Colors.orange;
      case ReportType.tax:
        return Colors.red;
      case ReportType.project:
        return Colors.purple;
      case ReportType.financial:
        return Colors.teal;
    }
  }
}

enum ReportPeriod {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  thisQuarter,
  thisYear,
  lastYear,
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.thisQuarter:
        return 'This Quarter';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.lastYear:
        return 'Last Year';
      case ReportPeriod.custom:
        return 'Custom Range';
    }
  }

  DateTimeRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportPeriod.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case ReportPeriod.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: startOfWeek,
          end: startOfWeek.add(const Duration(days: 7)),
        );
      case ReportPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
      case ReportPeriod.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfLastMonth, end: endOfLastMonth);
      case ReportPeriod.thisQuarter:
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        final quarterEnd = DateTime(now.year, quarterStart.month + 3, 1);
        return DateTimeRange(start: quarterStart, end: quarterEnd);
      case ReportPeriod.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: startOfYear, end: endOfYear);
      case ReportPeriod.lastYear:
        final startOfLastYear = DateTime(now.year - 1, 1, 1);
        final endOfLastYear = DateTime(now.year, 1, 1);
        return DateTimeRange(start: startOfLastYear, end: endOfLastYear);
      case ReportPeriod.custom:
        // Default to this month for custom, will be overridden
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: startOfMonth, end: endOfMonth);
    }
  }
}

enum ExportFormat {
  pdf,
  excel,
  csv,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.csv:
        return 'CSV';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.excel:
        return '.xlsx';
      case ExportFormat.csv:
        return '.csv';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.excel:
        return Icons.table_chart;
      case ExportFormat.csv:
        return Icons.description;
    }
  }
}

class ReportFilterModel {
  final ReportType type;
  final ReportPeriod period;
  final DateTimeRange? customDateRange;
  final String? clientId;
  final String? projectId;
  final String? status;
  final double? minAmount;
  final double? maxAmount;

  const ReportFilterModel({
    required this.type,
    required this.period,
    this.customDateRange,
    this.clientId,
    this.projectId,
    this.status,
    this.minAmount,
    this.maxAmount,
  });

  DateTimeRange get effectiveDateRange {
    if (period == ReportPeriod.custom && customDateRange != null) {
      return customDateRange!;
    }
    return period.getDateRange();
  }

  ReportFilterModel copyWith({
    ReportType? type,
    ReportPeriod? period,
    DateTimeRange? customDateRange,
    String? clientId,
    String? projectId,
    String? status,
    double? minAmount,
    double? maxAmount,
  }) {
    return ReportFilterModel(
      type: type ?? this.type,
      period: period ?? this.period,
      customDateRange: customDateRange ?? this.customDateRange,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      status: status ?? this.status,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}

class ReportDataModel {
  final String title;
  final String subtitle;
  final ReportType type;
  final DateTimeRange dateRange;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic> charts;
  final DateTime generatedAt;

  const ReportDataModel({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.dateRange,
    required this.summary,
    required this.data,
    required this.charts,
    required this.generatedAt,
  });

  String get formattedDateRange {
    final start = dateRange.start;
    final end = dateRange.end.subtract(const Duration(days: 1));

    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return '${start.day}/${start.month}/${start.year}';
    }

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  String get fileName {
    final typeStr = type.name.toLowerCase();
    final dateStr = '${dateRange.start.year}${dateRange.start.month.toString().padLeft(2, '0')}';
    return '${typeStr}_report_$dateStr';
  }
}

// Chart data models
class ChartDataPoint {
  final String label;
  final double value;
  final Color color;
  final DateTime? date;
  final Map<String, dynamic> metadata;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
    this.date,
    this.metadata = const {},
  });
}

class FinancialSummary {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double taxOwed;
  final double paidTaxes;
  final List<MonthlyData> monthlyData;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.taxOwed,
    required this.paidTaxes,
    required this.monthlyData,
  });
}

class MonthlyData {
  final DateTime month;
  final double revenue;
  final double expenses;
  final double profit;

  MonthlyData({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.profit,
  });
}

class ClientReportData {
  final String clientId;
  final String clientName;
  final double totalRevenue;
  final int totalProjects;
  final int completedProjects;
  final double averageProjectValue;
  final List<DateTime> projectDates;

  ClientReportData({
    required this.clientId,
    required this.clientName,
    required this.totalRevenue,
    required this.totalProjects,
    required this.completedProjects,
    required this.averageProjectValue,
    required this.projectDates,
  });
}

class ProjectReportData {
  final int totalProjects;
  final int completedProjects;
  final int inProgressProjects;
  final int pendingProjects;
  final double averageCompletionTime;
  final double totalValue;
  final List<ProjectStatusData> statusBreakdown;

  ProjectReportData({
    required this.totalProjects,
    required this.completedProjects,
    required this.inProgressProjects,
    required this.pendingProjects,
    required this.averageCompletionTime,
    required this.totalValue,
    required this.statusBreakdown,
  });
}

class ProjectStatusData {
  final String status;
  final int count;
  final double percentage;
  final Color color;

  ProjectStatusData({
    required this.status,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class PaymentReportData {
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final List<PaymentMethodData> paymentMethods;
  final List<MonthlyPaymentData> monthlyPayments;

  PaymentReportData({
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.paymentMethods,
    required this.monthlyPayments,
  });
}

class PaymentMethodData {
  final String method;
  final double amount;
  final int count;
  final Color color;

  PaymentMethodData({
    required this.method,
    required this.amount,
    required this.count,
    required this.color,
  });
}

class MonthlyPaymentData {
  final DateTime month;
  final double paid;
  final double pending;
  final double overdue;

  MonthlyPaymentData({
    required this.month,
    required this.paid,
    required this.pending,
    required this.overdue,
  });
}

class TaxReportData {
  final double annualIncome;
  final double irgSimplifiedTax;
  final double casnosContribution;
  final double totalTaxOwed;
  final double totalTaxPaid;
  final DateTime nextTaxDeadline;
  final DateTime nextCasnosDeadline;
  final List<TaxPaymentData> taxPayments;

  TaxReportData({
    required this.annualIncome,
    required this.irgSimplifiedTax,
    required this.casnosContribution,
    required this.totalTaxOwed,
    required this.totalTaxPaid,
    required this.nextTaxDeadline,
    required this.nextCasnosDeadline,
    required this.taxPayments,
  });
}

class TaxPaymentData {
  final DateTime date;
  final String type;
  final double amount;
  final bool isPaid;

  TaxPaymentData({
    required this.date,
    required this.type,
    required this.amount,
    required this.isPaid,
  });
}

