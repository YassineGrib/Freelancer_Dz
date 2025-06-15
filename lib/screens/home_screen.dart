import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
// import '../services/connectivity_service.dart'; // Disabled for local-only app
// import '../services/offline_service.dart'; // Disabled for local-only app
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'all_deadlines_screen.dart';
import '../widgets/notification_badge.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  List<UpcomingDeadline> _upcomingDeadlines = [];
  bool _isLoadingDeadlines = false;
  StreamSubscription<DashboardData>? _dashboardSubscription;
  // Connectivity services disabled for local-only app
  // final ConnectivityService _connectivityService = ConnectivityService();
  // final OfflineService _offlineService = OfflineService();

  @override
  void initState() {
    super.initState();
    _loadUpcomingDeadlines();

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

    // _initializeOfflineServices(); // Disabled
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    // _connectivityService.removeListener(_onConnectivityChanged); // Disabled
    super.dispose();
  }

  // Future<void> _initializeOfflineServices() async {
  //   await _connectivityService.initialize();
  //   await _offlineService.initialize();
  // }

  // void _onConnectivityChanged() {
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }

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

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);

    try {
      await AuthService.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error signing out: ${AuthService.getErrorMessage(e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

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
        leading: const SizedBox(), // Remove back button
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

          // Sign Out Icon
          IconButton(
            onPressed: _handleSignOut,
            icon: const Icon(
              FontAwesomeIcons.rightFromBracket,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textXLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?['email'] ?? 'User',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textLarge,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (user?['full_name'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!['full_name'],
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButton(
              icon: FontAwesomeIcons.briefcase,
              title: 'Find Projects',
              subtitle: 'Browse available freelance projects',
              onTap: () {
                // Navigate to projects screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Projects feature coming soon!')),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              icon: FontAwesomeIcons.user,
              title: 'My Profile',
              subtitle: 'Update your freelancer profile',
              onTap: () {
                // Navigate to profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile feature coming soon!')),
                );
              },
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              icon: FontAwesomeIcons.message,
              title: 'Messages',
              subtitle: 'Chat with clients and employers',
              onTap: () {
                // Navigate to messages screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Messages feature coming soon!')),
                );
              },
            ),

            const Spacer(),

            // Sign Out Button
            CustomButton(
              text: 'Sign Out',
              onPressed: _handleSignOut,
              isLoading: _isLoading,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
