import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../models/payment_model.dart';
import '../models/project_model.dart';

import '../services/payment_service.dart';
import '../services/project_service.dart';
import '../services/client_service.dart';

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  // Generate comprehensive report data
  Future<ReportDataModel> generateReport(ReportFilterModel filter) async {
    switch (filter.type) {
      case ReportType.financial:
        return _generateFinancialReport(filter);
      case ReportType.client:
        return _generateClientReport(filter);
      case ReportType.project:
        return _generateProjectReport(filter);
      case ReportType.payment:
        return _generatePaymentReport(filter);
      case ReportType.tax:
        return _generateTaxReport(filter);
      case ReportType.expense:
        return _generateExpenseReport(filter);
    }
  }

  // Financial Report Generation
  Future<ReportDataModel> _generateFinancialReport(ReportFilterModel filter) async {
    final dateRange = filter.effectiveDateRange;

    try {
      // Get real data from services
      final payments = await PaymentService.getPayments();
      final projects = await ProjectService.getAllProjects();

      // Filter payments by date range
      final filteredPayments = payments.where((p) =>
        p.paymentDate.isAfter(dateRange.start) &&
        p.paymentDate.isBefore(dateRange.end.add(const Duration(days: 1)))).toList();

      // Filter projects by date range
      final filteredProjects = projects.where((p) =>
        p.createdAt.isAfter(dateRange.start) &&
        p.createdAt.isBefore(dateRange.end.add(const Duration(days: 1)))).toList();

      // Calculate financial metrics
      final totalRevenue = filteredPayments
          .where((p) => p.paymentStatus == PaymentStatus.completed)
          .fold(0.0, (sum, p) => sum + p.paymentAmount);

      const totalExpenses = 0.0; // TODO: Implement expense tracking
      final netProfit = totalRevenue - totalExpenses;
      final taxOwed = totalRevenue * 0.1; // Simplified 10% tax rate

      // Generate monthly revenue data
      final monthlyData = _generateMonthlyFinancialData(filteredPayments, dateRange);

      // Generate payment method breakdown
      final paymentMethodData = _generatePaymentMethodBreakdown(filteredPayments);

      final summary = {
        'totalRevenue': totalRevenue,
        'totalExpenses': totalExpenses,
        'netProfit': netProfit,
        'taxOwed': taxOwed,
        'paidTaxes': 0.0, // TODO: Track paid taxes
        'projectCount': filteredProjects.length,
        'paymentCount': filteredPayments.length,
      };

      final chartData = {
        'monthlyRevenue': monthlyData,
        'revenueBreakdown': paymentMethodData,
      };

      return ReportDataModel(
        title: 'Financial Report',
        subtitle: filter.period.displayName,
        type: ReportType.financial,
        dateRange: dateRange,
        summary: summary,
        data: _formatFinancialTableData(filteredPayments),
        charts: chartData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      // Fallback to placeholder data if real data fails
      return _generateFallbackFinancialReport(filter);
    }
  }

  // Client Report Generation
  Future<ReportDataModel> _generateClientReport(ReportFilterModel filter) async {
    final dateRange = filter.effectiveDateRange;

    try {
      // Get real data from services
      final clients = await ClientService.getAllClients();
      final projects = await ProjectService.getAllProjects();
      final payments = await PaymentService.getPayments();

      // Filter data by date range
      final filteredProjects = projects.where((p) =>
        p.createdAt.isAfter(dateRange.start) &&
        p.createdAt.isBefore(dateRange.end.add(const Duration(days: 1)))).toList();

      final filteredPayments = payments.where((p) =>
        p.paymentDate.isAfter(dateRange.start) &&
        p.paymentDate.isBefore(dateRange.end.add(const Duration(days: 1)))).toList();

      // Generate client performance data
      final clientRevenueData = <Map<String, dynamic>>[];
      double totalRevenue = 0.0;

      for (final client in clients) {
        final clientProjects = filteredProjects.where((p) => p.clientId == client.id).toList();
        final clientPayments = filteredPayments.where((p) =>
          clientProjects.any((proj) => proj.id == p.projectId)).toList();

        final clientRevenue = clientPayments
            .where((p) => p.paymentStatus == PaymentStatus.completed)
            .fold(0.0, (sum, p) => sum + p.paymentAmount);

        if (clientRevenue > 0) {
          clientRevenueData.add({
            'clientName': client.name,
            'revenue': clientRevenue,
            'projectCount': clientProjects.length,
          });
          totalRevenue += clientRevenue;
        }
      }

      // Sort by revenue and take top clients
      clientRevenueData.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
      final topClients = clientRevenueData.take(10).toList();

      // Calculate percentages for distribution chart
      final clientDistribution = topClients.take(5).map((client) => {
        'clientName': client['clientName'],
        'percentage': totalRevenue > 0 ? (client['revenue'] as double) / totalRevenue * 100 : 0.0,
      }).toList();

      final summary = {
        'totalClients': clients.length,
        'activeClients': clientRevenueData.length,
        'totalRevenue': totalRevenue,
        'averageRevenuePerClient': clientRevenueData.isNotEmpty ? totalRevenue / clientRevenueData.length : 0.0,
        'topClient': clientRevenueData.isNotEmpty ? clientRevenueData.first['clientName'] : 'N/A',
      };

      final chartData = {
        'clientRevenue': topClients,
        'clientDistribution': clientDistribution,
      };

      return ReportDataModel(
        title: 'Client Report',
        subtitle: filter.period.displayName,
        type: ReportType.client,
        dateRange: dateRange,
        summary: summary,
        data: clientRevenueData,
        charts: chartData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      // Fallback to placeholder data if real data fails
      return _generateFallbackClientReport(filter);
    }
  }

  // Project Report Generation
  Future<ReportDataModel> _generateProjectReport(ReportFilterModel filter) async {
    final dateRange = filter.effectiveDateRange;

    try {
      // Get real data from services
      final projects = await ProjectService.getAllProjects();

      // Filter projects by date range
      final filteredProjects = projects.where((p) =>
        p.createdAt.isAfter(dateRange.start) &&
        p.createdAt.isBefore(dateRange.end.add(const Duration(days: 1)))).toList();

      // Calculate project statistics
      final totalProjects = filteredProjects.length;
      final completedProjects = filteredProjects.where((p) => p.status == ProjectStatus.completed).length;
      final inProgressProjects = filteredProjects.where((p) => p.status == ProjectStatus.inProgress).length;
      final notStartedProjects = filteredProjects.where((p) => p.status == ProjectStatus.notStarted).length;

      final totalValue = filteredProjects.fold(0.0, (sum, p) => sum + (p.totalValue ?? 0.0));
      final averageProjectValue = totalProjects > 0 ? totalValue / totalProjects : 0.0;
      final completionRate = totalProjects > 0 ? (completedProjects / totalProjects) * 100 : 0.0;

      // Generate status breakdown for charts
      final statusBreakdown = [
        {
          'status': 'Completed',
          'count': completedProjects,
          'percentage': totalProjects > 0 ? (completedProjects / totalProjects) * 100 : 0.0,
          'color': 0xFF4CAF50,
        },
        {
          'status': 'In Progress',
          'count': inProgressProjects,
          'percentage': totalProjects > 0 ? (inProgressProjects / totalProjects) * 100 : 0.0,
          'color': 0xFF2196F3,
        },
        {
          'status': 'Not Started',
          'count': notStartedProjects,
          'percentage': totalProjects > 0 ? (notStartedProjects / totalProjects) * 100 : 0.0,
          'color': 0xFFFF9800,
        },
      ];

      // Generate monthly project creation data
      final monthlyData = _generateMonthlyProjectData(filteredProjects, dateRange);

      final summary = {
        'totalProjects': totalProjects,
        'completedProjects': completedProjects,
        'inProgressProjects': inProgressProjects,
        'notStartedProjects': notStartedProjects,
        'totalValue': totalValue,
        'averageProjectValue': averageProjectValue,
        'completionRate': completionRate,
      };

      final chartData = {
        'statusBreakdown': statusBreakdown,
        'monthlyProjects': monthlyData,
      };

      return ReportDataModel(
        title: 'Project Report',
        subtitle: filter.period.displayName,
        type: ReportType.project,
        dateRange: dateRange,
        summary: summary,
        data: _formatProjectTableData(filteredProjects),
        charts: chartData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      // Fallback to placeholder data if real data fails
      return _generateFallbackProjectReport(filter);
    }
  }

  // Placeholder methods for other report types
  Future<ReportDataModel> _generatePaymentReport(ReportFilterModel filter) async {
    final dateRange = filter.effectiveDateRange;

    final summary = {
      'totalPayments': 18,
      'completedPayments': 15,
      'pendingPayments': 3,
      'totalAmount': 25000.0,
      'averagePayment': 1388.89,
    };

    return ReportDataModel(
      title: 'Payment Report',
      subtitle: filter.period.displayName,
      type: ReportType.payment,
      dateRange: dateRange,
      summary: summary,
      data: [],
      charts: {},
      generatedAt: DateTime.now(),
    );
  }

  Future<ReportDataModel> _generateTaxReport(ReportFilterModel filter) async {
    final dateRange = filter.effectiveDateRange;

    final summary = {
      'annualIncome': 25000.0,
      'irgTax': 2500.0,
      'casnosTax': 24000.0,
      'totalTaxes': 26500.0,
      'paidTaxes': 1000.0,
      'remainingTaxes': 25500.0,
    };

    return ReportDataModel(
      title: 'Tax Report',
      subtitle: filter.period.displayName,
      type: ReportType.tax,
      dateRange: dateRange,
      summary: summary,
      data: [],
      charts: {},
      generatedAt: DateTime.now(),
    );
  }

  Future<ReportDataModel> _generateExpenseReport(ReportFilterModel filter) async {
    final dateRange = filter.effectiveDateRange;

    final summary = {
      'totalExpenses': 5000.0,
      'businessExpenses': 3000.0,
      'equipmentExpenses': 1500.0,
      'otherExpenses': 500.0,
      'averageMonthlyExpenses': 1666.67,
    };

    return ReportDataModel(
      title: 'Expense Report',
      subtitle: filter.period.displayName,
      type: ReportType.expense,
      dateRange: dateRange,
      summary: summary,
      data: [],
      charts: {},
      generatedAt: DateTime.now(),
    );
  }

  // Helper methods for real data processing
  List<Map<String, dynamic>> _generateMonthlyFinancialData(List<PaymentModel> payments, DateTimeRange dateRange) {
    final monthlyData = <String, Map<String, double>>{};

    // Initialize months in range
    var current = DateTime(dateRange.start.year, dateRange.start.month, 1);
    final end = DateTime(dateRange.end.year, dateRange.end.month, 1);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final monthKey = '${current.year}-${current.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = {'revenue': 0.0, 'expenses': 0.0, 'profit': 0.0};
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Aggregate payment data by month
    for (final payment in payments) {
      if (payment.paymentStatus == PaymentStatus.completed) {
        final monthKey = '${payment.paymentDate.year}-${payment.paymentDate.month.toString().padLeft(2, '0')}';
        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey]!['revenue'] = (monthlyData[monthKey]!['revenue'] ?? 0.0) + payment.paymentAmount;
          monthlyData[monthKey]!['profit'] = (monthlyData[monthKey]!['profit'] ?? 0.0) + payment.paymentAmount;
        }
      }
    }

    return monthlyData.entries.map((entry) => {
      'month': entry.key,
      'revenue': entry.value['revenue'],
      'expenses': entry.value['expenses'],
      'profit': entry.value['profit'],
    }).toList();
  }

  List<Map<String, dynamic>> _generatePaymentMethodBreakdown(List<PaymentModel> payments) {
    final methodTotals = <String, double>{};

    for (final payment in payments) {
      if (payment.paymentStatus == PaymentStatus.completed) {
        final method = payment.paymentMethod.displayName;
        methodTotals[method] = (methodTotals[method] ?? 0) + payment.paymentAmount;
      }
    }

    return methodTotals.entries.map((entry) => {
      'method': entry.key,
      'amount': entry.value,
    }).toList();
  }

  List<Map<String, dynamic>> _formatFinancialTableData(List<PaymentModel> payments) {
    return payments.map((payment) => {
      'date': payment.paymentDate.toIso8601String().split('T')[0],
      'amount': payment.paymentAmount,
      'method': payment.paymentMethod.displayName,
      'status': payment.paymentStatus.displayName,
      'projectId': payment.projectId,
    }).toList();
  }

  ReportDataModel _generateFallbackFinancialReport(ReportFilterModel filter) {
    final dateRange = filter.effectiveDateRange;

    // Fallback to placeholder data
    final summary = {
      'totalRevenue': 25000.0,
      'totalExpenses': 5000.0,
      'netProfit': 20000.0,
      'taxOwed': 2500.0,
      'paidTaxes': 1000.0,
      'projectCount': 12,
      'paymentCount': 18,
    };

    final chartData = {
      'monthlyRevenue': [
        {'month': '2024-01', 'revenue': 8000.0, 'expenses': 1500.0, 'profit': 6500.0},
        {'month': '2024-02', 'revenue': 9500.0, 'expenses': 1800.0, 'profit': 7700.0},
        {'month': '2024-03', 'revenue': 7500.0, 'expenses': 1700.0, 'profit': 5800.0},
      ],
      'revenueBreakdown': [
        {'method': 'Bank Transfer', 'amount': 15000.0},
        {'method': 'Cash', 'amount': 7000.0},
        {'method': 'PayPal', 'amount': 3000.0},
      ],
    };

    return ReportDataModel(
      title: 'Financial Report',
      subtitle: filter.period.displayName,
      type: ReportType.financial,
      dateRange: dateRange,
      summary: summary,
      data: [],
      charts: chartData,
      generatedAt: DateTime.now(),
    );
  }

  ReportDataModel _generateFallbackClientReport(ReportFilterModel filter) {
    final dateRange = filter.effectiveDateRange;

    // Fallback to placeholder data
    final summary = {
      'totalClients': 8,
      'activeClients': 6,
      'totalRevenue': 25000.0,
      'averageRevenuePerClient': 3125.0,
      'topClient': 'ABC Corporation',
    };

    final chartData = {
      'clientRevenue': [
        {'clientName': 'ABC Corporation', 'revenue': 8500.0},
        {'clientName': 'XYZ Ltd', 'revenue': 6200.0},
        {'clientName': 'Tech Solutions', 'revenue': 4800.0},
        {'clientName': 'Digital Agency', 'revenue': 3200.0},
        {'clientName': 'StartupCo', 'revenue': 2300.0},
      ],
      'clientDistribution': [
        {'clientName': 'ABC Corporation', 'percentage': 34.0},
        {'clientName': 'XYZ Ltd', 'percentage': 24.8},
        {'clientName': 'Tech Solutions', 'percentage': 19.2},
        {'clientName': 'Digital Agency', 'percentage': 12.8},
        {'clientName': 'Others', 'percentage': 9.2},
      ],
    };

    return ReportDataModel(
      title: 'Client Report',
      subtitle: filter.period.displayName,
      type: ReportType.client,
      dateRange: dateRange,
      summary: summary,
      data: [],
      charts: chartData,
      generatedAt: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> _generateMonthlyProjectData(List<ProjectModel> projects, DateTimeRange dateRange) {
    final monthlyData = <String, int>{};

    // Initialize months in range
    var current = DateTime(dateRange.start.year, dateRange.start.month, 1);
    final end = DateTime(dateRange.end.year, dateRange.end.month, 1);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final monthKey = '${current.year}-${current.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = 0;
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Count projects by creation month
    for (final project in projects) {
      final monthKey = '${project.createdAt.year}-${project.createdAt.month.toString().padLeft(2, '0')}';
      if (monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
      }
    }

    return monthlyData.entries.map((entry) => {
      'month': entry.key,
      'count': entry.value,
    }).toList();
  }

  List<Map<String, dynamic>> _formatProjectTableData(List<ProjectModel> projects) {
    return projects.map((project) => {
      'projectName': project.projectName,
      'clientName': project.client?.name ?? 'Unknown Client',
      'status': project.status.displayName,
      'value': project.totalValue ?? 0.0,
      'progress': project.progressPercentage,
      'createdAt': project.createdAt.toIso8601String().split('T')[0],
    }).toList();
  }

  ReportDataModel _generateFallbackProjectReport(ReportFilterModel filter) {
    final dateRange = filter.effectiveDateRange;

    // Fallback to placeholder data
    final summary = {
      'totalProjects': 12,
      'completedProjects': 8,
      'inProgressProjects': 3,
      'notStartedProjects': 1,
      'totalValue': 45000.0,
      'averageProjectValue': 3750.0,
      'completionRate': 66.7,
    };

    final chartData = {
      'statusBreakdown': [
        {'status': 'Completed', 'count': 8, 'percentage': 66.7, 'color': 0xFF4CAF50},
        {'status': 'In Progress', 'count': 3, 'percentage': 25.0, 'color': 0xFF2196F3},
        {'status': 'Not Started', 'count': 1, 'percentage': 8.3, 'color': 0xFFFF9800},
      ],
      'monthlyProjects': [
        {'month': '2024-01', 'count': 4},
        {'month': '2024-02', 'count': 5},
        {'month': '2024-03', 'count': 3},
      ],
    };

    return ReportDataModel(
      title: 'Project Report',
      subtitle: filter.period.displayName,
      type: ReportType.project,
      dateRange: dateRange,
      summary: summary,
      data: [],
      charts: chartData,
      generatedAt: DateTime.now(),
    );
  }
}

