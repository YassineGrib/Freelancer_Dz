import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FreeLancer Mobile'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Projects tab title
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// Clients tab title
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// Payments tab title
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// Invoices tab title
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// Expenses tab title
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// Menu tab title
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// New project action
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// Add client action
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// Record payment action
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// Create invoice action
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// Recent activities section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// Upcoming deadlines section title
  ///
  /// In en, this message translates to:
  /// **'Upcoming Deadlines'**
  String get upcomingDeadlines;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Message when no recent activities
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get noRecentActivities;

  /// Message when no upcoming deadlines
  ///
  /// In en, this message translates to:
  /// **'No upcoming deadlines'**
  String get noUpcomingDeadlines;

  /// Total revenue label
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// Active projects label
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// Pending payments label
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// This month label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Currency setting label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Notifications setting label
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Security setting label
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// About setting label
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Add button text
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Search placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Filter button text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort button text
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Profile settings menu item
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// Profile settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// Change password menu item
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Change password subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateAccountPassword;

  /// Email settings menu item
  ///
  /// In en, this message translates to:
  /// **'Email Settings'**
  String get emailSettings;

  /// Email settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage email preferences'**
  String get manageEmailPreferences;

  /// Application section title
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// Appearance menu item
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Appearance subtitle
  ///
  /// In en, this message translates to:
  /// **'Theme and display settings'**
  String get themeDisplaySettings;

  /// Data storage menu item
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorage;

  /// Data storage subtitle
  ///
  /// In en, this message translates to:
  /// **'Backup and sync settings'**
  String get backupSyncSettings;

  /// Business section title
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// Business profile menu item
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile;

  /// Business profile subtitle
  ///
  /// In en, this message translates to:
  /// **'Company information and branding'**
  String get companyInfoBranding;

  /// Invoice settings menu item
  ///
  /// In en, this message translates to:
  /// **'Invoice Settings'**
  String get invoiceSettings;

  /// Invoice settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Default invoice templates and settings'**
  String get defaultInvoiceTemplates;

  /// Tax settings menu item
  ///
  /// In en, this message translates to:
  /// **'Tax Settings'**
  String get taxSettings;

  /// Tax settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Tax rates and calculation preferences'**
  String get taxRatesCalculation;

  /// Currency rates menu item
  ///
  /// In en, this message translates to:
  /// **'Currency & Rates'**
  String get currencyRates;

  /// Support section title
  ///
  /// In en, this message translates to:
  /// **'Support & Information'**
  String get supportInformation;

  /// Help support menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Help support subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get getHelpContactSupport;

  /// Terms privacy menu item
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// Terms privacy subtitle
  ///
  /// In en, this message translates to:
  /// **'Terms of service and privacy policy'**
  String get termsServicePrivacyPolicy;

  /// About subtitle
  ///
  /// In en, this message translates to:
  /// **'App version and information'**
  String get appVersionInfo;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// Default user email
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get userEmail;

  /// Account type label
  ///
  /// In en, this message translates to:
  /// **'Freelancer Account'**
  String get freelancerAccount;

  /// Sign out button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Auto sync setting
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get autoSync;

  /// Auto sync description
  ///
  /// In en, this message translates to:
  /// **'Automatically sync data when online'**
  String get autoSyncDescription;

  /// Database section title
  ///
  /// In en, this message translates to:
  /// **'Database Backup & Restore'**
  String get databaseBackupRestore;

  /// Backup button
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// Restore button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings Export & Import'**
  String get settingsExportImport;

  /// Export button
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Import button
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Reset database button
  ///
  /// In en, this message translates to:
  /// **'Reset Database'**
  String get resetDatabase;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Default currency dialog title
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// Import settings dialog title
  ///
  /// In en, this message translates to:
  /// **'Import Settings'**
  String get importSettings;

  /// Settings import placeholder
  ///
  /// In en, this message translates to:
  /// **'Paste settings JSON here'**
  String get pasteSettingsJson;

  /// Restore database dialog title
  ///
  /// In en, this message translates to:
  /// **'Restore Database'**
  String get restoreDatabase;

  /// Restore cancelled message
  ///
  /// In en, this message translates to:
  /// **'Restore cancelled'**
  String get restoreCancelled;

  /// Login screen welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Register screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Join our community'**
  String get joinOurCommunity;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Full name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Confirm password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordPlaceholder;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Login screen sign up prompt
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Register screen login prompt
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning title
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Info title
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Yes button
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Apply button
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Clear button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Reset button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Send button
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Create button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Select button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Choose button
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// Browse button
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// Upload button
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Download button
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy button
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Paste button
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Cut button
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// Undo button
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Redo button
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// Empty activities message
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get noActivitiesYet;

  /// No filtered activities message
  ///
  /// In en, this message translates to:
  /// **'No activities match your filters'**
  String get noActivitiesMatchFilters;

  /// Filter adjustment suggestion
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingFilters;

  /// Activities explanation message
  ///
  /// In en, this message translates to:
  /// **'Activities will appear here as you use the app'**
  String get activitiesWillAppear;

  /// No deadlines message
  ///
  /// In en, this message translates to:
  /// **'No deadlines found'**
  String get noDeadlinesFound;

  /// Deadlines explanation message
  ///
  /// In en, this message translates to:
  /// **'Add projects and invoices to track deadlines'**
  String get addProjectsInvoices;

  /// Demo badge text
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// Demo deadlines explanation
  ///
  /// In en, this message translates to:
  /// **'Showing demo deadlines. Add real projects and invoices to track actual deadlines.'**
  String get showingDemoDeadlines;

  /// Reports screen title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Filters section title
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Time period filter label
  ///
  /// In en, this message translates to:
  /// **'Time Period'**
  String get timePeriod;

  /// Advanced filters section title
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get advancedFilters;

  /// Client filter label
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// Project filter label
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// Status filter label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Amount filter label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Minimum amount placeholder
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// Maximum amount placeholder
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// All filter option
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// In progress status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Not started status
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Custom date range label
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get customDateRange;

  /// Date range picker placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// Mark as paid menu option
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// Create payment button
  ///
  /// In en, this message translates to:
  /// **'Create Payment'**
  String get createPayment;

  /// Payment details label
  ///
  /// In en, this message translates to:
  /// **'Payment Details:'**
  String get paymentDetails;

  /// Creating payment loading message
  ///
  /// In en, this message translates to:
  /// **'Creating payment...'**
  String get creatingPayment;

  /// Payment creation success message
  ///
  /// In en, this message translates to:
  /// **'Payment created successfully!'**
  String get paymentCreatedSuccessfully;

  /// Payment creation error message
  ///
  /// In en, this message translates to:
  /// **'Error creating payment'**
  String get errorCreatingPayment;

  /// Cannot mark paid error message
  ///
  /// In en, this message translates to:
  /// **'Cannot mark project as paid: Missing project or client information'**
  String get cannotMarkPaid;

  /// Project fully paid message
  ///
  /// In en, this message translates to:
  /// **'Project is already fully paid'**
  String get projectFullyPaid;

  /// Payment confirmation question
  ///
  /// In en, this message translates to:
  /// **'Create a payment for the remaining amount?'**
  String get createPaymentForRemaining;

  /// Language change success message prefix
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get languageChanged;

  /// Dashboard loading error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoadDashboard;

  /// Dashboard loading error prefix
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard'**
  String get errorLoadingDashboard;

  /// Dashboard refresh error prefix
  ///
  /// In en, this message translates to:
  /// **'Error refreshing dashboard'**
  String get errorRefreshingDashboard;

  /// Demo data explanation for activities
  ///
  /// In en, this message translates to:
  /// **'Showing demo data. Start adding projects, payments, and invoices to see real activities.'**
  String get showingDemoData;

  /// This week time period
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Last week time period
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// Last 30 days time period
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// Last 90 days time period
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last90Days;

  /// This year time period
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// Last year time period
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// Total earnings label
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// Completed projects label
  ///
  /// In en, this message translates to:
  /// **'Completed Projects'**
  String get completedProjects;

  /// Unpaid projects label
  ///
  /// In en, this message translates to:
  /// **'Unpaid Projects'**
  String get unpaidProjects;

  /// Section or title showing performance data for the month
  ///
  /// In en, this message translates to:
  /// **'Monthly Performance'**
  String get monthlyPerformance;

  /// Section or title showing performance data for the year
  ///
  /// In en, this message translates to:
  /// **'Yearly Performance'**
  String get yearlyPerformance;

  /// Label showing the last time data was updated
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// Button or action to refresh the dashboard data
  ///
  /// In en, this message translates to:
  /// **'Refresh Dashboard'**
  String get refreshDashboard;

  /// Label showing financial profit
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// Label showing total income before expenses
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// Status label for active items or projects
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Label showing income after expenses
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get netIncome;

  /// Indicates something just happened
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Indicates how many minutes ago
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(Object minutes);

  /// Indicates how many hours ago
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(Object hours);

  /// Indicates how many days ago
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(Object days);

  /// Currency format in millions
  ///
  /// In en, this message translates to:
  /// **'{amount}M DA'**
  String currencyMillion(Object amount);

  /// Currency format in thousands
  ///
  /// In en, this message translates to:
  /// **'{amount}K DA'**
  String currencyThousand(Object amount);

  /// Currency format for small values
  ///
  /// In en, this message translates to:
  /// **'{amount} DA'**
  String currencyPlain(Object amount);

  /// Alert label for overdue payments
  ///
  /// In en, this message translates to:
  /// **'Overdue {days} days'**
  String overduePayment(Object days);

  /// Alert label for upcoming payments
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String dueInDays(Object days);

  /// No description provided for @taxManagement.
  ///
  /// In en, this message translates to:
  /// **'Tax Management'**
  String get taxManagement;

  /// No description provided for @taxYear.
  ///
  /// In en, this message translates to:
  /// **'Tax Year:'**
  String get taxYear;

  /// No description provided for @taxStatistics.
  ///
  /// In en, this message translates to:
  /// **'Tax Statistics'**
  String get taxStatistics;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @calculateTaxesForYear.
  ///
  /// In en, this message translates to:
  /// **'Calculate your taxes for this year'**
  String get calculateTaxesForYear;

  /// No description provided for @calculateTaxes.
  ///
  /// In en, this message translates to:
  /// **'Calculate Taxes'**
  String get calculateTaxes;

  /// Section title for tax payments of a specific year
  ///
  /// In en, this message translates to:
  /// **'Tax Payments {year}'**
  String taxPaymentsForYear(int year);

  /// Message when no taxes calculated for a year
  ///
  /// In en, this message translates to:
  /// **'No taxes calculated for {year}'**
  String noTaxesCalculated(int year);

  /// Formatted due date
  ///
  /// In en, this message translates to:
  /// **'Due: {day}/{month}/{year}'**
  String dueDate(Object day, Object month, Object year);

  /// Currency amount followed by currency symbol
  ///
  /// In en, this message translates to:
  /// **'{amount} DA'**
  String currencyWithSymbol(Object amount);

  /// Label for a payment due today
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// Label for a payment due tomorrow
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// Indicates how many days a payment is overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days, plural, =1{# day} other{# days}}'**
  String overdueBy(int days);

  /// Indicates how many days until the payment is due
  ///
  /// In en, this message translates to:
  /// **'Due in {days, plural, =0{today} =1{{days} day} other{{days} days}}'**
  String dueIn(int days);

  /// No description provided for @businessManagement.
  ///
  /// In en, this message translates to:
  /// **'إدارة الأعمال'**
  String get businessManagement;

  /// No description provided for @manageAllBusiness.
  ///
  /// In en, this message translates to:
  /// **'إدارة جميع جوانب عملك الحر'**
  String get manageAllBusiness;

  /// No description provided for @projectManagement.
  ///
  /// In en, this message translates to:
  /// **'إدارة المشاريع'**
  String get projectManagement;

  /// No description provided for @manageProjectsTrackProgress.
  ///
  /// In en, this message translates to:
  /// **'إدارة مشاريعك وتتبع التقدم'**
  String get manageProjectsTrackProgress;

  /// No description provided for @viewProjects.
  ///
  /// In en, this message translates to:
  /// **'عرض المشاريع'**
  String get viewProjects;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'إضافة مشروع'**
  String get addProject;

  /// No description provided for @manageClients.
  ///
  /// In en, this message translates to:
  /// **'إدارة العملاء'**
  String get manageClients;

  /// No description provided for @trackPayments.
  ///
  /// In en, this message translates to:
  /// **'تتبع المدفوعات'**
  String get trackPayments;

  /// No description provided for @manageExpenses.
  ///
  /// In en, this message translates to:
  /// **'إدارة النفقات'**
  String get manageExpenses;

  /// No description provided for @createInvoices.
  ///
  /// In en, this message translates to:
  /// **'إنشاء الفواتير'**
  String get createInvoices;

  /// No description provided for @taxes.
  ///
  /// In en, this message translates to:
  /// **'الضرائب'**
  String get taxes;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'التقويم'**
  String get calendar;

  /// No description provided for @viewEvents.
  ///
  /// In en, this message translates to:
  /// **'عرض الأحداث'**
  String get viewEvents;

  /// No description provided for @businessAnalytics.
  ///
  /// In en, this message translates to:
  /// **'تحليلات الأعمال'**
  String get businessAnalytics;

  /// Section title for displaying all deadlines
  ///
  /// In en, this message translates to:
  /// **'All Deadlines'**
  String get allDeadlines;

  /// Message when no deadlines found for a given filter
  ///
  /// In en, this message translates to:
  /// **'No {filter} deadlines found'**
  String noDeadlinesWithFilter(String filter);

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @framework.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get framework;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'Freelancer Mobile Team'**
  String get developerName;

  /// No description provided for @developerDescription.
  ///
  /// In en, this message translates to:
  /// **'Specialized in mobile app development'**
  String get developerDescription;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Designed specifically for Algerian freelancers to manage their business efficiently with local tax compliance and Arabic language support.'**
  String get appDescription;

  /// No description provided for @keyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeatures;

  /// No description provided for @clientManagement.
  ///
  /// In en, this message translates to:
  /// **'Client Management'**
  String get clientManagement;

  /// No description provided for @paymentTracking.
  ///
  /// In en, this message translates to:
  /// **'Payment Tracking'**
  String get paymentTracking;

  /// No description provided for @expenseManagement.
  ///
  /// In en, this message translates to:
  /// **'Expense Management'**
  String get expenseManagement;

  /// No description provided for @invoiceGeneration.
  ///
  /// In en, this message translates to:
  /// **'Invoice Generation'**
  String get invoiceGeneration;

  /// No description provided for @algerianTaxManagement.
  ///
  /// In en, this message translates to:
  /// **'Algerian Tax Management'**
  String get algerianTaxManagement;

  /// No description provided for @calendarEvents.
  ///
  /// In en, this message translates to:
  /// **'Calendar & Events'**
  String get calendarEvents;

  /// No description provided for @businessReports.
  ///
  /// In en, this message translates to:
  /// **'Business Reports'**
  String get businessReports;

  /// No description provided for @smartNotifications.
  ///
  /// In en, this message translates to:
  /// **'Smart Notifications'**
  String get smartNotifications;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get termsOfServiceDescription;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyDescription.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get privacyPolicyDescription;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @openSourceLicensesDescription.
  ///
  /// In en, this message translates to:
  /// **'Third-party libraries and licenses'**
  String get openSourceLicensesDescription;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get contactSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get reportBug;

  /// No description provided for @rateUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Rate the app on Play Store'**
  String get rateUsDescription;

  /// No description provided for @reportBugDescription.
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app'**
  String get reportBugDescription;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
