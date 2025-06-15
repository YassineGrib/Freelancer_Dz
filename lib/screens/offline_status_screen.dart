import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/offline_service.dart';

class OfflineStatusScreen extends StatefulWidget {
  const OfflineStatusScreen({super.key});

  @override
  State<OfflineStatusScreen> createState() => _OfflineStatusScreenState();
}

class _OfflineStatusScreenState extends State<OfflineStatusScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();
  final OfflineService _offlineService = OfflineService();

  bool _isLoading = false;
  Map<String, int> _offlineStats = {};

  @override
  void initState() {
    super.initState();
    _loadOfflineStats();

    // Listen for changes
    _connectivityService.addListener(_onStatusChanged);
    _syncService.addListener(_onStatusChanged);
    _offlineService.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onStatusChanged);
    _syncService.removeListener(_onStatusChanged);
    _offlineService.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    if (mounted) {
      setState(() {});
      _loadOfflineStats();
    }
  }

  Future<void> _loadOfflineStats() async {
    try {
      final stats = await _offlineService.getOfflineStats();
      setState(() {
        _offlineStats = stats;
      });
    } catch (e) {
      debugPrint('Error loading offline stats: $e');
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _syncService.syncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Sync completed successfully' : 'Sync completed with errors'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
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

  Future<void> _clearOfflineData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Data'),
        content: const Text(
          'This will delete all locally stored data. Make sure you have synced your changes first. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _offlineService.clearOfflineData();
      await _loadOfflineStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline data cleared'),
            backgroundColor: Colors.green,
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
          'Offline Status',
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _connectivityService.refresh();
          await _loadOfflineStats();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connectivity Status
            _buildConnectivityCard(),
            const SizedBox(height: 16),

            // Sync Status
            _buildSyncCard(),
            const SizedBox(height: 16),

            // Offline Data Stats
            _buildOfflineStatsCard(),
            const SizedBox(height: 16),

            // Actions
            _buildActionsCard(),
            const SizedBox(height: 16),

            // Sync Errors (if any)
            if (_syncService.hasErrors) _buildErrorsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityCard() {
    final isOnline = _connectivityService.isOnline;
    final statusColor = isOnline ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: statusColor.withOpacity( 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isOnline ? FontAwesomeIcons.wifi : Icons.wifi_off,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _connectivityService.getConnectivityStatusText(),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _connectivityService.getDetailedConnectivityInfo(),
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

  Widget _buildSyncCard() {
    final isSyncing = _syncService.isSyncing;
    final pendingChanges = _syncService.pendingChanges;
    final lastSyncTime = _syncService.lastSyncTime;

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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        FontAwesomeIcons.arrowsRotate,
                        color: AppColors.primary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Status',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _syncService.syncStatus,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoRow('Pending Changes', pendingChanges.toString()),
          if (lastSyncTime != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Last Sync', _formatDateTime(lastSyncTime)),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineStatsCard() {
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
            'Offline Data',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (_offlineStats.isNotEmpty) ...[
            _buildInfoRow('Clients', _offlineStats['clients']?.toString() ?? '0'),
            const SizedBox(height: 8),
            _buildInfoRow('Projects', _offlineStats['projects']?.toString() ?? '0'),
            const SizedBox(height: 8),
            _buildInfoRow('Payments', _offlineStats['payments']?.toString() ?? '0'),
            const SizedBox(height: 8),
            _buildInfoRow('Expenses', _offlineStats['expenses']?.toString() ?? '0'),
            const SizedBox(height: 8),
            _buildInfoRow('Invoices', _offlineStats['invoices']?.toString() ?? '0'),
          ] else ...[
            Text(
              'Loading offline data...',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
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
            'Actions',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Sync Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _connectivityService.isOnline && !_isLoading ? _syncNow : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(FontAwesomeIcons.arrowsRotate),
              label: Text(_isLoading ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Clear Data Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearOfflineData,
              icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
              label: const Text('Clear Offline Data', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.red.withOpacity( 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.exclamationTriangle, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sync Errors',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textLarge,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._syncService.syncErrors.map((error) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '• $error',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          )),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _syncService.clearErrors();
            },
            child: const Text('Clear Errors'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
          value,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
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
}

