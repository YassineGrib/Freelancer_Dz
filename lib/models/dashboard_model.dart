import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../l10n/app_localizations.dart';

class DashboardStats {
  final int totalClients;
  final int activeProjects;
  final int completedProjects;
  final int totalProjects; // New: Total projects regardless of status
  final int unpaidProjects; // New: Projects that haven't been fully paid
  final double unpaidProjectsAmount; // New: Total amount of unpaid projects
  final int pendingPayments;
  final double totalRevenue;
  final double monthlyRevenue;
  final double totalExpenses;
  final double monthlyExpenses;
  final int overdueInvoices;
  final int upcomingDeadlines;
  final double taxesDue;
  final int unreadNotifications;

  DashboardStats({
    this.totalClients = 0,
    this.activeProjects = 0,
    this.completedProjects = 0,
    this.totalProjects = 0,
    this.unpaidProjects = 0,
    this.unpaidProjectsAmount = 0.0,
    this.pendingPayments = 0,
    this.totalRevenue = 0.0,
    this.monthlyRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.monthlyExpenses = 0.0,
    this.overdueInvoices = 0,
    this.upcomingDeadlines = 0,
    this.taxesDue = 0.0,
    this.unreadNotifications = 0,
  });

  double get netIncome => totalRevenue - totalExpenses;
  double get monthlyNetIncome => monthlyRevenue - monthlyExpenses;
  double get profitMargin =>
      totalRevenue > 0 ? (netIncome / totalRevenue) * 100 : 0;
}

class RecentActivity {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final ActivityType type;
  final String? relatedId;

  RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.relatedId,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

enum ActivityType {
  project,
  payment,
  client,
  invoice,
  expense,
  tax,
}

extension ActivityTypeExtension on ActivityType {
  IconData get icon {
    switch (this) {
      case ActivityType.project:
        return Icons.work;
      case ActivityType.payment:
        return Icons.payment;
      case ActivityType.client:
        return Icons.person;
      case ActivityType.invoice:
        return Icons.receipt;
      case ActivityType.expense:
        return Icons.money_off;
      case ActivityType.tax:
        return Icons.account_balance;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.project:
        return Colors.blue;
      case ActivityType.payment:
        return Colors.green;
      case ActivityType.client:
        return Colors.purple;
      case ActivityType.invoice:
        return Colors.orange;
      case ActivityType.expense:
        return Colors.red;
      case ActivityType.tax:
        return Colors.indigo;
    }
  }
}

class QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class UpcomingDeadline {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final DeadlineType type;
  final String? relatedId;

  UpcomingDeadline({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.type,
    this.relatedId,
  });

  int get daysUntil => deadline.difference(DateTime.now()).inDays;
  bool get isOverdue => deadline.isBefore(DateTime.now());
  bool get isToday => daysUntil == 0;
  bool get isTomorrow => daysUntil == 1;

  String formattedDeadline(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (isOverdue) {
      return loc.overdueBy(-daysUntil);
    } else if (isToday) {
      return loc.dueToday;
    } else if (isTomorrow) {
      return loc.dueTomorrow;
    } else {
      return loc.dueIn(daysUntil);
    }
  }



  Color get urgencyColor {
    if (isOverdue) return Colors.red;
    if (daysUntil < 3) return Colors.red;
    if (daysUntil < 7) return Colors.orange;
    return Colors.green;
  }
}

enum DeadlineType {
  project,
  invoice,
  tax,
  payment,
}

extension DeadlineTypeExtension on DeadlineType {
  IconData get icon {
    switch (this) {
      case DeadlineType.project:
        return Icons.work;
      case DeadlineType.invoice:
        return Icons.receipt;
      case DeadlineType.tax:
        return Icons.account_balance;
      case DeadlineType.payment:
        return Icons.payment;
    }
  }

  String displayName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case DeadlineType.project:
        return loc.project;
      case DeadlineType.invoice:
        return loc.invoice;
      case DeadlineType.tax:
        return loc.tax;
      case DeadlineType.payment:
        return loc.payment;
    }
  }
}


class MonthlyData {
  final String month;
  final double revenue;
  final double expenses;
  final int projects;
  final int clients;

  MonthlyData({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.projects,
    required this.clients,
  });

  double get profit => revenue - expenses;
}

class DashboardData {
  final DashboardStats stats;
  final List<RecentActivity> recentActivities;
  final List<UpcomingDeadline> upcomingDeadlines;
  final List<MonthlyData> monthlyData;
  final DateTime lastUpdated;

  DashboardData({
    required this.stats,
    required this.recentActivities,
    required this.upcomingDeadlines,
    required this.monthlyData,
    required this.lastUpdated,
  });

  factory DashboardData.empty() {
    return DashboardData(
      stats: DashboardStats(),
      recentActivities: [],
      upcomingDeadlines: [],
      monthlyData: [],
      lastUpdated: DateTime.now(),
    );
  }

  // Sample data for demonstration
  factory DashboardData.sample() {
    final now = DateTime.now();

    return DashboardData(
      stats: DashboardStats(
        totalClients: 15,
        activeProjects: 8,
        completedProjects: 23,
        totalProjects: 31, // 8 active + 23 completed
        unpaidProjects: 3,
        unpaidProjectsAmount: 45000.0,
        pendingPayments: 5,
        totalRevenue: 450000.0,
        monthlyRevenue: 85000.0,
        totalExpenses: 120000.0,
        monthlyExpenses: 25000.0,
        overdueInvoices: 2,
        upcomingDeadlines: 4,
        taxesDue: 15000.0,
        unreadNotifications: 7,
      ),
      recentActivities: [
        RecentActivity(
          id: '1',
          title: 'Payment Received',
          description: 'Payment of 50,000 DA from Client ABC',
          timestamp: now.subtract(const Duration(hours: 2)),
          type: ActivityType.payment,
          relatedId: 'payment_1',
        ),
        RecentActivity(
          id: '2',
          title: 'Project Completed',
          description: 'E-commerce Website project marked as completed',
          timestamp: now.subtract(const Duration(hours: 5)),
          type: ActivityType.project,
          relatedId: 'project_1',
        ),
        RecentActivity(
          id: '3',
          title: 'New Client Added',
          description: 'Client XYZ Company added to the system',
          timestamp: now.subtract(const Duration(days: 1)),
          type: ActivityType.client,
          relatedId: 'client_1',
        ),
        RecentActivity(
          id: '4',
          title: 'Invoice Generated',
          description: 'Invoice #INV-003 generated for Mobile App project',
          timestamp: now.subtract(const Duration(days: 2)),
          type: ActivityType.invoice,
          relatedId: 'invoice_3',
        ),
      ],
      upcomingDeadlines: [
        UpcomingDeadline(
          id: '1',
          title: 'Mobile App Design',
          description: 'Project deadline approaching',
          deadline: now.add(const Duration(days: 2)),
          type: DeadlineType.project,
          relatedId: 'project_2',
        ),
        UpcomingDeadline(
          id: '2',
          title: 'Invoice #INV-002',
          description: 'Payment due from Client DEF',
          deadline: now.add(const Duration(days: 5)),
          type: DeadlineType.invoice,
          relatedId: 'invoice_2',
        ),
        UpcomingDeadline(
          id: '3',
          title: 'IRG Tax Payment',
          description: 'Annual tax payment due',
          deadline: DateTime(now.year + 1, 1, 10),
          type: DeadlineType.tax,
          relatedId: 'tax_irg',
        ),
      ],
      monthlyData: [
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
      ],
      lastUpdated: now,
    );
  }
}
