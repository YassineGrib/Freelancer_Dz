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
import '../widgets/custom_text_field.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;

  List<ProjectModel> _projects = [];
  List<client_model.ClientModel> _clients = [];

  ProjectModel? _selectedProject;
  client_model.ClientModel? _selectedClient;
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  Currency _selectedCurrency = Currency.da;
  DateTime _selectedExpenseDate = DateTime.now();
  bool _isReimbursable = false;
  bool _isRecurring = false;
  DateTime? _recurringEndDate;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (_isEditing) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final projects = await ProjectService.getAllProjects();
      final clients = await ClientService.getClients();

      setState(() {
        _projects = projects;
        _clients = clients;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _populateFields() {
    final expense = widget.expense!;
    _titleController.text = expense.title;
    _descriptionController.text = expense.description ?? '';
    _amountController.text = expense.amount.toString();
    _vendorController.text = expense.vendor ?? '';
    _notesController.text = expense.notes ?? '';

    _selectedCategory = expense.category;
    _selectedPaymentMethod = expense.paymentMethod;
    _selectedCurrency = expense.currency;
    _selectedExpenseDate = expense.expenseDate;
    _isReimbursable = expense.isReimbursable;
    _isRecurring = expense.isRecurring;
    _recurringEndDate = expense.recurringEndDate;

    // Set selected project and client after data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Find project by ID, only set if found
        try {
          _selectedProject = _projects.firstWhere(
            (p) => p.id == expense.projectId,
          );
        } catch (e) {
          _selectedProject = null;
        }

        // Find client by ID, only set if found
        try {
          _selectedClient = _clients.firstWhere(
            (c) => c.id == expense.clientId,
          );
        } catch (e) {
          _selectedClient = null;
        }
      });
    });
  }

  void _onProjectChanged(ProjectModel? project) {
    setState(() {
      _selectedProject = project;
      if (project != null) {
        // Auto-select client based on project
        try {
          _selectedClient = _clients.firstWhere(
            (c) => c.id == project.clientId,
          );
        } catch (e) {
          // Client not found, keep current selection
        }

        // Auto-select currency based on project
        _selectedCurrency =
            _convertProjectCurrencyToExpenseCurrency(project.currency);
      }
    });
  }

  void _onClientChanged(client_model.ClientModel? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _selectedProject == null) {
        // Auto-select currency based on client if no project selected
        _selectedCurrency =
            _convertClientCurrencyToExpenseCurrency(client.currency);
      }
    });
  }

  // Helper method to convert project currency to expense currency
  Currency _convertProjectCurrencyToExpenseCurrency(
      client_model.Currency projectCurrency) {
    switch (projectCurrency) {
      case client_model.Currency.da:
        return Currency.da;
      case client_model.Currency.usd:
        return Currency.usd;
      case client_model.Currency.eur:
        return Currency.eur;
    }
  }

  // Helper method to convert client currency to expense currency
  Currency _convertClientCurrencyToExpenseCurrency(
      client_model.Currency clientCurrency) {
    switch (clientCurrency) {
      case client_model.Currency.da:
        return Currency.da;
      case client_model.Currency.usd:
        return Currency.usd;
      case client_model.Currency.eur:
        return Currency.eur;
    }
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expense title is required';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount greater than 0';
    }
    if (amount > 1000000) {
      return 'Amount seems too large. Please verify.';
    }
    return null;
  }

  Future<void> _selectDate(
      BuildContext context, bool isRecurringEndDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isRecurringEndDate
          ? (_recurringEndDate ?? DateTime.now().add(const Duration(days: 30)))
          : _selectedExpenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isRecurringEndDate) {
          _recurringEndDate = picked;
        } else {
          _selectedExpenseDate = picked;
        }
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = ExpenseModel(
        id: _isEditing ? widget.expense!.id : null,
        projectId: _selectedProject?.id,
        clientId: _selectedClient?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        category: _selectedCategory,
        paymentMethod: _selectedPaymentMethod,
        expenseDate: _selectedExpenseDate,
        vendor: _vendorController.text.trim().isEmpty
            ? null
            : _vendorController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isReimbursable: _isReimbursable,
        isRecurring: _isRecurring,
        recurringEndDate: _isRecurring ? _recurringEndDate : null,
        createdAt: _isEditing ? widget.expense!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        await ExpenseService.updateExpense(expense);
      } else {
        await ExpenseService.addExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Expense updated successfully'
                : 'Expense added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            FontAwesomeIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Add Section - Only Title and Amount Required
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.bolt,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quick Add Expense',
                                style: GoogleFonts.poppins(
                                  fontSize: AppConstants.textLarge,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Just enter the title and amount to get started quickly. Other details can be added later.',
                            style: GoogleFonts.poppins(
                              fontSize: AppConstants.textSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Expense Title *',
                            hint: 'Enter expense title',
                            prefixIcon: FontAwesomeIcons.receipt,
                            controller: _titleController,
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Amount *',
                            hint: 'Enter amount',
                            prefixIcon: FontAwesomeIcons.dollarSign,
                            controller: _amountController,
                            validator: _validateAmount,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category, Payment & Currency Section
                    ExpansionTile(
                      title: Text(
                        'Category & Payment Details',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Set category, payment method, and currency',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      initiallyExpanded: _isEditing,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Category'),
                              _buildCategoryDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              _buildSectionTitle('Payment Method'),
                              _buildPaymentMethodDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              _buildSectionTitle('Currency'),
                              _buildCurrencyDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              _buildSectionTitle('Expense Date'),
                              _buildDateField(
                                  'Expense Date', _selectedExpenseDate, false),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Project & Client Section
                    ExpansionTile(
                      title: Text(
                        'Project & Client (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Link expense to a project or client',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      initiallyExpanded: _isEditing &&
                          (_selectedProject != null || _selectedClient != null),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Project (Optional)'),
                              _buildProjectDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              _buildSectionTitle('Client (Optional)'),
                              _buildClientDropdown(),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Additional Details Section
                    ExpansionTile(
                      title: Text(
                        'Additional Details (Optional)',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Add vendor, description, notes, and other options',
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.textSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      initiallyExpanded: _isEditing,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                label: 'Vendor (Optional)',
                                hint: 'Enter vendor name',
                                prefixIcon: FontAwesomeIcons.store,
                                controller: _vendorController,
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              CustomTextField(
                                label: 'Description (Optional)',
                                hint: 'Enter expense description',
                                prefixIcon: FontAwesomeIcons.fileLines,
                                controller: _descriptionController,
                                maxLines: 3,
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              CustomTextField(
                                label: 'Notes (Optional)',
                                hint: 'Additional notes',
                                prefixIcon: FontAwesomeIcons.noteSticky,
                                controller: _notesController,
                                maxLines: 3,
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              // Reimbursable Switch
                              Row(
                                children: [
                                  Switch(
                                    value: _isReimbursable,
                                    onChanged: (value) =>
                                        setState(() => _isReimbursable = value),
                                    activeColor: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reimbursable',
                                    style: GoogleFonts.poppins(
                                      fontSize: AppConstants.textMedium,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),
                              // Recurring Switch
                              Row(
                                children: [
                                  Switch(
                                    value: _isRecurring,
                                    onChanged: (value) =>
                                        setState(() => _isRecurring = value),
                                    activeColor: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recurring Expense',
                                    style: GoogleFonts.poppins(
                                      fontSize: AppConstants.textMedium,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              // Recurring End Date (if recurring is enabled)
                              if (_isRecurring) ...[
                                const SizedBox(
                                    height: AppConstants.paddingMedium),
                                _buildSectionTitle('Recurring End Date'),
                                _buildDateField('Recurring End Date',
                                    _recurringEndDate, true),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.paddingLarge),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.paddingMedium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textWhite),
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update Expense' : 'Add Expense',
                                style: GoogleFonts.poppins(
                                  fontSize: AppConstants.textMedium,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ExpenseCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        hintText: 'Select category',
        prefixIcon: Icon(_selectedCategory.icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      items: ExpenseCategory.values.map((category) {
        return DropdownMenuItem<ExpenseCategory>(
          value: category,
          child: Row(
            children: [
              Icon(category.icon, size: 20, color: category.color),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (category) {
        if (category != null) {
          setState(() => _selectedCategory = category);
        }
      },
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<Currency>(
      value: _selectedCurrency,
      decoration: InputDecoration(
        hintText: 'Select currency',
        prefixIcon: const Icon(FontAwesomeIcons.coins),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      items: Currency.values.map((currency) {
        return DropdownMenuItem<Currency>(
          value: currency,
          child: Text(
            '${currency.code} - ${currency.displayName}',
            style: GoogleFonts.poppins(),
          ),
        );
      }).toList(),
      onChanged: (currency) {
        if (currency != null) {
          setState(() => _selectedCurrency = currency);
        }
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<PaymentMethod>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        hintText: 'Select payment method',
        prefixIcon: const Icon(FontAwesomeIcons.creditCard),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      items: PaymentMethod.values.map((method) {
        return DropdownMenuItem<PaymentMethod>(
          value: method,
          child: Text(
            method.displayName,
            style: GoogleFonts.poppins(),
          ),
        );
      }).toList(),
      onChanged: (method) {
        if (method != null) {
          setState(() => _selectedPaymentMethod = method);
        }
      },
    );
  }

  Widget _buildProjectDropdown() {
    // Ensure selected project is in the list or set to null
    if (_selectedProject != null &&
        !_projects.any((p) => p.id == _selectedProject!.id)) {
      _selectedProject = null;
    }

    return DropdownButtonFormField<ProjectModel>(
      value: _selectedProject,
      decoration: InputDecoration(
        hintText: 'Select a project (optional)',
        prefixIcon: const Icon(FontAwesomeIcons.diagramProject),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      items: _projects.map((project) {
        return DropdownMenuItem<ProjectModel>(
          value: project,
          child: Text(
            project.projectName,
            style: GoogleFonts.poppins(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onProjectChanged,
    );
  }

  Widget _buildClientDropdown() {
    // Ensure selected client is in the list or set to null
    if (_selectedClient != null &&
        !_clients.any((c) => c.id == _selectedClient!.id)) {
      _selectedClient = null;
    }

    return DropdownButtonFormField<client_model.ClientModel>(
      value: _selectedClient,
      decoration: InputDecoration(
        hintText: 'Select a client (optional)',
        prefixIcon: const Icon(FontAwesomeIcons.user),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      items: _clients.map((client) {
        return DropdownMenuItem<client_model.ClientModel>(
          value: client,
          child: Text(
            client.isCompany &&
                    client.companyName != null &&
                    client.companyName!.isNotEmpty
                ? client.companyName!
                : client.name,
            style: GoogleFonts.poppins(),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onClientChanged,
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, bool isRecurringEndDate) {
    return InkWell(
      onTap: () => _selectDate(context, isRecurringEndDate),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(
              FontAwesomeIcons.calendar,
              size: 16,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'Select $label',
                style: GoogleFonts.poppins(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isRecurringEndDate && date != null)
              IconButton(
                onPressed: () => setState(() => _recurringEndDate = null),
                icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
