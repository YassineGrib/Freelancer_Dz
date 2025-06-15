import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  List<RecentActivity> _activities = [];
  List<RecentActivity> _filteredActivities = [];
  bool _isLoading = true;
  ActivityType? _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activities = await DashboardService.getRecentActivities(limit: 100);
      setState(() {
        _activities = activities;
        _filteredActivities = activities;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activities: $e'),
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

  void _filterActivities() {
    setState(() {
      _filteredActivities = _activities.where((activity) {
        final matchesSearch = _searchQuery.isEmpty ||
            activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            activity.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesType = _selectedFilter == null || activity.type == _selectedFilter;
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterActivities();
  }

  void _onFilterChanged(ActivityType? type) {
    setState(() => _selectedFilter = type);
    _filterActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'All Activities',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowsRotate, color: AppColors.primary),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Projects', ActivityType.project),
                      const SizedBox(width: 8),
                      _buildFilterChip('Payments', ActivityType.payment),
                      const SizedBox(width: 8),
                      _buildFilterChip('Invoices', ActivityType.invoice),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expenses', ActivityType.expense),
                      const SizedBox(width: 8),
                      _buildFilterChip('Clients', ActivityType.client),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tax', ActivityType.tax),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Activities List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredActivities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadActivities,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: _filteredActivities.length,
                          itemBuilder: (context, index) {
                            final activity = _filteredActivities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ActivityType? type) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textSmall,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => _onFilterChanged(type),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.clockRotateLeft,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != null
                ? 'No activities match your filters'
                : 'No activities yet',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != null
                ? 'Try adjusting your search or filters'
                : 'Activities will appear here as you use the app',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(RecentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.timeAgo,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.project:
        return FontAwesomeIcons.briefcase;
      case ActivityType.payment:
        return FontAwesomeIcons.creditCard;
      case ActivityType.client:
        return FontAwesomeIcons.user;
      case ActivityType.invoice:
        return FontAwesomeIcons.fileInvoice;
      case ActivityType.expense:
        return FontAwesomeIcons.receipt;
      case ActivityType.tax:
        return FontAwesomeIcons.percent;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.project:
        return Colors.blue;
      case ActivityType.payment:
        return Colors.green;
      case ActivityType.client:
        return Colors.purple;
      case ActivityType.invoice:
        return Colors.orange;
      case ActivityType.expense:
        return Colors.red;
      case ActivityType.tax:
        return Colors.indigo;
    }
  }
}
