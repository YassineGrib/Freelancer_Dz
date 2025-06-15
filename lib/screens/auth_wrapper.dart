import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import 'login_screen.dart';
import 'tabbed_home_screen.dart';
import 'business_profile_onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final OnboardingService _onboardingService = OnboardingService.instance;
  bool _isCheckingOnboarding = false;
  bool _needsBusinessProfileOnboarding = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    // Check onboarding status on initial load if user is already logged in
    if (AuthService.isLoggedIn) {
      _checkOnboardingStatus();
    }
  }

  void _setupAuthListener() {
    AuthService.authStateChanges.listen((Map<String, dynamic>? user) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild when auth state changes
        });

        // Check onboarding status when user logs in
        if (user != null) {
          _checkOnboardingStatus();
        }
      }
    });
  }

  Future<void> _checkOnboardingStatus() async {
    if (!AuthService.isLoggedIn) return;

    setState(() => _isCheckingOnboarding = true);

    try {
      final needsOnboarding =
          await _onboardingService.needsBusinessProfileOnboarding();
      if (mounted) {
        setState(() {
          _needsBusinessProfileOnboarding = needsOnboarding;
          _isCheckingOnboarding = false;
        });
      }
    } catch (e) {
      print('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _needsBusinessProfileOnboarding = false;
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show login screen if not logged in
    if (!AuthService.isLoggedIn) {
      return const LoginScreen();
    }

    // Show loading while checking onboarding status
    if (_isCheckingOnboarding) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show business profile onboarding if needed
    if (_needsBusinessProfileOnboarding) {
      return const BusinessProfileOnboardingScreen();
    }

    // Show main app
    return const TabbedHomeScreen();
  }
}
