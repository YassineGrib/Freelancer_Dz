import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/report_model.dart';
import '../services/export_service.dart';

class ReportDetailsScreen extends StatefulWidget {
  final ReportDataModel reportData;

  const ReportDetailsScreen({
    super.key,
    required this.reportData,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.reportData.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Report Header
          _buildReportHeader(),

          // Tab Navigation
          _buildTabNavigation(),

          // Tab Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader() {
    return Container(
      width: double.infinity,
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
                  color: widget.reportData.type.color.withOpacity(0.1),
                ),
                child: Icon(
                  widget.reportData.type.icon,
                  color: widget.reportData.type.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reportData.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      widget.reportData.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Period: ${widget.reportData.formattedDateRange}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            'Generated: ${_formatDateTime(widget.reportData.generatedAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Summary', 0),
          ),
          Expanded(
            child: _buildTabButton('Charts', 1),
          ),
          Expanded(
            child: _buildTabButton('Data', 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildSummaryTab();
      case 1:
        return _buildChartsTab();
      case 2:
        return _buildDataTab();
      default:
        return _buildSummaryTab();
    }
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Summary',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Summary Cards Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: widget.reportData.summary.length,
          itemBuilder: (context, index) {
            final entry = widget.reportData.summary.entries.elementAt(index);
            return _buildSummaryCard(entry.key, entry.value);
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTitle(title),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _formatValue(value),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Visual Analytics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Charts based on report type
        if (widget.reportData.type == ReportType.financial) ...[
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildRevenueBreakdownChart(),
        ] else if (widget.reportData.type == ReportType.client) ...[
          _buildClientRevenueChart(),
          const SizedBox(height: 24),
          _buildClientDistributionChart(),
        ] else if (widget.reportData.type == ReportType.project) ...[
          _buildProjectStatusChart(),
          const SizedBox(height: 24),
          _buildMonthlyProjectsChart(),
        ] else ...[
          _buildPlaceholderChart(),
        ],
      ],
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Raw Data',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Data Table
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: widget.reportData.data.isEmpty
              ? _buildEmptyDataState()
              : _buildDataTable(),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final chartData =
        widget.reportData.charts['monthlyRevenue'] as List<dynamic>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No revenue data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Revenue Trend',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((entry) {
                      final data = entry.value as Map<String, dynamic>;
                      return FlSpot(
                        entry.key.toDouble(),
                        (data['revenue'] as num).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownChart() {
    final chartData =
        widget.reportData.charts['revenueBreakdown'] as List<dynamic>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No payment method data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue by Payment Method',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: chartData.asMap().entries.map((entry) {
                  final data = entry.value as Map<String, dynamic>;
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.red
                  ];
                  return PieChartSectionData(
                    value: (data['amount'] as num).toDouble(),
                    title: data['method'] as String,
                    color: colors[entry.key % colors.length],
                    radius: 100,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientRevenueChart() {
    final chartData =
        widget.reportData.charts['clientRevenue'] as List<dynamic>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No client revenue data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Clients by Revenue',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  final data = entry.value as Map<String, dynamic>;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (data['revenue'] as num).toDouble(),
                        color: Colors.blue,
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDistributionChart() {
    final chartData =
        widget.reportData.charts['clientDistribution'] as List<dynamic>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No client distribution data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client Revenue Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: chartData.asMap().entries.map((entry) {
                  final data = entry.value as Map<String, dynamic>;
                  final colors = [
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.red
                  ];
                  return PieChartSectionData(
                    value: (data['percentage'] as num).toDouble(),
                    title: '${(data['percentage'] as num).toStringAsFixed(1)}%',
                    color: colors[entry.key % colors.length],
                    radius: 100,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStatusChart() {
    final chartData =
        widget.reportData.charts['statusBreakdown'] as List<dynamic>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No project status data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Status Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: chartData.map((data) {
                  final statusData = data as Map<String, dynamic>;
                  return PieChartSectionData(
                    value: (statusData['count'] as num).toDouble(),
                    title: statusData['status'] as String,
                    color: Color(statusData['color'] as int),
                    radius: 100,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProjectsChart() {
    final chartData =
        widget.reportData.charts['monthlyProjects'] as List<dynamic>? ?? [];

    if (chartData.isEmpty) {
      return _buildEmptyChartState('No monthly project data available');
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Project Creation',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  final data = entry.value as Map<String, dynamic>;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (data['count'] as num).toDouble(),
                        color: Colors.orange,
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Charts for this report type\nare coming soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChartState(String message) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDataState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No data available for this report',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (widget.reportData.data.isEmpty) {
      return _buildEmptyDataState();
    }

    final data = widget.reportData.data;
    final headers = data.first.keys.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((header) {
          return DataColumn(
            label: Text(
              _formatTitle(header),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
        rows: data.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;

          return DataRow(
            onSelectChanged: (selected) {
              if (selected == true) {
                _showDrillDownDialog(row, index);
              }
            },
            cells: headers.map((header) {
              return DataCell(
                Text(
                  _formatValue(row[header]),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // Helper methods
  String _formatTitle(String title) {
    return title
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ')
        .trim();
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) {
      return value.toStringAsFixed(2);
    }
    if (value is int) {
      return value.toString();
    }
    return value.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Action handlers
  void _shareReport() {
    _showEnhancedExportDialog(defaultAction: ExportAction.share);
  }

  void _exportReport() {
    _showEnhancedExportDialog(defaultAction: ExportAction.save);
  }

  void _showEnhancedExportDialog({ExportAction? defaultAction}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Export Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose format and action:',
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
                        ? 'Formatted document with charts'
                        : 'Raw data for analysis',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showActionSelectionDialog(format, defaultAction);
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

  void _showActionSelectionDialog(
      ExportFormat format, ExportAction? defaultAction) {
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
              'What would you like to do with the ${format.displayName}?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...ExportAction.values.map((action) {
              final isDefault = action == defaultAction;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isDefault ? Colors.blue.withOpacity(0.1) : null,
                child: ListTile(
                  leading: Icon(
                    action.icon,
                    color: isDefault ? Colors.blue : Colors.grey[600],
                  ),
                  title: Text(
                    action.displayName,
                    style: GoogleFonts.poppins(
                      fontWeight: isDefault ? FontWeight.w600 : FontWeight.w500,
                      color: isDefault ? Colors.blue : null,
                    ),
                  ),
                  subtitle: Text(
                    action.description,
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _performEnhancedExport(format, action);
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

  Future<void> _performExport(
      ExportFormat format, bool shareAfterExport) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                shareAfterExport ? 'Preparing to share...' : 'Exporting...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );

      final exportService = ExportService();

      if (shareAfterExport) {
        await exportService.exportAndShare(widget.reportData, format);
      } else {
        String? filePath;
        switch (format) {
          case ExportFormat.pdf:
            filePath = await exportService.exportToPDF(widget.reportData);
            break;
          case ExportFormat.csv:
            filePath = await exportService.exportToCSV(widget.reportData);
            break;
          case ExportFormat.excel:
            throw Exception('Excel export not yet implemented');
        }

        if (filePath != null && mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Report exported successfully to: $filePath',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shareAfterExport
                  ? 'Report shared successfully!'
                  : 'Report exported successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performEnhancedExport(
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
                  _getLoadingMessage(action),
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      );

      final exportService = ExportService();
      final result = await exportService.exportWithOptions(
          widget.reportData, format, action);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
            action: result.success &&
                    result.filePath != null &&
                    action == ExportAction.save
                ? SnackBarAction(
                    label: 'Open',
                    textColor: Colors.white,
                    onPressed: () => _openFile(result.filePath!),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLoadingMessage(ExportAction action) {
    switch (action) {
      case ExportAction.save:
        return 'Saving report to device...';
      case ExportAction.share:
        return 'Preparing to share...';
      case ExportAction.saveAndShare:
        return 'Saving and preparing to share...';
    }
  }

  void _openFile(String filePath) {
    // TODO: Implement file opening functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'File opening functionality coming soon',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Drill-down functionality
  void _showDrillDownDialog(Map<String, dynamic> rowData, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detailed Information',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Row ${index + 1} Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: rowData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatTitle(entry.key),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: Text(
                                _formatValue(entry.value),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDrillDownActions(rowData),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillDownActions(Map<String, dynamic> rowData) {
    return Column(
      children: [
        const Divider(),
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (rowData.containsKey('projectId'))
              _buildActionChip(
                icon: Icons.work,
                label: 'View Project',
                onTap: () => _navigateToProject(rowData['projectId']),
              ),
            if (rowData.containsKey('clientName'))
              _buildActionChip(
                icon: Icons.person,
                label: 'View Client',
                onTap: () => _navigateToClient(rowData['clientName']),
              ),
            _buildActionChip(
              icon: Icons.filter_alt,
              label: 'Filter Similar',
              onTap: () => _filterSimilarData(rowData),
            ),
            _buildActionChip(
              icon: Icons.share,
              label: 'Share',
              onTap: () => _shareRowData(rowData),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drill-down action handlers
  void _navigateToProject(String? projectId) {
    Navigator.of(context).pop(); // Close dialog
    if (projectId != null) {
      // TODO: Navigate to project details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to project: $projectId'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _navigateToClient(String? clientName) {
    Navigator.of(context).pop(); // Close dialog
    if (clientName != null) {
      // TODO: Navigate to client details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to client: $clientName'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _filterSimilarData(Map<String, dynamic> rowData) {
    Navigator.of(context).pop(); // Close dialog
    // TODO: Implement filtering similar data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filter similar data functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareRowData(Map<String, dynamic> rowData) {
    Navigator.of(context).pop(); // Close dialog
    // TODO: Implement sharing row data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share row data functionality coming soon'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
