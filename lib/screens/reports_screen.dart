import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import '../services/export_service.dart';
import '../l10n/app_localizations.dart';

import '../widgets/loading_widget.dart';
import 'report_details_screen.dart';
import 'scheduled_reports_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsService _reportsService = ReportsService();

  ReportPeriod _selectedPeriod = ReportPeriod.thisMonth;
  DateTimeRange? _customDateRange;
  bool _isLoading = false;
  String? _error;

  // Advanced filtering options
  String? _selectedClientId;
  String? _selectedProjectId;
  String? _selectedStatus;
  double? _minAmount;
  double? _maxAmount;
  bool _showAdvancedFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.reports ?? 'Reports',
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
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),

          // Report Categories
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading reports...')
                : _error != null
                    ? _buildErrorState()
                    : _buildReportCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header with Filter Summary
          _buildFilterHeader(),

          // Collapsible Filter Content
          if (_showAdvancedFilters) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildFilterContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    final hasActiveFilters = _hasActiveFilters();
    final filterSummary = _getFilterSummary();

    return InkWell(
      onTap: () {
        setState(() {
          _showAdvancedFilters = !_showAdvancedFilters;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Filter Icon with Badge
            Stack(
              children: [
                Icon(
                  Icons.tune,
                  color: hasActiveFilters
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                if (hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Filter Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)?.filters ?? 'Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick Period Chips
                      Expanded(
                        child: _buildQuickPeriodChips(),
                      ),
                    ],
                  ),
                  if (filterSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      filterSummary,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Expand/Collapse Icon
            Icon(
              _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ReportPeriod.values.take(4).map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _onPeriodSelected(period),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  period.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All Period Options
          _buildAllPeriodOptions(),

          // Custom Date Range (if selected)
          if (_selectedPeriod == ReportPeriod.custom) ...[
            const SizedBox(height: 16),
            _buildCustomDateRangeSelector(),
          ],

          // Advanced Filters in Compact Grid
          const SizedBox(height: 16),
          _buildCompactAdvancedFilters(),

          // Action Buttons
          const SizedBox(height: 16),
          _buildFilterActions(),
        ],
      ),
    );
  }

  Widget _buildAllPeriodOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.timePeriod ?? 'Time Period',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return GestureDetector(
              onTap: () => _onPeriodSelected(period),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  period.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedClientId != null ||
        _selectedProjectId != null ||
        _selectedStatus != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _selectedPeriod != ReportPeriod.thisMonth;
  }

  String _getFilterSummary() {
    final filters = <String>[];

    if (_selectedPeriod != ReportPeriod.thisMonth) {
      filters.add(_selectedPeriod.displayName);
    }

    if (_selectedClientId != null) filters.add('Client');
    if (_selectedProjectId != null) filters.add('Project');
    if (_selectedStatus != null) filters.add('Status');
    if (_minAmount != null || _maxAmount != null) filters.add('Amount');

    if (filters.isEmpty) return '';
    return filters.join(' • ');
  }

  Widget _buildCompactAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.advancedFilters ?? 'Advanced Filters',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Compact Filter Grid
        Row(
          children: [
            Expanded(
              child: _buildCompactFilterDropdown(
                label: AppLocalizations.of(context)?.client ?? 'Client',
                value: _selectedClientId,
                hint: AppLocalizations.of(context)?.all ?? 'All',
                icon: Icons.person_outline,
                items: const [], // TODO: Load from ClientService
                onChanged: (value) => setState(() => _selectedClientId = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactFilterDropdown(
                label: AppLocalizations.of(context)?.project ?? 'Project',
                value: _selectedProjectId,
                hint: AppLocalizations.of(context)?.all ?? 'All',
                icon: Icons.work_outline,
                items: const [], // TODO: Load from ProjectService
                onChanged: (value) =>
                    setState(() => _selectedProjectId = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildCompactFilterDropdown(
                label: AppLocalizations.of(context)?.status ?? 'Status',
                value: _selectedStatus,
                hint: AppLocalizations.of(context)?.all ?? 'All',
                icon: Icons.flag_outlined,
                items: [
                  DropdownMenuItem(
                      value: 'completed',
                      child: Text(AppLocalizations.of(context)?.completed ??
                          'Completed')),
                  DropdownMenuItem(
                      value: 'in_progress',
                      child: Text(AppLocalizations.of(context)?.inProgress ??
                          'In Progress')),
                  DropdownMenuItem(
                      value: 'not_started',
                      child: Text(AppLocalizations.of(context)?.notStarted ??
                          'Not Started')),
                  DropdownMenuItem(
                      value: 'pending',
                      child: Text(
                          AppLocalizations.of(context)?.pending ?? 'Pending')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAmountRangeFilter(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactFilterDropdown({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.arrow_drop_down, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_money,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)?.amount ?? 'Amount',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context)?.min ?? 'Min',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: GoogleFonts.poppins(fontSize: 11),
                  keyboardType: TextInputType.number,
                  onChanged: (text) {
                    final amount = double.tryParse(text);
                    setState(() => _minAmount = amount);
                  },
                  controller: TextEditingController(
                    text: _minAmount?.toStringAsFixed(0) ?? '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text('-',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context)?.max ?? 'Max',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: GoogleFonts.poppins(fontSize: 11),
                  keyboardType: TextInputType.number,
                  onChanged: (text) {
                    final amount = double.tryParse(text);
                    setState(() => _maxAmount = amount);
                  },
                  controller: TextEditingController(
                    text: _maxAmount?.toStringAsFixed(0) ?? '',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearAdvancedFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: Text(
              AppLocalizations.of(context)?.clear ?? 'Clear',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAdvancedFilters = false;
              });
            },
            icon: const Icon(Icons.check, size: 16),
            label: Text(
              AppLocalizations.of(context)?.apply ?? 'Apply',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.customDateRange ?? 'Custom Date Range',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectCustomDateRange,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _customDateRange != null
                        ? '${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}'
                        : (AppLocalizations.of(context)?.selectDateRange ??
                            'Select Date Range'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _customDateRange != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCategories() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Report Categories',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Report Type Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: ReportType.values.length,
          itemBuilder: (context, index) {
            final reportType = ReportType.values[index];
            return _buildReportTypeCard(reportType);
          },
        ),

        const SizedBox(height: 24),

        // Quick Actions
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildReportTypeCard(ReportType reportType) {
    return GestureDetector(
      onTap: () => _generateReport(reportType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: reportType.color.withValues(alpha: 0.1),
              ),
              child: Icon(
                reportType.icon,
                color: reportType.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reportType.displayName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              reportType.description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.download,
                label: 'Export All',
                onTap: _exportAllReports,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.email,
                label: 'Email Reports',
                onTap: _emailReports,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.blue,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
            'Error Loading Reports',
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

  // Event Handlers
  void _onPeriodSelected(ReportPeriod period) {
    setState(() {
      _selectedPeriod = period;
      if (period != ReportPeriod.custom) {
        _customDateRange = null;
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );

    if (dateRange != null) {
      setState(() {
        _customDateRange = dateRange;
      });
    }
  }

  Future<void> _generateReport(ReportType reportType) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final filter = ReportFilterModel(
        type: reportType,
        period: _selectedPeriod,
        customDateRange: _customDateRange,
      );

      final reportData = await _reportsService.generateReport(filter);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailsScreen(reportData: reportData),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportAllReports() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Export All Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose format and action for all report types:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Format Selection
            Text(
              'Format:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...ExportFormat.values.map((format) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(format.icon, color: Colors.blue),
                  title: Text(
                    format.displayName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    format == ExportFormat.pdf
                        ? 'Formatted documents with charts'
                        : 'Raw data for analysis',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBulkActionSelectionDialog(format);
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkActionSelectionDialog(ExportFormat format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Action',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What would you like to do with all ${format.displayName} reports?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...ExportAction.values.map((action) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(action.icon, color: Colors.grey[600]),
                  title: Text(
                    action.displayName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    action.description,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _performBulkExport(format, action);
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Back',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkExport(
      ExportFormat format, ExportAction action) async {
    try {
      // Show loading indicator with action-specific message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getBulkLoadingMessage(action),
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      );

      final exportService = ExportService();
      final results = <ExportResult>[];

      // Generate and export all report types
      for (final reportType in ReportType.values) {
        final filter = ReportFilterModel(
          type: reportType,
          period: _selectedPeriod,
          customDateRange: _customDateRange,
        );

        final reportData = await _reportsService.generateReport(filter);
        final result =
            await exportService.exportWithOptions(reportData, format, action);
        results.add(result);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        final successCount = results.where((r) => r.success).length;
        final totalCount = results.length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getBulkResultMessage(action, successCount, totalCount),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor:
                successCount == totalCount ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error exporting reports: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getBulkLoadingMessage(ExportAction action) {
    switch (action) {
      case ExportAction.save:
        return 'Saving all reports to device...';
      case ExportAction.share:
        return 'Preparing to share all reports...';
      case ExportAction.saveAndShare:
        return 'Saving and preparing to share all reports...';
    }
  }

  String _getBulkResultMessage(
      ExportAction action, int successCount, int totalCount) {
    final actionText = action == ExportAction.save
        ? 'saved'
        : action == ExportAction.share
            ? 'shared'
            : 'saved and shared';

    if (successCount == totalCount) {
      return 'Successfully $actionText $successCount reports!';
    } else {
      return 'Successfully $actionText $successCount of $totalCount reports';
    }
  }

  void _emailReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduledReportsScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearAdvancedFilters() {
    setState(() {
      _selectedClientId = null;
      _selectedProjectId = null;
      _selectedStatus = null;
      _minAmount = null;
      _maxAmount = null;
    });
  }
}
