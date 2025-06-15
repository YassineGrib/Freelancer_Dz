import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app localization and language preferences
class LocalizationService {
  static const String _languageKey = 'selected_language';
  static LocalizationService? _instance;
  
  LocalizationService._();
  
  static LocalizationService get instance {
    _instance ??= LocalizationService._();
    return _instance!;
  }
  
  /// Supported languages in the app
  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      isRTL: false,
    ),
    SupportedLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      isRTL: false,
    ),
    SupportedLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
  ];
  
  /// Get the current selected language
  Future<SupportedLanguage> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode != null) {
      return supportedLanguages.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => supportedLanguages.first,
      );
    }
    
    // If no language is saved, try to use system locale
    final systemLocale = PlatformDispatcher.instance.locale;
    final systemLanguage = supportedLanguages.where(
      (lang) => lang.code == systemLocale.languageCode,
    ).firstOrNull;
    
    return systemLanguage ?? supportedLanguages.first;
  }
  
  /// Set the current language
  Future<void> setLanguage(SupportedLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);
  }
  
  /// Get language by code
  SupportedLanguage? getLanguageByCode(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if a language is supported
  bool isLanguageSupported(String code) {
    return supportedLanguages.any((lang) => lang.code == code);
  }
  
  /// Get the locale for a language code
  Locale getLocaleForLanguage(String code) {
    return Locale(code);
  }
  
  /// Get all supported locales
  List<Locale> getSupportedLocales() {
    return supportedLanguages.map((lang) => Locale(lang.code)).toList();
  }
  
  /// Check if the current language is RTL
  bool isCurrentLanguageRTL(String currentLanguageCode) {
    final language = getLanguageByCode(currentLanguageCode);
    return language?.isRTL ?? false;
  }
}

/// Model for supported languages
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;
  
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isRTL,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportedLanguage && other.code == code;
  }
  
  @override
  int get hashCode => code.hashCode;
  
  @override
  String toString() => '$flag $nativeName';
  
  /// Get display name for the language
  String get displayName => '$flag $nativeName';
}

