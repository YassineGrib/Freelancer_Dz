import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import 'auth_wrapper.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showLoginForm = false;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  bool _rememberMe = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    // Brief delay to show logo
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      // Check if user is already logged in
      if (AuthService.isLoggedIn) {
        // User is logged in, navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      } else {
        // User is not logged in, show login form
        setState(() {
          _isCheckingAuth = false;
          _showLoginForm = true;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (response.user != null && mounted) {
        // Login successful, navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      } else {
        if (mounted) {
          _showErrorSnackBar(response.error ?? 'Login failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AuthService.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppConstants.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isCheckingAuth
            ? _buildSplashContent()
            : _showLoginForm
                ? _buildLoginForm()
                : _buildSplashContent(),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple Logo
          const Icon(
            FontAwesomeIcons.briefcase,
            color: AppColors.primary,
            size: 80,
          ),

          if (_isCheckingAuth) ...[
            const SizedBox(height: AppConstants.paddingLarge),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // Logo (smaller version)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: const Icon(
                  FontAwesomeIcons.briefcase,
                  color: AppColors.white,
                  size: 45,
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Welcome Text
            Center(
              child: Text(
                AppLocalizations.of(context)?.welcomeBack ?? 'Welcome Back',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textXXLarge,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            Center(
              child: Text(
                AppLocalizations.of(context)?.signInToContinue ?? 'Sign in to continue',
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textLarge,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingXLarge),

            // Email Field
            CustomTextField(
              controller: _emailController,
              label: AppLocalizations.of(context)?.email ?? 'Email',
              hint: AppLocalizations.of(context)?.enterEmail ?? 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: FontAwesomeIcons.envelope,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.emailRequired;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return AppConstants.emailInvalid;
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              label: AppLocalizations.of(context)?.password ?? 'Password',
              hint: AppLocalizations.of(context)?.enterPassword ?? 'Enter your password',
              obscureText: true,
              prefixIcon: FontAwesomeIcons.lock,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppConstants.passwordRequired;
                }
                if (value.length < 6) {
                  return AppConstants.passwordTooShort;
                }
                return null;
              },
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Remember Me Checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                Text(
                  'Remember me',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Login Button
            CustomButton(
              text: AppLocalizations.of(context)?.signIn ?? 'Sign In',
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Forgot Password
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                  _showErrorSnackBar('Forgot password feature coming soon');
                },
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: AppConstants.textMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingMedium),

            // Sign Up Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)?.dontHaveAccount ?? "Don't have an account? ",
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)?.signUp ?? 'Sign Up',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: AppColors.primary,
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
    );
  }
}
