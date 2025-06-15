import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tax_model.dart';
import '../services/tax_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key});

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();

  bool _isLoading = false;
  bool _isCalculated = false;
  bool _isLoadingIncome = false;
  int _selectedYear = DateTime.now().year;
  TaxCalculationModel? _calculation;
  double _calculatedIncome = 0.0;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  String? _validateIncome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Annual income is required';
    }

    final income = double.tryParse(value.trim());
    if (income == null || income < 0) {
      return 'Please enter a valid amount';
    }

    return null;
  }

  Future<void> _loadIncomeFromPayments() async {
    setState(() => _isLoadingIncome = true);

    try {
      final income =
          await TaxService.calculateAnnualIncomeFromPayments(_selectedYear);
      setState(() {
        _calculatedIncome = income;
        _incomeController.text = income.toStringAsFixed(0);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading income from payments: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingIncome = false);
    }
  }

  Future<void> _calculateFromPayments() async {
    setState(() => _isLoading = true);

    try {
      final calculation =
          await TaxService.calculateTaxesFromPayments(_selectedYear);
      setState(() {
        _calculation = calculation;
        _calculatedIncome = calculation.annualIncome;
        _incomeController.text = calculation.annualIncome.toStringAsFixed(0);
        _isCalculated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating taxes from payments: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTaxes() {
    if (!_formKey.currentState!.validate()) return;

    final annualIncome = double.parse(_incomeController.text.trim());
    final calculation =
        TaxService.calculateTotalTaxes(annualIncome, _selectedYear);

    setState(() {
      _calculation = calculation;
      _isCalculated = true;
    });
  }

  Future<void> _saveCalculation() async {
    if (_calculation == null) return;

    setState(() => _isLoading = true);

    try {
      // Save calculation
      await TaxService.saveTaxCalculation(_calculation!);

      // Generate tax payments for next year
      await TaxService.generateTaxPaymentsForYear(_selectedYear, _calculation!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Calculation saved and payments created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving calculation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reset() {
    setState(() {
      _calculation = null;
      _isCalculated = false;
    });
    _incomeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tax Calculator',
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
        actions: [
          if (_isCalculated)
            IconButton(
              onPressed: _reset,
              icon: const Icon(
                FontAwesomeIcons.arrowsRotate,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              _buildInfoCard(),
              const SizedBox(height: AppConstants.paddingMedium),

              // Year Selector
              _buildYearSelector(),
              const SizedBox(height: AppConstants.paddingMedium),

              // Income Input
              if (!_isCalculated) ...[
                _buildIncomeInput(),
                const SizedBox(height: AppConstants.paddingMedium),

                // Auto Calculate from Payments Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Calculate from Payments',
                    onPressed: _isLoading ? null : _calculateFromPayments,
                    icon: FontAwesomeIcons.coins,
                    isLoading: _isLoading,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: AppConstants.textSmall,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),

                const SizedBox(height: 12),

                // Manual Calculate Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _calculateTaxes,
                    icon: const Icon(FontAwesomeIcons.calculator, size: 16),
                    label: Text(
                      'Calculate Manually',
                      style: GoogleFonts.poppins(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],

              // Results
              if (_isCalculated && _calculation != null) ...[
                _buildResultsSection(),
                const SizedBox(height: AppConstants.paddingMedium),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Save & Create Payments',
                        onPressed: _isLoading ? null : _saveCalculation,
                        icon: FontAwesomeIcons.floppyDisk,
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(FontAwesomeIcons.arrowsRotate, size: 16),
                      label: Text(
                        'Recalculate',
                        style: GoogleFonts.poppins(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Algerian Tax Rules',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• IRG Simplified: If income < 2,000,000 DA → 10,000 DA fixed',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            '• IRG Simplified: If income ≥ 2,000,000 DA → 0.5% of income',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            '• CASNOS: 24,000 DA annually (fixed)',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.calendar,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Fiscal Year:',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          DropdownButton<int>(
            value: _selectedYear,
            underline: const SizedBox(),
            items: years.map((year) {
              return DropdownMenuItem<int>(
                value: year,
                child: Text(
                  year.toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (year) {
              if (year != null) {
                setState(() => _selectedYear = year);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Annual Income',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          label: 'Amount in Algerian Dinar',
          controller: _incomeController,
          hint: 'Enter annual income in Algerian Dinar',
          prefixIcon: FontAwesomeIcons.coins,
          keyboardType: TextInputType.number,
          validator: _validateIncome,
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_calculation == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation Results',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Income Summary
        _buildResultCard(
          'Annual Income',
          '${_calculation!.annualIncome.toStringAsFixed(0)} DA',
          Icons.trending_up,
          Colors.blue,
        ),

        const SizedBox(height: 12),

        // IRG Tax
        _buildResultCard(
          'IRG Simplified',
          '${_calculation!.irgAmount.toStringAsFixed(0)} DA',
          Icons.account_balance,
          Colors.red,
          subtitle: _calculation!.annualIncome < 2000000
              ? 'Fixed amount (less than 2M DA)'
              : '0.5% of income (more than 2M DA)',
        ),

        const SizedBox(height: 12),

        // CASNOS
        _buildResultCard(
          'CASNOS',
          '${_calculation!.casnosAmount.toStringAsFixed(0)} DA',
          Icons.health_and_safety,
          Colors.blue,
          subtitle: 'Fixed annual amount',
        ),

        const SizedBox(height: 12),

        // Total
        _buildResultCard(
          'Total Taxes',
          '${_calculation!.totalTaxes.toStringAsFixed(0)} DA',
          Icons.calculate,
          Colors.green,
          isTotal: true,
        ),

        const SizedBox(height: 16),

        // Payment Dates Info
        _buildPaymentDatesInfo(),
      ],
    );
  }

  Widget _buildResultCard(
      String title, String amount, IconData icon, Color color,
      {String? subtitle, bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isTotal ? color.withValues(alpha: 0.1) : AppColors.surface,
        border: Border.all(
          color: isTotal ? color : AppColors.border,
          width: isTotal ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: AppColors.textWhite, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isTotal
                        ? AppConstants.textMedium
                        : AppConstants.textSmall,
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize:
                  isTotal ? AppConstants.textLarge : AppConstants.textMedium,
              fontWeight: FontWeight.w700,
              color: isTotal ? color : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDatesInfo() {
    final nextYear = _selectedYear + 1;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Deadlines',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• IRG: Due before January 10, $nextYear',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: Colors.orange.shade700,
            ),
          ),
          Text(
            '• CASNOS: Due before June 20, $nextYear',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
