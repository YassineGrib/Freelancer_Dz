import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tax_model.dart';
import '../services/tax_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

import 'tax_calculator_screen.dart';
import 'tax_payment_screen.dart';

class TaxManagementScreen extends StatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  List<TaxPaymentModel> _taxPayments = [];
  List<TaxPaymentModel> _upcomingPayments = [];
  List<TaxPaymentModel> _overduePayments = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final payments = await TaxService.getTaxPaymentsByYear(_selectedYear);
      final upcoming = await TaxService.getUpcomingTaxPayments();
      final overdue = await TaxService.getOverdueTaxPayments();
      final stats = await TaxService.getTaxStatistics();

      setState(() {
        _taxPayments = payments;
        _upcomingPayments = upcoming;
        _overduePayments = overdue;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tax data: $e')),
        );
      }
    }
  }

  void _navigateToCalculator() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const TaxCalculatorScreen(),
          ),
        )
        .then((_) => _loadData());
  }

  void _navigateToPaymentDetails(TaxPaymentModel payment) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => TaxPaymentScreen(payment: payment),
          ),
        )
        .then((_) => _loadData());
  }

  void _onYearChanged(int year) {
    setState(() => _selectedYear = year);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Tax Management',
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
            onPressed: _navigateToCalculator,
            icon: const Icon(
              FontAwesomeIcons.calculator,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Year Selector
                  _buildYearSelector(),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Statistics Cards
                  _buildStatisticsSection(),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Alerts Section
                  if (_overduePayments.isNotEmpty ||
                      _upcomingPayments.isNotEmpty)
                    _buildAlertsSection(),

                  // Tax Payments Section
                  _buildTaxPaymentsSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCalculator,
        backgroundColor: AppColors.primary,
        child: const Icon(
          FontAwesomeIcons.calculator,
          color: AppColors.textWhite,
        ),
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
            'Tax Year:',
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
              if (year != null) _onYearChanged(year);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Statistics',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Paid',
                '${(_statistics['total_paid_amount'] ?? 0.0).toStringAsFixed(0)} DA',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                '${(_statistics['total_pending_amount'] ?? 0.0).toStringAsFixed(0)} DA',
                Icons.schedule,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Payments',
                '${_statistics['paid_payments'] ?? 0}',
                Icons.payment,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                '${_statistics['overdue_payments'] ?? 0}',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Overdue payments
        if (_overduePayments.isNotEmpty)
          ..._overduePayments.map((payment) => _buildAlertCard(
                payment,
                'Overdue ${payment.daysOverdue} days',
                Colors.red,
                Icons.warning,
              )),

        // Upcoming payments
        if (_upcomingPayments.isNotEmpty)
          ..._upcomingPayments.map((payment) => _buildAlertCard(
                payment,
                'Due in ${payment.daysUntilDue} days',
                Colors.orange,
                Icons.schedule,
              )),

        const SizedBox(height: AppConstants.paddingMedium),
      ],
    );
  }

  Widget _buildAlertCard(
      TaxPaymentModel payment, String subtitle, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => _navigateToPaymentDetails(payment),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.type.englishName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textSmall,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${payment.amount.toStringAsFixed(0)} DA',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tax Payments $_selectedYear',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_taxPayments.isEmpty)
          _buildEmptyState()
        else
          ..._taxPayments.map((payment) => _buildPaymentCard(payment)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              FontAwesomeIcons.calculator,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No taxes calculated for $_selectedYear',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculate your taxes for this year',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Calculate Taxes',
              onPressed: _navigateToCalculator,
              icon: FontAwesomeIcons.calculator,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(TaxPaymentModel payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => _navigateToPaymentDetails(payment),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Type Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: payment.type.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  payment.type.icon,
                  color: AppColors.textWhite,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Payment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.type.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.type.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: payment.status.color.withValues(alpha: 0.1),
                            border: Border.all(
                                color: payment.status.color
                                    .withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            payment.status.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: payment.status.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Due: ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: payment.isOverdue
                                ? AppColors.error
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${payment.amount.toStringAsFixed(0)} DA',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Icon(
                    payment.status.icon,
                    size: 16,
                    color: payment.status.color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
