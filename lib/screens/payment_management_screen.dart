import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

import 'add_edit_payment_screen.dart';
import 'payment_details_screen.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  List<PaymentModel> _payments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  PaymentStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final payments = await PaymentService.getPayments();
      setState(() {
        _payments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments = _payments.where((payment) {
        final matchesSearch = _searchQuery.isEmpty ||
            payment.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            payment.referenceNumber
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            payment.project?.projectName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            payment.client?.name
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true;

        final matchesStatus =
            _selectedStatus == null || payment.paymentStatus == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterPayments();
  }

  void _onStatusFilterChanged(PaymentStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterPayments();
  }

  Future<void> _navigateToAddPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPaymentScreen(),
      ),
    );

    if (result == true) {
      _loadPayments();
    }
  }

  void _navigateToEditPayment(PaymentModel payment) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditPaymentScreen(payment: payment),
      ),
    );
    if (result == true) {
      _loadPayments();
    }
  }

  Future<void> _deletePayment(PaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this payment?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PaymentService.deletePayment(payment.id!);
        _loadPayments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting payment: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToPaymentDetails(PaymentModel payment) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailsScreen(payment: payment),
      ),
    );

    // Refresh the list if payment was updated or deleted
    if (result == true) {
      _loadPayments();
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
        title: Text(
          'Payment Management',
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
            onPressed: _navigateToAddPayment,
            icon: const Icon(
              FontAwesomeIcons.plus,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      ElevatedButton(
                        onPressed: _loadPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search and Filter Section
                    _buildSearchAndFilterSection(),

                    // Payments List
                    Expanded(
                      child: _filteredPayments.isEmpty
                          ? _buildEmptyState()
                          : _buildPaymentsList(),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPayment,
        backgroundColor: AppColors.primary,
        child: const Icon(
          FontAwesomeIcons.plus,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: 'Search payments...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                prefixIcon: const Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 16,
                  color: AppColors.textLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingMedium,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _selectedStatus == null,
                    () => _onStatusFilterChanged(null)),
                const SizedBox(width: 8),
                ...PaymentStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        status.displayName,
                        _selectedStatus == status,
                        () => _onStatusFilterChanged(status),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textSmall,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
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
              // Payment Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(payment.paymentStatus),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    _getStatusIcon(payment.paymentStatus),
                    color: AppColors.textWhite,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Payment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project name
                    Text(
                      payment.project?.projectName ?? 'Unknown Project',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Client name
                    Text(
                      payment.client?.name ?? 'Unknown Client',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          payment.paymentStatus.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${payment.paymentAmount.toStringAsFixed(2)} ${payment.currency.code}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(
                  FontAwesomeIcons.ellipsisVertical,
                  size: 16,
                  color: AppColors.textLight,
                ),
                color: AppColors.surface,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: const BorderSide(color: AppColors.border),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditPayment(payment);
                  } else if (value == 'delete') {
                    _deletePayment(payment);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.pen,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.receipt,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != null
                ? 'No payments found'
                : 'No payments yet',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != null
                ? 'Try adjusting your search or filter'
                : 'Add your first payment to get started',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textLight,
            ),
          ),
          if (_searchQuery.isEmpty && _selectedStatus == null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add Payment',
              onPressed: _navigateToAddPayment,
              icon: FontAwesomeIcons.plus,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }
}
