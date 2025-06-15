import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invoice_model.dart';
import '../models/project_model.dart';
import '../models/client_model.dart' as client_model;
import '../services/invoice_service.dart';
import '../services/project_service.dart';
import '../services/client_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';

class AddEditInvoiceScreen extends StatefulWidget {
  final InvoiceModel? invoice;

  const AddEditInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _discountController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;

  List<ProjectModel> _projects = [];
  List<client_model.ClientModel> _clients = [];
  List<InvoiceItemModel> _items = [];

  ProjectModel? _selectedProject;
  client_model.ClientModel? _selectedClient;
  InvoiceType _selectedType = InvoiceType.client;
  InvoiceStatus _selectedStatus = InvoiceStatus.draft;
  Currency _selectedCurrency = Currency.da;
  DateTime _selectedIssueDate = DateTime.now();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0.0;
  double _discount = 0.0;

  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (_isEditing) {
      _populateFields();
    } else {
      _generateInvoiceNumber();
      _addDefaultItem();
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _termsController.dispose();
    _paymentInstructionsController.dispose();
    _taxRateController.dispose();
    _discountController.dispose();
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

  Future<void> _generateInvoiceNumber() async {
    try {
      final invoiceNumber = await InvoiceService.generateInvoiceNumber();
      setState(() {
        _invoiceNumberController.text = invoiceNumber;
      });
    } catch (e) {
      // Use fallback number
      final currentYear = DateTime.now().year;
      setState(() {
        _invoiceNumberController.text = 'INV-$currentYear-0001';
      });
    }
  }

  void _addDefaultItem() {
    setState(() {
      _items.add(const InvoiceItemModel(
        description: '',
        quantity: 1,
        unitPrice: 0.0,
        total: 0.0,
      ));
    });
  }

  void _populateFields() {
    final invoice = widget.invoice!;
    _invoiceNumberController.text = invoice.invoiceNumber;
    _notesController.text = invoice.notes ?? '';
    _termsController.text = invoice.terms ?? '';
    _paymentInstructionsController.text = invoice.paymentInstructions ?? '';
    _taxRateController.text = (invoice.taxRate ?? 0.0).toString();
    _discountController.text = (invoice.discount ?? 0.0).toString();

    _selectedType = invoice.type;
    _selectedStatus = invoice.status;
    _selectedCurrency = invoice.currency;
    _selectedIssueDate = invoice.issueDate;
    _selectedDueDate = invoice.dueDate;
    _taxRate = invoice.taxRate ?? 0.0;
    _discount = invoice.discount ?? 0.0;
    _items = List.from(invoice.items);

    // Set selected project and client after data loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Find project by ID, only set if found
        try {
          _selectedProject = _projects.firstWhere(
            (p) => p.id == invoice.projectId,
          );
        } catch (e) {
          _selectedProject = null;
        }

        // Find client by ID, only set if found
        try {
          _selectedClient = _clients.firstWhere(
            (c) => c.id == invoice.clientId,
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
        _selectedCurrency = _convertProjectCurrencyToInvoiceCurrency(project.currency);

        // If this is a project invoice, auto-populate items
        if (_selectedType == InvoiceType.project) {
          _populateProjectItems(project);
        }
      }
    });
  }

  void _onTypeChanged(InvoiceType? type) {
    setState(() {
      _selectedType = type ?? InvoiceType.client;

      if (_selectedType == InvoiceType.project) {
        // Clear manual items for project invoice
        _items.clear();
        // If project is selected, populate items
        if (_selectedProject != null) {
          _populateProjectItems(_selectedProject!);
        }
      } else {
        // For client invoice, ensure at least one empty item
        if (_items.isEmpty) {
          _addDefaultItem();
        }
      }
    });
  }

  void _populateProjectItems(ProjectModel project) {
    _items.clear();

    // Create single item from project
    final projectItem = InvoiceItemModel(
      description: project.description.isNotEmpty
          ? '${project.projectName} - ${project.description}'
          : project.projectName,
      quantity: 1,
      unitPrice: project.totalValue ?? 0.0,
      total: project.totalValue ?? 0.0,
    );

    _items.add(projectItem);
  }

  void _onClientChanged(client_model.ClientModel? client) {
    setState(() {
      _selectedClient = client;
      if (client != null && _selectedProject == null) {
        // Auto-select currency based on client if no project selected
        _selectedCurrency = _convertClientCurrencyToInvoiceCurrency(client.currency);
      }
    });
  }

