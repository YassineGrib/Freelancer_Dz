import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import '../models/client_model.dart' as client_model;
import '../models/payment_model.dart';
import '../models/expense_model.dart' as expense_model;
import '../models/project_model.dart';
import '../models/tax_model.dart';
import 'client_service.dart';
import 'payment_service.dart';
import 'expense_service.dart';
import 'project_service.dart';
import 'tax_service.dart';

class ReportService {
  static final _supabase = Supabase.instance.client;

  /// Generate Client Report
  static Future<ReportDataModel> generateClientReport(ReportFilterModel filter) async {
    try {
      final dateRange = filter.effectiveDateRange;
      final clients = await ClientService.getAllClients();
      final payments = await PaymentService.getPayments();
      final projects = await ProjectService.getAllProjects();

      // Filter data by date range
      final filteredPayments = payments.where((payment) {
        final paymentDate = payment.paymentDate ?? payment.createdAt;
        return paymentDate.isAfter(dateRange.start) &&
               paymentDate.isBefore(dateRange.end);
      }).toList();

      final filteredProjects = projects.where((project) {
        return project.createdAt.isAfter(dateRange.start) &&
               project.createdAt.isBefore(dateRange.end);
      }).toList();

      // Calculate summary
      final totalClients = clients.length;
      final totalRevenue = filteredPayments
          .where((p) => p.paymentStatus == PaymentStatus.completed)
          .fold<double>(0.0, (sum, payment) => sum + payment.paymentAmount);

      // Prepare data
      final clientData = <Map<String, dynamic>>[];
      for (final client in clients) {
        final clientPayments = filteredPayments
            .where((p) => p.clientId == client.id)
            .toList();
        final clientProjects = filteredProjects
            .where((p) => p.clientId == client.id)
            .toList();

        final totalPaid = clientPayments
            .where((p) => p.paymentStatus == PaymentStatus.completed)
            .fold<double>(0.0, (sum, p) => sum + p.paymentAmount);
        final totalPending = clientPayments
            .where((p) => p.paymentStatus == PaymentStatus.pending)
            .fold<double>(0.0, (sum, p) => sum + p.paymentAmount);

        clientData.add({
          'client_name': client.name,
          'company': client.companyName ?? 'N/A',
          'email': client.email,
          'phone': client.phone,
          'client_type': client.clientType.displayName,
          'projects_count': clientProjects.length,
          'total_paid': totalPaid,
          'total_pending': totalPending,
          'total_revenue': totalPaid + totalPending,
          'last_payment': clientPayments.isNotEmpty
              ? clientPayments.last.paymentDate.toString().split(' ')[0] ?? 'N/A'
              : 'N/A',
        });
      }

      // Sort by total revenue
      clientData.sort((a, b) => (b['total_revenue'] as double).compareTo(a['total_revenue'] as double));

      // Chart data
      final chartData = {
        'client_types': {
          'individual_local': clients.where((c) => c.clientType == client_model.ClientType.individualLocal).length,
          'individual_foreign': clients.where((c) => c.clientType == client_model.ClientType.individualForeign).length,
          'national_company': clients.where((c) => c.clientType == client_model.ClientType.nationalCompany).length,
          'international_company': clients.where((c) => c.clientType == client_model.ClientType.companyInternational).length,
        },
        'top_clients': clientData.take(5).map((c) => {
          'name': c['client_name'],
          'revenue': c['total_revenue'],
        }).toList(),
      };

      return ReportDataModel(
        title: 'Client Report',
        subtitle: 'Client performance and payment analysis',
        type: ReportType.client,
        dateRange: dateRange,
        summary: {
          'total_clients': totalClients,
          'total_revenue': totalRevenue,
          'avg_revenue_per_client': totalClients > 0 ? totalRevenue / totalClients : 0.0,
          'total_projects': filteredProjects.length,
        },
        data: clientData,
        charts: chartData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate client report: $e');
    }
  }

  /// Generate Payment Report
  static Future<ReportDataModel> generatePaymentReport(ReportFilterModel filter) async {
    try {
      final dateRange = filter.effectiveDateRange;
      final payments = await PaymentService.getPayments();
      final clients = await ClientService.getAllClients();

      // Filter payments by date range
      final filteredPayments = payments.where((payment) {
        final paymentDate = payment.paymentDate ?? payment.createdAt;
        return paymentDate.isAfter(dateRange.start) &&
               paymentDate.isBefore(dateRange.end);
      }).toList();

      // Calculate summary
      final totalPayments = filteredPayments.length;
      final completedPayments = filteredPayments
          .where((p) => p.paymentStatus == PaymentStatus.completed)
          .toList();
      final pendingPayments = filteredPayments
          .where((p) => p.paymentStatus == PaymentStatus.pending)
          .toList();
      final overduePayments = filteredPayments
          .where((p) => p.paymentStatus == PaymentStatus.failed)
          .toList();

      final totalAmount = filteredPayments.fold<double>(0.0, (sum, p) => sum + p.paymentAmount);
      final completedAmount = completedPayments.fold<double>(0.0, (sum, p) => sum + p.paymentAmount);
      final pendingAmount = pendingPayments.fold<double>(0.0, (sum, p) => sum + p.paymentAmount);
      final overdueAmount = overduePayments.fold<double>(0.0, (sum, p) => sum + p.paymentAmount);

      // Prepare data
      final paymentData = <Map<String, dynamic>>[];
      for (final payment in filteredPayments) {
        final client = clients.firstWhere(
          (c) => c.id == payment.clientId,
          orElse: () => client_model.ClientModel(
            name: 'Unknown Client',
            email: '',
            phone: '',
            address: '',
            clientType: client_model.ClientType.individualLocal,
            currency: client_model.Currency.da,
            createdAt: DateTime.now(),
          ),
        );

        paymentData.add({
          'payment_id': payment.id ?? 'N/A',
          'client_name': client.name,
          'amount': payment.paymentAmount,
          'currency': payment.currency.code,
          'status': payment.paymentStatus.displayName,
          'method': payment.paymentMethod.displayName,
          'payment_date': payment.paymentDate.toString().split(' ')[0] ?? 'N/A',
          'due_date': payment.dueDate?.toString().split(' ')[0] ?? 'N/A',
          'description': payment.description ?? 'N/A',
          'created_at': payment.createdAt.toString().split(' ')[0],
        });
      }

      // Sort by payment date
      paymentData.sort((a, b) {
        final dateA = DateTime.tryParse(a['payment_date'] as String? ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['payment_date'] as String? ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      // Chart data
      final chartData = {
        'payment_status': {
          'completed': completedPayments.length,
          'pending': pendingPayments.length,
          'overdue': overduePayments.length,
        },
        'payment_amounts': {
          'completed': completedAmount,
          'pending': pendingAmount,
          'overdue': overdueAmount,
        },
        'monthly_trend': _calculateMonthlyTrend(filteredPayments),
      };

      return ReportDataModel(
        title: 'Payment Report',
        subtitle: 'Payment tracking and analysis',
        type: ReportType.payment,
        dateRange: dateRange,
        summary: {
          'total_payments': totalPayments,
          'completed_payments': completedPayments.length,
          'pending_payments': pendingPayments.length,
          'overdue_payments': overduePayments.length,
          'total_amount': totalAmount,
          'completed_amount': completedAmount,
          'pending_amount': pendingAmount,
          'overdue_amount': overdueAmount,
          'collection_rate': totalAmount > 0 ? (completedAmount / totalAmount * 100) : 0.0,
        },
        data: paymentData,
        charts: chartData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate payment report: $e');
    }
  }

  /// Generate Expense Report
  static Future<ReportDataModel> generateExpenseReport(ReportFilterModel filter) async {
    try {
      final dateRange = filter.effectiveDateRange;
      final expenses = await ExpenseService.getAllExpenses();

      // Filter expenses by date range
      final filteredExpenses = expenses.where((expense) {
        return expense.createdAt.isAfter(dateRange.start) &&
               expense.createdAt.isBefore(dateRange.end);
      }).toList();

      // Calculate summary
      final totalExpenses = filteredExpenses.length;
      final totalAmount = filteredExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
      final avgExpense = totalExpenses > 0 ? totalAmount / totalExpenses : 0.0;

      // Group by category
      final categoryTotals = <String, double>{};
      for (final expense in filteredExpenses) {
        final category = expense_model.getExpenseCategoryDisplay(expense.category).displayName;
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + expense.amount;
      }

      // Prepare data
      final expenseData = filteredExpenses.map((expense) => {
        'expense_id': expense.id ?? 'N/A',
        'description': expense.description,
        'category': expense_model.getExpenseCategoryDisplay(expense.category).displayName,
        'amount': expense.amount,
        'currency': expense.currency.code,
        'date': expense.createdAt.toString().split(' ')[0],
        'receipt_url': expense.receiptUrl ?? 'N/A',
        'notes': expense.notes ?? 'N/A',
        'created_at': expense.createdAt.toString().split(' ')[0],
      }).toList();

      // Sort by date
      expenseData.sort((a, b) {
        final dateA = DateTime.parse(a['date'] as String);
        final dateB = DateTime.parse(b['date'] as String);
        return dateB.compareTo(dateA);
      });

      // Chart data
      final chartData = {
        'category_breakdown': categoryTotals,
        'monthly_trend': _calculateExpenseMonthlyTrend(filteredExpenses),
      };

      return ReportDataModel(
        title: 'Expense Report',
        subtitle: 'Business expense breakdown and analysis',
        type: ReportType.expense,
        dateRange: dateRange,
        summary: {
          'total_expenses': totalExpenses,
          'total_amount': totalAmount,
          'avg_expense': avgExpense,
          'categories_count': categoryTotals.length,
          'largest_expense': filteredExpenses.isNotEmpty
              ? filteredExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b)
              : 0.0,
        },
        data: expenseData,
        charts: chartData,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to generate expense report: $e');
    }
  }

  /// Calculate monthly trend for payments
  static Map<String, double> _calculateMonthlyTrend(List<PaymentModel> payments) {
    final monthlyTotals = <String, double>{};

    for (final payment in payments) {
      if (payment.paymentStatus == PaymentStatus.completed) {
        final monthKey = '${payment.paymentDate.year}-${payment.paymentDate.month.toString().padLeft(2, '0')}';
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + payment.paymentAmount;
      }
    }

    return monthlyTotals;
  }

  /// Calculate monthly trend for expenses
  static Map<String, double> _calculateExpenseMonthlyTrend(List<expense_model.ExpenseModel> expenses) {
    final monthlyTotals = <String, double>{};

    for (final expense in expenses) {
      final monthKey = '${expense.createdAt.year}-${expense.createdAt.month.toString().padLeft(2, '0')}';
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + expense.amount;
    }

    return monthlyTotals;
  }

  /// Generate report based on filter
  static Future<ReportDataModel> generateReport(ReportFilterModel filter) async {
    switch (filter.type) {
      case ReportType.client:
        return generateClientReport(filter);
      case ReportType.payment:
        return generatePaymentReport(filter);
      case ReportType.expense:
        return generateExpenseReport(filter);
      case ReportType.tax:
        // Return empty report for now
        return ReportDataModel(
          title: 'Tax Report',
          subtitle: 'Tax calculations and payment tracking',
          type: ReportType.tax,
          dateRange: filter.effectiveDateRange,
          summary: {},
          data: [],
          charts: {},
          generatedAt: DateTime.now(),
        );
      case ReportType.project:
        // Return empty report for now
        return ReportDataModel(
          title: 'Project Report',
          subtitle: 'Project progress and profitability analysis',
          type: ReportType.project,
          dateRange: filter.effectiveDateRange,
          summary: {},
          data: [],
          charts: {},
          generatedAt: DateTime.now(),
        );
      case ReportType.financial:
        // Return empty report for now
        return ReportDataModel(
          title: 'Financial Report',
          subtitle: 'Overall financial performance summary',
          type: ReportType.financial,
          dateRange: filter.effectiveDateRange,
          summary: {},
          data: [],
          charts: {},
          generatedAt: DateTime.now(),
        );
    }
  }
}

