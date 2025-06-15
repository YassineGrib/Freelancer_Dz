import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../services/payment_validation_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'add_edit_payment_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final PaymentModel payment;

  const PaymentDetailsScreen({
    super.key,
    required this.payment,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  late PaymentModel _payment;
  bool _isLoading = false;
  Map<String, dynamic>? _projectSummary;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
    _loadProjectSummary();
  }

  Future<void> _loadProjectSummary() async {
    try {
      final summary = await PaymentValidationService.getProjectPaymentSummary(_payment.projectId);
      setState(() {
        _projectSummary = summary;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _changePaymentStatus(PaymentStatus newStatus) async {
    if (_payment.paymentStatus == newStatus) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPayment = await PaymentService.changePaymentStatus(_payment.id!, newStatus);
      setState(() {
        _payment = updatedPayment;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment status updated to ${newStatus.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload project summary after status change
      _loadProjectSummary();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPaymentScreen(payment: _payment),
      ),
    );

    if (result == true) {
      // Reload payment details
      try {
        final updatedPayment = await PaymentService.getPaymentById(_payment.id!);
        if (updatedPayment != null) {
          setState(() {
            _payment = updatedPayment;
          });
          _loadProjectSummary();
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _deletePayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PaymentService.deletePayment(_payment.id!);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.partial:
        return Colors.amber;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return FontAwesomeIcons.circleCheck;
      case PaymentStatus.pending:
        return FontAwesomeIcons.clock;
      case PaymentStatus.failed:
        return FontAwesomeIcons.circleXmark;
      case PaymentStatus.cancelled:
        return FontAwesomeIcons.ban;
      case PaymentStatus.refunded:
        return FontAwesomeIcons.rotateLeft;
      case PaymentStatus.partial:
        return FontAwesomeIcons.triangleExclamation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Payment Details',
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textLarge,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              FontAwesomeIcons.ellipsisVertical,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editPayment();
                  break;
                case 'delete':
                  _deletePayment();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.pen, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Payment',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: AppConstants.textSmall,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.trash, size: 14, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Payment',
                      style: GoogleFonts.poppins(
                        color: Colors.red,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaymentHeader(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildPaymentDetails(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  if (_projectSummary != null) _buildProjectSummary(),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildStatusActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getStatusColor(_payment.paymentStatus),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Center(
              child: Icon(
                _getStatusIcon(_payment.paymentStatus),
                color: AppColors.textWhite,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_payment.paymentAmount.toStringAsFixed(2)} ${_payment.currency.code}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_payment.paymentStatus).withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(_payment.paymentStatus).withOpacity( 0.3),
                    ),
                  ),
                  child: Text(
                    _payment.paymentStatus.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(_payment.paymentStatus),
                    ),
                  ),
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
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
          const SizedBox(height: AppConstants.paddingMedium),
          _buildDetailRow('Project', _payment.project?.projectName ?? 'Unknown Project'),
          _buildDetailRow('Client', _payment.client?.name ?? 'Unknown Client'),
          _buildDetailRow('Payment Method', _payment.paymentMethod.displayName),
          _buildDetailRow('Payment Type', _payment.paymentType.displayName),
          _buildDetailRow('Payment Date', '${_payment.paymentDate.day}/${_payment.paymentDate.month}/${_payment.paymentDate.year}'),
          if (_payment.dueDate != null)
            _buildDetailRow('Due Date', '${_payment.dueDate!.day}/${_payment.dueDate!.month}/${_payment.dueDate!.year}'),
          if (_payment.referenceNumber != null)
            _buildDetailRow('Reference Number', _payment.referenceNumber!),
          if (_payment.description != null)
            _buildDetailRow('Description', _payment.description!),
          if (_payment.notes != null)
            _buildDetailRow('Notes', _payment.notes!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSummary() {
    final summary = _projectSummary!;
    final projectTotal = summary['projectTotalValue'] ?? 0.0;
    final completedTotal = summary['completedTotal'] ?? 0.0;
    final pendingTotal = summary['pendingTotal'] ?? 0.0;
    final remainingAmount = summary['remainingAmount'] ?? 0.0;
    final paymentProgress = summary['paymentProgress'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Payment Summary',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildSummaryRow('Project Total', '${projectTotal.toStringAsFixed(2)} ${_payment.currency.code}', Colors.blue),
          _buildSummaryRow('Completed Payments', '${completedTotal.toStringAsFixed(2)} ${_payment.currency.code}', Colors.green),
          _buildSummaryRow('Pending Payments', '${pendingTotal.toStringAsFixed(2)} ${_payment.currency.code}', Colors.orange),
          _buildSummaryRow('Remaining Amount', '${remainingAmount.toStringAsFixed(2)} ${_payment.currency.code}', Colors.red),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Progress: ',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${paymentProgress.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textSmall,
                  fontWeight: FontWeight.w600,
                  color: paymentProgress >= 100 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (paymentProgress / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: paymentProgress >= 100 ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Actions',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          if (_payment.paymentStatus == PaymentStatus.pending) ...[
            CustomButton(
              text: 'Mark as Completed',
              onPressed: () => _changePaymentStatus(PaymentStatus.completed),
              icon: FontAwesomeIcons.circleCheck,
              backgroundColor: Colors.green,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Mark as Failed',
              onPressed: () => _changePaymentStatus(PaymentStatus.failed),
              icon: FontAwesomeIcons.circleXmark,
              backgroundColor: Colors.red,
            ),
          ] else if (_payment.paymentStatus == PaymentStatus.completed) ...[
            CustomButton(
              text: 'Mark as Pending',
              onPressed: () => _changePaymentStatus(PaymentStatus.pending),
              icon: FontAwesomeIcons.clock,
              backgroundColor: Colors.orange,
            ),
          ] else if (_payment.paymentStatus == PaymentStatus.failed) ...[
            CustomButton(
              text: 'Mark as Pending',
              onPressed: () => _changePaymentStatus(PaymentStatus.pending),
              icon: FontAwesomeIcons.clock,
              backgroundColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Mark as Completed',
              onPressed: () => _changePaymentStatus(PaymentStatus.completed),
              icon: FontAwesomeIcons.circleCheck,
              backgroundColor: Colors.green,
            ),
          ],
        ],
      ),
    );
  }
}

