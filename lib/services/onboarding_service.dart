import 'package:shared_preferences/shared_preferences.dart';
import 'business_profile_service.dart';

class OnboardingService {
  static const String _businessProfileCompletedKey = 'business_profile_completed';
  static const String _isFirstTimeUserKey = 'is_first_time_user';
  
  static OnboardingService? _instance;
  
  OnboardingService._();
  
  static OnboardingService get instance {
    _instance ??= OnboardingService._();
    return _instance!;
  }

  // Check if business profile onboarding is completed
  Future<bool> isBusinessProfileCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool(_businessProfileCompletedKey) ?? false;
      
      // Double-check with actual business profile validation
      if (isCompleted) {
        final businessProfileService = BusinessProfileService.instance;
        final isActuallyComplete = await businessProfileService.isBusinessProfileComplete();
        
        // If marked as complete but validation fails, reset the flag
        if (!isActuallyComplete) {
          await markBusinessProfileIncomplete();
          return false;
        }
      }
      
      return isCompleted;
    } catch (e) {
      print('Error checking business profile completion: $e');
      return false;
    }
  }

  // Mark business profile as completed
  Future<bool> markBusinessProfileCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_businessProfileCompletedKey, true);
      return true;
    } catch (e) {
      print('Error marking business profile as completed: $e');
      return false;
    }
  }

  // Mark business profile as incomplete
  Future<bool> markBusinessProfileIncomplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_businessProfileCompletedKey, false);
      return true;
    } catch (e) {
      print('Error marking business profile as incomplete: $e');
      return false;
    }
  }

  // Check if user is first time user
  Future<bool> isFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isFirstTimeUserKey) ?? true;
    } catch (e) {
      print('Error checking first time user status: $e');
      return true;
    }
  }

  // Mark user as no longer first time
  Future<bool> markUserAsReturning() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstTimeUserKey, false);
      return true;
    } catch (e) {
      print('Error marking user as returning: $e');
      return false;
    }
  }

  // Check if user needs business profile onboarding
  Future<bool> needsBusinessProfileOnboarding() async {
    final isCompleted = await isBusinessProfileCompleted();
    return !isCompleted;
  }

  // Complete business profile onboarding
  Future<bool> completeBusinessProfileOnboarding() async {
    try {
      // Verify that business profile is actually complete
      final businessProfileService = BusinessProfileService.instance;
      final isComplete = await businessProfileService.isBusinessProfileComplete();
      
      if (!isComplete) {
        return false;
      }
      
      // Mark as completed and user as returning
      await markBusinessProfileCompleted();
      await markUserAsReturning();
      
      return true;
    } catch (e) {
      print('Error completing business profile onboarding: $e');
      return false;
    }
  }

  // Reset onboarding status (for testing purposes)
  Future<bool> resetOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_businessProfileCompletedKey);
      await prefs.remove(_isFirstTimeUserKey);
      return true;
    } catch (e) {
      print('Error resetting onboarding status: $e');
      return false;
    }
  }
}
