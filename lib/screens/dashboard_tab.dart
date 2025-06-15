import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/responsive_utils.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../l10n/app_localizations.dart';
import 'add_edit_project_screen.dart';
import 'add_edit_client_screen.dart';
import 'add_edit_payment_screen.dart';
import 'add_edit_invoice_screen.dart';
import 'all_deadlines_screen.dart';
import 'all_activities_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isYearlyView = false; // Toggle between monthly and yearly view
  StreamSubscription<DashboardData>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  void _initializeDashboard() {
    // Check for cached data first for instant display
    final cachedData = DashboardService.getCachedData();
    if (cachedData != null) {
      setState(() {
        _dashboardData = cachedData;
        _isLoading = false;
      });
    }

    // Subscribe to data stream for real-time updates
    _dataSubscription = DashboardService.dataStream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _dashboardData = data;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
          _showErrorSnackBar(
              '${AppLocalizations.of(context)?.errorLoadingDashboard ?? 'Error loading dashboard'}: $error');
        }
      },
    );

    // Load fresh data
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Only show loading if we don't have cached data
    if (_dashboardData == null) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await DashboardService.getDashboardData();
      // Data will be updated via stream subscription
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            '${AppLocalizations.of(context)?.errorLoadingDashboard ?? 'Error loading dashboard'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await DashboardService.refreshDashboard();
      // Data will be updated via stream subscription

      // Notify parent to refresh deadlines in title bar
      if (mounted && context.findAncestorStateOfType<State>() != null) {
        // Try to refresh parent if it has the method
        try {
          final parentState = context.findAncestorStateOfType<State>();
          if (parentState != null && parentState.mounted) {
            // This will trigger a rebuild of the parent which should refresh deadlines
            (parentState as dynamic)._loadUpcomingDeadlines?.call();
          }
        } catch (e) {
          // Ignore if parent doesn't have the method
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            '${AppLocalizations.of(context)?.errorRefreshingDashboard ?? 'Error refreshing dashboard'}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading only if we have no data at all
    if (_isLoading && _dashboardData == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.triangleExclamation,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.failedToLoadDashboard ??
                  'Failed to load dashboard',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveUtils.getMaxContentWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with refresh button
                _buildHeader(),
                const SizedBox(height: AppConstants.paddingMedium),

                // Monthly Performance Overview
                _buildMonthlyPerformanceCard(),
                const SizedBox(height: AppConstants.paddingMedium),

                // Quick Actions
                _buildQuickActions(),
                // const SizedBox(height: AppConstants.paddingMedium),

                // Recent Activities
                _buildRecentActivities(),
                // const SizedBox(height: AppConstants.paddingMedium),

                // Upcoming Deadlines
                _buildUpcomingDeadlines(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textXLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: ${_formatTime(_dashboardData!.lastUpdated)}',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        // Background loading indicator
        if (_isLoading && _dashboardData != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),

        IconButton(
          onPressed: _isRefreshing ? null : _refreshDashboard,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 0),
                )
              : const Icon(FontAwesomeIcons.arrowsRotate),
          tooltip: 'Refresh Dashboard',
        ),
      ],
    );
  }

  // Build Period Toggle Switch
  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('This Month', !_isYearlyView),
          _buildToggleOption('This Year', _isYearlyView),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearlyView = text == 'This Year';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyPerformanceCard() {
    final stats = _dashboardData!.stats;

    // Use yearly or monthly data based on toggle
    final revenue = _isYearlyView ? stats.totalRevenue : stats.monthlyRevenue;
    final expenses =
        _isYearlyView ? stats.totalExpenses : stats.monthlyExpenses;
    final netIncome = revenue - expenses;
    final profitMargin = revenue > 0 ? (netIncome / revenue) * 100 : 0;

    final revenueProgress =
        revenue > 0 ? (revenue / (revenue + expenses)) : 0.0;
    final expenseProgress =
        expenses > 0 ? (expenses / (revenue + expenses)) : 0.0;

    // Determine profit status color for small indicators
    Color profitStatusColor = AppColors.primary;
    if (profitMargin > 50) {
      profitStatusColor = Colors.green;
    } else if (profitMargin > 30) {
      profitStatusColor = Colors.blue;
    } else if (profitMargin > 10) {
      profitStatusColor = Colors.orange;
    } else {
      profitStatusColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Simple like other sections
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isYearlyView ? 'Yearly Performance' : 'Monthly Performance',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Toggle and Profit in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Toggle Switch
              _buildPeriodToggle(),
              // Profit Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: profitStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: profitStatusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${profitMargin.toStringAsFixed(1)}% Profit',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    fontWeight: FontWeight.w600,
                    color: profitStatusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Revenue and Expenses Overview
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revenue',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(revenue),
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: revenueProgress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 6,
                    ),

                    const SizedBox(height: 12),

                    // Expenses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expenses',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(expenses),
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: expenseProgress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.red),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Active Projects Circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stats.activeProjects}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Net Income
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.chartLine,
                        size: 16,
                        color: netIncome >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Net Income',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(netIncome),
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.bold,
                      color: netIncome >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Unpaid Projects
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.triangleExclamation,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unpaid Projects',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${stats.unpaidProjects} (${_formatCurrency(stats.unpaidProjectsAmount)})',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              FontAwesomeIcons.bolt,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.quickActions ?? 'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Clean container with 2-items-per-row layout
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Row 1: New Project + Add Client
              _buildQuickActionRow(
                leftTitle:
                    AppLocalizations.of(context)?.newProject ?? 'New Project',
                leftIcon: FontAwesomeIcons.plus,
                leftColor: Colors.blue,
                leftAction: () => _navigateToAddProject(),
                rightTitle:
                    AppLocalizations.of(context)?.addClient ?? 'Add Client',
                rightIcon: FontAwesomeIcons.userPlus,
                rightColor: Colors.green,
                rightAction: () => _navigateToAddClient(),
                isFirst: true,
              ),
              // Row 2: Record Payment + Create Invoice
              _buildQuickActionRow(
                leftTitle: AppLocalizations.of(context)?.recordPayment ??
                    'Record Payment',
                leftIcon: FontAwesomeIcons.creditCard,
                leftColor: Colors.purple,
                leftAction: () => _navigateToAddPayment(),
                rightTitle: AppLocalizations.of(context)?.createInvoice ??
                    'Create Invoice',
                rightIcon: FontAwesomeIcons.fileInvoice,
                rightColor: Colors.orange,
                rightAction: () => _navigateToAddInvoice(),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionRow({
    required String leftTitle,
    required IconData leftIcon,
    required Color leftColor,
    required VoidCallback leftAction,
    required String rightTitle,
    required IconData rightIcon,
    required Color rightColor,
    required VoidCallback rightAction,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          // Left action item
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: leftAction,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        leftIcon,
                        size: 16,
                        color: leftColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          leftTitle,
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          // Right action item
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: rightAction,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        rightIcon,
                        size: 16,
                        color: rightColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rightTitle,
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = _dashboardData!.recentActivities.take(5).toList();
    final hasSampleData =
        activities.isNotEmpty && activities.first.id.startsWith('sample');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.clockRotateLeft,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.recentActivities ??
                      'Recent Activities',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (hasSampleData) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.demo ?? 'Demo',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: () => _navigateToAllActivities(),
              child: Text(AppLocalizations.of(context)?.viewAll ?? 'View All'),
            ),
          ],
        ),
        // const SizedBox(height: 16),
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No recent activities',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else ...[
          if (hasSampleData)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.showingDemoData ??
                          'Showing demo data. Start adding projects, payments, and invoices to see real activities.',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ...activities.map((activity) => _buildActivityCard(activity)),
        ],
      ],
    );
  }

  Widget _buildActivityCard(RecentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.type.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              activity.type.icon,
              size: 20,
              color: activity.type.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.timeAgo,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines() {
    final deadlines = _dashboardData!.upcomingDeadlines.take(3).toList();
    final hasSampleData =
        deadlines.isNotEmpty && deadlines.first.id.startsWith('sample');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.calendarDays,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.upcomingDeadlines ??
                      'Upcoming Deadlines',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (hasSampleData) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.grey.shade700.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.demo ?? 'Demo',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: () => _navigateToAllDeadlines(),
              child: Text(AppLocalizations.of(context)?.viewAll ?? 'View All'),
            ),
          ],
        ),
        //  const SizedBox(height: 16),
        if (deadlines.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No upcoming deadlines',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else ...[
          if (hasSampleData)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade700.withValues(alpha: 0.05),
                border: Border.all(
                    color: Colors.grey.shade700.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.showingDemoDeadlines ??
                          'Showing demo deadlines. Add real projects and invoices to track actual deadlines.',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ...deadlines.map((deadline) => _buildDeadlineCard(deadline)),
        ],
      ],
    );
  }

  Widget _buildDeadlineCard(UpcomingDeadline deadline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: deadline.urgencyColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: deadline.urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              deadline.type.icon,
              size: 20,
              color: deadline.urgencyColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deadline.description,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deadline.urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              deadline.formattedDeadline,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                fontWeight: FontWeight.w600,
                color: deadline.urgencyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Methods
  void _navigateToAddProject() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProjectScreen(),
      ),
    ).then((_) {
      // Refresh dashboard when returning from add project screen
      _refreshDashboard();
    });
  }

  void _navigateToAddClient() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditClientScreen(),
      ),
    ).then((_) {
      // Refresh dashboard when returning from add client screen
      _refreshDashboard();
    });
  }

  void _navigateToAddPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPaymentScreen(),
      ),
    ).then((_) {
      // Refresh dashboard when returning from add payment screen
      _refreshDashboard();
    });
  }

  void _navigateToAddInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditInvoiceScreen(),
      ),
    ).then((_) {
      // Refresh dashboard when returning from add invoice screen
      _refreshDashboard();
    });
  }

  void _navigateToAllDeadlines() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllDeadlinesScreen(),
      ),
    ).then((_) {
      // Refresh dashboard when returning from all deadlines screen
      _refreshDashboard();
    });
  }

  void _navigateToAllActivities() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllActivitiesScreen(),
      ),
    ).then((_) {
      // Refresh dashboard when returning from all activities screen
      _refreshDashboard();
    });
  }

  // Helper Methods
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M DA';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K DA';
    } else {
      return '${amount.toStringAsFixed(0)} DA';
    }
  }
}
