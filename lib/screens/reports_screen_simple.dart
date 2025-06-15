import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/report_model.dart';
import '../services/report_service_simple.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<ReportType> _reportTypes = ReportType.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Reports',
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
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Business Reports',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textXLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate detailed reports for your freelance business',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 30),

            // Report Types Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4, // Adjusted for fixed height
                ),
                itemCount: _reportTypes.length,
                itemBuilder: (context, index) {
                  final reportType = _reportTypes[index];
                  return _buildReportCard(context, reportType);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, ReportType reportType) {
    return InkWell(
      onTap: () => _navigateToReportDetail(context, reportType),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 140, // Fixed height for consistency
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: reportType.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                reportType.icon,
                size: 24,
                color: reportType.color,
              ),
            ),
            const SizedBox(height: 12),

            // Title only
            Text(
              reportType.displayName,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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

  void _navigateToReportDetail(BuildContext context, ReportType reportType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(reportType: reportType),
      ),
    );
  }
}

class ReportDetailScreen extends StatefulWidget {
  final ReportType reportType;

  const ReportDetailScreen({
    super.key,
    required this.reportType,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportFilterModel _filter = ReportFilterModel(
    type: ReportType.client,
    period: ReportPeriod.thisMonth,
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filter = _filter.copyWith(type: widget.reportType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.reportType.displayName,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textXLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Info Card
            _buildReportInfoCard(),
            const SizedBox(height: 30),

            // Quick Period Buttons
            _buildQuickPeriodButtons(),
            const SizedBox(height: 30),

            // Generate Report Button
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.reportType.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              widget.reportType.icon,
              size: 30,
              color: widget.reportType.color,
            ),
          ),
          const SizedBox(width: 20),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reportType.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textXLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPeriodButtons() {
    final quickPeriods = [
      ReportPeriod.today,
      ReportPeriod.thisWeek,
      ReportPeriod.thisMonth,
      ReportPeriod.thisYear,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Periods',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickPeriods.map((period) {
            final isSelected = _filter.period == period;
            return InkWell(
              onTap: () => _updatePeriod(period),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.reportType.color
                      : widget.reportType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.reportType.color,
                    width: 1,
                  ),
                ),
                child: Text(
                  period.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    color: isSelected ? Colors.white : widget.reportType.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.reportType.color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
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
                    'Generate Report',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textLarge,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _updatePeriod(ReportPeriod period) {
    setState(() {
      _filter = _filter.copyWith(period: period);
    });
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await ReportService.generateReport(_filter);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportViewScreen(report: report),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
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
}

class ReportViewScreen extends StatelessWidget {
  final ReportDataModel report;

  const ReportViewScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          report.title,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textXLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: ListView(
          children: [
            // Report Header
            _buildReportHeader(context),
            const SizedBox(height: 30),

            // Summary Section
            _buildSummarySection(context),
            const SizedBox(height: 30),

            // Data Section
            _buildDataSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.title,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textXLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Period: ${report.formattedDateRange}',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...report.summary.entries.map((entry) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatKey(entry.key),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _formatValue(entry.value),
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w600,
                    color: report.type.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    if (report.data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.paddingLarge * 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Icon(
              Icons.data_usage,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for this period',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Data',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${report.data.length} records found',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ...report.data.take(10).map((item) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.containsKey('client_name'))
                  Text(
                    item['client_name'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (item.containsKey('description'))
                  Text(
                    item['description'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 8),
                ...item.entries
                    .take(3)
                    .where((entry) =>
                        entry.key != 'client_name' &&
                        entry.key != 'description')
                    .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatKey(entry.key),
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatValue(entry.value),
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
        if (report.data.length > 10)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Showing 10 of ${report.data.length} records',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is double) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}
