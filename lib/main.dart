import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/localization_service.dart';
import 'services/locale_notifier.dart';
import 'services/auth_service.dart';
import 'utils/colors.dart';
import 'utils/constants.dart';

import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local authentication service
  await AuthService.initialize();

  // Initialize locale notifier
  await LocaleNotifier().initialize();

  runApp(const FreeLancerApp());
}

class FreeLancerApp extends StatefulWidget {
  const FreeLancerApp({super.key});

  @override
  State<FreeLancerApp> createState() => _FreeLancerAppState();
}

class _FreeLancerAppState extends State<FreeLancerApp> {
  final LocaleNotifier _localeNotifier = LocaleNotifier();

  @override
  void initState() {
    super.initState();
    // Listen to locale changes
    _localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when locale changes
      });
    }
  }

  void _setLocale(Locale locale) async {
    // Use the locale notifier to change locale
    await _localeNotifier.changeLocale(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Localization support
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationService.instance.getSupportedLocales(),
      locale: _localeNotifier.getLocale(),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      home: LocalizationProvider(
        setLocale: _setLocale,
        child: const SplashScreen(),
      ),
    );
  }
}

// Provider widget to pass locale change function down the widget tree
class LocalizationProvider extends InheritedWidget {
  final Function(Locale) setLocale;

  const LocalizationProvider({
    super.key,
    required this.setLocale,
    required super.child,
  });

  static LocalizationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocalizationProvider>();
  }

  @override
  bool updateShouldNotify(LocalizationProvider oldWidget) {
    return setLocale != oldWidget.setLocale;
  }
}
