import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../l10n/app_localizations.dart';


class AllDeadlinesScreen extends StatefulWidget {
  const AllDeadlinesScreen({super.key});

  @override
  State<AllDeadlinesScreen> createState() => _AllDeadlinesScreenState();
}

class _AllDeadlinesScreenState extends State<AllDeadlinesScreen> {
  List<UpcomingDeadline> _deadlines = [];
  bool _isLoading = true;
  DeadlineType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadDeadlines();
  }

  Future<void> _loadDeadlines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deadlines = await DashboardService.getUpcomingDeadlines(limit: 50);
      setState(() {
        _deadlines = deadlines;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading deadlines: $e'),
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

  List<UpcomingDeadline> get _filteredDeadlines {
    if (_selectedFilter == null) {
      return _deadlines;
    }
    return _deadlines.where((d) => d.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.allDeadlines??'All Deadlines',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textXLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadDeadlines,
            tooltip: AppLocalizations.of(context)?.refresh??'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          
          // Deadlines List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDeadlines.isEmpty
                    ? _buildEmptyState()
                    : _buildDeadlinesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      null, // All
      DeadlineType.project,
      DeadlineType.invoice,
      DeadlineType.tax,
      DeadlineType.payment,
    ];

    return Container(
      height: 50,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          final title = filter?.displayName(context) ?? AppLocalizations.of(context)?.all??'All';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(title),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : null;
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        },
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
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.noDeadlinesFound??'No deadlines found',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == null
                ? AppLocalizations.of(context)!.noDeadlinesFound
                : AppLocalizations.of(context)!
                .noDeadlinesWithFilter(_selectedFilter!.displayName(context).toLowerCase()),
            textAlign: TextAlign.center,
          )

        ],
      ),
    );
  }

  Widget _buildDeadlinesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredDeadlines.length,
      itemBuilder: (context, index) {
        final deadline = _filteredDeadlines[index];
        return _buildDeadlineCard(deadline);
      },
    );
  }

  Widget _buildDeadlineCard(UpcomingDeadline deadline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: deadline.urgencyColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: deadline.urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              deadline.type.icon,
              size: 20,
              color: deadline.urgencyColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deadline.description,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                   const  Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${deadline.deadline.day}/${deadline.deadline.month}/${deadline.deadline.year}',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deadline.urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              deadline.formattedDeadline(context),
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                fontWeight: FontWeight.w600,
                color: deadline.urgencyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
