import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/business_profile_model.dart';

class BusinessProfileService {
  static const String _businessProfileKey = 'business_profile';
  static BusinessProfileService? _instance;

  BusinessProfileService._();

  static BusinessProfileService get instance {
    _instance ??= BusinessProfileService._();
    return _instance!;
  }

  // Get business profile
  Future<BusinessProfileModel> getBusinessProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_businessProfileKey);

      if (profileJson != null) {
        final profileData = jsonDecode(profileJson);
        return BusinessProfileModel.fromJson(profileData);
      }

      return BusinessProfileModel.defaultProfile;
    } catch (e) {
      print('Error loading business profile: $e');
      return BusinessProfileModel.defaultProfile;
    }
  }

  // Save business profile
  Future<bool> saveBusinessProfile(BusinessProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedProfile = profile.copyWith(
        updatedAt: DateTime.now(),
      );

      final profileJson = jsonEncode(updatedProfile.toJson());
      await prefs.setString(_businessProfileKey, profileJson);

      return true;
    } catch (e) {
      print('Error saving business profile: $e');
      return false;
    }
  }

  // Update company logo
  Future<String?> updateCompanyLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Get app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final logoDir = Directory(path.join(appDir.path, 'logos'));

        // Create logos directory if it doesn't exist
        if (!await logoDir.exists()) {
          await logoDir.create(recursive: true);
        }

        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(pickedFile.path);
        final fileName = 'company_logo_$timestamp$extension';
        final logoPath = path.join(logoDir.path, fileName);

        // Copy file to app directory
        final logoFile = File(pickedFile.path);
        await logoFile.copy(logoPath);

        return logoPath;
      }

      return null;
    } catch (e) {
      print('Error updating company logo: $e');
      return null;
    }
  }

  // Delete company logo
  Future<bool> deleteCompanyLogo(String logoPath) async {
    try {
      final logoFile = File(logoPath);
      if (await logoFile.exists()) {
        await logoFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting company logo: $e');
      return false;
    }
  }

  // Validate business profile
  Map<String, String> validateBusinessProfile(BusinessProfileModel profile) {
    final errors = <String, String>{};

    if (profile.companyName.trim().isEmpty) {
      errors['companyName'] = 'Company name is required';
    }

    if (profile.email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else if (!_isValidEmail(profile.email)) {
      errors['email'] = 'Please enter a valid email address';
    }

    if (profile.phone.trim().isEmpty) {
      errors['phone'] = 'Phone number is required';
    }

    if (profile.address.trim().isEmpty) {
      errors['address'] = 'Address is required';
    }

    if (profile.city.trim().isEmpty) {
      errors['city'] = 'City is required';
    }

    if (profile.country.trim().isEmpty) {
      errors['country'] = 'Country is required';
    }

    // Additional required fields based on UI
    if (profile.state.trim().isEmpty) {
      errors['state'] = 'State is required';
    }

    if (profile.postalCode.trim().isEmpty) {
      errors['postalCode'] = 'Postal code is required';
    }

    if (profile.taxId == null || profile.taxId!.trim().isEmpty) {
      errors['taxId'] = 'NiF ID is required';
    }

    if (profile.registrationNumber == null ||
        profile.registrationNumber!.trim().isEmpty) {
      errors['registrationNumber'] = 'Card Number is required';
    }

    return errors;
  }

  // Check if business profile is complete
  Future<bool> isBusinessProfileComplete() async {
    final profile = await getBusinessProfile();
    final errors = validateBusinessProfile(profile);
    return errors.isEmpty;
  }

  // Get business profile completion percentage
  Future<double> getProfileCompletionPercentage() async {
    final profile = await getBusinessProfile();
    int completedFields = 0;
    int totalFields = 10; // Essential fields count

    if (profile.companyName.isNotEmpty) completedFields++;
    if (profile.email.isNotEmpty) completedFields++;
    if (profile.phone.isNotEmpty) completedFields++;
    if (profile.address.isNotEmpty) completedFields++;
    if (profile.city.isNotEmpty) completedFields++;
    if (profile.country.isNotEmpty) completedFields++;
    if (profile.companyLogo != null) completedFields++;
    if (profile.website != null && profile.website!.isNotEmpty)
      completedFields++;
    if (profile.taxId != null && profile.taxId!.isNotEmpty) completedFields++;
    if (profile.bankAccountNumber != null &&
        profile.bankAccountNumber!.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // Export business profile
  Future<Map<String, dynamic>> exportBusinessProfile() async {
    final profile = await getBusinessProfile();
    return profile.toJson();
  }

  // Import business profile
  Future<bool> importBusinessProfile(Map<String, dynamic> profileData) async {
    try {
      final profile = BusinessProfileModel.fromJson(profileData);
      return await saveBusinessProfile(profile);
    } catch (e) {
      print('Error importing business profile: $e');
      return false;
    }
  }

  // Reset business profile
  Future<bool> resetBusinessProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_businessProfileKey);
      return true;
    } catch (e) {
      print('Error resetting business profile: $e');
      return false;
    }
  }

  // Helper method to validate email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get countries list
  List<String> getCountriesList() {
    return [
      'Algeria',
      'Morocco',
      'Tunisia',
      'Egypt',
      'Libya',
      'Sudan',
      'France',
      'Germany',
      'United Kingdom',
      'United States',
      'Canada',
      'Australia',
      'Other',
    ];
  }

  // Get business types
  List<BusinessType> getBusinessTypes() {
    return BusinessType.values;
  }
}
