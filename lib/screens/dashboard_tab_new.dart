import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await DashboardService.getDashboardData();
      setState(() {
        _dashboardData = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await DashboardService.refreshDashboard();
      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
              FontAwesomeIcons.exclamationTriangle,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with refresh button
            _buildHeader(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Business Health Score
            _buildHealthScoreCard(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Key Statistics Grid
            _buildStatsGrid(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Quick Actions
            _buildQuickActions(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Financial Overview
            _buildFinancialOverview(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Recent Activities
            _buildRecentActivities(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Upcoming Deadlines
            _buildUpcomingDeadlines(),
          ],
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
        IconButton(
          onPressed: _isRefreshing ? null : _refreshDashboard,
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(FontAwesomeIcons.arrowsRotate),
          tooltip: 'Refresh Dashboard',
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard() {
    final healthScore =
        DashboardService.calculateBusinessHealthScore(_dashboardData!.stats);
    final scoreColor = healthScore >= 80
        ? Colors.green
        : healthScore >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                '${healthScore.round()}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Health Score',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getHealthMessage(healthScore),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _dashboardData!.stats;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Active Projects',
          stats.activeProjects.toString(),
          FontAwesomeIcons.briefcase,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Clients',
          stats.totalClients.toString(),
          FontAwesomeIcons.users,
          Colors.green,
        ),
        _buildStatCard(
          'Monthly Revenue',
          _formatCurrency(stats.monthlyRevenue),
          FontAwesomeIcons.chartLine,
          Colors.purple,
        ),
        _buildStatCard(
          'Pending Payments',
          stats.pendingPayments.toString(),
          FontAwesomeIcons.clock,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable row for compact design
        SizedBox(
          height: _getQuickActionHeight(),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildQuickActionChip(
                'New Project',
                FontAwesomeIcons.plus,
                Colors.blue,
                () => _showComingSoon('New Project'),
              ),
              _buildQuickActionChip(
                'Add Client',
                FontAwesomeIcons.userPlus,
                Colors.green,
                () => _showComingSoon('Add Client'),
              ),
              _buildQuickActionChip(
                'Record Payment',
                FontAwesomeIcons.creditCard,
                Colors.purple,
                () => _showComingSoon('Record Payment'),
              ),
              _buildQuickActionChip(
                'Create Invoice',
                FontAwesomeIcons.fileInvoice,
                Colors.orange,
                () => _showComingSoon('Create Invoice'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to get responsive height for quick actions
  double _getQuickActionHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 60.0;
    } else if (screenWidth > 400) {
      return 56.0;
    } else {
      return 52.0;
    }
  }

  Widget _buildQuickActionChip(
      String title, IconData icon, Color color, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 400;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 20 : 16,
              vertical: isLargeScreen ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isLargeScreen ? 24 : 20,
                  height: isLargeScreen ? 24 : 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: isLargeScreen ? 14 : 12,
                    color: color,
                  ),
                ),
                SizedBox(width: isLargeScreen ? 10 : 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isLargeScreen
                        ? AppConstants.textMedium
                        : AppConstants.textSmall,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final stats = _dashboardData!.stats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFinancialRow('Total Revenue', stats.totalRevenue, Colors.green),
          const SizedBox(height: 12),
          _buildFinancialRow('Total Expenses', stats.totalExpenses, Colors.red),
          const SizedBox(height: 12),
          _buildFinancialRow('Net Income', stats.netIncome, Colors.blue),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profit Margin',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${stats.profitMargin.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.bold,
                    color: stats.profitMargin > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textMedium,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textMedium,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    final activities = _dashboardData!.recentActivities.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToAllActivities(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        else
          ...activities
              .map((activity) => _buildActivityCard(activity))
              .toList(),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Deadlines',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showComingSoon('View All Deadlines'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        else
          ...deadlines.map((deadline) => _buildDeadlineCard(deadline)).toList(),
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
              deadline.formattedDeadline(context),
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

  String _getHealthMessage(double score) {
    if (score >= 90) return 'Excellent! Your business is thriving.';
    if (score >= 80) return 'Great! Keep up the good work.';
    if (score >= 70) return 'Good! Some areas need attention.';
    if (score >= 60) return 'Fair. Consider improving key metrics.';
    return 'Needs attention. Focus on critical issues.';
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
