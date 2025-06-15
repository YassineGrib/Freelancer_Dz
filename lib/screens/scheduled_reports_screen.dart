import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/report_model.dart';
import '../services/scheduled_reports_service.dart';

import '../widgets/loading_widget.dart';
import '../utils/colors.dart';

class ScheduledReportsScreen extends StatefulWidget {
  const ScheduledReportsScreen({super.key});

  @override
  State<ScheduledReportsScreen> createState() => _ScheduledReportsScreenState();
}

class _ScheduledReportsScreenState extends State<ScheduledReportsScreen> {
  final ScheduledReportsService _scheduledReportsService =
      ScheduledReportsService();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Scheduled Reports',
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
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading scheduled reports...')
          : _error != null
              ? _buildErrorState()
              : _buildScheduledReportsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduledReportDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildScheduledReportsList() {
    final scheduledReports = _scheduledReportsService.getScheduledReports();

    if (scheduledReports.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scheduledReports.length,
      itemBuilder: (context, index) {
        final report = scheduledReports[index];
        return _buildScheduledReportCard(report);
      },
    );
  }

  Widget _buildScheduledReportCard(ScheduledReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: report.reportType.color.withOpacity(0.1),
                ),
                child: Icon(
                  report.reportType.icon,
                  color: report.reportType.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${report.reportType.displayName} • ${report.frequency.displayName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: report.isActive,
                onChanged: (value) => _toggleScheduledReport(report.id),
                activeColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.email,
                label: '${report.emailRecipients.length} recipients',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: report.exportFormat.icon,
                label: report.exportFormat.displayName,
              ),
              const SizedBox(width: 8),
              if (report.lastSent != null)
                _buildInfoChip(
                  icon: Icons.schedule,
                  label: 'Last: ${_formatDate(report.lastSent!)}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _executeScheduledReport(report.id),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: Text(
                    'Run Now',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editScheduledReport(report),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteScheduledReport(report.id),
                  icon: const Icon(Icons.delete, size: 16),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Scheduled Reports',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first scheduled report to\nautomatically receive reports via email',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddScheduledReportDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Scheduled Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Scheduled Reports',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Event handlers
  void _showAddScheduledReportDialog() {
    // TODO: Implement add scheduled report dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add scheduled report dialog coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editScheduledReport(ScheduledReportModel report) {
    // TODO: Implement edit scheduled report dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${report.name} coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _toggleScheduledReport(String id) async {
    try {
      await _scheduledReportsService.toggleScheduledReport(id);
      setState(() {}); // Refresh the UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _executeScheduledReport(String id) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _scheduledReportsService.executeScheduledReport(id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report executed and sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error executing report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteScheduledReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Scheduled Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this scheduled report? This action cannot be undone.',
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
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _scheduledReportsService.deleteScheduledReport(id);
        setState(() {}); // Refresh the UI

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled report deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
