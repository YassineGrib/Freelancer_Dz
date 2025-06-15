import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/payment_model.dart';
import '../models/project_model.dart';
import '../models/client_model.dart';
import '../services/payment_service.dart';
import '../services/project_service.dart';
import '../services/client_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';

class AddEditPaymentScreen extends StatefulWidget {
  final PaymentModel? payment;

  const AddEditPaymentScreen({super.key, this.payment});

  @override
  State<AddEditPaymentScreen> createState() => _AddEditPaymentScreenState();
}

class _AddEditPaymentScreenState extends State<AddEditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;

  List<ProjectModel> _projects = [];
  List<ClientModel> _clients = [];

  ProjectModel? _selectedProject;
  ClientModel? _selectedClient;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  PaymentStatus _selectedPaymentStatus =
      PaymentStatus.completed; // Default to completed for new payments
  PaymentType _selectedPaymentType = PaymentType.partial;
  Currency _selectedCurrency = Currency.da;
  DateTime _selectedPaymentDate = DateTime.now();
  DateTime? _selectedDueDate;

  // Smart payment system variables
  List<PaymentMethod> _availablePaymentMethods = [];
  List<PaymentType> _availablePaymentTypes = [];
  double? _projectTotalAmount;

  bool get _isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (_isEditing) {
      _populateFields();
    } else {
      // Initialize smart payment system for new payments
      _initializeSmartPaymentSystem();
    }
  }

  /// Initialize smart payment system with default values
  void _initializeSmartPaymentSystem() {
    // Set default available payment methods based on default currency
    _availablePaymentMethods =
        PaymentMethodExtension.getAvailableMethodsForCurrency(
            _selectedCurrency);

    // Set default payment method
    if (_availablePaymentMethods.isNotEmpty) {
      _selectedPaymentMethod = _availablePaymentMethods.first;
    }

    // Set default available payment types
    _availablePaymentTypes = [
      PaymentType.partial,
      PaymentType.advance,
      PaymentType.milestone
    ];
  }

  /// Initialize smart payment system for editing existing payment
  void _initializeSmartPaymentSystemForEdit() {
    // Set available payment methods based on current currency
    _availablePaymentMethods =
        PaymentMethodExtension.getAvailableMethodsForCurrency(
            _selectedCurrency);

    // Ensure current payment method is available
    if (!_availablePaymentMethods.contains(_selectedPaymentMethod)) {
      _availablePaymentMethods.add(_selectedPaymentMethod);
    }

    // Set project total amount if project is selected
    if (_selectedProject != null) {
      _projectTotalAmount = _getProjectTotalAmount(_selectedProject!);
    }

    // Set available payment types
    _availablePaymentTypes = PaymentType.values.toList();
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
    final payment = widget.payment!;
    _amountController.text = payment.paymentAmount.toString();
    _referenceController.text = payment.referenceNumber ?? '';
    _descriptionController.text = payment.description ?? '';
    _notesController.text = payment.notes ?? '';

    _selectedPaymentMethod = payment.paymentMethod;
    _selectedPaymentStatus = payment.paymentStatus;
    _selectedPaymentType = payment.paymentType;
    _selectedCurrency = payment.currency;
    _selectedPaymentDate = payment.paymentDate;
    _selectedDueDate = payment.dueDate;

    // Set selected project and client after data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Find project by ID, only set if found
        try {
          _selectedProject = _projects.firstWhere(
            (p) => p.id == payment.projectId,
          );
        } catch (e) {
          // Project not found, leave as null
          _selectedProject = null;
        }

        // Find client by ID, only set if found
        try {
          _selectedClient = _clients.firstWhere(
            (c) => c.id == payment.clientId,
          );
        } catch (e) {
          // Client not found, leave as null
          _selectedClient = null;
        }

        // Initialize smart payment system for editing
        _initializeSmartPaymentSystemForEdit();
      });
    });
  }

  void _onProjectChanged(ProjectModel? project) {
    setState(() {
      _selectedProject = project;
      if (project != null) {
        // Auto-select client based on project
        _selectedClient = _clients.firstWhere(
          (c) => c.id == project.clientId,
          orElse: () => _selectedClient!,
        );

        // Smart currency selection based on project
        _selectedCurrency = project.currency;

        // Update available payment methods based on currency
        _availablePaymentMethods =
            PaymentMethodExtension.getAvailableMethodsForCurrency(
                _selectedCurrency);

        // Auto-select first available payment method
        if (_availablePaymentMethods.isNotEmpty &&
            !_availablePaymentMethods.contains(_selectedPaymentMethod)) {
          _selectedPaymentMethod = _availablePaymentMethods.first;
        }

        // Store project total amount for smart validation
        _projectTotalAmount = _getProjectTotalAmount(project);

        // Update available payment types based on current amount
        _updateAvailablePaymentTypes();
      }
    });
  }

  void _onClientChanged(ClientModel? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _selectedProject == null) {
        // Auto-select currency based on client if no project selected
        _selectedCurrency = client.currency;

        // Update available payment methods based on currency
        _availablePaymentMethods =
            PaymentMethodExtension.getAvailableMethodsForCurrency(
                _selectedCurrency);

        // Auto-select first available payment method
        if (_availablePaymentMethods.isNotEmpty &&
            !_availablePaymentMethods.contains(_selectedPaymentMethod)) {
          _selectedPaymentMethod = _availablePaymentMethods.first;
        }
      }
    });
  }

  /// Get project total amount for smart payment validation
  double _getProjectTotalAmount(ProjectModel project) {
    // Use the totalValue getter from ProjectModel
    return project.totalValue ?? project.estimatedValue ?? 0.0;
  }

  /// Update available payment types based on current payment amount
  void _updateAvailablePaymentTypes() {
    if (_projectTotalAmount != null) {
      final currentAmount = double.tryParse(_amountController.text) ?? 0.0;
      _availablePaymentTypes = PaymentTypeExtension.getAvailablePaymentTypes(
          currentAmount, _projectTotalAmount!);

      // Auto-suggest payment type
      if (currentAmount > 0) {
        final suggestedType = PaymentTypeExtension.getSuggestedPaymentType(
            currentAmount, _projectTotalAmount!);
        if (_availablePaymentTypes.contains(suggestedType)) {
          _selectedPaymentType = suggestedType;
        }
      }
    }
  }

  /// Smart amount validation
  void _onAmountChanged(String value) {
    _updateAvailablePaymentTypes();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Payment amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount greater than 0';
    }

    // Enhanced validation: Check against project total and existing completed payments
    if (_projectTotalAmount != null && _selectedProject != null) {
      // For completed payments, check against remaining project value
      if (_selectedPaymentStatus == PaymentStatus.completed) {
        // This is a simplified check - the comprehensive validation happens in the service
        if (amount > _projectTotalAmount!) {
          return 'Amount cannot exceed project total\nProject Total: ${_projectTotalAmount!.toStringAsFixed(2)} ${_selectedCurrency.code}';
        }
      }
    }

    // Additional validation for very large amounts
    if (amount > 1000000) {
      return 'Amount seems too large. Please verify.';
    }

    return null;
  }

  Future<void> _selectDate(BuildContext context, bool isDueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate
          ? (_selectedDueDate ?? DateTime.now())
          : _selectedPaymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _selectedDueDate = picked;
        } else {
          _selectedPaymentDate = picked;
        }
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payment = PaymentModel(
        id: _isEditing ? widget.payment!.id : null,
        projectId: _selectedProject!.id!,
        clientId: _selectedClient!.id!,
        paymentAmount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: _selectedPaymentStatus,
        paymentType: _selectedPaymentType,
        paymentDate: _selectedPaymentDate,
        dueDate: _selectedDueDate,
        referenceNumber: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: _isEditing ? widget.payment!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        await PaymentService.updatePayment(payment);
      } else {
        await PaymentService.addPayment(payment);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Payment updated successfully'
                : 'Payment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payment: $e'),
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
        title: Text(_isEditing ? 'Edit Payment' : 'Add Payment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Add Section - Essential Fields Only
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
                          const Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.bolt,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Quick Add Payment',
                                style: TextStyle(
                                  fontSize: AppConstants.textLarge,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select project, client, and enter amount to record payment quickly. Other details can be added later.',
                            style: TextStyle(
                              fontSize: AppConstants.textSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Project Selection
                          _buildSectionTitle('Project *', 'المشروع'),
                          _buildProjectDropdown(),
                          const SizedBox(height: AppConstants.paddingMedium),

                          // Client Selection
                          _buildSectionTitle('Client *', 'العميل'),
                          _buildClientDropdown(),
                          const SizedBox(height: AppConstants.paddingMedium),

                          // Payment Amount
                          CustomTextField(
                            label: 'Payment Amount *',
                            hint: 'Enter payment amount',
                            prefixIcon: FontAwesomeIcons.dollarSign,
                            controller: _amountController,
                            validator: _validateAmount,
                            keyboardType: TextInputType.number,
                            onChanged: _onAmountChanged,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Details Section
                    ExpansionTile(
                      title: const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: AppConstants.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Set payment method, status, type, and currency',
                        style: TextStyle(
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
                              // Currency Selection
                              _buildSectionTitle('Currency', 'العملة'),
                              _buildCurrencyDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Payment Method
                              _buildSectionTitle(
                                  'Payment Method', 'طريقة الدفع'),
                              _buildPaymentMethodDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Payment Status
                              _buildSectionTitle(
                                  'Payment Status', 'حالة الدفع'),
                              _buildPaymentStatusDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Payment Type
                              _buildSectionTitle('Payment Type', 'نوع الدفع'),
                              _buildPaymentTypeDropdown(),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Payment Date
                              _buildSectionTitle('Payment Date', 'تاريخ الدفع'),
                              _buildDateField(
                                  'Payment Date', _selectedPaymentDate, false),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Due Date (Optional)
                              _buildSectionTitle('Due Date (Optional)',
                                  'تاريخ الاستحقاق (اختياري)'),
                              _buildDateField(
                                  'Due Date', _selectedDueDate, true),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Additional Information Section
                    ExpansionTile(
                      title: const Text(
                        'Additional Information (Optional)',
                        style: TextStyle(
                          fontSize: AppConstants.textLarge,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Add reference number, description, and notes',
                        style: TextStyle(
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
                              // Reference Number
                              CustomTextField(
                                label: 'Reference Number (Optional)',
                                hint: 'Invoice number, transaction ID, etc.',
                                prefixIcon: FontAwesomeIcons.hashtag,
                                controller: _referenceController,
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Description
                              CustomTextField(
                                label: 'Description (Optional)',
                                hint: 'Payment description',
                                prefixIcon: FontAwesomeIcons.fileLines,
                                controller: _descriptionController,
                                maxLines: 3,
                              ),
                              const SizedBox(
                                  height: AppConstants.paddingMedium),

                              // Notes
                              CustomTextField(
                                label: 'Notes (Optional)',
                                hint: 'Additional notes',
                                prefixIcon: FontAwesomeIcons.noteSticky,
                                controller: _notesController,
                                maxLines: 3,
                              ),
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
                        onPressed: _isLoading ? null : _savePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.paddingMedium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white),
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update Payment' : 'Add Payment',
                                style: const TextStyle(
                                  fontSize: AppConstants.textMedium,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title, String arabicTitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppConstants.textMedium,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
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
        hintText: 'Select a project',
        prefixIcon: const Icon(FontAwesomeIcons.diagramProject),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      items: _projects.map((project) {
        return DropdownMenuItem<ProjectModel>(
          value: project,
          child: Text(
            project.projectName,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onProjectChanged,
      validator: (value) => value == null ? 'Please select a project' : null,
    );
  }

  Widget _buildClientDropdown() {
    // Ensure selected client is in the list or set to null
    if (_selectedClient != null &&
        !_clients.any((c) => c.id == _selectedClient!.id)) {
      _selectedClient = null;
    }

    return DropdownButtonFormField<ClientModel>(
      value: _selectedClient,
      decoration: InputDecoration(
        hintText: 'Select a client',
        prefixIcon: const Icon(FontAwesomeIcons.user),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      items: _clients.map((client) {
        return DropdownMenuItem<ClientModel>(
          value: client,
          child: Text(
            client.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onClientChanged,
      validator: (value) => value == null ? 'Please select a client' : null,
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<Currency>(
      value: _selectedCurrency,
      decoration: InputDecoration(
        hintText: 'Select currency',
        prefixIcon: const Icon(FontAwesomeIcons.coins),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      items: Currency.values.map((currency) {
        return DropdownMenuItem<Currency>(
          value: currency,
          child: Text('${currency.name} (${currency.code})'),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCurrency = value!),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    // Use smart filtering based on currency
    final availableMethods = _availablePaymentMethods.isNotEmpty
        ? _availablePaymentMethods
        : PaymentMethodExtension.getAvailableMethodsForCurrency(
            _selectedCurrency);

    return DropdownButtonFormField<PaymentMethod>(
      value: availableMethods.contains(_selectedPaymentMethod)
          ? _selectedPaymentMethod
          : null,
      decoration: InputDecoration(
        hintText: 'Select payment method',
        prefixIcon: const Icon(FontAwesomeIcons.creditCard),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        helperText: _selectedCurrency == Currency.da
            ? 'Local payment methods for DZD'
            : 'International payment methods',
      ),
      items: availableMethods.map((method) {
        return DropdownMenuItem<PaymentMethod>(
          value: method,
          child: Text(method.displayName),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
      validator: (value) =>
          value == null ? 'Please select a payment method' : null,
    );
  }

  Widget _buildPaymentStatusDropdown() {
    return DropdownButtonFormField<PaymentStatus>(
      value: _selectedPaymentStatus,
      decoration: InputDecoration(
        hintText: 'Select payment status',
        prefixIcon: const Icon(FontAwesomeIcons.circleCheck),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      items: PaymentStatus.values.map((status) {
        return DropdownMenuItem<PaymentStatus>(
          value: status,
          child: Text(status.displayName),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPaymentStatus = value!),
    );
  }

  Widget _buildPaymentTypeDropdown() {
    // Use smart filtering based on payment amount and project total
    final availableTypes = _availablePaymentTypes.isNotEmpty
        ? _availablePaymentTypes
        : [
            PaymentType.partial,
            PaymentType.advance,
            PaymentType.milestone
          ]; // Default types

    return DropdownButtonFormField<PaymentType>(
      value: availableTypes.contains(_selectedPaymentType)
          ? _selectedPaymentType
          : null,
      decoration: InputDecoration(
        hintText: 'Select payment type',
        prefixIcon: const Icon(FontAwesomeIcons.tags),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        helperText: _projectTotalAmount != null
            ? 'Based on project total: ${_projectTotalAmount!.toStringAsFixed(2)} ${_selectedCurrency.code}'
            : 'Select project first for smart suggestions',
      ),
      items: availableTypes.map((type) {
        return DropdownMenuItem<PaymentType>(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedPaymentType = value!),
      validator: (value) =>
          value == null ? 'Please select a payment type' : null,
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isDueDate) {
    return InkWell(
      onTap: () => _selectDate(context, isDueDate),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          children: [
            const Icon(FontAwesomeIcons.calendar,
                color: AppColors.textSecondary),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'Select $label',
                style: TextStyle(
                  fontSize: AppConstants.textMedium,
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isDueDate && date != null)
              IconButton(
                onPressed: () => setState(() => _selectedDueDate = null),
                icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
