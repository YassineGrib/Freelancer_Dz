import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/project_model.dart';
import '../models/payment_model.dart';
import '../models/client_model.dart';
import '../services/project_service.dart';
import '../services/payment_service.dart';
import '../services/payment_validation_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

import 'add_edit_project_screen.dart';

// Payment filter enum
enum PaymentFilter {
  fullyPaid,
  partiallyPaid,
  unpaid,
  overdue,
}

extension PaymentFilterExtension on PaymentFilter {
  String get displayName {
    switch (this) {
      case PaymentFilter.fullyPaid:
        return 'Fully Paid';
      case PaymentFilter.partiallyPaid:
        return 'Partially Paid';
      case PaymentFilter.unpaid:
        return 'Unpaid';
      case PaymentFilter.overdue:
        return 'Overdue';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentFilter.fullyPaid:
        return FontAwesomeIcons.circleCheck;
      case PaymentFilter.partiallyPaid:
        return FontAwesomeIcons.clockRotateLeft;
      case PaymentFilter.unpaid:
        return FontAwesomeIcons.circleXmark;
      case PaymentFilter.overdue:
        return FontAwesomeIcons.triangleExclamation;
    }
  }

  Color get color {
    switch (this) {
      case PaymentFilter.fullyPaid:
        return AppColors.success;
      case PaymentFilter.partiallyPaid:
        return Colors.orange;
      case PaymentFilter.unpaid:
        return AppColors.error;
      case PaymentFilter.overdue:
        return AppColors.error;
    }
  }
}

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ProjectStatus? _selectedFilter;
  PaymentFilter? _selectedPaymentFilter;

  // Smart UI state
  bool _isSearchExpanded = false;
  bool _isFiltersExpanded = false;
  late AnimationController _searchAnimationController;
  late AnimationController _filtersAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<double> _filtersAnimation;

  // Cache for payment data to avoid repeated API calls
  final Map<String, Map<String, dynamic>> _paymentSummaryCache = {};
  bool _isLoadingPayments = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProjects();
  }

  void _initializeAnimations() {
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filtersAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );
    _filtersAnimation = CurvedAnimation(
      parent: _filtersAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    _filtersAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      setState(() => _isLoading = true);
      final projects = await ProjectService.getAllProjects();
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _isLoading = false;
      });

      // Load payment data for all projects
      _loadPaymentDataForProjects();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects: $e')),
        );
      }
    }
  }

  // Load payment data for all projects
  Future<void> _loadPaymentDataForProjects() async {
    if (_projects.isEmpty) return;

    setState(() {
      _isLoadingPayments = true;
    });

    try {
      // Clear cache to ensure fresh data
      _paymentSummaryCache.clear();

      // Load payment data for each project
      for (final project in _projects) {
        if (project.id != null) {
          try {
            final summary =
                await PaymentValidationService.getProjectPaymentSummary(
                    project.id!);
            _paymentSummaryCache[project.id!] = summary;
          } catch (e) {
            // If payment data fails for one project, continue with others
            print('Failed to load payment data for project ${project.id}: $e');
            _paymentSummaryCache[project.id!] = {
              'completedTotal': 0.0,
              'pendingTotal': 0.0,
              'paymentProgress': 0.0,
            };
          }
        }
      }

      setState(() {
        _isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPayments = false;
      });
      // Handle error silently in production
    }
  }

  // Refresh payment data when returning from other screens
  Future<void> _refreshPaymentData() async {
    if (_projects.isNotEmpty) {
      await _loadPaymentDataForProjects();
    }
  }

  // Override to refresh data when screen becomes visible
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh payment data when returning to this screen
    if (mounted && _projects.isNotEmpty) {
      _refreshPaymentData();
    }
  }

  void _filterProjects() {
    setState(() {
      _filteredProjects = _projects.where((project) {
        final matchesSearch = _searchQuery.isEmpty ||
            project.projectName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            project.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (project.client?.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (project.client?.companyName
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        final matchesStatusFilter =
            _selectedFilter == null || project.status == _selectedFilter;

        final matchesPaymentFilter = _selectedPaymentFilter == null ||
            _matchesPaymentFilter(project, _selectedPaymentFilter!);

        return matchesSearch && matchesStatusFilter && matchesPaymentFilter;
      }).toList();
    });
  }

  bool _matchesPaymentFilter(ProjectModel project, PaymentFilter filter) {
    if (project.id == null) return false;

    final totalAmount = project.totalValue ?? 0.0;
    if (totalAmount <= 0) return filter == PaymentFilter.unpaid;

    final paidAmount = _calculatePaidAmount(project.id!);
    final paymentProgress = paidAmount / totalAmount;
    final isOverdue = project.isOverdue;

    switch (filter) {
      case PaymentFilter.fullyPaid:
        return paymentProgress >= 1.0;
      case PaymentFilter.partiallyPaid:
        return paymentProgress > 0.0 && paymentProgress < 1.0;
      case PaymentFilter.unpaid:
        return paymentProgress == 0.0;
      case PaymentFilter.overdue:
        return isOverdue && paymentProgress < 1.0;
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterProjects();
  }

  void _onFilterChanged(ProjectStatus? filter) {
    setState(() => _selectedFilter = filter);
    _filterProjects();
  }

  void _onPaymentFilterChanged(PaymentFilter? filter) {
    setState(() => _selectedPaymentFilter = filter);
    _filterProjects();
  }

  // Smart UI methods
  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });

    if (_isSearchExpanded) {
      _searchAnimationController.forward();
      // Auto-focus search field when expanded
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    } else {
      _searchAnimationController.reverse();
      _searchController.clear();
      _onSearchChanged('');
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleFilters() {
    setState(() {
      _isFiltersExpanded = !_isFiltersExpanded;
    });

    if (_isFiltersExpanded) {
      _filtersAnimationController.forward();
    } else {
      _filtersAnimationController.reverse();
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedFilter = null;
      _selectedPaymentFilter = null;
    });
    _filterProjects();
  }

  bool get _hasActiveFilters =>
      _selectedFilter != null ||
      _selectedPaymentFilter != null ||
      _searchQuery.isNotEmpty;

  int get _activeFilterCount {
    int count = 0;
    if (_selectedFilter != null) count++;
    if (_selectedPaymentFilter != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  String _getActiveFiltersText() {
    List<String> filters = [];
    if (_selectedFilter != null) {
      filters.add(_selectedFilter!.displayName);
    }
    if (_selectedPaymentFilter != null) {
      filters.add(_selectedPaymentFilter!.displayName);
    }
    if (_searchQuery.isNotEmpty) {
      filters.add(
          '${(AppLocalizations.of(context)?.search??'Search')}: "${_searchQuery.length > 20 ? '${_searchQuery.substring(0, 20)}...' : _searchQuery}"');
    }
    return filters.join(' • ');
  }

  void _navigateToAddProject() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditProjectScreen(),
          ),
        )
        .then((_) => _loadProjects());
  }

  void _navigateToEditProject(ProjectModel project) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditProjectScreen(project: project),
          ),
        )
        .then((_) => _loadProjects());
  }

  // Method to refresh data when returning from other screens
  Future<void> refreshData() async {
    await _loadProjects();
  }

  // Quick status change method
  Future<void> _changeProjectStatus(
      ProjectModel project, ProjectStatus newStatus) async {
    if (project.id == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Updating status to ${newStatus.displayName}...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Update project status
      final updatedProject = project.copyWith(status: newStatus);
      await ProjectService.updateProject(updatedProject);

      // Reload projects to reflect changes
      await _loadProjects();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteProject(ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Project', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete "${project.projectName}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true && project.id != null) {
      try {
        await ProjectService.deleteProject(project.id!);
        _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting project: $e')),
          );
        }
      }
    }
  }

  Future<void> _markProjectAsPaid(ProjectModel project) async {
    if (project.id == null || project.client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot mark project as paid: Missing project or client information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate remaining amount to be paid
    final totalAmount = project.totalValue ?? 0.0;
    final paidAmount = _calculatePaidAmount(project.id!);
    final remainingAmount = totalAmount - paidAmount;

    if (remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project is already fully paid'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog with payment details
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Project as Paid', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a payment for the remaining amount?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Project: ${project.projectName}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  Text(
                    'Client: ${project.client!.name}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  Text(
                    'Amount: ${remainingAmount.toStringAsFixed(2)} ${project.currency.code}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text('Create Payment', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Creating payment...'),
              ],
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Create payment with default configuration
        final payment = PaymentModel(
          projectId: project.id!,
          clientId: project.client!.id!,
          paymentAmount: remainingAmount,
          currency: project.currency,
          paymentMethod: _getDefaultPaymentMethod(project.currency),
          paymentStatus: PaymentStatus.completed,
          paymentType: PaymentTypeExtension.getSuggestedPaymentType(
              remainingAmount, totalAmount),
          paymentDate: DateTime.now(),
          description: 'Full payment for project: ${project.projectName}',
          notes: 'Auto-generated payment from project management',
          createdAt: DateTime.now(),
        );

        // Create the payment
        await PaymentService.addPayment(payment);

        // Refresh project data to reflect the new payment
        await _loadProjects();

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment of ${remainingAmount.toStringAsFixed(2)} ${project.currency.code} created successfully!',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating payment: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Helper method to get default payment method based on currency
  PaymentMethod _getDefaultPaymentMethod(Currency currency) {
    switch (currency) {
      case Currency.da:
        return PaymentMethod.cash; // Default for Algerian Dinar
      case Currency.usd:
      case Currency.eur:
        return PaymentMethod.bankTransfer; // Default for foreign currencies
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.projectManagement??'Project Management',
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
        actions: [
          // Smart Search Toggle
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearchExpanded
                  ? FontAwesomeIcons.xmark
                  : FontAwesomeIcons.magnifyingGlass,
              color:
                  _isSearchExpanded ? AppColors.error : AppColors.textPrimary,
              size: 20,
            ),
          ),
          // Smart Filter Toggle with Badge
          Stack(
            children: [
              IconButton(
                onPressed: _toggleFilters,
                icon: Icon(
                  FontAwesomeIcons.filter,
                  color: _hasActiveFilters
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  size: 20,
                ),
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Add Project Button
          IconButton(
            onPressed: _navigateToAddProject,
            icon: const Icon(
              FontAwesomeIcons.plus,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Smart Search Section
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _searchAnimation,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.background,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText:
                                'Search projects, clients, descriptions...',
                            hintStyle:
                                GoogleFonts.poppins(color: AppColors.textLight),
                            prefixIcon: const Icon(
                              FontAwesomeIcons.magnifyingGlass,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      FontAwesomeIcons.xmark,
                                      color: AppColors.textLight,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.circleInfo,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Found ${_filteredProjects.length} result${_filteredProjects.length != 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: AppConstants.textSmall,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          // Smart Filter Section
          AnimatedBuilder(
            animation: _filtersAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _filtersAnimation,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Filter Header with Clear All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.textMedium,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_hasActiveFilters)
                            TextButton(
                              onPressed: _clearAllFilters,
                              child: Text(
                                'Clear All',
                                style: GoogleFonts.poppins(
                                  fontSize: AppConstants.textSmall,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Project Status Filter Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Status',
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.textSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('All', _selectedFilter == null,
                                    () => _onFilterChanged(null)),
                                const SizedBox(width: 8),
                                ...ProjectStatus.values.map((status) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildFilterChip(
                                        status.displayName,
                                        _selectedFilter == status,
                                        () => _onFilterChanged(status),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Payment Status Filter Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Status',
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.textSmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPaymentFilterChip(
                                    'All',
                                    _selectedPaymentFilter == null,
                                    () => _onPaymentFilterChanged(null)),
                                const SizedBox(width: 8),
                                ...PaymentFilter.values.map((filter) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _buildPaymentFilterChip(
                                        filter.displayName,
                                        _selectedPaymentFilter == filter,
                                        () => _onPaymentFilterChanged(filter),
                                        icon: filter.icon,
                                        color: filter.color,
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Active Filters Summary (when filters are active but panel is closed)
          if (_hasActiveFilters && !_isFiltersExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMedium,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.filter,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: Text(
                      'Clear',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Project List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredProjects.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          return _buildProjectCard(project);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProject,
        backgroundColor: AppColors.primary,
        child: const Icon(
          FontAwesomeIcons.plus,
          color: AppColors.textWhite,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textSmall,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppColors.surface,
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && isSelected) ...[
              Icon(
                icon,
                size: 12,
                color: AppColors.textWhite,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.diagramProject,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedFilter != null ||
                    _selectedPaymentFilter != null
                ? AppLocalizations.of(context)?.noProjectsFound??'No projects found'
                : AppLocalizations.of(context)?.noProjectsYet??'No projects yet',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedFilter != null ||
                    _selectedPaymentFilter != null
                ? AppLocalizations.of(context)?.tryAdjustingFilters??'Try adjusting your search or filters'
                : AppLocalizations.of(context)?.createFirstProject??'Create your first project to get started',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty &&
              _selectedFilter == null &&
              _selectedPaymentFilter == null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: AppLocalizations.of(context)?.addProject??'Add Project',
              onPressed: _navigateToAddProject,
              icon: FontAwesomeIcons.plus,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final statusColor = ProjectModel.getStatusColor(project.status);
    final isOverdue = project.isOverdue;

    // Calculate financial progress (get real payments for this project)
    final totalAmount = project.totalValue ?? 0.0;
    final paidAmount = _calculatePaidAmount(project.id ?? '');
    final remainingAmount = totalAmount - paidAmount;
    final paymentProgress = totalAmount > 0 ? (paidAmount / totalAmount) : 0.0;

    // Calculate days remaining (using end date if available)
    final now = DateTime.now();
    final deadline =
        project.endDate ?? project.createdAt.add(const Duration(days: 30));
    final daysRemaining = deadline.difference(now).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToEditProject(project),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Compact
              Row(
                children: [
                  // Compact Avatar
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getProjectInitial(project),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Project Info - Compact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              project.client?.isCompany == true
                                  ? FontAwesomeIcons.building
                                  : FontAwesomeIcons.user,
                              size: 10,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                project.client != null
                                    ? (project.client!.isCompany &&
                                            project.client!.companyName != null
                                        ? project.client!.companyName!
                                        : project.client!.name)
                                    : 'No client',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Compact Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Dropdown - Smaller
                      _buildCompactStatusDropdown(project, statusColor),
                      const SizedBox(width: 6),
                      // More Menu - Smaller
                      _buildCompactActionsMenu(project),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Compact Info Grid
              _buildCompactInfoGrid(project, totalAmount, paidAmount,
                  paymentProgress, isOverdue, daysRemaining),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for project initial
  String _getProjectInitial(ProjectModel project) {
    return project.projectName.isNotEmpty
        ? project.projectName[0].toUpperCase()
        : 'P';
  }

  // Calculate paid amount for a project from real payment data
  double _calculatePaidAmount(String projectId) {
    if (projectId.isEmpty) return 0.0;

    // Get payment data from cache
    final paymentSummary = _paymentSummaryCache[projectId];
    if (paymentSummary != null) {
      return paymentSummary['completedTotal'] ?? 0.0;
    }

    // Return 0 if no payment data available yet
    return 0.0;
  }

  // Build Compact Status Dropdown
  Widget _buildCompactStatusDropdown(ProjectModel project, Color statusColor) {
    return Container(
      constraints: const BoxConstraints(
          minWidth: 100), // Increased minimum width to match progress section
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3), // Increased horizontal padding
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectStatus>(
          value: project.status,
          isDense: true,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
          dropdownColor: AppColors.surface,
          icon: Icon(
            FontAwesomeIcons.chevronDown,
            size: 8,
            color: statusColor,
          ),
          onChanged: (ProjectStatus? newStatus) {
            if (newStatus != null && newStatus != project.status) {
              _changeProjectStatus(project, newStatus);
            }
          },
          items: ProjectStatus.values.map((ProjectStatus status) {
            final itemColor = ProjectModel.getStatusColor(status);
            return DropdownMenuItem<ProjectStatus>(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: itemColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Build Compact Actions Menu
  Widget _buildCompactActionsMenu(ProjectModel project) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(
          FontAwesomeIcons.ellipsisVertical,
          size: 12,
          color: AppColors.textSecondary,
        ),
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        onSelected: (value) {
          if (value == 'edit') {
            _navigateToEditProject(project);
          } else if (value == 'delete') {
            _deleteProject(project);
          } else if (value == 'mark_paid') {
            _markProjectAsPaid(project);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: AppLocalizations.of(context)?.edit,
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.pen,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.edit??'Edit',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'mark_paid',
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.creditCard,
                  size: 12,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.markAsPaid??'Mark as Paid',
                  style: GoogleFonts.poppins(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: AppLocalizations.of(context)?.delete??'delete',
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.trash,
                  size: 12,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)?.delete??'Delete',
                  style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Compact Info Grid
  Widget _buildCompactInfoGrid(
      ProjectModel project,
      double totalAmount,
      double paidAmount,
      double paymentProgress,
      bool isOverdue,
      int daysRemaining) {
    final remainingAmount = totalAmount - paidAmount;

    return Column(
      children: [
        // Financial Row with Progress and Timeline on the right
        if (totalAmount > 0) ...[
          Row(
            children: [
              // Financial Section - Left side
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      // Financial Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.dollarSign,
                                size: 10,
                                color: paymentProgress >= 1.0
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${totalAmount.toStringAsFixed(0)} ${project.currency.code}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: paymentProgress >= 1.0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          _isLoadingPayments
                              ? const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Text(
                                  '${(paymentProgress * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: paymentProgress >= 1.0
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Progress Bar
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: paymentProgress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: paymentProgress >= 1.0
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Payment Stats - Single Row Format
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Paid amount
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "${AppLocalizations.of(context)?.paid??'Paid'}:" ,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: paidAmount.toStringAsFixed(0),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Left amount
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Left: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: remainingAmount.toStringAsFixed(0),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Progress and Timeline - Right side
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Project Progress
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.listCheck,
                            size: 10,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)?.progress??'Progress',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${project.progressPercentage}%',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Timeline Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red.withValues(alpha: 0.08)
                            : (daysRemaining <= 7
                                ? Colors.orange.withValues(alpha: 0.08)
                                : AppColors.textLight.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOverdue
                              ? Colors.red.withValues(alpha: 0.15)
                              : (daysRemaining <= 7
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : AppColors.textLight
                                      .withValues(alpha: 0.15)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            project.endDate != null
                                ? (isOverdue
                                    ? FontAwesomeIcons.triangleExclamation
                                    : FontAwesomeIcons.calendar)
                                : FontAwesomeIcons.calendar,
                            size: 10,
                            color: project.endDate != null
                                ? (isOverdue
                                    ? Colors.red
                                    : (daysRemaining <= 7
                                        ? Colors.orange
                                        : AppColors.textLight))
                                : AppColors.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.endDate != null
                                ? (isOverdue ? 'Overdue' : 'Days left')
                                : 'No deadline',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (project.endDate != null && !isOverdue)
                            Text(
                              '${daysRemaining}d',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: daysRemaining <= 7
                                    ? Colors.orange
                                    : AppColors.textLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // When no financial data, show progress and timeline in bottom row
          Row(
            children: [
              // Project Progress
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.listCheck,
                        size: 10,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)?.progress??'Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${project.progressPercentage}%',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Timeline Info
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withValues(alpha: 0.08)
                        : (daysRemaining <= 7
                            ? Colors.orange.withValues(alpha: 0.08)
                            : AppColors.textLight.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOverdue
                          ? Colors.red.withValues(alpha: 0.15)
                          : (daysRemaining <= 7
                              ? Colors.orange.withValues(alpha: 0.15)
                              : AppColors.textLight.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        project.endDate != null
                            ? (isOverdue
                                ? FontAwesomeIcons.triangleExclamation
                                : FontAwesomeIcons.calendar)
                            : FontAwesomeIcons.calendar,
                        size: 10,
                        color: project.endDate != null
                            ? (isOverdue
                                ? Colors.red
                                : (daysRemaining <= 7
                                    ? Colors.orange
                                    : AppColors.textLight))
                            : AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        project.endDate != null
                            ? (isOverdue ? 'Overdue' : 'Days left')
                            : 'No deadline',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (project.endDate != null && !isOverdue)
                        Text(
                          '${daysRemaining}d',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: daysRemaining <= 7
                                ? Colors.orange
                                : AppColors.textLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
