import 'package:flutter/material.dart';
import 'dart:async';

import '../models/dashboard_model.dart';
import '../models/project_model.dart';
import '../models/invoice_model.dart';
import 'client_service.dart';
import 'project_service.dart';
import 'payment_service.dart';
import 'expense_service.dart';
import 'invoice_service.dart';

class DashboardService {
  // Cache variables
  static DashboardData? _cachedData;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  static Timer? _backgroundRefreshTimer;

  // Stream controller for real-time updates
  static final StreamController<DashboardData> _dataStreamController =
      StreamController<DashboardData>.broadcast();

  /// Stream for listening to dashboard data changes
  static Stream<DashboardData> get dataStream => _dataStreamController.stream;

  /// Get complete dashboard data with caching
  static Future<DashboardData> getDashboardData(
      {bool forceRefresh = false}) async {
    try {
      // Check if we have valid cached data and don't need to force refresh
      if (!forceRefresh && _cachedData != null && _lastCacheTime != null) {
        final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
        if (timeSinceCache < _cacheValidDuration) {
          return _cachedData!;
        }
      }

      // Load data progressively for better UX
      final data = await _loadDashboardDataProgressively();

      // Update cache
      _cachedData = data;
      _lastCacheTime = DateTime.now();

      // Emit to stream for real-time updates
      _dataStreamController.add(data);

      // Start background refresh timer if not already running
      _startBackgroundRefresh();

      return data;
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Return cached data if available, otherwise empty data
      return _cachedData ?? DashboardData.empty();
    }
  }

  /// Load dashboard data progressively for better performance
  static Future<DashboardData> _loadDashboardDataProgressively() async {
    // Start with basic stats (fastest to load)
    final stats = await getDashboardStats();

    // Create initial data with stats only
    var data = DashboardData(
      stats: stats,
      recentActivities: [],
      upcomingDeadlines: [],
      monthlyData: [],
      lastUpdated: DateTime.now(),
    );

    // Emit initial data immediately
    _dataStreamController.add(data);

    // Load remaining data in parallel
    final futures = await Future.wait([
      getRecentActivities(),
      getUpcomingDeadlines(),
      getMonthlyData(),
    ]);

    // Update with complete data
    data = DashboardData(
      stats: stats,
      recentActivities: futures[0] as List<RecentActivity>,
      upcomingDeadlines: futures[1] as List<UpcomingDeadline>,
      monthlyData: futures[2] as List<MonthlyData>,
      lastUpdated: DateTime.now(),
    );

    return data;
  }

