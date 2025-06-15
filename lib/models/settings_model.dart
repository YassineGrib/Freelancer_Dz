enum ThemeMode {
  light('Light'),
  dark('Dark'),
  system('System');

  const ThemeMode(this.displayName);
  final String displayName;
}

enum Language {
  english('English', 'en'),
  arabic('العربية', 'ar'),
  french('Français', 'fr');

  const Language(this.displayName, this.code);
  final String displayName;
  final String code;
}

enum Currency {
  dzd('Algerian Dinar', 'DZD', 'DA'),
  usd('US Dollar', 'USD', '\$'),
  eur('Euro', 'EUR', '€');

  const Currency(this.displayName, this.code, this.symbol);
  final String displayName;
  final String code;
  final String symbol;
}

enum DateFormat {
  ddMmYyyy('DD/MM/YYYY'),
  mmDdYyyy('MM/DD/YYYY'),
  yyyyMmDd('YYYY-MM-DD');

  const DateFormat(this.displayName);
  final String displayName;
}

enum TimeFormat {
  format12('12 Hour'),
  format24('24 Hour');

  const TimeFormat(this.displayName);
  final String displayName;
}

class PrivacySettings {
  final bool dataCollection;
  final bool analytics;
  final bool crashReports;
  final bool locationTracking;
  final bool biometricAuth;
  final bool autoLock;
  final int autoLockMinutes;

  const PrivacySettings({
    this.dataCollection = false,
    this.analytics = false,
    this.crashReports = true,
    this.locationTracking = false,
    this.biometricAuth = false,
    this.autoLock = false,
    this.autoLockMinutes = 5,
  });

  PrivacySettings copyWith({
    bool? dataCollection,
    bool? analytics,
    bool? crashReports,
    bool? locationTracking,
    bool? biometricAuth,
    bool? autoLock,
    int? autoLockMinutes,
  }) {
    return PrivacySettings(
      dataCollection: dataCollection ?? this.dataCollection,
      analytics: analytics ?? this.analytics,
      crashReports: crashReports ?? this.crashReports,
      locationTracking: locationTracking ?? this.locationTracking,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      autoLock: autoLock ?? this.autoLock,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data_collection': dataCollection,
      'analytics': analytics,
      'crash_reports': crashReports,
      'location_tracking': locationTracking,
      'biometric_auth': biometricAuth,
      'auto_lock': autoLock,
      'auto_lock_minutes': autoLockMinutes,
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      dataCollection: json['data_collection'] ?? false,
      analytics: json['analytics'] ?? false,
      crashReports: json['crash_reports'] ?? true,
      locationTracking: json['location_tracking'] ?? false,
      biometricAuth: json['biometric_auth'] ?? false,
      autoLock: json['auto_lock'] ?? false,
      autoLockMinutes: json['auto_lock_minutes'] ?? 5,
    );
  }
}

class AppSettings {
  final ThemeMode themeMode;
  final Language language;
  final Currency defaultCurrency;
  final DateFormat dateFormat;
  final TimeFormat timeFormat;

  final PrivacySettings privacy;
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool offlineMode;
  final bool showTutorials;
  final bool compactView;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = Language.english,
    this.defaultCurrency = Currency.dzd,
    this.dateFormat = DateFormat.ddMmYyyy,
    this.timeFormat = TimeFormat.format24,
    this.privacy = const PrivacySettings(),
    this.autoSync = true,
    this.syncIntervalMinutes = 15,
    this.offlineMode = false,
    this.showTutorials = true,
    this.compactView = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Language? language,
    Currency? defaultCurrency,
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    PrivacySettings? privacy,
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? offlineMode,
    bool? showTutorials,
    bool? compactView,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      privacy: privacy ?? this.privacy,
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      offlineMode: offlineMode ?? this.offlineMode,
      showTutorials: showTutorials ?? this.showTutorials,
      compactView: compactView ?? this.compactView,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode.name,
      'language': language.code,
      'default_currency': defaultCurrency.code,
      'date_format': dateFormat.name,
      'time_format': timeFormat.name,
      'privacy': privacy.toJson(),
      'auto_sync': autoSync,
      'sync_interval_minutes': syncIntervalMinutes,
      'offline_mode': offlineMode,
      'show_tutorials': showTutorials,
      'compact_view': compactView,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['theme_mode'],
        orElse: () => ThemeMode.system,
      ),
      language: Language.values.firstWhere(
        (lang) => lang.code == json['language'],
        orElse: () => Language.english,
      ),
      defaultCurrency: Currency.values.firstWhere(
        (curr) => curr.code == json['default_currency'],
        orElse: () => Currency.dzd,
      ),
      dateFormat: DateFormat.values.firstWhere(
        (format) => format.name == json['date_format'],
        orElse: () => DateFormat.ddMmYyyy,
      ),
      timeFormat: TimeFormat.values.firstWhere(
        (format) => format.name == json['time_format'],
        orElse: () => TimeFormat.format24,
      ),
      privacy: json['privacy'] != null
          ? PrivacySettings.fromJson(json['privacy'])
          : const PrivacySettings(),
      autoSync: json['auto_sync'] ?? true,
      syncIntervalMinutes: json['sync_interval_minutes'] ?? 15,
      offlineMode: json['offline_mode'] ?? false,
      showTutorials: json['show_tutorials'] ?? true,
      compactView: json['compact_view'] ?? false,
    );
  }
}
