import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/invoice_model.dart';

import '../models/client_model.dart' as client_model;
import '../services/invoice_service.dart';

import '../services/client_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';

import 'add_edit_invoice_screen.dart';
import 'invoice_detail_screen.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final _searchController = TextEditingController();
  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> _filteredInvoices = [];

  List<client_model.ClientModel> _clients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  InvoiceType? _selectedTypeFilter;
  InvoiceStatus? _selectedStatusFilter;
  String? _selectedProjectFilter;
  String? _selectedClientFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final invoices = await InvoiceService.getAllInvoices();
      final clients = await ClientService.getClients();

      setState(() {
        _invoices = invoices;
        _filteredInvoices = invoices;
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _filterInvoices() {
    setState(() {
      _filteredInvoices = _invoices.where((invoice) {
        final matchesSearch = _searchQuery.isEmpty ||
            invoice.invoiceNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (invoice.clientName
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (invoice.notes
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        final matchesType =
            _selectedTypeFilter == null || invoice.type == _selectedTypeFilter;

        final matchesStatus = _selectedStatusFilter == null ||
            invoice.status == _selectedStatusFilter;

        final matchesProject = _selectedProjectFilter == null ||
            invoice.projectId == _selectedProjectFilter;

        final matchesClient = _selectedClientFilter == null ||
            invoice.clientId == _selectedClientFilter;

        return matchesSearch &&
            matchesType &&
            matchesStatus &&
            matchesProject &&
            matchesClient;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterInvoices();
  }

  void _onTypeFilterChanged(InvoiceType? type) {
    setState(() => _selectedTypeFilter = type);
    _filterInvoices();
  }

  void _onStatusFilterChanged(InvoiceStatus? status) {
    setState(() => _selectedStatusFilter = status);
    _filterInvoices();
  }

  void _navigateToAddInvoice() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditInvoiceScreen(),
          ),
        )
        .then((_) => _loadData());
  }

  void _navigateToEditInvoice(InvoiceModel invoice) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditInvoiceScreen(invoice: invoice),
          ),
        )
        .then((_) => _loadData());
  }

  void _navigateToInvoiceDetail(InvoiceModel invoice) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => InvoiceDetailScreen(invoice: invoice),
          ),
        )
        .then((_) => _loadData());
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Invoice', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete invoice "${invoice.invoiceNumber}"? This action cannot be undone.',
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

    if (confirmed == true && invoice.id != null) {
      try {
        await InvoiceService.deleteInvoice(invoice.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting invoice: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateInvoiceStatus(
      InvoiceModel invoice, InvoiceStatus newStatus) async {
    try {
      await InvoiceService.updateInvoiceStatus(invoice.id!, newStatus);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Invoice status updated to ${newStatus.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating invoice status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Invoice Management',
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
            onPressed: _navigateToAddInvoice,
            icon: const Icon(
              FontAwesomeIcons.plus,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
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
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Search invoices...',
                      hintStyle:
                          GoogleFonts.poppins(color: AppColors.textLight),
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

                // Type Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Types', _selectedTypeFilter == null,
                          () => _onTypeFilterChanged(null)),
                      const SizedBox(width: 8),
                      ...InvoiceType.values.map((type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              type.displayName,
                              _selectedTypeFilter == type,
                              () => _onTypeFilterChanged(type),
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Status Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                          'All Status',
                          _selectedStatusFilter == null,
                          () => _onStatusFilterChanged(null)),
                      const SizedBox(width: 8),
                      ...InvoiceStatus.values.map((status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              status.displayName,
                              _selectedStatusFilter == status,
                              () => _onStatusFilterChanged(status),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Invoice List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredInvoices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium),
                        itemCount: _filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _filteredInvoices[index];
                          return _buildInvoiceCard(invoice);
                        },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            FontAwesomeIcons.fileInvoice,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedStatusFilter != null
                ? 'No invoices found'
                : 'No invoices yet',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatusFilter != null
                ? 'Try adjusting your search or filters'
                : 'Create your first invoice to get started',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _selectedStatusFilter == null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: 'Create Invoice',
              onPressed: _navigateToAddInvoice,
              icon: FontAwesomeIcons.plus,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final client = _clients.firstWhere(
      (c) => c.id == invoice.clientId,
      orElse: () => client_model.ClientModel(
        name: invoice.clientName ?? 'Unknown Client',
        email: '',
        phone: '',
        address: '',
        clientType: client_model.ClientType.individualLocal,
        currency: client_model.Currency.da,
        createdAt: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => _navigateToInvoiceDetail(invoice),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Type & Status Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: invoice.type.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        invoice.type.icon,
                        color: AppColors.textWhite,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: invoice.status.color,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.textWhite, width: 1),
                        ),
                        child: Icon(
                          invoice.status.icon,
                          color: AppColors.textWhite,
                          size: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Invoice Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice number
                    Text(
                      invoice.invoiceNumber,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Client name
                    Text(
                      client.isCompany &&
                              client.companyName != null &&
                              client.companyName!.isNotEmpty
                          ? client.companyName!
                          : client.name,
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
                            color: invoice.type.color.withOpacity(0.1),
                            border: Border.all(
                                color: invoice.type.color.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            invoice.type.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: invoice.type.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          invoice.status.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textSmall,
                            color: invoice.status.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due: ${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: invoice.isOverdue
                            ? AppColors.error
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${invoice.total.toStringAsFixed(2)} ${invoice.currency.code}',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      switch (value) {
                        case 'edit':
                          _navigateToEditInvoice(invoice);
                          break;
                        case 'delete':
                          _deleteInvoice(invoice);
                          break;
                        case 'mark_sent':
                          _updateInvoiceStatus(invoice, InvoiceStatus.sent);
                          break;
                        case 'mark_paid':
                          _updateInvoiceStatus(invoice, InvoiceStatus.paid);
                          break;
                        case 'mark_overdue':
                          _updateInvoiceStatus(invoice, InvoiceStatus.overdue);
                          break;
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
                      if (invoice.status == InvoiceStatus.draft)
                        PopupMenuItem(
                          value: 'mark_sent',
                          child: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.paperPlane,
                                size: 14,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mark as Sent',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary,
                                  fontSize: AppConstants.textSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (invoice.status == InvoiceStatus.sent ||
                          invoice.status == InvoiceStatus.overdue)
                        PopupMenuItem(
                          value: 'mark_paid',
                          child: Row(
                            children: [
                              const Icon(
                                FontAwesomeIcons.circleCheck,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mark as Paid',
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
            ],
          ),
        ),
      ),
    );
  }
}
