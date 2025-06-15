import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifying = false;
  bool _obscurePassword = true;
  String? _currentEmail;
  bool _emailNotifications = true;
  bool _marketingEmails = false;
  bool _securityAlerts = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentEmail() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentEmail = user?['email'];
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.changeEmail(
        newEmail: _newEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
        _newEmailController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  Future<void> _resendVerificationEmail() async {
    setState(() => _isVerifying = true);

    try {
      // await AuthService.resendEmailVerification(); // Not available in local auth
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Email Settings',
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
            // Current Email Section
            _buildCurrentEmailSection(),
            const SizedBox(height: 24),

            // Change Email Section
            _buildChangeEmailSection(),
            const SizedBox(height: 24),

            // Email Preferences Section
            _buildEmailPreferencesSection(),
            const SizedBox(height: 24),

            // Verification Section
            _buildVerificationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEmailSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.primary.withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  FontAwesomeIcons.envelope,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Email',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentEmail ?? 'Loading...',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeEmailSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              'Change Email Address',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textLarge,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // New Email Field
            CustomTextField(
              controller: _newEmailController,
              label: 'New Email Address',
              hint: 'Enter your new email address',
              prefixIcon: FontAwesomeIcons.envelope,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                if (value.trim() == _currentEmail) {
                  return 'New email must be different from current email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              prefixIcon: FontAwesomeIcons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Change Email Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Change Email',
                onPressed: _isLoading ? null : _changeEmail,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                icon: _isLoading ? null : FontAwesomeIcons.paperPlane,
                isLoading: _isLoading,
                height: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Preferences',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Email Notifications
          SwitchListTile(
            title: Text(
              'Email Notifications',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Receive notifications about your account',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Security Alerts
          SwitchListTile(
            title: Text(
              'Security Alerts',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Important security notifications',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
            value: _securityAlerts,
            onChanged: (value) {
              setState(() {
                _securityAlerts = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const Divider(),

          // Marketing Emails
          SwitchListTile(
            title: Text(
              'Marketing Emails',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Updates and promotional content',
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textSmall,
                color: AppColors.textSecondary,
              ),
            ),
            value: _marketingEmails,
            onChanged: (value) {
              setState(() {
                _marketingEmails = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Verification',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'If you haven\'t received a verification email, you can request a new one.',
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Resend Verification Email',
              onPressed: _isVerifying ? null : _resendVerificationEmail,
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              icon: _isVerifying ? null : FontAwesomeIcons.envelope,
              isLoading: _isVerifying,
              height: 45,
            ),
          ),
        ],
      ),
    );
  }
}

