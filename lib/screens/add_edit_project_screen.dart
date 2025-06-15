import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_model.dart';
import '../models/client_model.dart';
import '../services/project_service.dart';
import '../services/client_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AddEditProjectScreen extends StatefulWidget {
  final ProjectModel? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _fixedAmountController = TextEditingController();
  final _estimatedHoursController = TextEditingController();
  final _actualHoursController = TextEditingController();
  final _progressController = TextEditingController();

  List<ClientModel> _clients = [];
  ClientModel? _selectedClient;
  ProjectStatus _selectedStatus = ProjectStatus.notStarted;
  PricingType _selectedPricingType = PricingType.fixedPrice;
  Currency _selectedCurrency = Currency.da;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isLoadingClients = true;
  bool get _isEditing => widget.project != null;

  // Enhanced UI/UX variables
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _showValidationErrors = false;
  final List<GlobalKey<FormState>> _stepFormKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void initState() {
    super.initState();
    _loadClients();
    if (_isEditing) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _fixedAmountController.dispose();
    _estimatedHoursController.dispose();
    _actualHoursController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await ClientService.getAllClients();
      setState(() {
        _clients = clients;
        _isLoadingClients = false;
      });

      // After clients are loaded, populate fields if editing
      if (_isEditing && _clients.isNotEmpty) {
        _setSelectedClientForEditing();
      }
    } catch (e) {
      setState(() => _isLoadingClients = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e')),
        );
      }
    }
  }

  void _populateFields() {
    final project = widget.project!;
    _projectNameController.text = project.projectName;
    _descriptionController.text = project.description;
    _selectedStatus = project.status;
    _selectedPricingType = project.pricingType;
    _selectedCurrency = project.currency;
    _startDate = project.startDate;
    _endDate = project.endDate;
    _progressController.text = project.progressPercentage.toString();

    if (project.hourlyRate != null) {
      _hourlyRateController.text = project.hourlyRate!.toString();
    }
    if (project.fixedAmount != null) {
      _fixedAmountController.text = project.fixedAmount!.toString();
    }
    if (project.estimatedHours != null) {
      _estimatedHoursController.text = project.estimatedHours!.toString();
    }
    if (project.actualHours != null) {
      _actualHoursController.text = project.actualHours!.toString();
    }

    // Note: Client selection is handled separately in _setSelectedClientForEditing
    // after clients are loaded to ensure proper client selection
  }

  void _setSelectedClientForEditing() {
    if (!_isEditing || _clients.isEmpty || widget.project == null) return;

    final project = widget.project!;
    try {
      // Find the client that matches the project's clientId
      final matchingClient = _clients.firstWhere(
        (client) => client.id == project.clientId,
      );

      setState(() {
        _selectedClient = matchingClient;
      });
    } catch (e) {
      // If no matching client found, show a warning but don't crash
      // Note: Using debugPrint instead of print for production safety
      debugPrint(
          'Warning: Could not find client with ID ${project.clientId} for project ${project.projectName}');

      // Optionally show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Warning: Original client not found. Please select a client.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onClientChanged(ClientModel? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && !_isEditing) {
        // Auto-set currency based on client's currency
        _selectedCurrency = client.currency;
      }
    });
  }

  void _onPricingTypeChanged(PricingType? type) {
    if (type != null) {
      setState(() {
        _selectedPricingType = type;
        // Clear opposite pricing fields
        if (type == PricingType.fixedPrice) {
          _hourlyRateController.clear();
          _estimatedHoursController.clear();
          _actualHoursController.clear();
        } else {
          _fixedAmountController.clear();
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, clear it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String? _validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name is required';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    return null;
  }

  String? _validateHourlyRate(String? value) {
    if (_selectedPricingType == PricingType.hourlyRate) {
      if (value == null || value.trim().isEmpty) {
        return 'Hourly rate is required';
      }
      final rate = double.tryParse(value);
      if (rate == null || rate <= 0) {
        return 'Please enter a valid hourly rate';
      }
    }
    return null;
  }

  String? _validateFixedAmount(String? value) {
    if (_selectedPricingType == PricingType.fixedPrice) {
      if (value == null || value.trim().isEmpty) {
        return 'Fixed amount is required';
      }
      final amount = double.tryParse(value);
      if (amount == null || amount <= 0) {
        return 'Please enter a valid amount';
      }
    }
    return null;
  }

  String? _validateEstimatedHours(String? value) {
    if (_selectedPricingType == PricingType.hourlyRate &&
        value != null &&
        value.trim().isNotEmpty) {
      final hours = double.tryParse(value);
      if (hours == null || hours <= 0) {
        return 'Please enter valid hours';
      }
    }
    return null;
  }

  String? _validateActualHours(String? value) {
    if (_selectedPricingType == PricingType.hourlyRate &&
        value != null &&
        value.trim().isNotEmpty) {
      final hours = double.tryParse(value);
      if (hours == null || hours <= 0) {
        return 'Please enter valid hours';
      }
    }
    return null;
  }

  String? _validateProgress(String? value) {
    // Allow empty value, will default to 0
    if (value != null && value.trim().isNotEmpty) {
      final progress = int.tryParse(value);
      if (progress == null || progress < 0 || progress > 100) {
        return 'Progress must be between 0 and 100';
      }
    }
    return null;
  }

  // Enhanced navigation methods
  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    setState(() => _showValidationErrors = true);

    switch (_currentStep) {
      case 0: // Basic Info
        return _stepFormKeys[0].currentState?.validate() ?? false;
      case 1: // Client Selection
        if (_selectedClient == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a client'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      case 2: // Pricing
        return _stepFormKeys[2].currentState?.validate() ?? false;
      case 3: // Timeline & Status
        return _stepFormKeys[3].currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  Future<void> _saveProject() async {
    // Simple validation without forms - just check required fields
    bool allValid = true;
    int firstInvalidStep = -1;

    // Step 0: Basic Info - Check controllers directly
    if (_projectNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      allValid = false;
      firstInvalidStep = 0;
    }

    // Step 1: Client Selection
    if (allValid && _selectedClient == null) {
      allValid = false;
      firstInvalidStep = 1;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Step 2: Pricing - Check based on pricing type
    if (allValid) {
      if (_selectedPricingType == PricingType.fixedPrice) {
        if (_fixedAmountController.text.trim().isEmpty) {
          allValid = false;
          firstInvalidStep = 2;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please enter fixed amount for fixed price projects'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          final amount = double.tryParse(_fixedAmountController.text);
          if (amount == null || amount <= 0) {
            allValid = false;
            firstInvalidStep = 2;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fixed amount must be greater than 0'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (_selectedPricingType == PricingType.hourlyRate) {
        if (_hourlyRateController.text.trim().isEmpty) {
          allValid = false;
          firstInvalidStep = 2;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Please enter hourly rate for hourly rate projects'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          final rate = double.tryParse(_hourlyRateController.text);
          if (rate == null || rate <= 0) {
            allValid = false;
            firstInvalidStep = 2;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hourly rate must be greater than 0'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    // Step 3: Timeline & Status - Date validation
    if (allValid && _startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        allValid = false;
        firstInvalidStep = 3;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be after start date'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Progress percentage validation
    if (allValid && _progressController.text.trim().isNotEmpty) {
      try {
        final progress = int.parse(_progressController.text.trim());
        if (progress < 0 || progress > 100) {
          allValid = false;
          firstInvalidStep = 3;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress percentage must be between 0 and 100'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        allValid = false;
        firstInvalidStep = 3;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid progress percentage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // If validation failed, navigate to first invalid step
    if (!allValid && firstInvalidStep != -1) {
      setState(() => _currentStep = firstInvalidStep);
      _pageController.animateToPage(
        firstInvalidStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final project = ProjectModel(
        id: _isEditing ? widget.project!.id : null,
        clientId: _selectedClient!.id!,
        projectName: _projectNameController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _selectedStatus,
        pricingType: _selectedPricingType,
        hourlyRate: _selectedPricingType == PricingType.hourlyRate &&
                _hourlyRateController.text.isNotEmpty
            ? double.parse(_hourlyRateController.text)
            : null,
        fixedAmount: _selectedPricingType == PricingType.fixedPrice &&
                _fixedAmountController.text.isNotEmpty
            ? double.parse(_fixedAmountController.text)
            : null,
        estimatedHours: _estimatedHoursController.text.isNotEmpty
            ? double.parse(_estimatedHoursController.text)
            : null,
        actualHours: _actualHoursController.text.isNotEmpty
            ? double.parse(_actualHoursController.text)
            : null,
        currency: _selectedCurrency,
        startDate: _startDate,
        endDate: _endDate,
        progressPercentage: _progressController.text.trim().isEmpty
            ? 0
            : int.parse(_progressController.text),
        createdAt: _isEditing ? widget.project!.createdAt : DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
      );

      if (_isEditing) {
        await ProjectService.updateProject(project);
      } else {
        await ProjectService.createProject(project);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Project updated successfully'
                : 'Project created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Project' : 'Add Project',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoadingClients
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Enhanced Progress Indicator
                _buildProgressIndicator(),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentStep = index),
                    children: [
                      _buildBasicInfoStep(),
                      _buildClientSelectionStep(),
                      _buildPricingStep(),
                      _buildTimelineStatusStep(),
                    ],
                  ),
                ),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress circles and lines
          Stack(
            children: [
              // Progress lines (behind circles)
              Positioned.fill(
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        margin: EdgeInsets.only(
                          left:
                              index == 0 ? 50 : 16, // Start after first circle
                          right: index == 2 ? 50 : 16, // End before last circle
                        ),
                        decoration: BoxDecoration(
                          color: index < _currentStep
                              ? Colors.green
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Step circles (on top of lines)
              Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  final isCompleted = index < _currentStep;

                  return Expanded(
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? AppColors.primary
                                  : AppColors.border,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  FontAwesomeIcons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Step Labels
          Row(
            children: [
              Expanded(
                child: Text(
                  'Basic Info',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        _currentStep == 0 ? FontWeight.w600 : FontWeight.normal,
                    color: _currentStep == 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Client',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        _currentStep == 1 ? FontWeight.w600 : FontWeight.normal,
                    color: _currentStep == 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Pricing',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        _currentStep == 2 ? FontWeight.w600 : FontWeight.normal,
                    color: _currentStep == 2
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Timeline',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        _currentStep == 3 ? FontWeight.w600 : FontWeight.normal,
                    color: _currentStep == 3
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 1: Basic Information
  Widget _buildBasicInfoStep() {
    return Form(
      key: _stepFormKeys[0],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.diagramProject,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Information',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Enter basic details about your project',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Project Name
            CustomTextField(
              label: 'Project Name',
              hint: 'Enter a descriptive project name',
              prefixIcon: FontAwesomeIcons.diagramProject,
              controller: _projectNameController,
              validator: _validateProjectName,
            ),

            const SizedBox(height: 20),

            // Description
            CustomTextField(
              label: 'Description',
              hint: 'Describe what this project involves...',
              prefixIcon: FontAwesomeIcons.fileLines,
              controller: _descriptionController,
              validator: _validateDescription,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Tips Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.lightbulb,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: Use a clear, descriptive name and detailed description to help track your project progress.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Client Selection
  Widget _buildClientSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FontAwesomeIcons.users,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Client',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Choose the client for this project',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Client Selection Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: _selectedClient != null
                    ? AppColors.primary
                    : AppColors.border,
                width: _selectedClient != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.user,
                      color: _selectedClient != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Client',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonHideUnderline(
                  child: DropdownButton<ClientModel>(
                    value: _selectedClient,
                    hint: Text(
                      'Select a client for this project',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    isExpanded: true,
                    onChanged: _onClientChanged,
                    items: _clients.map((client) {
                      final displayName =
                          client.isCompany && client.companyName != null
                              ? client.companyName!
                              : client.name;
                      return DropdownMenuItem<ClientModel>(
                        value: client,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                client.isCompany
                                    ? FontAwesomeIcons.building
                                    : FontAwesomeIcons.user,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    client.email,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: client.currency.displayName == 'DA'
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                client.currency.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: client.currency.displayName == 'DA'
                                      ? Colors.green
                                      : Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          if (_selectedClient != null) ...[
            const SizedBox(height: 20),

            // Selected Client Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.circleCheck,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client Selected',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'Currency will be set to ${_selectedClient!.currency.code}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // No Clients Message
          if (_clients.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    FontAwesomeIcons.triangleExclamation,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Clients Found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to add at least one client before creating a project. Go to Client Management to add clients.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Step 3: Pricing
  Widget _buildPricingStep() {
    return Form(
      key: _stepFormKeys[2],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.dollarSign,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pricing Details',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Set your pricing model and rates',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Pricing Type Selection
            Text(
              'Pricing Model',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onPricingTypeChanged(PricingType.fixedPrice),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedPricingType == PricingType.fixedPrice
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        border: Border.all(
                          color: _selectedPricingType == PricingType.fixedPrice
                              ? AppColors.primary
                              : AppColors.border,
                          width: _selectedPricingType == PricingType.fixedPrice
                              ? 2
                              : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            FontAwesomeIcons.dollarSign,
                            color:
                                _selectedPricingType == PricingType.fixedPrice
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fixed Price',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  _selectedPricingType == PricingType.fixedPrice
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'One-time payment',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onPricingTypeChanged(PricingType.hourlyRate),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedPricingType == PricingType.hourlyRate
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        border: Border.all(
                          color: _selectedPricingType == PricingType.hourlyRate
                              ? AppColors.primary
                              : AppColors.border,
                          width: _selectedPricingType == PricingType.hourlyRate
                              ? 2
                              : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            FontAwesomeIcons.clock,
                            color:
                                _selectedPricingType == PricingType.hourlyRate
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hourly Rate',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  _selectedPricingType == PricingType.hourlyRate
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pay per hour',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Pricing Fields
            if (_selectedPricingType == PricingType.fixedPrice) ...[
              CustomTextField(
                label: 'Fixed Amount',
                hint: 'Enter total project amount',
                prefixIcon: FontAwesomeIcons.dollarSign,
                controller: _fixedAmountController,
                validator: _validateFixedAmount,
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              CustomTextField(
                label: 'Hourly Rate',
                hint: 'Enter your hourly rate',
                prefixIcon: FontAwesomeIcons.clock,
                controller: _hourlyRateController,
                validator: _validateHourlyRate,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Estimated Hours',
                      hint: 'Est. hours',
                      prefixIcon: FontAwesomeIcons.hourglass,
                      controller: _estimatedHoursController,
                      validator: _validateEstimatedHours,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'Actual Hours',
                      hint: 'Actual hours',
                      prefixIcon: FontAwesomeIcons.hourglassEnd,
                      controller: _actualHoursController,
                      validator: _validateActualHours,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Currency Selection
            Text(
              'Currency',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Currency>(
                  value: _selectedCurrency,
                  isExpanded: true,
                  onChanged: (currency) {
                    if (currency != null) {
                      setState(() => _selectedCurrency = currency);
                    }
                  },
                  items: Currency.values.map((currency) {
                    return DropdownMenuItem<Currency>(
                      value: currency,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currency.displayName == 'DA'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currency.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: currency.displayName == 'DA'
                                    ? Colors.green
                                    : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currency.displayName == 'DA'
                                ? 'Algerian Dinar'
                                : currency.displayName == 'USD'
                                    ? 'US Dollar'
                                    : 'Euro',
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 4: Timeline & Status
  Widget _buildTimelineStatusStep() {
    return Form(
      key: _stepFormKeys[3],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.calendar,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeline & Status',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Set project timeline and current status',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Project Status
            Text(
              'Project Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProjectStatus>(
                  value: _selectedStatus,
                  isExpanded: true,
                  onChanged: (status) {
                    if (status != null) {
                      setState(() {
                        _selectedStatus = status;
                        // Auto-complete progress when status is set to completed
                        if (status == ProjectStatus.completed) {
                          _progressController.text = '100';
                        }
                      });
                    }
                  },
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem<ProjectStatus>(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: ProjectModel.getStatusColor(status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            status.displayName,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progress
            CustomTextField(
              label: 'Progress (%)',
              hint: 'Enter progress percentage (0-100)',
              prefixIcon: FontAwesomeIcons.chartLine,
              controller: _progressController,
              validator: _validateProgress,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 32),

            // Timeline Section
            Text(
              'Project Timeline',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: _startDate != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: _startDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.play,
                                color: _startDate != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Start Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Select start date',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _startDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: _endDate != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: _endDate != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.stop,
                                color: _endDate != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'End Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Select end date',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _endDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.circleInfo,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ready to Create Project',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Review all the information and click "Create Project" to add this project to your portfolio.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Buttons
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(FontAwesomeIcons.chevronLeft, size: 16),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Next/Save Button
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : (_currentStep == 3 ? _saveProject : _nextStep),
              icon: _isLoading && _currentStep == 3
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _currentStep == 3
                          ? FontAwesomeIcons.check
                          : FontAwesomeIcons.chevronRight,
                      size: 16,
                    ),
              label: Text(
                _isLoading && _currentStep == 3
                    ? (_isEditing ? 'Updating...' : 'Creating...')
                    : _currentStep == 3
                        ? (_isEditing ? 'Update Project' : 'Create Project')
                        : 'Next',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
