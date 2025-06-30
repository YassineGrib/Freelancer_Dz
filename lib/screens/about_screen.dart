import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freelancer_mobile/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.about,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textXLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Logo and Info
          _buildAppInfoSection(),
          const SizedBox(height: 24),

          // App Details
          _buildAppDetailsCard(),
          const SizedBox(height: 16),

          // Developer Info
          _buildDeveloperCard(),
          const SizedBox(height: 16),

          // Features
          _buildFeaturesCard(),
          const SizedBox(height: 16),

          // Legal
          _buildLegalCard(),
          const SizedBox(height: 16),

          // Contact & Support
          _buildContactCard(),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Center(
      child: Column(
        children: [
          // App Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              FontAwesomeIcons.briefcase,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // App Name
          Text(
            'FreeLancer Mobile',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // App Tagline
          Text(
            'Complete Freelance Management Solution',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Version
          Text(
            'Version 1.0.0',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Information',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('Build Number', '1'),
          _buildInfoRow('Release Date', 'December 2024'),
          _buildInfoRow('Platform', 'Android & iOS'),
          _buildInfoRow('Framework', 'Flutter'),
          _buildInfoRow('Database', 'Supabase'),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Developer',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  FontAwesomeIcons.code,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Freelancer Mobile Team',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Specialized in mobile app development',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Designed specifically for Algerian freelancers to manage their business efficiently with local tax compliance and Arabic language support.',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildFeatureItem(FontAwesomeIcons.users, 'Client Management'),
          _buildFeatureItem(FontAwesomeIcons.briefcase, 'Project Management'),
          _buildFeatureItem(FontAwesomeIcons.creditCard, 'Payment Tracking'),
          _buildFeatureItem(FontAwesomeIcons.receipt, 'Expense Management'),
          _buildFeatureItem(FontAwesomeIcons.fileInvoice, 'Invoice Generation'),
          _buildFeatureItem(FontAwesomeIcons.calculator, 'Algerian Tax Management'),
          _buildFeatureItem(FontAwesomeIcons.calendar, 'Calendar & Events'),
          _buildFeatureItem(FontAwesomeIcons.chartLine, 'Business Reports'),
          _buildFeatureItem(FontAwesomeIcons.bell, 'Smart Notifications'),
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legal',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildLegalItem(
            'Terms of Service',
            'Read our terms and conditions',
            () => _showComingSoon('Terms of Service'),
          ),
          const SizedBox(height: 12),
          _buildLegalItem(
            'Privacy Policy',
            'How we protect your data',
            () => _showComingSoon('Privacy Policy'),
          ),
          const SizedBox(height: 12),
          _buildLegalItem(
            'Open Source Licenses',
            'Third-party libraries and licenses',
            () => _showComingSoon('Open Source Licenses'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact & Support',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildContactItem(
            FontAwesomeIcons.envelope,
            'Email Support',
            'support@freelancermobile.com',
            () => _showComingSoon('Email Support'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            FontAwesomeIcons.globe,
            'Website',
            'www.freelancermobile.com',
            () => _showComingSoon('Website'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            FontAwesomeIcons.star,
            'Rate Us',
            'Rate the app on Play Store',
            () => _showComingSoon('Rate Us'),
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            FontAwesomeIcons.bug,
            'Report Bug',
            'Help us improve the app',
            () => _showComingSoon('Bug Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.fileLines,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
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
            size: 12,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
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
            size: 12,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    // This would be implemented in a real app context
    // For now, we'll just show a placeholder message
  }
}

