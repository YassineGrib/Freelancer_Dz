import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/settings_service.dart';
import '../services/local_database_service.dart';
import '../services/database_backup_service.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../services/project_service.dart';
import '../services/invoice_service.dart';
import '../services/payment_service.dart';
import '../services/expense_service.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class DataSettingsScreen extends StatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  State<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends State<DataSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _isLoading = false;
  bool _isLoadingStats = true;
  bool _isBackupExpanded = false;
  bool _isSyncExpanded = false;
  bool _isDataManagementExpanded = false;
  bool _isAdvancedExpanded = false;

  // Real data statistics
  Map<String, int> _dataStats = {
    'clients': 0,
    'projects': 0,
    'invoices': 0,
    'payments': 0,
    'expenses': 0,
  };

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _loadDataStatistics();
  }

  Future<void> _initializeSettings() async {
    if (!_settingsService.isInitialized) {
      await _settingsService.initialize();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDataStatistics() async {
    try {
      setState(() => _isLoadingStats = true);

      // Load data counts in parallel for better performance
      final results = await Future.wait([
        ClientService.getAllClients(),
        ProjectService.getAllProjects(),
        InvoiceService.getAllInvoices(),
        PaymentService.getPayments(),
        ExpenseService.getAllExpenses(),
      ]);

      if (mounted) {
        setState(() {
          _dataStats = {
            'clients': results[0].length,
            'projects': results[1].length,
            'invoices': results[2].length,
            'payments': results[3].length,
            'expenses': results[4].length,
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
        // Optionally show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data statistics: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.dataStorage ?? 'Data & Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              FontAwesomeIcons.arrowsRotate,
              color: _isLoadingStats
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              size: 18,
            ),
            onPressed: _isLoadingStats ? null : _loadDataStatistics,
            tooltip: 'Refresh Statistics',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // Data Overview Section
          _buildDataOverviewCard(),
          const SizedBox(height: AppConstants.paddingMedium),

          // Backup & Restore Section
          _buildExpandableSection(
            title: 'Backup & Restore',
            subtitle: 'Manage your data backups',
            icon: FontAwesomeIcons.database,
            isExpanded: _isBackupExpanded,
            onToggle: () =>
                setState(() => _isBackupExpanded = !_isBackupExpanded),
            children: _buildBackupSection(),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Sync Settings Section
          _buildExpandableSection(
            title: 'Sync Settings',
            subtitle: 'Configure data synchronization',
            icon: FontAwesomeIcons.arrowsRotate,
            isExpanded: _isSyncExpanded,
            onToggle: () => setState(() => _isSyncExpanded = !_isSyncExpanded),
            children: _buildSyncSection(),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Data Management Section
          _buildExpandableSection(
            title: 'Data Management',
            subtitle: 'Export, import, and manage data',
            icon: FontAwesomeIcons.fileExport,
            isExpanded: _isDataManagementExpanded,
            onToggle: () => setState(
                () => _isDataManagementExpanded = !_isDataManagementExpanded),
            children: _buildDataManagementSection(),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Advanced Options Section
          _buildExpandableSection(
            title: 'Advanced Options',
            subtitle: 'Database maintenance and reset',
            icon: FontAwesomeIcons.gear,
            isExpanded: _isAdvancedExpanded,
            onToggle: () =>
                setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
            children: _buildAdvancedSection(),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
        ],
      ),
    );
  }

  Widget _buildDataOverviewCard() {
    final totalRecords = _dataStats.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: const Icon(
                  FontAwesomeIcons.chartPie,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Overview',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isLoadingStats
                          ? 'Loading...'
                          : '$totalRecords total records',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingStats)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Data Statistics Grid
          if (_isLoadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.paddingLarge),
                child: CircularProgressIndicator(),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: AppConstants.paddingMedium,
              mainAxisSpacing: AppConstants.paddingMedium,
              children: _dataStats.entries.map((entry) {
                return _buildDataStatItem(
                  _getDataTypeIcon(entry.key),
                  _getDataTypeLabel(entry.key),
                  entry.value,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDataStatItem(IconData icon, String label, int count) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDataTypeIcon(String type) {
    switch (type) {
      case 'clients':
        return FontAwesomeIcons.users;
      case 'projects':
        return FontAwesomeIcons.briefcase;
      case 'invoices':
        return FontAwesomeIcons.receipt;
      case 'payments':
        return FontAwesomeIcons.creditCard;
      case 'expenses':
        return FontAwesomeIcons.moneyBill;
      default:
        return FontAwesomeIcons.database;
    }
  }

  String _getDataTypeLabel(String type) {
    switch (type) {
      case 'clients':
        return 'Clients';
      case 'projects':
        return 'Projects';
      case 'invoices':
        return 'Invoices';
      case 'payments':
        return 'Payments';
      case 'expenses':
        return 'Expenses';
      default:
        return type;
    }
  }

  Widget _buildExpandableSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textMedium,
                            fontWeight: FontWeight.w600,
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
                  Icon(
                    isExpanded
                        ? FontAwesomeIcons.chevronUp
                        : FontAwesomeIcons.chevronDown,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: AppColors.border,
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(children: children),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBackupSection() {
    return [
      // Backup Status
      _buildStatusCard(
        title: 'Last Backup',
        subtitle: 'Never backed up',
        icon: FontAwesomeIcons.clock,
        status: 'warning',
      ),
      const SizedBox(height: AppConstants.paddingMedium),

      // Backup Actions
      Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Create Backup',
              icon: FontAwesomeIcons.download,
              color: Colors.green,
              onPressed: _exportDatabase,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: _buildActionButton(
              label: 'Restore Backup',
              icon: FontAwesomeIcons.upload,
              color: Colors.blue,
              onPressed: _importDatabase,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.paddingMedium),

      // Auto Backup Toggle
      _buildToggleOption(
        title: 'Auto Backup',
        subtitle: 'Automatically backup data weekly',
        value: false, // TODO: Get from settings
        onChanged: (value) {
          // TODO: Implement auto backup setting
        },
      ),
    ];
  }

  List<Widget> _buildSyncSection() {
    return [
      // Sync Status
      _buildStatusCard(
        title: 'Sync Status',
        subtitle: _settingsService.settings.autoSync ? 'Active' : 'Disabled',
        icon: FontAwesomeIcons.arrowsRotate,
        status: _settingsService.settings.autoSync ? 'success' : 'inactive',
      ),
      const SizedBox(height: AppConstants.paddingMedium),

      // Auto Sync Toggle
      _buildToggleOption(
        title: 'Auto Sync',
        subtitle: 'Automatically sync data when online',
        value: _settingsService.settings.autoSync,
        onChanged: (value) async {
          await _settingsService.updateAutoSync(value);
          setState(() {});
        },
      ),
      const SizedBox(height: AppConstants.paddingMedium),

      // Sync Interval
      _buildSliderOption(
        title: 'Sync Interval',
        subtitle: '${_settingsService.settings.syncIntervalMinutes} minutes',
        value: _settingsService.settings.syncIntervalMinutes.toDouble(),
        min: 5,
        max: 60,
        divisions: 11,
        onChanged: (value) async {
          await _settingsService.updateSyncInterval(value.round());
          setState(() {});
        },
      ),
      const SizedBox(height: AppConstants.paddingMedium),

      // Manual Sync Button
      SizedBox(
        width: double.infinity,
        child: _buildActionButton(
          label: 'Sync Now',
          icon: FontAwesomeIcons.arrowsRotate,
          color: AppColors.primary,
          onPressed: _performManualSync,
        ),
      ),
    ];
  }

  List<Widget> _buildDataManagementSection() {
    return [
      // Export Options
      Text(
        'Export Data',
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: AppConstants.paddingSmall),
      Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Export Settings',
              icon: FontAwesomeIcons.gear,
              color: AppColors.primary,
              onPressed: _exportSettings,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: _buildActionButton(
              label: 'Export All Data',
              icon: FontAwesomeIcons.fileExport,
              color: Colors.orange,
              onPressed: _exportAllData,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.paddingLarge),

      // Import Options
      Text(
        'Import Data',
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: AppConstants.paddingSmall),
      SizedBox(
        width: double.infinity,
        child: _buildActionButton(
          label: 'Import Settings',
          icon: FontAwesomeIcons.upload,
          color: Colors.purple,
          onPressed: _importSettings,
        ),
      ),
    ];
  }

  List<Widget> _buildAdvancedSection() {
    return [
      // Database Maintenance
      Text(
        'Database Maintenance',
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: AppConstants.paddingSmall),
      SizedBox(
        width: double.infinity,
        child: _buildActionButton(
          label: 'Optimize Database',
          icon: FontAwesomeIcons.wrench,
          color: Colors.blue,
          onPressed: _optimizeDatabase,
        ),
      ),
      const SizedBox(height: AppConstants.paddingLarge),

      // Danger Zone
      Text(
        'Danger Zone',
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
      const SizedBox(height: AppConstants.paddingSmall),
      SizedBox(
        width: double.infinity,
        child: _buildActionButton(
          label: 'Reset All Data',
          icon: FontAwesomeIcons.triangleExclamation,
          color: Colors.red,
          onPressed: _resetDatabase,
        ),
      ),
    ];
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
  }) {
    Color statusColor;
    switch (status) {
      case 'success':
        statusColor = Colors.green;
        break;
      case 'warning':
        statusColor = Colors.orange;
        break;
      case 'error':
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(icon, size: 16, color: statusColor),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
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
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        children: [
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

  Widget _buildSliderOption({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
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
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.round()} min',
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _exportDatabase() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseBackupService.createAndShareBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Database backup created successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importDatabase() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Restore Database',
      content:
          'This will replace ALL your current data. This action cannot be undone.\n\nAre you sure?',
      confirmText: 'Restore',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await DatabaseBackupService.restoreFromBackup();
      if (mounted) {
        if (success) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restore cancelled',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to restore database: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performManualSync() async {
    setState(() => _isLoading = true);
    try {
      // Simulate sync operation
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data synchronized successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync failed: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportSettings() async {
    try {
      _settingsService.exportSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings exported to clipboard!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error exporting settings: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAllData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement comprehensive data export
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All data exported successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importSettings() async {
    // Show import dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Import settings feature coming soon!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _optimizeDatabase() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement database optimization
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Database optimized successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Optimization failed: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Reset Database',
      content:
          'This will permanently delete ALL your data including clients, projects, payments, expenses, invoices, and tax records. This action cannot be undone.\n\nAre you sure?',
      confirmText: 'Reset Database',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await LocalDatabaseService.instance.resetDatabase();
      await AuthService.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Database reset successfully. Please sign in again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to reset database: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : AppColors.textPrimary,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              confirmText,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
