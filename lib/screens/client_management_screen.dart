import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';
import '../widgets/custom_button.dart';

import 'add_edit_client_screen.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  ClientType? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);

    try {
      final clients = await ClientService.getClients();
      setState(() {
        _clients = clients;
        _filteredClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clients: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterClients() {
    setState(() {
      _filteredClients = _clients.where((client) {
        final matchesSearch = _searchQuery.isEmpty ||
            client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            client.phone.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesFilter =
            _selectedFilter == null || client.clientType == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterClients();
  }

  void _onFilterChanged(ClientType? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterClients();
  }

  Future<void> _deleteClient(ClientModel client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Client',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${client.name}?',
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
        await ClientService.deleteClient(client.id!);
        _loadClients();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting client: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddClient() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AddEditClientScreen(),
          ),
        )
        .then((_) => _loadClients());
  }

  void _navigateToEditClient(ClientModel client) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddEditClientScreen(client: client),
          ),
        )
        .then((_) => _loadClients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Client Management',
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
            onPressed: _navigateToAddClient,
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
                      hintText: 'Search clients...',
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

                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _selectedFilter == null,
                          () => _onFilterChanged(null)),
                      const SizedBox(width: 8),
                      ...ClientType.values.map((type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              type.displayName,
                              _selectedFilter == type,
                              () => _onFilterChanged(type),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Client List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium),
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return _buildClientCard(client);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddClient,
        backgroundColor: AppColors.primary,
        child: const Icon(
          FontAwesomeIcons.plus,
          color: AppColors.textWhite,
          size: 20,
        ),
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
            FontAwesomeIcons.users,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != null
                ? 'No clients found'
                : 'No clients yet',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != null
                ? 'Try adjusting your search or filter'
                : 'Add your first client to get started',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textLight,
            ),
          ),
          if (_searchQuery.isEmpty && _selectedFilter == null) ...[
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add Client',
              onPressed: _navigateToAddClient,
              icon: FontAwesomeIcons.plus,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => _navigateToEditClient(client),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              // Client Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _getClientInitial(client),
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textLarge,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary name (company name for companies, person name for individuals)
                    Text(
                      _getDisplayName(client),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Secondary info (contact person for companies, email for individuals)
                    Text(
                      _getSecondaryInfo(client),
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          client.clientType.displayName,
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
                            client.currency.displayName,
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
                    _navigateToEditClient(client);
                  } else if (value == 'delete') {
                    _deleteClient(client);
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

  // Helper methods for client display
  String _getClientInitial(ClientModel client) {
    if (client.isCompany &&
        client.companyName != null &&
        client.companyName!.isNotEmpty) {
      return client.companyName![0].toUpperCase();
    }
    return client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C';
  }

  String _getDisplayName(ClientModel client) {
    if (client.isCompany &&
        client.companyName != null &&
        client.companyName!.isNotEmpty) {
      return client.companyName!;
    }
    return client.name;
  }

  String _getSecondaryInfo(ClientModel client) {
    if (client.isCompany) {
      // For companies, show contact person name
      return 'Contact: ${client.name}';
    }
    // For individuals, show email
    return client.email;
  }
}