  // Helper method to convert project currency to invoice currency
  Currency _convertProjectCurrencyToInvoiceCurrency(client_model.Currency projectCurrency) {
    switch (projectCurrency) {
      case client_model.Currency.da:
        return Currency.da;
      case client_model.Currency.usd:
        return Currency.usd;
      case client_model.Currency.eur:
        return Currency.eur;
    }
  }

  // Helper method to convert client currency to invoice currency
  Currency _convertClientCurrencyToInvoiceCurrency(client_model.Currency clientCurrency) {
    switch (clientCurrency) {
      case client_model.Currency.da:
        return Currency.da;
      case client_model.Currency.usd:
        return Currency.usd;
      case client_model.Currency.eur:
        return Currency.eur;
    }
  }

  void _addItem() {
    setState(() {
      _items.add(const InvoiceItemModel(
        description: '',
        quantity: 1,
        unitPrice: 0.0,
        total: 0.0,
      ));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  void _updateItem(int index, InvoiceItemModel item) {
    setState(() {
      _items[index] = item;
    });
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  double _calculateTaxAmount() {
    final subtotal = _calculateSubtotal();
    return (subtotal - _discount) * (_taxRate / 100);
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final taxAmount = _calculateTaxAmount();
    return subtotal - _discount + taxAmount;
  }

  String? _validateInvoiceNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invoice number is required';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _selectedIssueDate : _selectedDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _selectedIssueDate = picked;
        } else {
          _selectedDueDate = picked;
        }
      });
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty || _items.every((item) => item.description.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subtotal = _calculateSubtotal();
      final taxAmount = _calculateTaxAmount();
      final total = _calculateTotal();

      final invoice = InvoiceModel(
        id: _isEditing ? widget.invoice!.id : null,
        invoiceNumber: _invoiceNumberController.text.trim(),
        type: _selectedType,
        projectId: _selectedProject?.id,
        clientId: _selectedClient?.id,
        status: _selectedStatus,
        issueDate: _selectedIssueDate,
        dueDate: _selectedDueDate,
        currency: _selectedCurrency,
        items: _items,
        subtotal: subtotal,
        taxRate: _taxRate > 0 ? _taxRate : null,
        taxAmount: _taxRate > 0 ? taxAmount : null,
        discount: _discount > 0 ? _discount : null,
        total: total,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        terms: _termsController.text.trim().isEmpty
            ? null
            : _termsController.text.trim(),
        paymentInstructions: _paymentInstructionsController.text.trim().isEmpty
            ? null
            : _paymentInstructionsController.text.trim(),
        createdAt: _isEditing ? widget.invoice!.createdAt : DateTime.now(),
        // Cache client information for PDF generation
        clientName: _selectedClient?.isCompany == true && _selectedClient?.companyName != null
            ? _selectedClient!.companyName!
            : _selectedClient?.name,
        clientAddress: _selectedClient?.address,
        clientPhone: _selectedClient?.phone,
        clientEmail: _selectedClient?.email,
      );

      if (_isEditing) {
        await InvoiceService.updateInvoice(invoice);
      } else {
        await InvoiceService.addInvoice(invoice);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Invoice updated successfully' : 'Invoice created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice: $e'),
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
          _isEditing ? 'Edit Invoice' : 'Create Invoice',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Number
                    CustomTextField(
                      label: 'Invoice Number',
                      hint: 'Enter invoice number',
                      prefixIcon: FontAwesomeIcons.hashtag,
                      controller: _invoiceNumberController,
                      validator: _validateInvoiceNumber,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Invoice Type Selection
                    _buildSectionTitle('Invoice Type'),
                    _buildTypeDropdown(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Status Selection
                    _buildSectionTitle('Status'),
                    _buildStatusDropdown(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Project Selection (Optional)
                    _buildSectionTitle('Project (Optional)'),
                    _buildProjectDropdown(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Client Selection (Optional)
                    _buildSectionTitle('Client (Optional)'),
                    _buildClientDropdown(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Currency Selection
                    _buildSectionTitle('Currency'),
                    _buildCurrencyDropdown(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Dates
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Issue Date'),
                              _buildDateField('Issue Date', _selectedIssueDate, true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Due Date'),
                              _buildDateField('Due Date', _selectedDueDate, false),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Invoice Items
                    _buildSectionTitle('Invoice Items'),
                    _buildItemsList(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Add Item Button (only for client invoices)
                    if (_selectedType == InvoiceType.client)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(FontAwesomeIcons.plus, size: 16),
                          label: Text('Add Item', style: GoogleFonts.poppins()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                    // Project Invoice Info
                    if (_selectedType == InvoiceType.project)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity( 0.1),
                          border: Border.all(color: Colors.blue.withOpacity( 0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Project invoices automatically include the project as a single item. You cannot add additional items.',
                                style: GoogleFonts.poppins(
                                  fontSize: AppConstants.textSmall,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Tax and Discount
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Tax Rate (%)',
                            hint: '0.0',
                            prefixIcon: FontAwesomeIcons.percent,
                            controller: _taxRateController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _taxRate = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Discount',
                            hint: '0.0',
                            prefixIcon: FontAwesomeIcons.tag,
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _discount = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Invoice Summary
                    _buildInvoiceSummary(),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Notes
                    CustomTextField(
                      label: 'Notes (Optional)',
                      hint: 'Additional notes for the invoice',
                      prefixIcon: FontAwesomeIcons.noteSticky,
                      controller: _notesController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Terms
                    CustomTextField(
                      label: 'Terms & Conditions (Optional)',
                      hint: 'Payment terms and conditions',
                      prefixIcon: FontAwesomeIcons.fileContract,
                      controller: _termsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    // Payment Instructions
                    CustomTextField(
                      label: 'Payment Instructions (Optional)',
                      hint: 'How to make payment',
                      prefixIcon: FontAwesomeIcons.creditCard,
                      controller: _paymentInstructionsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveInvoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update Invoice' : 'Create Invoice',
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

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<InvoiceType>(
          value: _selectedType,
          decoration: InputDecoration(
            hintText: 'Select invoice type',
            prefixIcon: Icon(_selectedType.icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          items: InvoiceType.values.map((type) {
            return DropdownMenuItem<InvoiceType>(
              value: type,
              child: Row(
                children: [
                  Icon(type.icon, size: 20, color: type.color),
                  const SizedBox(width: 8),
                  Text(
                    type.displayName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _onTypeChanged,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _selectedType.color.withOpacity( 0.1),
            border: Border.all(color: _selectedType.color.withOpacity( 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: _selectedType.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedType.description,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: _selectedType.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<InvoiceStatus>(
      value: _selectedStatus,
      decoration: InputDecoration(
        hintText: 'Select status',
        prefixIcon: Icon(_selectedStatus.icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      items: InvoiceStatus.values.map((status) {
        return DropdownMenuItem<InvoiceStatus>(
          value: status,
          child: Row(
            children: [
              Icon(status.icon, size: 20, color: status.color),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (status) {
        if (status != null) {
          setState(() => _selectedStatus = status);
        }
      },
    );
  }

  Widget _buildProjectDropdown() {
    // Ensure selected project is in the list or set to null
    if (_selectedProject != null && !_projects.any((p) => p.id == _selectedProject!.id)) {
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
    if (_selectedClient != null && !_clients.any((c) => c.id == _selectedClient!.id)) {
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
            client.isCompany && client.companyName != null && client.companyName!.isNotEmpty
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

  Widget _buildDateField(String label, DateTime date, bool isIssueDate) {
    return InkWell(
      onTap: () => _selectDate(context, isIssueDate),
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
                '${date.day}/${date.month}/${date.year}',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildItemRow(index, item);
      }).toList(),
    );
  }

  Widget _buildItemRow(int index, InvoiceItemModel item) {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitPriceController = TextEditingController(text: item.unitPrice.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_items.length > 1)
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(
                    FontAwesomeIcons.trash,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              hintText: 'Item description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              final updatedItem = item.copyWith(
                description: value,
                total: item.quantity * item.unitPrice,
              );
              _updateItem(index, updatedItem);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    hintText: 'Qty',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 1;
                    final updatedItem = item.copyWith(
                      quantity: quantity,
                      total: quantity * item.unitPrice,
                    );
                    _updateItem(index, updatedItem);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: unitPriceController,
                  decoration: InputDecoration(
                    hintText: 'Unit Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final unitPrice = double.tryParse(value) ?? 0.0;
                    final updatedItem = item.copyWith(
                      unitPrice: unitPrice,
                      total: item.quantity * unitPrice,
                    );
                    _updateItem(index, updatedItem);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.total.toStringAsFixed(2)} ${_selectedCurrency.code}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    final subtotal = _calculateSubtotal();
    final taxAmount = _calculateTaxAmount();
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (_discount > 0) _buildSummaryRow('Discount', -_discount),
          if (_taxRate > 0) _buildSummaryRow('Tax (${_taxRate.toStringAsFixed(1)}%)', taxAmount),
          const Divider(),
          _buildSummaryRow('Total', total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? AppConstants.textMedium : AppConstants.textSmall,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ${_selectedCurrency.code}',
            style: GoogleFonts.poppins(
              fontSize: isTotal ? AppConstants.textMedium : AppConstants.textSmall,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
