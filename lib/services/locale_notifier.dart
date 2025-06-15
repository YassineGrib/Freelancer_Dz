import 'package:flutter/material.dart';
import 'localization_service.dart';

/// Global locale change notifier
class LocaleNotifier extends ChangeNotifier {
  static final LocaleNotifier _instance = LocaleNotifier._internal();
  factory LocaleNotifier() => _instance;
  LocaleNotifier._internal();

  Locale? _currentLocale;
  
  Locale? get currentLocale => _currentLocale;

  /// Initialize the locale from saved preferences
  Future<void> initialize() async {
    final currentLanguage = await LocalizationService.instance.getCurrentLanguage();
    _currentLocale = Locale(currentLanguage.code);
    notifyListeners();
  }

  /// Change the app locale and notify all listeners
  Future<void> changeLocale(String languageCode) async {
    final language = LocalizationService.instance.getLanguageByCode(languageCode);
    if (language != null) {
      // Save the language preference
      await LocalizationService.instance.setLanguage(language);
      
      // Update the current locale
      _currentLocale = Locale(languageCode);
      
      // Notify all listeners to rebuild
      notifyListeners();
    }
  }

  /// Get the current locale or default to English
  Locale getLocale() {
    return _currentLocale ?? const Locale('en');
  }
}
