import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

import '../services/settings_service.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();

  // Controllers
  final _irgRateController = TextEditingController();
  final _casnosAmountController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _businessRegistrationController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _enableAutoCalculation = true;
  bool _enableTaxReminders = true;
  bool _enableCasnosReminders = true;

  TaxCalculationMethod _selectedMethod = TaxCalculationMethod.simplified;
  int _reminderDaysBefore = 30;

  @override
  void initState() {
    super.initState();
    _loadTaxSettings();
  }

  @override
  void dispose() {
    _irgRateController.dispose();
    _casnosAmountController.dispose();
    _taxIdController.dispose();
    _businessRegistrationController.dispose();
    super.dispose();
  }

  Future<void> _loadTaxSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load current tax settings
      // In a real app, this would load from a tax settings service
      await Future.delayed(const Duration(milliseconds: 500));

      // Set default values
      _irgRateController.text = '0.5';
      _casnosAmountController.text = '24000';
      _taxIdController.text = '';
      _businessRegistrationController.text = '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tax settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTaxSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Save tax settings
      // In a real app, this would save to a tax settings service
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tax settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tax Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            FontAwesomeIcons.arrowLeft,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // IRG Tax Settings
                    _buildIrgTaxSection(),
                    const SizedBox(height: 20),

                    // CASNOS Settings
                    _buildCasnosSection(),
                    const SizedBox(height: 20),

                    // Business Information
                    _buildBusinessInfoSection(),
                    const SizedBox(height: 20),

                    // Calculation Settings
                    _buildCalculationSection(),
                    const SizedBox(height: 20),

                    // Reminder Settings
                    _buildReminderSection(),
                    const SizedBox(height: 32),

                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              FontAwesomeIcons.percent,
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
                  'Algerian Tax Settings',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure IRG, CASNOS, and tax calculation preferences',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrgTaxSection() {
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
            'IRG Tax Settings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Tax Calculation Method
          DropdownButtonFormField<TaxCalculationMethod>(
            value: _selectedMethod,
            decoration: InputDecoration(
              labelText: 'Calculation Method',
              prefixIcon: const Icon(
                FontAwesomeIcons.calculator,
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
            items: TaxCalculationMethod.values.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(method.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMethod = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // IRG Rate (for percentage method)
          if (_selectedMethod == TaxCalculationMethod.percentage)
            CustomTextField(
              controller: _irgRateController,
              label: 'IRG Tax Rate (%)',
              hint: 'Enter IRG tax rate percentage',
              prefixIcon: FontAwesomeIcons.percent,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'IRG rate is required';
                }
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) {
                  return 'Enter valid rate (0-100)';
                }
                return null;
              },
            ),

          // Information about IRG calculation
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IRG Tax Information:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Simplified: 10,000 DA fixed (if annual income < 2M DA)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.blue[600],
                  ),
                ),
                Text(
                  '• Percentage: 0.5% of annual income (if ≥ 2M DA)',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.blue[600],
                  ),
                ),
                Text(
                  '• Payment deadline: January 10th',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasnosSection() {
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
            'CASNOS Settings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _casnosAmountController,
            label: 'Annual CASNOS Amount (DA)',
            hint: 'Enter annual CASNOS amount',
            prefixIcon: FontAwesomeIcons.coins,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'CASNOS amount is required';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Enter valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // CASNOS Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CASNOS Information:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Standard amount: 24,000 DA annually',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  '• Payment deadline: June 20th',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  '• Social security contribution for freelancers',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
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
            'Business Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _taxIdController,
            label: 'Tax ID Number',
            hint: 'Enter your tax identification number',
            prefixIcon: FontAwesomeIcons.idCard,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _businessRegistrationController,
            label: 'Business Registration Number',
            hint: 'Enter business registration number',
            prefixIcon: FontAwesomeIcons.building,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationSection() {
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
            'Calculation Settings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Auto Calculate Taxes',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Automatically calculate taxes based on income',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: _enableAutoCalculation,
            onChanged: (value) {
              setState(() {
                _enableAutoCalculation = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
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
            'Reminder Settings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'IRG Tax Reminders',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Get notified before IRG tax deadline',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: _enableTaxReminders,
            onChanged: (value) {
              setState(() {
                _enableTaxReminders = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: Text(
              'CASNOS Reminders',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Get notified before CASNOS payment deadline',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            value: _enableCasnosReminders,
            onChanged: (value) {
              setState(() {
                _enableCasnosReminders = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableTaxReminders || _enableCasnosReminders) ...[
            const SizedBox(height: 16),
            Text(
              'Reminder Days Before Deadline',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _reminderDaysBefore,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  FontAwesomeIcons.bell,
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
              items: [7, 14, 30, 60, 90].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days days before'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _reminderDaysBefore = value;
                  });
                }
              },
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
        text: 'Save Tax Settings',
        onPressed: _isSaving ? null : _saveTaxSettings,
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        icon: _isSaving ? null : FontAwesomeIcons.floppyDisk,
        isLoading: _isSaving,
        height: 50,
      ),
    );
  }
}

enum TaxCalculationMethod {
  simplified,
  percentage;

  String get displayName {
    switch (this) {
      case TaxCalculationMethod.simplified:
        return 'IRG Simplifié (Fixed Amount)';
      case TaxCalculationMethod.percentage:
        return 'IRG Percentage (0.5%)';
    }
  }
}
