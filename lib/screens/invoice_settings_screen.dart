import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/colors.dart';
import '../models/invoice_settings_model.dart';
import '../models/client_model.dart';
import '../services/invoice_settings_service.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_widget.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceSettingsService = InvoiceSettingsService.instance;

  // Controllers
  final _invoicePrefixController = TextEditingController();
  final _nextInvoiceNumberController = TextEditingController();
  final _defaultDueDaysController = TextEditingController();
  final _defaultTermsController = TextEditingController();
  final _defaultNotesController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();
  final _defaultTaxRateController = TextEditingController();
  final _taxLabelController = TextEditingController();
  final _defaultDiscountValueController = TextEditingController();

  InvoiceSettingsModel? _currentSettings;
  InvoiceNumberFormat _selectedNumberFormat =
      InvoiceNumberFormat.prefixYearDashNumber;
  Currency _selectedCurrency = Currency.da;
  DiscountType _selectedDiscountType = DiscountType.percentage;
  InvoiceTemplate _selectedTemplate = InvoiceTemplate.modern;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _includeCompanyLogo = true;
  bool _includePaymentInstructions = true;
  bool _enableTax = false;
  bool _enableDiscount = false;

  @override
  void initState() {
    super.initState();
    _loadInvoiceSettings();
  }

  @override
  void dispose() {
    _invoicePrefixController.dispose();
    _nextInvoiceNumberController.dispose();
    _defaultDueDaysController.dispose();
    _defaultTermsController.dispose();
    _defaultNotesController.dispose();
    _paymentInstructionsController.dispose();
    _defaultTaxRateController.dispose();
    _taxLabelController.dispose();
    _defaultDiscountValueController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceSettings() async {
    try {
      final settings = await _invoiceSettingsService.getInvoiceSettings();
      setState(() {
        _currentSettings = settings;
        _invoicePrefixController.text = settings.invoicePrefix;
        _nextInvoiceNumberController.text =
            settings.nextInvoiceNumber.toString();
        _defaultDueDaysController.text = settings.defaultDueDays.toString();
        _defaultTermsController.text = settings.defaultTerms;
        _defaultNotesController.text = settings.defaultNotes;
        _paymentInstructionsController.text = settings.paymentInstructions;
        _defaultTaxRateController.text = settings.defaultTaxRate.toString();
        _taxLabelController.text = settings.taxLabel;
        _defaultDiscountValueController.text =
            settings.defaultDiscountValue.toString();

        _selectedNumberFormat = settings.numberFormat;
        _selectedCurrency = settings.defaultCurrency;
        _selectedDiscountType = settings.defaultDiscountType;
        _selectedTemplate = settings.defaultTemplate;
        _includeCompanyLogo = settings.includeCompanyLogo;
        _includePaymentInstructions = settings.includePaymentInstructions;
        _enableTax = settings.enableTax;
        _enableDiscount = settings.enableDiscount;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invoice settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveInvoiceSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final settings = InvoiceSettingsModel(
        id: _currentSettings?.id,
        invoicePrefix: _invoicePrefixController.text.trim(),
        nextInvoiceNumber: int.parse(_nextInvoiceNumberController.text),
        numberFormat: _selectedNumberFormat,
        defaultDueDays: int.parse(_defaultDueDaysController.text),
        defaultTerms: _defaultTermsController.text.trim(),
        defaultNotes: _defaultNotesController.text.trim(),
        includeCompanyLogo: _includeCompanyLogo,
        includePaymentInstructions: _includePaymentInstructions,
        paymentInstructions: _paymentInstructionsController.text.trim(),
        defaultCurrency: _selectedCurrency,
        enableTax: _enableTax,
        defaultTaxRate: double.parse(_defaultTaxRateController.text),
        taxLabel: _taxLabelController.text.trim(),
        enableDiscount: _enableDiscount,
        defaultDiscountType: _selectedDiscountType,
        defaultDiscountValue:
            double.parse(_defaultDiscountValueController.text),
        defaultTemplate: _selectedTemplate,
        customFields: _currentSettings?.customFields ?? {},
        createdAt: _currentSettings?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success =
          await _invoiceSettingsService.saveInvoiceSettings(settings);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save invoice settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving invoice settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _getPreviewInvoiceNumber() {
    if (_currentSettings == null) return 'INV-2025-0001';

    final tempSettings = _currentSettings!.copyWith(
      invoicePrefix: _invoicePrefixController.text.trim(),
      nextInvoiceNumber: int.tryParse(_nextInvoiceNumberController.text) ?? 1,
      numberFormat: _selectedNumberFormat,
    );

    return _invoiceSettingsService.previewInvoiceNumber(tempSettings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading invoice settings...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Invoice Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceNumberingSection(),
              const SizedBox(height: 24),
              _buildDefaultsSection(),
              const SizedBox(height: 24),
              _buildTaxSection(),
              const SizedBox(height: 24),
              _buildDiscountSection(),
              const SizedBox(height: 24),
              _buildTemplateSection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceNumberingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Numbering',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _invoicePrefixController,
            label: 'Invoice Prefix *',
            hint: 'Enter invoice prefix (e.g., INV)',
            prefixIcon: FontAwesomeIcons.hashtag,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Invoice prefix is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nextInvoiceNumberController,
            label: 'Next Invoice Number *',
            hint: 'Enter next invoice number',
            prefixIcon: FontAwesomeIcons.listOl,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Next invoice number is required';
              }
              final number = int.tryParse(value);
              if (number == null || number < 1) {
                return 'Please enter a valid number (minimum 1)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<InvoiceNumberFormat>(
            value: _selectedNumberFormat,
            decoration: InputDecoration(
              labelText: 'Number Format',
              prefixIcon: const Icon(
                FontAwesomeIcons.fileInvoice,
                color: AppColors.primary,
                size: 20,
              ),
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
            items: InvoiceNumberFormat.values.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedNumberFormat = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.eye,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview: ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _getPreviewInvoiceNumber(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Settings',
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
                child: CustomTextField(
                  controller: _defaultDueDaysController,
                  label: 'Default Due Days *',
                  hint: 'Enter default due days',
                  prefixIcon: FontAwesomeIcons.calendar,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Due days is required';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days < 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<Currency>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Default Currency',
                    prefixIcon: const Icon(
                      FontAwesomeIcons.coins,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
                  items: Currency.values.map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _defaultTermsController,
            label: 'Default Payment Terms',
            hint: 'Enter default payment terms',
            prefixIcon: FontAwesomeIcons.fileContract,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _defaultNotesController,
            label: 'Default Notes',
            hint: 'Enter default invoice notes',
            prefixIcon: FontAwesomeIcons.noteSticky,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tax Settings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Switch(
                value: _enableTax,
                onChanged: (value) {
                  setState(() {
                    _enableTax = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_enableTax) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _taxLabelController,
                    label: 'Tax Label',
                    hint: 'Enter tax label (e.g., VAT, GST)',
                    prefixIcon: FontAwesomeIcons.tag,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _defaultTaxRateController,
                    label: 'Default Tax Rate (%)',
                    hint: 'Enter tax rate percentage',
                    prefixIcon: FontAwesomeIcons.percent,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_enableTax &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Tax rate is required';
                      }
                      if (value != null && value.isNotEmpty) {
                        final rate = double.tryParse(value);
                        if (rate == null || rate < 0 || rate > 100) {
                          return 'Enter valid rate (0-100)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Discount Settings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Switch(
                value: _enableDiscount,
                onChanged: (value) {
                  setState(() {
                    _enableDiscount = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_enableDiscount) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DiscountType>(
                    value: _selectedDiscountType,
                    decoration: InputDecoration(
                      labelText: 'Discount Type',
                      prefixIcon: Icon(
                        _selectedDiscountType.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
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
                    items: DiscountType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDiscountType = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _defaultDiscountValueController,
                    label: _selectedDiscountType == DiscountType.percentage
                        ? 'Default Discount (%)'
                        : 'Default Discount Amount',
                    hint: _selectedDiscountType == DiscountType.percentage
                        ? 'Enter discount percentage'
                        : 'Enter discount amount',
                    prefixIcon: _selectedDiscountType.icon,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_enableDiscount &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Discount value is required';
                      }
                      if (value != null && value.isNotEmpty) {
                        final discountValue = double.tryParse(value);
                        if (discountValue == null || discountValue < 0) {
                          return 'Enter valid discount value';
                        }
                        if (_selectedDiscountType == DiscountType.percentage &&
                            discountValue > 100) {
                          return 'Percentage cannot exceed 100%';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Template',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<InvoiceTemplate>(
            value: _selectedTemplate,
            decoration: InputDecoration(
              labelText: 'Default Template',
              prefixIcon: Icon(
                _selectedTemplate.icon,
                color: AppColors.primary,
                size: 20,
              ),
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
            items: InvoiceTemplate.values.map((template) {
              return DropdownMenuItem(
                value: template,
                child: Row(
                  children: [
                    Icon(template.icon,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(template.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedTemplate = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice Options',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Include Company Logo',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Show company logo on invoices',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: _includeCompanyLogo,
            onChanged: (value) {
              setState(() {
                _includeCompanyLogo = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              'Include Payment Instructions',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Show payment instructions on invoices',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: _includePaymentInstructions,
            onChanged: (value) {
              setState(() {
                _includePaymentInstructions = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          if (_includePaymentInstructions) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: _paymentInstructionsController,
              label: 'Payment Instructions',
              hint: 'Enter payment instructions for invoices',
              prefixIcon: FontAwesomeIcons.creditCard,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Save Invoice Settings',
        onPressed: _isSaving ? null : _saveInvoiceSettings,
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        icon: _isSaving ? null : FontAwesomeIcons.floppyDisk,
        isLoading: _isSaving,
        height: 50,
      ),
    );
  }
}
