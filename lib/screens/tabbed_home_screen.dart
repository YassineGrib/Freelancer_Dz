import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'dashboard_tab.dart';
import 'menu_tab.dart';
import 'all_deadlines_screen.dart';
import '../widgets/notification_badge.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class TabbedHomeScreen extends StatefulWidget {
  const TabbedHomeScreen({super.key});

  @override
  State<TabbedHomeScreen> createState() => _TabbedHomeScreenState();
}

class _TabbedHomeScreenState extends State<TabbedHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  List<UpcomingDeadline> _upcomingDeadlines = [];
  bool _isLoadingDeadlines = false;
  StreamSubscription<DashboardData>? _dashboardSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUpcomingDeadlines();

    // Add listener to refresh deadlines when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadUpcomingDeadlines();
      }
    });

    // Subscribe to dashboard data stream for automatic updates
    _dashboardSubscription =
        DashboardService.dataStream.listen((dashboardData) {
      if (mounted) {
        setState(() {
          _upcomingDeadlines = dashboardData.upcomingDeadlines;
          _isLoadingDeadlines = false;
        });
      }
    });

    // Add lifecycle observer to refresh when app comes to foreground
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashboardSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh deadlines when app comes back to foreground
      _loadUpcomingDeadlines();
    }
  }

  Future<void> _loadUpcomingDeadlines() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDeadlines = true;
    });

    try {
      final deadlines = await DashboardService.getUpcomingDeadlines(limit: 50);
      if (mounted) {
        setState(() {
          _upcomingDeadlines = deadlines;
          _isLoadingDeadlines = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _upcomingDeadlines = [];
          _isLoadingDeadlines = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'FreeLancer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false, // Move title to the left
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Deadlines Notification Icon with Badge
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllDeadlinesScreen(),
                ),
              );
              // Refresh deadlines when returning from deadlines screen
              if (result == true) {
                _loadUpcomingDeadlines();
              }
            },
            icon: NotificationBadge(
              deadlines: _upcomingDeadlines,
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ),
            tooltip: 'View Deadlines',
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.chartLine,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.dashboard,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.bars,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.menu,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardTab(),
          MenuTab(),
        ],
      ),
    );
  }
}