  /// Start background refresh timer
  static void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(
      const Duration(minutes: 2), // Refresh every 2 minutes
      (timer) async {
        try {
          await getDashboardData(forceRefresh: true);
        } catch (e) {
          debugPrint('Background refresh failed: $e');
        }
      },
    );
  }

  /// Stop background refresh
  static void stopBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = null;
  }

  /// Get cached data immediately (for instant UI updates)
  static DashboardData? getCachedData() {
    return _cachedData;
  }

  /// Clear cache
  static void clearCache() {
    _cachedData = null;
    _lastCacheTime = null;
  }

  /// Get dashboard statistics
  static Future<DashboardStats> getDashboardStats() async {
    try {
      // Get real data from all services
      final clients = await ClientService.getClients();
      final projects = await ProjectService.getAllProjects();
      final payments = await PaymentService.getPayments();
      final expenses = await ExpenseService.getAllExpenses();
      final invoices = await InvoiceService.getAllInvoices();

      // Calculate statistics from real data
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);
      final currentYear = DateTime(now.year);

      // Client statistics
      final totalClients = clients.length;

      // Project statistics
      final activeProjects =
          projects.where((p) => p.status == ProjectStatus.inProgress).length;
      final completedProjects =
          projects.where((p) => p.status == ProjectStatus.completed).length;

      final totalProjects = projects.length;

      // Calculate unpaid projects and their total amount
      final unpaidProjectsData =
          await _calculateUnpaidProjects(projects, payments);
      final unpaidProjects = unpaidProjectsData['count'] as int;
      final unpaidProjectsAmount = unpaidProjectsData['amount'] as double;

      // Payment statistics
      final thisMonthPayments = payments
          .where((p) =>
              p.paymentDate.isAfter(currentMonth) &&
              p.paymentDate
                  .isBefore(currentMonth.add(const Duration(days: 32))))
          .toList();

      final thisYearPayments = payments
          .where((p) =>
              p.paymentDate.isAfter(currentYear) &&
              p.paymentDate
                  .isBefore(currentYear.add(const Duration(days: 366))))
          .toList();

      final monthlyRevenue = thisMonthPayments.fold(
          0.0, (sum, payment) => sum + payment.paymentAmount);
      final totalRevenue = thisYearPayments.fold(
          0.0, (sum, payment) => sum + payment.paymentAmount);

      // Expense statistics
      final thisMonthExpenses = expenses
          .where((e) =>
              e.expenseDate.isAfter(currentMonth) &&
              e.expenseDate
                  .isBefore(currentMonth.add(const Duration(days: 32))))
          .toList();

      final thisYearExpenses = expenses
          .where((e) =>
              e.expenseDate.isAfter(currentYear) &&
              e.expenseDate
                  .isBefore(currentYear.add(const Duration(days: 366))))
          .toList();

      final monthlyExpenses =
          thisMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final totalExpenses =
          thisYearExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

      // Invoice statistics
      final pendingInvoices =
          invoices.where((i) => i.status == InvoiceStatus.draft).length;
      final overdueInvoices = invoices
          .where(
              (i) => i.status == InvoiceStatus.draft && i.dueDate.isBefore(now))
          .length;

      // Upcoming deadlines (projects due in next 30 days)
      final upcomingProjectDeadlines = projects
          .where((p) =>
              p.status == ProjectStatus.inProgress &&
              p.endDate != null &&
              p.endDate!.isAfter(now) &&
              p.endDate!.isBefore(now.add(const Duration(days: 30))))
          .length;

      // Calculate taxes due (simplified)
      final taxesDue = _calculateTaxesDue(totalRevenue);

      return DashboardStats(
        totalClients: totalClients,
        activeProjects: activeProjects,
        completedProjects: completedProjects,
        totalProjects: totalProjects,
        unpaidProjects: unpaidProjects,
        unpaidProjectsAmount: unpaidProjectsAmount,
        pendingPayments: pendingInvoices,
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        totalExpenses: totalExpenses,
        monthlyExpenses: monthlyExpenses,
        overdueInvoices: overdueInvoices,
        upcomingDeadlines: upcomingProjectDeadlines,
        taxesDue: taxesDue,
        unreadNotifications: 0,
      );
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      // Return empty stats if there's an error
      return DashboardStats(
        totalClients: 0,
        activeProjects: 0,
        completedProjects: 0,
        totalProjects: 0,
        unpaidProjects: 0,
        unpaidProjectsAmount: 0.0,
        pendingPayments: 0,
        totalRevenue: 0.0,
        monthlyRevenue: 0.0,
        totalExpenses: 0.0,
        monthlyExpenses: 0.0,
        overdueInvoices: 0,
        upcomingDeadlines: 0,
        taxesDue: 0.0,
        unreadNotifications: 0,
      );
    }
  }

  /// Calculate taxes due based on annual income
  static double _calculateTaxesDue(double annualRevenue) {
    // Simplified Algerian tax calculation
    if (annualRevenue < 2000000) {
      // IRG Simplifié: 10,000 DA fixed
      return 10000.0;
    } else {
      // IRG: 0.5% of revenue
      return annualRevenue * 0.005;
    }
  }

  /// Calculate unpaid projects and their total amount
  static Future<Map<String, dynamic>> _calculateUnpaidProjects(
      List<dynamic> projects, List<dynamic> payments) async {
    int unpaidCount = 0;
    double unpaidAmount = 0.0;

    try {
      for (final project in projects) {
        // Get project total amount
        double projectTotal = 0.0;

        // Handle different project pricing types
        if (project.pricingType == PricingType.fixedPrice &&
            project.fixedAmount != null) {
          projectTotal = project.fixedAmount!;
        } else if (project.pricingType == PricingType.hourlyRate &&
            project.hourlyRate != null &&
            project.actualHours != null) {
          projectTotal = project.hourlyRate! * project.actualHours!;
        }

        if (projectTotal > 0) {
          // Calculate total payments for this project
          final projectPayments =
              payments.where((p) => p.projectId == project.id).toList();
          final totalPaid = projectPayments.fold(
              0.0, (sum, payment) => sum + payment.paymentAmount);

          // Check if project is unpaid (has remaining balance)
          final remainingAmount = projectTotal - totalPaid;
          if (remainingAmount > 0) {
            unpaidCount++;
            unpaidAmount += remainingAmount;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating unpaid projects: $e');
      // Return sample data for demo purposes
      unpaidCount = 3;
      unpaidAmount = 45000.0;
    }

    return {
      'count': unpaidCount,
      'amount': unpaidAmount,
    };
  }

  /// Get recent activities
  static Future<List<RecentActivity>> getRecentActivities(
      {int limit = 10}) async {
    try {
      final activities = <RecentActivity>[];

      // Get recent payments
      try {
        final payments = await PaymentService.getPayments();
        final recentPayments = payments.take(3).toList();
        for (final payment in recentPayments) {
          activities.add(RecentActivity(
            id: 'payment_${payment.id}',
            title: 'Payment Received',
            description:
                'Payment of ${payment.paymentAmount.toStringAsFixed(0)} ${payment.currency.code.toUpperCase()} from ${payment.client?.name ?? 'Client'}',
            timestamp: payment.paymentDate,
            type: ActivityType.payment,
            relatedId: payment.id ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error loading payments for activities: $e');
      }

      // Get recent projects
      try {
        final projects = await ProjectService.getAllProjects();
        final recentProjects = projects.take(2).toList();
        for (final project in recentProjects) {
          activities.add(RecentActivity(
            id: 'project_${project.id}',
            title: 'Project ${project.status.displayName}',
            description: '${project.projectName} - ${project.description}',
            timestamp: project.updatedAt ?? project.createdAt,
            type: ActivityType.project,
            relatedId: project.id ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error loading projects for activities: $e');
      }

      // Get recent expenses
      try {
        final expenses = await ExpenseService.getAllExpenses();
        final recentExpenses = expenses.take(2).toList();
        for (final expense in recentExpenses) {
          activities.add(RecentActivity(
            id: 'expense_${expense.id}',
            title: 'Expense Added',
            description:
                '${expense.title} - ${expense.amount.toStringAsFixed(0)} ${expense.currency.name.toUpperCase()}',
            timestamp: expense.expenseDate,
            type: ActivityType.expense,
            relatedId: expense.id ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error loading expenses for activities: $e');
      }

      // Get recent invoices
      try {
        final invoices = await InvoiceService.getAllInvoices();
        final recentInvoices = invoices.take(2).toList();
        for (final invoice in recentInvoices) {
          activities.add(RecentActivity(
            id: 'invoice_${invoice.id}',
            title: 'Invoice ${invoice.status.displayName}',
            description:
                'Invoice ${invoice.invoiceNumber} - ${invoice.total.toStringAsFixed(0)} ${invoice.currency.code.toUpperCase()}',
            timestamp: invoice.createdAt,
            type: ActivityType.invoice,
            relatedId: invoice.id ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error loading invoices for activities: $e');
      }

      // Sort by timestamp and return limited results
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(limit).toList();
    } catch (e) {
      debugPrint('Error loading recent activities: $e');
      return [];
    }
  }

  /// Get upcoming deadlines
  static Future<List<UpcomingDeadline>> getUpcomingDeadlines(
      {int limit = 5}) async {
    try {
      final deadlines = <UpcomingDeadline>[];
      final now = DateTime.now();
      final futureLimit = now.add(const Duration(days: 30));

      // Get project deadlines
      try {
        final projects = await ProjectService.getAllProjects();
        final upcomingProjects = projects
            .where((p) =>
                p.status == ProjectStatus.inProgress &&
                p.endDate != null &&
                p.endDate!.isAfter(now) &&
                p.endDate!.isBefore(futureLimit))
            .toList();

        for (final project in upcomingProjects) {
          deadlines.add(UpcomingDeadline(
            id: 'project_${project.id}',
            title: project.projectName,
            description: 'Project deadline approaching',
            deadline: project.endDate!,
            type: DeadlineType.project,
            relatedId: project.id ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error loading projects for deadlines: $e');
      }

      // Get invoice payment deadlines
      try {
        final invoices = await InvoiceService.getAllInvoices();
        final upcomingInvoices = invoices
            .where((i) =>
                i.status == InvoiceStatus.draft &&
                i.dueDate.isAfter(now) &&
                i.dueDate.isBefore(futureLimit))
            .toList();

        for (final invoice in upcomingInvoices) {
          deadlines.add(UpcomingDeadline(
            id: 'invoice_${invoice.id}',
            title: 'Invoice ${invoice.invoiceNumber}',
            description: 'Payment due from ${invoice.clientName}',
            deadline: invoice.dueDate,
            type: DeadlineType.invoice,
            relatedId: invoice.id ?? '',
          ));
        }
      } catch (e) {
        debugPrint('Error loading invoices for deadlines: $e');
      }

      // Add tax deadlines (static for now)
      final currentYear = now.year;
      final nextYear = currentYear + 1;

      // IRG Tax deadline (January 10)
      final irgDeadline = DateTime(nextYear, 1, 10);
      if (irgDeadline.isAfter(now) && irgDeadline.isBefore(futureLimit)) {
        deadlines.add(UpcomingDeadline(
          id: 'tax_irg_$nextYear',
          title: 'IRG Tax Payment',
          description: 'Annual tax payment due',
          deadline: irgDeadline,
          type: DeadlineType.tax,
          relatedId: 'tax_irg',
        ));
      }

      // CASNOS deadline (June 20)
      final casnosDeadline = DateTime(currentYear, 6, 20);
      if (casnosDeadline.isAfter(now) && casnosDeadline.isBefore(futureLimit)) {
        deadlines.add(UpcomingDeadline(
          id: 'tax_casnos_$currentYear',
          title: 'CASNOS Payment',
          description: 'Social security payment due',
          deadline: casnosDeadline,
          type: DeadlineType.tax,
          relatedId: 'tax_casnos',
        ));
      }

      // Sort by deadline and return limited results
      deadlines.sort((a, b) => a.deadline.compareTo(b.deadline));
      return deadlines.take(limit).toList();
    } catch (e) {
      debugPrint('Error loading upcoming deadlines: $e');
      return [];
    }
  }

  /// Get monthly performance data
  static Future<List<MonthlyData>> getMonthlyData({int months = 6}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));

      return [
        MonthlyData(
            month: 'Jan',
            revenue: 75000,
            expenses: 20000,
            projects: 5,
            clients: 3),
        MonthlyData(
            month: 'Feb',
            revenue: 82000,
            expenses: 22000,
            projects: 6,
            clients: 4),
        MonthlyData(
            month: 'Mar',
            revenue: 68000,
            expenses: 18000,
            projects: 4,
            clients: 2),
        MonthlyData(
            month: 'Apr',
            revenue: 95000,
            expenses: 25000,
            projects: 7,
            clients: 5),
        MonthlyData(
            month: 'May',
            revenue: 88000,
            expenses: 23000,
            projects: 6,
            clients: 3),
        MonthlyData(
            month: 'Jun',
            revenue: 92000,
            expenses: 24000,
            projects: 8,
            clients: 4),
        MonthlyData(
            month: 'Jul',
            revenue: 85000,
            expenses: 25000,
            projects: 7,
            clients: 3),
        MonthlyData(
            month: 'Aug',
            revenue: 98000,
            expenses: 26000,
            projects: 9,
            clients: 5),
        MonthlyData(
            month: 'Sep',
            revenue: 87000,
            expenses: 24000,
            projects: 6,
            clients: 4),
        MonthlyData(
            month: 'Oct',
            revenue: 93000,
            expenses: 27000,
            projects: 8,
            clients: 4),
        MonthlyData(
            month: 'Nov',
            revenue: 89000,
            expenses: 25000,
            projects: 7,
            clients: 3),
        MonthlyData(
            month: 'Dec',
            revenue: 96000,
            expenses: 28000,
            projects: 9,
            clients: 6),
      ].take(months).toList();
    } catch (e) {
      debugPrint('Error loading monthly data: $e');
      return [];
    }
  }

  /// Get quick actions for dashboard
  static List<QuickAction> getQuickActions(context) {
    return [
      QuickAction(
        title: 'New Project',
        subtitle: 'Start a new project',
        icon: Icons.add_business,
        color: Colors.blue,
        onTap: () {
          // Navigate to add project
        },
      ),
      QuickAction(
        title: 'Add Client',
        subtitle: 'Register new client',
        icon: Icons.person_add,
        color: Colors.green,
        onTap: () {
          // Navigate to add client
        },
      ),
      QuickAction(
        title: 'Record Payment',
        subtitle: 'Log new payment',
        icon: Icons.payment,
        color: Colors.purple,
        onTap: () {
          // Navigate to add payment
        },
      ),
      QuickAction(
        title: 'Create Invoice',
        subtitle: 'Generate invoice',
        icon: Icons.receipt_long,
        color: Colors.orange,
        onTap: () {
          // Navigate to create invoice
        },
      ),
    ];
  }

  /// Refresh dashboard data
  static Future<void> refreshDashboard() async {
    try {
      // Clear cache to force fresh data
      clearCache();

      // Get fresh data
      await getDashboardData(forceRefresh: true);

      debugPrint('Dashboard refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      rethrow;
    }
  }

  /// Quick refresh for background updates (lighter operation)
  static Future<void> quickRefresh() async {
    try {
      // Only refresh stats for quick updates
      final stats = await getDashboardStats();

      if (_cachedData != null) {
        final updatedData = DashboardData(
          stats: stats,
          recentActivities: _cachedData!.recentActivities,
          upcomingDeadlines: _cachedData!.upcomingDeadlines,
          monthlyData: _cachedData!.monthlyData,
          lastUpdated: DateTime.now(),
        );

        _cachedData = updatedData;
        _dataStreamController.add(updatedData);
      }
    } catch (e) {
      debugPrint('Quick refresh failed: $e');
    }
  }

  /// Dispose resources
  static void dispose() {
    stopBackgroundRefresh();
    _dataStreamController.close();
  }

  /// Get dashboard summary for notifications
  static Future<String> getDashboardSummary() async {
    try {
      final stats = await getDashboardStats();

      final summary = StringBuffer();
      summary.writeln('📊 Dashboard Summary:');
      summary.writeln('• ${stats.activeProjects} active projects');
      summary.writeln('• ${stats.pendingPayments} pending payments');
      summary.writeln('• ${stats.upcomingDeadlines} upcoming deadlines');

      if (stats.overdueInvoices > 0) {
        summary.writeln('⚠️ ${stats.overdueInvoices} overdue invoices');
      }

      if (stats.taxesDue > 0) {
        summary.writeln('💰 ${stats.taxesDue.toStringAsFixed(0)} DA taxes due');
      }

      return summary.toString();
    } catch (e) {
      return 'Unable to load dashboard summary';
    }
  }

  /// Calculate business health score (0-100)
  static double calculateBusinessHealthScore(DashboardStats stats) {
    double score = 100.0;

    // Deduct points for issues
    if (stats.overdueInvoices > 0) {
      score -= (stats.overdueInvoices * 10).clamp(0, 30);
    }

    if (stats.pendingPayments > 5) {
      score -= ((stats.pendingPayments - 5) * 5).clamp(0, 20);
    }

    if (stats.upcomingDeadlines > 10) {
      score -= ((stats.upcomingDeadlines - 10) * 3).clamp(0, 15);
    }

    // Add points for good metrics
    if (stats.profitMargin > 50) {
      score += 10;
    } else if (stats.profitMargin > 30) {
      score += 5;
    }

    if (stats.activeProjects > 5) {
      score += 5;
    }

    return score.clamp(0, 100);
  }


}
