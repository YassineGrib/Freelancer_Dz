import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _settingsKey = 'app_settings';
  AppSettings _settings = const AppSettings();
  bool _isInitialized = false;

  AppSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  // Initialize settings from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(settingsMap);
      }

      _isInitialized = true;
      notifyListeners();
      debugPrint('⚙️ Settings initialized: ${_settings.language.displayName}');
    } catch (e) {
      debugPrint('⚙️ Error initializing settings: $e');
      _settings = const AppSettings();
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save settings to storage
  Future<bool> saveSettings(AppSettings newSettings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(newSettings.toJson());

      await prefs.setString(_settingsKey, settingsJson);
      _settings = newSettings;
      notifyListeners();

      debugPrint('⚙️ Settings saved successfully');
      return true;
    } catch (e) {
      debugPrint('⚙️ Error saving settings: $e');
      return false;
    }
  }

  // Update theme mode
  Future<bool> updateThemeMode(ThemeMode themeMode) async {
    final newSettings = _settings.copyWith(themeMode: themeMode);
    return await saveSettings(newSettings);
  }

  // Update language
  Future<bool> updateLanguage(Language language) async {
    final newSettings = _settings.copyWith(language: language);
    return await saveSettings(newSettings);
  }

  // Update default currency
  Future<bool> updateDefaultCurrency(Currency currency) async {
    final newSettings = _settings.copyWith(defaultCurrency: currency);
    return await saveSettings(newSettings);
  }

  // Update date format
  Future<bool> updateDateFormat(DateFormat dateFormat) async {
    final newSettings = _settings.copyWith(dateFormat: dateFormat);
    return await saveSettings(newSettings);
  }

  // Update time format
  Future<bool> updateTimeFormat(TimeFormat timeFormat) async {
    final newSettings = _settings.copyWith(timeFormat: timeFormat);
    return await saveSettings(newSettings);
  }

  // Update privacy settings
  Future<bool> updatePrivacySettings(PrivacySettings privacy) async {
    final newSettings = _settings.copyWith(privacy: privacy);
    return await saveSettings(newSettings);
  }

  // Update auto sync
  Future<bool> updateAutoSync(bool autoSync) async {
    final newSettings = _settings.copyWith(autoSync: autoSync);
    return await saveSettings(newSettings);
  }

  // Update sync interval
  Future<bool> updateSyncInterval(int minutes) async {
    final newSettings = _settings.copyWith(syncIntervalMinutes: minutes);
    return await saveSettings(newSettings);
  }

  // Update offline mode
  Future<bool> updateOfflineMode(bool offlineMode) async {
    final newSettings = _settings.copyWith(offlineMode: offlineMode);
    return await saveSettings(newSettings);
  }

  // Update show tutorials
  Future<bool> updateShowTutorials(bool showTutorials) async {
    final newSettings = _settings.copyWith(showTutorials: showTutorials);
    return await saveSettings(newSettings);
  }

  // Update compact view
  Future<bool> updateCompactView(bool compactView) async {
    final newSettings = _settings.copyWith(compactView: compactView);
    return await saveSettings(newSettings);
  }

  // Reset to default settings
  Future<bool> resetToDefaults() async {
    return await saveSettings(const AppSettings());
  }

  // Export settings as JSON string
  String exportSettings() {
    return jsonEncode(_settings.toJson());
  }

  // Import settings from JSON string
  Future<bool> importSettings(String settingsJson) async {
    try {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      final newSettings = AppSettings.fromJson(settingsMap);
      return await saveSettings(newSettings);
    } catch (e) {
      debugPrint('⚙️ Error importing settings: $e');
      return false;
    }
  }

  // Get formatted date string based on settings
  String formatDate(DateTime date) {
    switch (_settings.dateFormat) {
      case DateFormat.ddMmYyyy:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case DateFormat.mmDdYyyy:
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case DateFormat.yyyyMmDd:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  // Get formatted time string based on settings
  String formatTime(DateTime time) {
    switch (_settings.timeFormat) {
      case TimeFormat.format12:
        final hour =
            time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final period = time.hour >= 12 ? 'PM' : 'AM';
        return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
      case TimeFormat.format24:
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  // Get currency symbol
  String getCurrencySymbol([Currency? currency]) {
    return (currency ?? _settings.defaultCurrency).symbol;
  }

  // Get currency code
  String getCurrencyCode([Currency? currency]) {
    return (currency ?? _settings.defaultCurrency).code;
  }

  // Check if biometric auth is enabled
  bool isBiometricAuthEnabled() {
    return _settings.privacy.biometricAuth;
  }

  // Check if auto lock is enabled
  bool isAutoLockEnabled() {
    return _settings.privacy.autoLock;
  }

  // Get auto lock minutes
  int getAutoLockMinutes() {
    return _settings.privacy.autoLockMinutes;
  }
}
