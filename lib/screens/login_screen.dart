import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'register_screen.dart';
import 'tabbed_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null && mounted) {
          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TabbedHomeScreen()),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.error ?? 'Login failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
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

  void _navigateToRegister() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: AppConstants.normalAnimation,
      ),
    );
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
                const SizedBox(height: 80),

                // Welcome Text
                Text(
                  AppLocalizations.of(context)?.welcomeBack ?? 'Welcome Back',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textTitle,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  AppLocalizations.of(context)?.signInToContinue ?? 'Sign in to continue',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textLarge,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 50),

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

                const SizedBox(height: 16),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle forgot password
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Login Button
                CustomButton(
                  text: AppLocalizations.of(context)?.signIn ?? 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 40),

                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.dontHaveAccount ?? "Don't have an account? ",
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          AppLocalizations.of(context)?.signUp ?? 'Sign Up',
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

