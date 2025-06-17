import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'client_management_screen.dart';
import 'project_management_screen.dart';
import 'payment_management_screen.dart';
import 'expense_management_screen.dart';
import 'invoice_management_screen.dart';
import 'tax_management_screen.dart';
import 'calendar_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'add_edit_project_screen.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.businessManagement??'Business Management',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textXLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

           const SizedBox(height: 8),

          Text(
            AppLocalizations.of(context)?.manageAllBusiness??'Manage all aspects of your freelance business',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textMedium,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Project Management Card (Full Width)
          _buildProjectCard(context),
          const SizedBox(height: AppConstants.paddingMedium),

          // Other Menu Items Grid
          _buildMenuGrid(context),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  FontAwesomeIcons.briefcase,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.projectManagement??'Project Management',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textLarge,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)?.manageProjectsTrackProgress??'Manage your projects and track progress',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textSmall,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProjectManagementScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.viewProjects??'View Projects',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditProjectScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: AppLocalizations.of(context)?.addProject??'Add Project',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = [
      {
        'icon': FontAwesomeIcons.users,
        'title': AppLocalizations.of(context)!.clients,
        'subtitle': AppLocalizations.of(context)?.manageClients??'Manage clients',
        'color': Colors.blue,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ClientManagementScreen()),
            ),
      },
      {
        'icon': FontAwesomeIcons.creditCard,
        'title': AppLocalizations.of(context)!.payments,
        'subtitle': AppLocalizations.of(context)?.trackPayments??'Track payments',
        'color': Colors.green,
        'onTap': () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const PaymentManagementScreen()),
          );
          // Trigger refresh of project data when returning from payment management
          if (mounted) {
            setState(() {});
          }
        },
      },
      {
        'icon': FontAwesomeIcons.receipt,
        'title': AppLocalizations.of(context)!.expenses,
        'subtitle': AppLocalizations.of(context)?.manageExpenses??'Manage expenses',
        'color': Colors.orange,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const ExpenseManagementScreen()),
            ),
      },
      {
        'icon': FontAwesomeIcons.fileInvoice,
        'title': AppLocalizations.of(context)!.invoices,
        'subtitle': AppLocalizations.of(context)?.createInvoices??'Create invoices',
        'color': Colors.purple,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const InvoiceManagementScreen()),
            ),
      },
      {
        'icon': FontAwesomeIcons.calculator,
        'title': AppLocalizations.of(context)?.taxes??'Taxes',
        'subtitle': AppLocalizations.of(context)?.taxManagement??'Tax management',
        'color': Colors.red,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const TaxManagementScreen()),
            ),
      },
      {
        'icon': FontAwesomeIcons.calendar,
        'title': AppLocalizations.of(context)?.calendar??'Calendar',
        'subtitle': AppLocalizations.of(context)?.viewEvents??'View events',
        'color': Colors.teal,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            ),
      },
      {
        'icon': FontAwesomeIcons.chartLine,
        'title': AppLocalizations.of(context)?.reports??'Reports',
        'subtitle': AppLocalizations.of(context)?.businessAnalytics??'Business analytics',
        'color': Colors.indigo,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ReportsScreen()),
            ),
      },
      {
        'icon': FontAwesomeIcons.gear,
        'title': AppLocalizations.of(context)?.settings??'Settings',
        'subtitle': 'App preferences',
        'color': Colors.grey,
        'onTap': () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildGridMenuItem(
          context,
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          color: item['color'] as Color,
          onTap: item['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildGridMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
