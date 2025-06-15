import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AddEditClientScreen extends StatefulWidget {
  final ClientModel? client;

  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Company-specific controllers
  final _companyNameController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _companyEmailController = TextEditingController();

  ClientType _selectedClientType = ClientType.individualLocal;
  Currency _selectedCurrency = Currency.da;
  bool _isLoading = false;
  bool get _isEditing => widget.client != null;
  bool get _isCompanyType => ClientModel.isCompanyType(_selectedClientType);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final client = widget.client!;
    _nameController.text = client.name;
    _emailController.text = client.email;
    _phoneController.text = client.phone;
    _addressController.text = client.address;
    _selectedClientType = client.clientType;
    _selectedCurrency = client.currency;

    // Populate company fields if available
    if (client.companyName != null) {
      _companyNameController.text = client.companyName!;
    }
    if (client.commercialRegisterNumber != null) {
      _commercialRegisterController.text = client.commercialRegisterNumber!;
    }
    if (client.taxIdentificationNumber != null) {
      _taxIdController.text = client.taxIdentificationNumber!;
    }
    if (client.companyEmail != null) {
      _companyEmailController.text = client.companyEmail!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyNameController.dispose();
    _commercialRegisterController.dispose();
    _taxIdController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    // Email is now optional, but if provided, it should be valid
    if (value != null && value.trim().isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid email';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    // Phone is now optional
    return null;
  }

  String? _validateAddress(String? value) {
    // Address is now optional
    return null;
  }

  // Company field validators - now optional
  String? _validateCompanyName(String? value) {
    // Company name is now optional
    return null;
  }

  String? _validateCommercialRegister(String? value) {
    // Commercial register is now optional
    return null;
  }

  String? _validateTaxId(String? value) {
    // Tax ID is now optional
    return null;
  }

  String? _validateCompanyEmail(String? value) {
    // Company email is optional, but if provided, it should be valid
    if (value != null && value.trim().isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid company email';
      }
    }
    return null;
  }

  void _onClientTypeChanged(ClientType? newType) {
    if (newType != null) {
      setState(() {
        _selectedClientType = newType;
        // Auto-set currency based on client type
        _selectedCurrency = ClientModel.getDefaultCurrency(newType);

        // Clear company fields if switching to individual type
        if (!ClientModel.isCompanyType(newType)) {
          _companyNameController.clear();
          _commercialRegisterController.clear();
          _taxIdController.clear();
          _companyEmailController.clear();
        }
      });
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = ClientModel(
        id: _isEditing ? widget.client!.id : null,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        clientType: _selectedClientType,
        currency: _selectedCurrency,
        createdAt: _isEditing ? widget.client!.createdAt : DateTime.now(),
        updatedAt: _isEditing ? DateTime.now() : null,
        // Company fields (only if company type)
        companyName:
            _isCompanyType && _companyNameController.text.trim().isNotEmpty
                ? _companyNameController.text.trim()
                : null,
        commercialRegisterNumber: _isCompanyType &&
                _commercialRegisterController.text.trim().isNotEmpty
            ? _commercialRegisterController.text.trim()
            : null,
        taxIdentificationNumber:
            _isCompanyType && _taxIdController.text.trim().isNotEmpty
                ? _taxIdController.text.trim()
                : null,
        companyEmail:
            _isCompanyType && _companyEmailController.text.trim().isNotEmpty
                ? _companyEmailController.text.trim()
                : null,
      );

      if (_isEditing) {
        await ClientService.updateClient(client);
      } else {
        await ClientService.addClient(client);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Client updated successfully'
                : 'Client added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving client: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Client' : 'Add Client',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Add Section - Only Name Required
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
                          'Quick Add Client',
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
                      'Just enter the client name to get started quickly. You can add more details later.',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Client Name *',
                      hint: 'Enter client name',
                      prefixIcon: FontAwesomeIcons.user,
                      controller: _nameController,
                      validator: _validateName,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Advanced Details Section
              ExpansionTile(
                title: Text(
                  'Advanced Details (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Add contact information and other details',
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
                          label: 'Email',
                          hint: 'Enter email address (optional)',
                          prefixIcon: FontAwesomeIcons.envelope,
                          controller: _emailController,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Phone',
                          hint: 'Enter phone number (optional)',
                          prefixIcon: FontAwesomeIcons.phone,
                          controller: _phoneController,
                          validator: _validatePhone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Address',
                          hint: 'Enter full address (optional)',
                          prefixIcon: FontAwesomeIcons.locationDot,
                          controller: _addressController,
                          validator: _validateAddress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Company-specific fields (only show for company types)
              if (_isCompanyType) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: Text(
                    'Company Information (Optional)',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Add company-specific details',
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
                            label: 'Company Name (Nom de company)',
                            hint: 'Enter official company name (optional)',
                            prefixIcon: FontAwesomeIcons.building,
                            controller: _companyNameController,
                            validator: _validateCompanyName,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Commercial Register Number (RC)',
                            hint: 'Enter commercial register number (optional)',
                            prefixIcon: FontAwesomeIcons.fileContract,
                            controller: _commercialRegisterController,
                            validator: _validateCommercialRegister,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Tax Identification Number (NIF)',
                            hint: 'Enter tax identification number (optional)',
                            prefixIcon: FontAwesomeIcons.receipt,
                            controller: _taxIdController,
                            validator: _validateTaxId,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Company Email',
                            hint: 'Enter company email address (optional)',
                            prefixIcon: FontAwesomeIcons.envelopeOpenText,
                            controller: _companyEmailController,
                            validator: _validateCompanyEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Client Type and Currency Section
              ExpansionTile(
                title: Text(
                  'Client Type & Currency',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Set client type and currency preferences',
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
                        // Client Type Section
                        Text(
                          'Client Type',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ClientType>(
                              value: _selectedClientType,
                              onChanged: _onClientTypeChanged,
                              style: GoogleFonts.poppins(
                                fontSize: AppConstants.textLarge,
                                color: AppColors.textPrimary,
                              ),
                              items: ClientType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Currency Section
                        Text(
                          'Currency',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Currency is automatically set based on client type. You can change it for foreign/international clients.',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Currency>(
                              value: _selectedCurrency,
                              onChanged: (_selectedClientType ==
                                          ClientType.individualForeign ||
                                      _selectedClientType ==
                                          ClientType.companyInternational)
                                  ? (Currency? newCurrency) {
                                      if (newCurrency != null) {
                                        setState(() {
                                          _selectedCurrency = newCurrency;
                                        });
                                      }
                                    }
                                  : null,
                              style: GoogleFonts.poppins(
                                fontSize: AppConstants.textLarge,
                                color: AppColors.textPrimary,
                              ),
                              items: Currency.values.map((currency) {
                                return DropdownMenuItem(
                                  value: currency,
                                  child: Text(
                                      '${currency.displayName} - ${_getCurrencyName(currency)}'),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Save Button
              CustomButton(
                text: _isEditing ? 'Update Client' : 'Add Client',
                onPressed: _saveClient,
                isLoading: _isLoading,
                icon: _isEditing
                    ? FontAwesomeIcons.floppyDisk
                    : FontAwesomeIcons.plus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencyName(Currency currency) {
    switch (currency) {
      case Currency.da:
        return 'Algerian Dinar';
      case Currency.usd:
        return 'US Dollar';
      case Currency.eur:
        return 'Euro';
    }
  }
}
