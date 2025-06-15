import 'local_auth_service.dart';

class AuthService {
  static final LocalAuthService _localAuth = LocalAuthService.instance;

  // Get current user
  static Map<String, dynamic>? get currentUser => _localAuth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _localAuth.isAuthenticated;

  // Sign up with email and password
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _localAuth.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  // Sign in with email and password
  static Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    return await _localAuth.signIn(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await _localAuth.signOut();
  }

  // Reset password
  static Future<AuthResult> resetPassword({required String email}) async {
    return await _localAuth.resetPassword(email: email);
  }

  // Update user profile
  static Future<AuthResult> updateProfile({
    String? fullName,
    String? email,
  }) async {
    return await _localAuth.updateProfile(
      fullName: fullName,
      email: email,
    );
  }

  // Change password
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _localAuth.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // Change email (combined with update profile)
  static Future<AuthResult> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    // For local auth, we'll verify password through sign in and then update
    final signInResult = await _localAuth.signIn(
      email: currentUser?['email'] ?? '',
      password: password,
    );

    if (!signInResult.success) {
      return AuthResult(
        success: false,
        error: 'Password is incorrect',
      );
    }

    return await _localAuth.updateProfile(email: newEmail);
  }

  // Get current user details
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return _localAuth.currentUser;
  }

  // Get auth state stream
  static Stream<Map<String, dynamic>?> get authStateChanges =>
      _localAuth.authStateChanges;

  // Initialize auth service
  static Future<void> initialize() async {
    await _localAuth.initialize();
  }

  // Handle auth errors
  static String getErrorMessage(dynamic error) {
    if (error is AuthResult) {
      return error.error ?? 'Unknown error';
    }
    return error.toString();
  }
}
