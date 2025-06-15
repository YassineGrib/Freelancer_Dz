import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tax_model.dart';
import '../services/tax_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class TaxPaymentScreen extends StatefulWidget {
  final TaxPaymentModel payment;

  const TaxPaymentScreen({super.key, required this.payment});

  @override
  State<TaxPaymentScreen> createState() => _TaxPaymentScreenState();
}

class _TaxPaymentScreenState extends State<TaxPaymentScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'bank_transfer';

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': 'bank'},
    {'value': 'cash', 'label': 'Cash', 'icon': 'money'},
    {'value': 'check', 'label': 'Check', 'icon': 'check'},
    {'value': 'ccp', 'label': 'CCP', 'icon': 'ccp'},
  ];

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.payment.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _markAsPaid() async {
    setState(() => _isLoading = true);

    try {
      await TaxService.markTaxPaymentAsPaid(
        widget.payment.id!,
        _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payment', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete this payment? This action cannot be undone.',
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

    if (confirmed == true && widget.payment.id != null) {
      setState(() => _isLoading = true);

      try {
        await TaxService.deleteTaxPayment(widget.payment.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting payment: $e')),
          );
        }
      } finally {
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
          'Tax Payment Details',
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
          if (widget.payment.status != TaxStatus.paid)
            PopupMenuButton<String>(
              icon: const Icon(
                FontAwesomeIcons.ellipsisVertical,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePayment();
                }
              },
              itemBuilder: (context) => [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Header
            _buildPaymentHeader(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Payment Details
            _buildPaymentDetails(),
            const SizedBox(height: AppConstants.paddingMedium),

            // Status and Actions
            if (widget.payment.status == TaxStatus.paid)
              _buildPaidStatus()
            else
              _buildPaymentActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: widget.payment.type.color.withValues(alpha: 0.1),
        border:
            Border.all(color: widget.payment.type.color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: widget.payment.type.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.payment.type.icon,
              color: AppColors.textWhite,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.payment.type.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w700,
                    color: widget.payment.type.color,
                  ),
                ),
                Text(
                  widget.payment.type.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    color: widget.payment.type.color,
                  ),
                ),
                Text(
                  'Tax Year ${widget.payment.year}',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: widget.payment.type.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.payment.amount.toStringAsFixed(0)} DA',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textLarge,
                  fontWeight: FontWeight.w700,
                  color: widget.payment.type.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.payment.status.color.withValues(alpha: 0.1),
                  border: Border.all(
                      color:
                          widget.payment.status.color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  widget.payment.status.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    fontWeight: FontWeight.w500,
                    color: widget.payment.status.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Due Date',
              '${widget.payment.dueDate.day}/${widget.payment.dueDate.month}/${widget.payment.dueDate.year}'),
          if (widget.payment.paidDate != null)
            _buildDetailRow('Payment Date',
                '${widget.payment.paidDate!.day}/${widget.payment.paidDate!.month}/${widget.payment.paidDate!.year}'),
          if (widget.payment.paymentMethod != null)
            _buildDetailRow('Payment Method',
                _getPaymentMethodLabel(widget.payment.paymentMethod!)),
          if (widget.payment.isOverdue)
            _buildDetailRow(
                'Days Overdue', '${widget.payment.daysOverdue} days',
                isError: true)
          else if (widget.payment.status != TaxStatus.paid)
            _buildDetailRow(
                'Days Remaining', '${widget.payment.daysUntilDue} days'),
          if (widget.payment.notes != null &&
              widget.payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Notes:',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.payment.notes!,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              fontWeight: FontWeight.w600,
              color: isError ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidStatus() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Successful',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'This payment has been marked as paid',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textSmall,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Record Payment',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Payment Method Selection
        Text(
          'Payment Method',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: _selectedPaymentMethod,
            isExpanded: true,
            underline: const SizedBox(),
            items: _paymentMethods.map((method) {
              return DropdownMenuItem<String>(
                value: method['value'],
                child: Text(
                  method['label']!,
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPaymentMethod = value);
              }
            },
          ),
        ),

        const SizedBox(height: 16),

        // Notes
        CustomTextField(
          label: 'Notes (Optional)',
          hint: 'Add notes about the payment',
          controller: _notesController,
          maxLines: 3,
          prefixIcon: FontAwesomeIcons.noteSticky,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Action Button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Mark as Paid',
            onPressed: _isLoading ? null : _markAsPaid,
            icon: FontAwesomeIcons.check,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodLabel(String method) {
    final methodData = _paymentMethods.firstWhere(
      (m) => m['value'] == method,
      orElse: () => {'label': method},
    );
    return methodData['label'] ?? method;
  }
}
