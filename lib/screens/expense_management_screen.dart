import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_model.dart';
import '../models/project_model.dart';
import '../models/client_model.dart' as client_model;
import '../services/expense_service.dart';
import '../services/project_service.dart';
import '../services/client_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

import 'add_edit_expense_screen.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final _searchController = TextEditingController();
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  List<ProjectModel> _projects = [];
  List<client_model.ClientModel> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ExpenseCategory? _selectedCategoryFilter;
  String? _selectedProjectFilter;
  String? _selectedClientFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final expenses = await ExpenseService.getAllExpenses();
      final projects = await ProjectService.getAllProjects();
      final clients = await ClientService.getClients();

      setState(() {
        _expenses = expenses;
        _filteredExpenses = expenses;
        _projects = projects;
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _filterExpenses() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        final matchesSearch = _searchQuery.isEmpty ||
            expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (expense.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (expense.vendor
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        final matchesCategory = _selectedCategoryFilter == null ||
            expense.category == _selectedCategoryFilter;

        final matchesProject = _selectedProjectFilter == null ||
            expense.projectId == _selectedProjectFilter;

        final matchesClient = _selectedClientFilter == null ||
            expense.clientId == _selectedClientFilter;

        return matchesSearch &&
            matchesCategory &&
            matchesProject &&
            matchesClient;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterExpenses();
  }

  void _onCategoryFilterChanged(ExpenseCategory? category) {
    setState(() => _selectedCategoryFilter = category);
    _filterExpenses();
  }

  void _onProjectFilterChanged(String? projectId) {
    setState(() => _selectedProjectFilter = projectId);
    _filterExpenses();
  }

  void _onClientFilterChanged(String? clientId) {
    setState(() => _selectedClientFilter = clientId);
    _filterExpenses();
  }

  void _navigateToAddExpense() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditExpenseScreen(),
          ),
        )
        .then((_) => _loadData());
  }

  void _navigateToEditExpense(ExpenseModel expense) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditExpenseScreen(expense: expense),
          ),
        )
        .then((_) => _loadData());
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
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

    if (confirmed == true && expense.id != null) {
      try {
        await ExpenseService.deleteExpense(expense.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expense: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Expense Management',
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
          IconButton(
            onPressed: _navigateToAddExpense,
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
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      hintStyle:
                          GoogleFonts.poppins(color: AppColors.textLight),
                      prefixIcon: const Icon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingMedium,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedCategoryFilter == null,
                          () => _onCategoryFilterChanged(null)),
                      const SizedBox(width: 8),
                      ...ExpenseCategory.values.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              category.displayName,
                              _selectedCategoryFilter == category,
                              () => _onCategoryFilterChanged(category),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expense List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredExpenses.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium),
                        itemCount: _filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = _filteredExpenses[index];
                          return _buildExpenseCard(expense);
                        },
                      ),
          ),
        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.receipt,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategoryFilter != null
                ? 'No expenses found'
                : 'No expenses yet',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategoryFilter != null
                ? 'Try adjusting your search or filters'
                : 'Create your first expense to get started',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _selectedCategoryFilter == null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add Expense',
              onPressed: _navigateToAddExpense,
              icon: FontAwesomeIcons.plus,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final project = _projects.firstWhere(
      (p) => p.id == expense.projectId,
      orElse: () => ProjectModel(
        clientId: '',
        projectName: 'Unknown Project',
        description: '',
        status: ProjectStatus.notStarted,
        pricingType: PricingType.fixedPrice,
        currency: client_model.Currency.da,
        createdAt: DateTime.now(),
      ),
    );

    final client = _clients.firstWhere(
      (c) => c.id == expense.clientId,
      orElse: () => client_model.ClientModel(
        name: 'Unknown Client',
        email: '',
        phone: '',
        address: '',
        clientType: client_model.ClientType.individualLocal,
        currency: client_model.Currency.da,
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => _navigateToEditExpense(expense),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: expense.category.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  expense.category.icon,
                  color: AppColors.textWhite,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Expense Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      expense.title,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Project/Client info
                    Text(
                      expense.projectId != null
                          ? project.projectName
                          : client.name,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.category.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.textSmall,
                              color: AppColors.textLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and Actions
              SizedBox(
                width: 120, // Fixed width to prevent overflow
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                  Text(
                    '${expense.amount.toStringAsFixed(2)} ${expense.currency.code}',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      FontAwesomeIcons.ellipsisVertical,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                    color: AppColors.surface,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditExpense(expense);
                      } else if (value == 'delete') {
                        _deleteExpense(expense);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.pen,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontSize: AppConstants.textSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.trash,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: AppColors.error,
                                fontSize: AppConstants.textSmall,
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
            ],
          ),
        ),
      ),
    );
  }


}
