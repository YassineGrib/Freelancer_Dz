import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../services/onboarding_service.dart';
import '../services/business_profile_service.dart';
import 'business_profile_settings_screen.dart';
import 'tabbed_home_screen.dart';

class BusinessProfileOnboardingScreen extends StatefulWidget {
  const BusinessProfileOnboardingScreen({super.key});

  @override
  State<BusinessProfileOnboardingScreen> createState() =>
      _BusinessProfileOnboardingScreenState();
}

class _BusinessProfileOnboardingScreenState
    extends State<BusinessProfileOnboardingScreen> {
  final OnboardingService _onboardingService = OnboardingService.instance;
  final BusinessProfileService _businessProfileService =
      BusinessProfileService.instance;
  bool _isLoading = false;
  bool _isCheckingProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    setState(() => _isCheckingProfile = true);

    try {
      final isComplete =
          await _businessProfileService.isBusinessProfileComplete();
      if (isComplete && mounted) {
        // Profile is already complete, mark onboarding as done and navigate to main app
        await _onboardingService.completeBusinessProfileOnboarding();
        _navigateToMainApp();
      }
    } catch (e) {
      print('Error checking profile completion: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingProfile = false);
      }
    }
  }

  Future<void> _navigateToBusinessProfile() async {
    setState(() => _isLoading = true);

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const BusinessProfileSettingsScreen(),
        ),
      );

      if (result == true && mounted) {
        // Profile was saved, check if it's now complete
        final isComplete =
            await _businessProfileService.isBusinessProfileComplete();
        if (isComplete) {
          await _onboardingService.completeBusinessProfileOnboarding();
          _navigateToMainApp();
        } else {
          // Show message that more fields are required
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete all required fields to continue'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const TabbedHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Welcome header
              const Center(
                child: Icon(
                  FontAwesomeIcons.building,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Welcome to Freelancer Mobile!',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textTitle,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Complete Your Business Profile',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textLarge,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Information card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.exclamationTriangle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Required Setup',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'To generate accurate reports and manage your freelance business effectively, you need to complete your business profile with the following information:',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildRequiredFields(),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              CustomButton(
                text: 'Complete Business Profile',
                onPressed: _navigateToBusinessProfile,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              Text(
                'You cannot access the main app features until your business profile is complete.',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textSmall,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRequiredFields() {
    final fields = [
      'Company Name',
      'Business Email',
      'Phone Number',
      'Business Address',
      'City, State & Postal Code',
      'Country',
      'NiF ID',
      'Card Number',
    ];

    return fields
        .map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.check,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    field,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
