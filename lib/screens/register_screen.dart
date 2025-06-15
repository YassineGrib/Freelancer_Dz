import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'tabbed_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.nameRequired;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.emailRequired;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return AppConstants.emailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.passwordRequired;
    }
    if (value.length < 6) {
      return AppConstants.passwordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.confirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return AppConstants.passwordsDoNotMatch;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the terms and conditions'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final response = await AuthService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

        if (response.user != null && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please check your email to verify your account.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 5),
            ),
          );

          // Navigate to home screen or back to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TabbedHomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AuthService.getErrorMessage(e)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back Button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    FontAwesomeIcons.arrowLeft,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome Text
                Text(
                  AppLocalizations.of(context)?.createAccount ?? 'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textTitle,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  AppLocalizations.of(context)?.joinOurCommunity ?? 'Join our community',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                // Name Field
                CustomTextField(
                  label: AppLocalizations.of(context)?.fullName ?? 'Full Name',
                  hint: AppLocalizations.of(context)?.enterFullName ?? 'Enter your full name',
                  prefixIcon: FontAwesomeIcons.user,
                  controller: _nameController,
                  validator: _validateName,
                ),

                const SizedBox(height: 20),

                // Email Field
                CustomTextField(
                  label: AppLocalizations.of(context)?.email ?? 'Email',
                  hint: AppLocalizations.of(context)?.enterEmail ?? 'Enter your email',
                  prefixIcon: FontAwesomeIcons.envelope,
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  label: AppLocalizations.of(context)?.password ?? 'Password',
                  hint: AppLocalizations.of(context)?.enterPassword ?? 'Enter your password',
                  prefixIcon: FontAwesomeIcons.lock,
                  controller: _passwordController,
                  validator: _validatePassword,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Confirm Password Field
                CustomTextField(
                  label: AppLocalizations.of(context)?.confirmPassword ?? 'Confirm Password',
                  hint: AppLocalizations.of(context)?.confirmPasswordPlaceholder ?? 'Confirm your password',
                  prefixIcon: FontAwesomeIcons.lock,
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: AppConstants.textMedium,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Register Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 40),

                // Sign In Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

