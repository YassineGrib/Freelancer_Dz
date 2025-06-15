import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSending = false;
  SupportCategory _selectedCategory = SupportCategory.general;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendSupportMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      // Simulate sending support message
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support message sent successfully! We\'ll get back to you soon.'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _subjectController.clear();
        _messageController.clear();
        _emailController.clear();
        setState(() {
          _selectedCategory = SupportCategory.general;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
          ),
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
          'Help & Support',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Quick Help Section
            _buildQuickHelpSection(),
            const SizedBox(height: 20),

            // FAQ Section
            _buildFaqSection(),
            const SizedBox(height: 20),

            // Contact Support Section
            _buildContactSupportSection(),
            const SizedBox(height: 20),

            // Contact Information
            _buildContactInfoSection(),
          ],
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
              color: AppColors.primary.withOpacity( 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              FontAwesomeIcons.headset,
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
                  'Help & Support',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get help with your freelancer app or contact our support team',
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

  Widget _buildQuickHelpSection() {
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
            'Quick Help',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildQuickHelpItem(
            icon: FontAwesomeIcons.circlePlay,
            title: 'Getting Started Guide',
            subtitle: 'Learn how to set up your freelancer profile',
            onTap: () => _showGettingStartedDialog(),
          ),
          const Divider(),
          _buildQuickHelpItem(
            icon: FontAwesomeIcons.fileInvoiceDollar,
            title: 'Invoice Management',
            subtitle: 'How to create and manage invoices',
            onTap: () => _showInvoiceHelpDialog(),
          ),
          const Divider(),
          _buildQuickHelpItem(
            icon: FontAwesomeIcons.percent,
            title: 'Tax Calculations',
            subtitle: 'Understanding Algerian tax requirements',
            onTap: () => _showTaxHelpDialog(),
          ),
          const Divider(),
          _buildQuickHelpItem(
            icon: FontAwesomeIcons.chartLine,
            title: 'Reports & Analytics',
            subtitle: 'Generate and understand your reports',
            onTap: () => _showReportsHelpDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
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
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildFaqItem(
            question: 'How do I calculate my IRG tax?',
            answer: 'IRG tax is calculated based on your annual income. If your income is less than 2M DA, you pay a fixed amount of 10,000 DA. If it\'s 2M DA or more, you pay 0.5% of your annual income.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            question: 'When is the CASNOS payment due?',
            answer: 'CASNOS payment is due on June 20th each year. The standard amount is 24,000 DA annually for freelancers.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            question: 'How do I backup my data?',
            answer: 'Your data is automatically synced to the cloud when you\'re online. You can also export your data from the Settings > Data & Storage section.',
          ),
          const SizedBox(height: 12),
          _buildFaqItem(
            question: 'Can I use the app offline?',
            answer: 'Yes! The app works offline and will sync your data when you\'re back online. All your core features are available offline.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
    );
  }

  Widget _buildContactSupportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection
            DropdownButtonFormField<SupportCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(
                  _selectedCategory.icon,
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
              items: SupportCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            CustomTextField(
              controller: _emailController,
              label: 'Your Email',
              hint: 'Enter your email address',
              prefixIcon: FontAwesomeIcons.envelope,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subject Field
            CustomTextField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Enter the subject of your message',
              prefixIcon: FontAwesomeIcons.tag,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Subject is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message Field
            CustomTextField(
              controller: _messageController,
              label: 'Message',
              hint: 'Describe your issue or question in detail',
              prefixIcon: FontAwesomeIcons.message,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Message is required';
                }
                if (value.trim().length < 10) {
                  return 'Message must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Send Message',
                onPressed: _isSending ? null : _sendSupportMessage,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                icon: _isSending ? null : FontAwesomeIcons.paperPlane,
                isLoading: _isSending,
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
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
            'Contact Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildContactItem(
            icon: FontAwesomeIcons.envelope,
            title: 'Email Support',
            subtitle: 'support@freelancerapp.com',
            onTap: () => _launchUrl('mailto:support@freelancerapp.com'),
          ),
          const Divider(),
          _buildContactItem(
            icon: FontAwesomeIcons.phone,
            title: 'Phone Support',
            subtitle: '+213 XXX XXX XXX',
            onTap: () => _launchUrl('tel:+213XXXXXXXXX'),
          ),
          const Divider(),
          _buildContactItem(
            icon: FontAwesomeIcons.globe,
            title: 'Website',
            subtitle: 'www.freelancerapp.com',
            onTap: () => _launchUrl('https://www.freelancerapp.com'),
          ),
          const Divider(),
          _buildContactItem(
            icon: FontAwesomeIcons.fileLines,
            title: 'Documentation',
            subtitle: 'View user manual and guides',
            onTap: () => _launchUrl('https://docs.freelancerapp.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              FontAwesomeIcons.externalLink,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods for quick help
  void _showGettingStartedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Getting Started',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Set up your profile in Settings > Profile',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '2. Add your first client in the Clients tab',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '3. Create your first project',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '4. Configure tax settings for Algeria',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '5. Start tracking payments and expenses',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Invoice Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Create professional invoices with automatic numbering, PDF export, and payment tracking. You can create client invoices with multiple items or project invoices that auto-generate from project data.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaxHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tax Calculations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'The app automatically calculates IRG tax (10,000 DA fixed or 0.5% of income) and CASNOS (24,000 DA annually). Set up reminders for payment deadlines: IRG on January 10th and CASNOS on June 20th.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportsHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Generate detailed reports for clients, payments, expenses, and taxes. Filter by date range and export as PDF. Use the dashboard for quick insights into your business performance.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

enum SupportCategory {
  general,
  technical,
  billing,
  feature,
  bug;

  String get displayName {
    switch (this) {
      case SupportCategory.general:
        return 'General Question';
      case SupportCategory.technical:
        return 'Technical Issue';
      case SupportCategory.billing:
        return 'Billing & Payments';
      case SupportCategory.feature:
        return 'Feature Request';
      case SupportCategory.bug:
        return 'Bug Report';
    }
  }

  IconData get icon {
    switch (this) {
      case SupportCategory.general:
        return FontAwesomeIcons.circleQuestion;
      case SupportCategory.technical:
        return FontAwesomeIcons.gear;
      case SupportCategory.billing:
        return FontAwesomeIcons.creditCard;
      case SupportCategory.feature:
        return FontAwesomeIcons.lightbulb;
      case SupportCategory.bug:
        return FontAwesomeIcons.bug;
    }
  }
}
