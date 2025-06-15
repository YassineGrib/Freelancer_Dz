import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';

class LocalAuthService {
  static LocalAuthService? _instance;
  static LocalAuthService get instance {
    _instance ??= LocalAuthService._internal();
    return _instance!;
  }

  LocalAuthService._internal();

  final LocalDatabaseService _db = LocalDatabaseService.instance;

  // Current user session
  String? _currentUserId;
  Map<String, dynamic>? _currentUser;

  // Stream controller for auth state changes
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  // Auth state stream
  Stream<Map<String, dynamic>?> get authStateChanges =>
      _authStateController.stream;

  // Current user getter
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentUserId => _currentUserId;
  bool get isAuthenticated => _currentUser != null;

  // Initialize auth service
  Future<void> initialize() async {
    await _loadSavedSession();
  }

  // Load saved session from SharedPreferences
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('current_user_id');

      if (savedUserId != null) {
        final user = await _db.getUserById(savedUserId);
        if (user != null) {
          _currentUserId = savedUserId;
          _currentUser = user;
          _authStateController.add(_currentUser);

          // Update last login
          await _db.updateUserLastLogin(savedUserId);
        } else {
          // User not found, clear saved session
          await _clearSavedSession();
        }
      }
    } catch (e) {
      print('Error loading saved session: $e');
      await _clearSavedSession();
    }
  }

  // Save session to SharedPreferences
  Future<void> _saveSavedSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  // Clear saved session
  Future<void> _clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      _currentUserId = null;
      _currentUser = null;
      _authStateController.add(null);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult(
          success: false,
          error: 'User with this email already exists',
        );
      }

      // Validate input
      if (!_isValidEmail(email)) {
        return AuthResult(
          success: false,
          error: 'Please enter a valid email address',
        );
      }

      if (password.length < 6) {
        return AuthResult(
          success: false,
          error: 'Password must be at least 6 characters long',
        );
      }

      if (fullName.trim().isEmpty) {
        return AuthResult(
          success: false,
          error: 'Full name is required',
        );
      }

      // Create user
      final userId = await _db.createUser(
        email: email.toLowerCase().trim(),
        password: password,
        fullName: fullName.trim(),
      );

      // Load user data
      final user = await _db.getUserById(userId);
      if (user != null) {
        _currentUserId = userId;
        _currentUser = user;
        await _saveSavedSession(userId);
        _authStateController.add(_currentUser);

        return AuthResult(
          success: true,
          user: user,
        );
      } else {
        return AuthResult(
          success: false,
          error: 'Failed to create user account',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to create account: ${e.toString()}',
      );
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      // Find user by email
      final user = await _db.getUserByEmail(email.toLowerCase().trim());

      if (user == null) {
        return AuthResult(
          success: false,
          error: 'No account found with this email address',
        );
      }

      // Verify password
      final hashedPassword = LocalDatabaseService.hashPassword(password);
      if (user['password_hash'] != hashedPassword) {
        return AuthResult(
          success: false,
          error: 'Incorrect password',
        );
      }

      // Sign in successful
      _currentUserId = user['id'];
      _currentUser = user;

      // Only save session if remember me is enabled
      if (rememberMe) {
        await _saveSavedSession(user['id']);
      }

      await _db.updateUserLastLogin(user['id']);
      _authStateController.add(_currentUser);

      return AuthResult(
        success: true,
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to sign in: ${e.toString()}',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _clearSavedSession();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Reset password (for local database, this would require security questions or admin intervention)
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      final user = await _db.getUserByEmail(email.toLowerCase().trim());
      if (user == null) {
        return AuthResult(
          success: false,
          error: 'No account found with this email address',
        );
      }

      // For local database, we can't send emails, so we'll return a success message
      // In a real app, you might implement security questions or admin reset
      return AuthResult(
        success: true,
        message: 'Password reset requested. Please contact administrator.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to reset password: ${e.toString()}',
      );
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? fullName,
    String? email,
  }) async {
    try {
      if (_currentUserId == null) {
        return AuthResult(
          success: false,
          error: 'No user signed in',
        );
      }

      final updates = <String, dynamic>{};

      if (fullName != null && fullName.trim().isNotEmpty) {
        updates['full_name'] = fullName.trim();
      }

      if (email != null && email.trim().isNotEmpty) {
        if (!_isValidEmail(email)) {
          return AuthResult(
            success: false,
            error: 'Please enter a valid email address',
          );
        }

        // Check if email is already taken by another user
        final existingUser =
            await _db.getUserByEmail(email.toLowerCase().trim());
        if (existingUser != null && existingUser['id'] != _currentUserId) {
          return AuthResult(
            success: false,
            error: 'Email address is already taken',
          );
        }

        updates['email'] = email.toLowerCase().trim();
      }

      if (updates.isNotEmpty) {
        updates['updated_at'] = LocalDatabaseService.getCurrentTimestamp();

        // Update user in database
        await _db.database.then((db) => db.update(
              'users',
              updates,
              where: 'id = ?',
              whereArgs: [_currentUserId],
            ));

        // Reload user data
        final updatedUser = await _db.getUserById(_currentUserId!);
        if (updatedUser != null) {
          _currentUser = updatedUser;
          _authStateController.add(_currentUser);
        }
      }

      return AuthResult(
        success: true,
        user: _currentUser,
        message: 'Profile updated successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  // Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUserId == null) {
        return AuthResult(
          success: false,
          error: 'No user signed in',
        );
      }

      // Verify current password
      final hashedCurrentPassword =
          LocalDatabaseService.hashPassword(currentPassword);
      if (_currentUser!['password_hash'] != hashedCurrentPassword) {
        return AuthResult(
          success: false,
          error: 'Current password is incorrect',
        );
      }

      // Validate new password
      if (newPassword.length < 6) {
        return AuthResult(
          success: false,
          error: 'New password must be at least 6 characters long',
        );
      }

      // Update password
      final hashedNewPassword = LocalDatabaseService.hashPassword(newPassword);
      await _db.database.then((db) => db.update(
            'users',
            {
              'password_hash': hashedNewPassword,
              'updated_at': LocalDatabaseService.getCurrentTimestamp(),
            },
            where: 'id = ?',
            whereArgs: [_currentUserId],
          ));

      return AuthResult(
        success: true,
        message: 'Password changed successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Dispose
  void dispose() {
    _authStateController.close();
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String? error;
  final String? message;
  final Map<String, dynamic>? user;

  AuthResult({
    required this.success,
    this.error,
    this.message,
    this.user,
  });
}
