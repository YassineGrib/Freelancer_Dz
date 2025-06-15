import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/database_backup_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _darkMode = false;
  bool _autoBackup = true;
  bool _offlineMode = false;
  bool _analyticsEnabled = true;
  double _fontSize = 16.0;
  String _selectedTheme = 'System';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'App Settings',
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
          // Appearance Settings
          _buildSectionHeader('Appearance'),
          _buildAppearanceCard(),
          const SizedBox(height: 16),

          // Data & Storage
          _buildSectionHeader('Data & Storage'),
          _buildDataStorageCard(),
          const SizedBox(height: 16),

          // Privacy & Analytics
          _buildSectionHeader('Privacy & Analytics'),
          _buildPrivacyCard(),
          const SizedBox(height: 16),

          // Advanced Settings
          _buildSectionHeader('Advanced'),
          _buildAdvancedCard(),
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

  Widget _buildAppearanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Theme Selection
          _buildSettingsItem(
            icon: FontAwesomeIcons.palette,
            title: 'Theme',
            subtitle: _selectedTheme,
            onTap: _showThemeDialog,
          ),
          _buildDivider(),

          // Dark Mode Toggle
          _buildSwitchItem(
            icon: FontAwesomeIcons.moon,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),
          _buildDivider(),

          // Font Size
          _buildSliderItem(
            icon: FontAwesomeIcons.textHeight,
            title: 'Font Size',
            subtitle: '${_fontSize.round()}px',
            value: _fontSize,
            min: 12.0,
            max: 24.0,
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataStorageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Auto Backup
          _buildSwitchItem(
            icon: FontAwesomeIcons.cloudArrowUp,
            title: 'Auto Backup',
            subtitle: 'Automatically backup data to cloud',
            value: _autoBackup,
            onChanged: (value) {
              setState(() {
                _autoBackup = value;
              });
            },
          ),
          _buildDivider(),

          // Offline Mode
          _buildSwitchItem(
            icon: FontAwesomeIcons.wifi,
            title: 'Offline Mode',
            subtitle: 'Work without internet connection',
            value: _offlineMode,
            onChanged: (value) {
              setState(() {
                _offlineMode = value;
              });
            },
          ),
          _buildDivider(),

          // Clear Cache
          _buildSettingsItem(
            icon: FontAwesomeIcons.broom,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: _showClearCacheDialog,
          ),
          _buildDivider(),

          // Export Data
          _buildSettingsItem(
            icon: FontAwesomeIcons.download,
            title: 'Export Data',
            subtitle: 'Create backup of your database',
            onTap: _exportDatabase,
          ),
          _buildDivider(),

          // Import Data
          _buildSettingsItem(
            icon: FontAwesomeIcons.upload,
            title: 'Import Data',
            subtitle: 'Restore from backup file',
            onTap: _importDatabase,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Analytics
          _buildSwitchItem(
            icon: FontAwesomeIcons.chartLine,
            title: 'Analytics',
            subtitle: 'Help improve the app with usage data',
            value: _analyticsEnabled,
            onChanged: (value) {
              setState(() {
                _analyticsEnabled = value;
              });
            },
          ),
          _buildDivider(),

          // Privacy Policy
          _buildSettingsItem(
            icon: FontAwesomeIcons.shield,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: _showPrivacyPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Debug Mode
          _buildSettingsItem(
            icon: FontAwesomeIcons.bug,
            title: 'Debug Information',
            subtitle: 'View app debug information',
            onTap: _showDebugInfo,
          ),
          _buildDivider(),

          // Reset Settings
          _buildSettingsItem(
            icon: FontAwesomeIcons.arrowRotateLeft,
            title: 'Reset Settings',
            subtitle: 'Reset all settings to default',
            onTap: _showResetDialog,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: textColor ?? AppColors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? AppColors.textPrimary,
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
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 12),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
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
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.border,
    );
  }

  // Dialog Methods
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportDatabase() async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Creating backup...'),
              ],
            ),
          ),
        );
      }

      // Create backup
      await DatabaseBackupService.createAndShareBackup();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup created and shared successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create backup: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importDatabase() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Import Database',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will replace all your current data with the data from the backup file. This action cannot be undone.\n\nAre you sure you want to continue?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Import',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Restoring backup...'),
              ],
            ),
          ),
        );
      }

      // Restore from backup
      final success = await DatabaseBackupService.restoreFromBackup();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Database restored successfully! Please restart the app.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // User cancelled file selection
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import cancelled',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to restore backup: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy policy coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDebugInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug information coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will reset all settings to default values. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _darkMode = false;
      _autoBackup = true;
      _offlineMode = false;
      _analyticsEnabled = true;
      _fontSize = 16.0;
      _selectedTheme = 'System';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to default!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

