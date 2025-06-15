import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/locale_notifier.dart';

import '../models/settings_model.dart' as settings_model;
import '../services/settings_service.dart';

import 'profile_settings_screen.dart';
import 'app_settings_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'business_profile_settings_screen.dart';
import 'invoice_settings_screen.dart';
import 'change_password_screen.dart';
import 'email_settings_screen.dart';
import 'tax_settings_screen.dart';
import 'help_support_screen.dart';
import 'data_settings_screen.dart';

import '../l10n/app_localizations.dart';
// import 'fiscal_year_management_screen.dart'; // Removed for now

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  final SettingsService _settingsService = SettingsService();
  SupportedLanguage? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final language = await LocalizationService.instance.getCurrentLanguage();
    setState(() {
      _currentLanguage = language;
    });
  }

  Future<void> _initializeSettings() async {
    if (!_settingsService.isInitialized) {
      await _settingsService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.settings ?? 'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false, // Left alignment
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          _buildUserProfileSection(user),
          const SizedBox(height: 24),

          // Account Settings
          _buildSectionHeader(
              AppLocalizations.of(context)?.account ?? 'Account'),
          _buildSettingsCard([
            _buildSettingsItem(
              icon: FontAwesomeIcons.user,
              title: AppLocalizations.of(context)?.profileSettings ??
                  'Profile Settings',
              subtitle: AppLocalizations.of(context)?.updatePersonalInfo ??
                  'Update your personal information',
              onTap: () => _navigateToProfileSettings(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.lock,
              title: AppLocalizations.of(context)?.changePassword ??
                  'Change Password',
              subtitle: AppLocalizations.of(context)?.updateAccountPassword ??
                  'Update your account password',
              onTap: () => _navigateToChangePassword(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.envelope,
              title: AppLocalizations.of(context)?.emailSettings ??
                  'Email Settings',
              subtitle: AppLocalizations.of(context)?.manageEmailPreferences ??
                  'Manage email preferences',
              onTap: () => _navigateToEmailSettings(),
            ),
          ]),

          const SizedBox(height: 16),

          // App Settings
          _buildSectionHeader(
              AppLocalizations.of(context)?.application ?? 'Application'),
          _buildSettingsCard([
            _buildSettingsItem(
              icon: FontAwesomeIcons.palette,
              title: AppLocalizations.of(context)?.appearance ?? 'Appearance',
              subtitle: AppLocalizations.of(context)?.themeDisplaySettings ??
                  'Theme and display settings',
              onTap: () => _navigateToAppSettings(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.language,
              title: AppLocalizations.of(context)?.language ?? 'Language',
              subtitle: _currentLanguage?.displayName ?? 'English',
              onTap: () => _showLanguageDialog(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.database,
              title:
                  AppLocalizations.of(context)?.dataStorage ?? 'Data & Storage',
              subtitle: AppLocalizations.of(context)?.backupSyncSettings ??
                  'Backup and sync settings',
              onTap: () => _navigateToDataSettings(),
            ),
          ]),

          const SizedBox(height: 16),

          // Business Settings
          _buildSectionHeader(
              AppLocalizations.of(context)?.business ?? 'Business'),
          _buildSettingsCard([
            _buildSettingsItem(
              icon: FontAwesomeIcons.building,
              title: AppLocalizations.of(context)?.businessProfile ??
                  'Business Profile',
              subtitle: AppLocalizations.of(context)?.companyInfoBranding ??
                  'Company information and branding',
              onTap: () => _navigateToBusinessProfile(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.receipt,
              title: AppLocalizations.of(context)?.invoiceSettings ??
                  'Invoice Settings',
              subtitle: AppLocalizations.of(context)?.defaultInvoiceTemplates ??
                  'Default invoice templates and settings',
              onTap: () => _navigateToInvoiceSettings(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.percent,
              title:
                  AppLocalizations.of(context)?.taxSettings ?? 'Tax Settings',
              subtitle: AppLocalizations.of(context)?.taxRatesCalculation ??
                  'Tax rates and calculation preferences',
              onTap: () => _navigateToTaxSettings(),
            ),
            // Fiscal Year Management temporarily disabled
            // _buildDivider(),
            // _buildSettingsItem(
            //   icon: FontAwesomeIcons.calendarDays,
            //   title: 'Fiscal Year Management',
            //   subtitle: 'Manage fiscal years and year-end transitions',
            //   onTap: () => _navigateToFiscalYearManagement(),
            // ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.moneyBill,
              title: AppLocalizations.of(context)?.currencyRates ??
                  'Currency & Rates',
              subtitle:
                  '${_settingsService.settings.defaultCurrency.displayName} (${_settingsService.settings.defaultCurrency.symbol})',
              onTap: () => _showCurrencySettingsDialog(),
            ),
          ]),

          const SizedBox(height: 16),

          // Support & Info
          _buildSectionHeader(
              AppLocalizations.of(context)?.supportInformation ??
                  'Support & Information'),
          _buildSettingsCard([
            _buildSettingsItem(
              icon: FontAwesomeIcons.circleQuestion,
              title:
                  AppLocalizations.of(context)?.helpSupport ?? 'Help & Support',
              subtitle: AppLocalizations.of(context)?.getHelpContactSupport ??
                  'Get help and contact support',
              onTap: () => _navigateToHelpSupport(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.fileLines,
              title: AppLocalizations.of(context)?.termsPrivacy ??
                  'Terms & Privacy',
              subtitle:
                  AppLocalizations.of(context)?.termsServicePrivacyPolicy ??
                      'Terms of service and privacy policy',
              onTap: () => _showTermsDialog(),
            ),
            _buildDivider(),
            _buildSettingsItem(
              icon: FontAwesomeIcons.circleInfo,
              title: AppLocalizations.of(context)?.about ?? 'About',
              subtitle: AppLocalizations.of(context)?.appVersionInfo ??
                  'App version and information',
              onTap: () => _navigateToAbout(),
            ),
          ]),

          const SizedBox(height: 24),

          // Sign Out Button
          _buildSignOutButton(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              FontAwesomeIcons.user,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['full_name'] ??
                      (AppLocalizations.of(context)?.userName ?? 'User Name'),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?['email'] ??
                      (AppLocalizations.of(context)?.userEmail ??
                          'user@example.com'),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.freelancerAccount ??
                      'Freelancer Account',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _navigateToProfileSettings(),
            icon: const Icon(
              FontAwesomeIcons.pen,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),

            // Content
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

            // Trailing
            trailing ??
                const Icon(
                  FontAwesomeIcons.chevronRight,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 68),
      color: AppColors.border,
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                AppLocalizations.of(context)?.signOut ?? 'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textMedium,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToProfileSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileSettingsScreen(),
      ),
    );
  }

  void _navigateToAppSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppSettingsScreen(),
      ),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _navigateToBusinessProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BusinessProfileSettingsScreen(),
      ),
    );
  }

  void _navigateToInvoiceSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvoiceSettingsScreen(),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _navigateToEmailSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSettingsScreen(),
      ),
    );
  }

  void _navigateToTaxSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaxSettingsScreen(),
      ),
    );
  }

  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  void _navigateToDataSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DataSettingsScreen(),
      ),
    );
  }

  // void _navigateToFiscalYearManagement() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const FiscalYearManagementScreen(),
  //     ),
  //   );
  // }

  // Dialog Methods

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationService.supportedLanguages.map((language) {
            final isSelected = _currentLanguage?.code == language.code;
            return ListTile(
              title: Text(
                language.displayName,
                style: GoogleFonts.poppins(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              leading: Icon(
                isSelected
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 16,
              ),
              onTap: () async {
                // Get the localized message before async operations
                final localizedMessage =
                    AppLocalizations.of(context)?.languageChanged ??
                        'Language changed to';

                // Close the dialog first
                Navigator.pop(context);

                // Use the locale notifier to change language
                await LocaleNotifier().changeLocale(language.code);

                // Update current language state
                setState(() {
                  _currentLanguage = language;
                });

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('$localizedMessage ${language.displayName}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencySettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Default Currency',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: settings_model.Currency.values.map((currency) {
            final isSelected =
                _settingsService.settings.defaultCurrency == currency;
            return ListTile(
              title: Text(
                '${currency.displayName} (${currency.code})',
                style: GoogleFonts.poppins(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                'Symbol: ${currency.symbol}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              leading: Icon(
                isSelected
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circle,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 16,
              ),
              onTap: () async {
                await _settingsService.updateDefaultCurrency(currency);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Currency changed to ${currency.code}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Terms & privacy coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Sign Out Method
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
}
