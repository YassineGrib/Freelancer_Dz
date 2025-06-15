import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  static String getAuthErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
          return 'Invalid email or password. Please check your credentials and try again.';
        case 'email not confirmed':
          return 'Please check your email and click the confirmation link before signing in.';
        case 'user already registered':
          return 'An account with this email already exists. Please sign in instead.';
        case 'password should be at least 6 characters':
          return 'Password must be at least 6 characters long.';
        case 'invalid email':
          return 'Please enter a valid email address.';
        case 'signup is disabled':
          return 'New user registration is currently disabled.';
        case 'email rate limit exceeded':
          return 'Too many email requests. Please wait before trying again.';
        case 'weak password':
          return 'Password is too weak. Please choose a stronger password.';
        default:
          return error.message;
      }
    }
    
    if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    }
    
    // Handle network errors
    if (error.toString().contains('SocketException') || 
        error.toString().contains('TimeoutException')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    // Generic error fallback
    return 'An unexpected error occurred. Please try again.';
  }
  
  static String getNetworkErrorMessage() {
    return 'Unable to connect to the server. Please check your internet connection and try again.';
  }
  
  static String getGenericErrorMessage() {
    return 'Something went wrong. Please try again later.';
  }
}

