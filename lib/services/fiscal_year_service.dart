import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fiscal_year_model.dart';
// TODO: Import actual models and services when available
// import '../models/client_model.dart';
// import '../models/project_model.dart';
// import '../models/payment_model.dart';
// import '../models/invoice_model.dart';
// import 'client_service.dart';
// import 'project_service.dart';
// import 'payment_service.dart';
// import 'invoice_service.dart';

class FiscalYearService {
  static const String _fiscalYearsKey = 'fiscal_years';
  static const String _currentFiscalYearKey = 'current_fiscal_year';
  static const String _archivedDataKey = 'archived_data';

  static FiscalYearService? _instance;
  static FiscalYearService get instance => _instance ??= FiscalYearService._();

  FiscalYearService._();

  final _fiscalYearController = StreamController<FiscalYear>.broadcast();
  Stream<FiscalYear> get fiscalYearStream => _fiscalYearController.stream;

  List<FiscalYear> _fiscalYears = [];
  FiscalYear? _currentFiscalYear;

  // Initialize service
  Future<void> initialize() async {
    await _loadFiscalYears();
    await _ensureCurrentFiscalYear();
    _startYearEndMonitoring();
  }

  // Load fiscal years from storage
  Future<void> _loadFiscalYears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fiscalYearsJson = prefs.getString(_fiscalYearsKey);

      if (fiscalYearsJson != null) {
        final List<dynamic> fiscalYearsList = json.decode(fiscalYearsJson);
        _fiscalYears = fiscalYearsList
            .map((json) => FiscalYear.fromJson(json))
            .toList();
      }

      final currentFiscalYearJson = prefs.getString(_currentFiscalYearKey);
      if (currentFiscalYearJson != null) {
        _currentFiscalYear = FiscalYear.fromJson(json.decode(currentFiscalYearJson));
      }
    } catch (e) {
      print('Error loading fiscal years: $e');
      _fiscalYears = [];
      _currentFiscalYear = null;
    }
  }

  // Save fiscal years to storage
  Future<void> _saveFiscalYears() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final fiscalYearsJson = json.encode(
        _fiscalYears.map((fy) => fy.toJson()).toList(),
      );
      await prefs.setString(_fiscalYearsKey, fiscalYearsJson);

      if (_currentFiscalYear != null) {
        final currentFiscalYearJson = json.encode(_currentFiscalYear!.toJson());
        await prefs.setString(_currentFiscalYearKey, currentFiscalYearJson);
      }
    } catch (e) {
      print('Error saving fiscal years: $e');
    }
  }

  // Ensure current fiscal year exists
  Future<void> _ensureCurrentFiscalYear() async {
    final currentYear = DateTime.now().year;

    // Check if current fiscal year exists
    final existingFiscalYear = _fiscalYears
        .where((fy) => fy.year == currentYear)
        .firstOrNull;

    if (existingFiscalYear == null) {
      // Create new fiscal year for current year
      await createFiscalYear(currentYear);
    } else {
      _currentFiscalYear = existingFiscalYear;
      _fiscalYearController.add(_currentFiscalYear!);
    }
  }

  // Create new fiscal year
  Future<FiscalYear> createFiscalYear(int year) async {
    final fiscalYear = FiscalYear.create(year);

    _fiscalYears.add(fiscalYear);

    if (year == DateTime.now().year) {
      _currentFiscalYear = fiscalYear;
      _fiscalYearController.add(_currentFiscalYear!);
    }

    await _saveFiscalYears();
    return fiscalYear;
  }

  // Get all fiscal years
  List<FiscalYear> getAllFiscalYears() {
    return List.unmodifiable(_fiscalYears);
  }

  // Get current fiscal year
  FiscalYear? getCurrentFiscalYear() {
    return _currentFiscalYear;
  }

  // Get fiscal year by year
  FiscalYear? getFiscalYearByYear(int year) {
    return _fiscalYears
        .where((fy) => fy.year == year)
        .firstOrNull;
  }

  // Get fiscal year by ID
  FiscalYear? getFiscalYearById(String id) {
    return _fiscalYears
        .where((fy) => fy.id == id)
        .firstOrNull;
  }

  // Update fiscal year
  Future<void> updateFiscalYear(FiscalYear fiscalYear) async {
    final index = _fiscalYears.indexWhere((fy) => fy.id == fiscalYear.id);
    if (index != -1) {
      _fiscalYears[index] = fiscalYear;

      if (fiscalYear.isCurrent) {
        _currentFiscalYear = fiscalYear;
        _fiscalYearController.add(_currentFiscalYear!);
      }

      await _saveFiscalYears();
    }
  }

  // Calculate fiscal year totals
  Future<FiscalYear> calculateFiscalYearTotals(int year) async {
    final fiscalYear = getFiscalYearByYear(year);
    if (fiscalYear == null) return createFiscalYear(year);

    try {
      // Get all data for the fiscal year
      // TODO: Replace with actual service calls when available
      final clients = <dynamic>[];
      final projects = <dynamic>[];
      final payments = <dynamic>[];
      final invoices = <dynamic>[];

      // Filter data by fiscal year (simplified for now)
      final fiscalYearClients = clients;
      final fiscalYearProjects = projects;
      final fiscalYearPayments = payments;
      final fiscalYearInvoices = invoices;

      // Calculate totals (simplified for now)
      const totalRevenue = 0.0;
      const totalExpenses = 0.0;
      const totalTaxes = 0.0;

      final updatedFiscalYear = fiscalYear.copyWith(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        totalTaxes: totalTaxes,
        totalClients: fiscalYearClients.length,
        totalProjects: fiscalYearProjects.length,
        totalInvoices: fiscalYearInvoices.length,
        totalPayments: fiscalYearPayments.length,
      );

      await updateFiscalYear(updatedFiscalYear);
      return updatedFiscalYear;
    } catch (e) {
      print('Error calculating fiscal year totals: $e');
      return fiscalYear;
    }
  }

  // Start year-end transition
  Future<YearEndTransition> startYearEndTransition(int fromYear, int toYear) async {
    final transition = YearEndTransition(
      id: 'transition_${fromYear}_to_${toYear}_${DateTime.now().millisecondsSinceEpoch}',
      fromYear: fromYear,
      toYear: toYear,
      status: YearEndTransitionStatus.pending,
      startedAt: DateTime.now(),
      steps: _createYearEndSteps(),
    );

    // Execute transition steps
    await _executeYearEndTransition(transition);

    return transition;
  }

  // Create year-end transition steps
  List<YearEndTransitionStep> _createYearEndSteps() {
    return [
      const YearEndTransitionStep(
        name: 'calculate_totals',
        description: 'Calculate fiscal year totals',
        status: YearEndStepStatus.pending,
      ),
      const YearEndTransitionStep(
        name: 'generate_summary',
        description: 'Generate fiscal year summary',
        status: YearEndStepStatus.pending,
      ),
      const YearEndTransitionStep(
        name: 'close_fiscal_year',
        description: 'Close current fiscal year',
        status: YearEndStepStatus.pending,
      ),
      const YearEndTransitionStep(
        name: 'create_new_year',
        description: 'Create new fiscal year',
        status: YearEndStepStatus.pending,
      ),
      const YearEndTransitionStep(
        name: 'archive_data',
        description: 'Archive previous year data',
        status: YearEndStepStatus.pending,
      ),
    ];
  }

  // Execute year-end transition
  Future<void> _executeYearEndTransition(YearEndTransition transition) async {
    try {
      // Step 1: Calculate totals
      await calculateFiscalYearTotals(transition.fromYear);

      // Step 2: Generate summary
      await generateFiscalYearSummary(transition.fromYear);

      // Step 3: Close fiscal year
      await closeFiscalYear(transition.fromYear);

      // Step 4: Create new fiscal year
      await createFiscalYear(transition.toYear);

      // Step 5: Archive data
      await archiveFiscalYearData(transition.fromYear);

    } catch (e) {
      print('Error executing year-end transition: $e');
    }
  }

  // Close fiscal year
  Future<void> closeFiscalYear(int year) async {
    final fiscalYear = getFiscalYearByYear(year);
    if (fiscalYear != null && fiscalYear.canBeClosed) {
      final closedFiscalYear = fiscalYear.copyWith(
        status: FiscalYearStatus.closed,
        closedAt: DateTime.now(),
      );
      await updateFiscalYear(closedFiscalYear);
    }
  }

  // Generate fiscal year summary
  Future<FiscalYearSummary> generateFiscalYearSummary(int year) async {
    final fiscalYear = await calculateFiscalYearTotals(year);

    // TODO: Generate detailed summary with monthly breakdowns
    final summary = FiscalYearSummary(
      fiscalYearId: fiscalYear.id,
      year: year,
      totalRevenue: fiscalYear.totalRevenue,
      totalExpenses: fiscalYear.totalExpenses,
      totalTaxes: fiscalYear.totalTaxes,
      netProfit: fiscalYear.netProfit,
      totalClients: fiscalYear.totalClients,
      totalProjects: fiscalYear.totalProjects,
      totalInvoices: fiscalYear.totalInvoices,
      totalPayments: fiscalYear.totalPayments,
      monthlyRevenue: {}, // TODO: Calculate monthly revenue
      monthlyExpenses: {}, // TODO: Calculate monthly expenses
      clientDistribution: {}, // TODO: Calculate client distribution
      projectTypeRevenue: {}, // TODO: Calculate project type revenue
      generatedAt: DateTime.now(),
    );

    return summary;
  }

  // Archive fiscal year data
  Future<void> archiveFiscalYearData(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all data for the fiscal year
      // TODO: Replace with actual service calls when available
      final clients = <dynamic>[];
      final projects = <dynamic>[];
      final payments = <dynamic>[];
      final invoices = <dynamic>[];

      final fiscalYear = getFiscalYearByYear(year);
      if (fiscalYear == null) return;

      // Filter data by fiscal year (simplified for now)
      final archivedData = {
        'fiscal_year': fiscalYear.toJson(),
        'clients': clients,
        'projects': projects,
        'payments': payments,
        'invoices': invoices,
        'archived_at': DateTime.now().toIso8601String(),
      };

      // Save archived data
      final existingArchives = prefs.getString(_archivedDataKey);
      Map<String, dynamic> archives = {};

      if (existingArchives != null) {
        archives = json.decode(existingArchives);
      }

      archives[year.toString()] = archivedData;

      await prefs.setString(_archivedDataKey, json.encode(archives));

      // Update fiscal year status to archived
      final archivedFiscalYear = fiscalYear.copyWith(
        status: FiscalYearStatus.archived,
      );
      await updateFiscalYear(archivedFiscalYear);

    } catch (e) {
      print('Error archiving fiscal year data: $e');
    }
  }

  // Get archived fiscal year data
  Future<Map<String, dynamic>?> getArchivedFiscalYearData(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final archivedDataJson = prefs.getString(_archivedDataKey);

      if (archivedDataJson != null) {
        final archives = json.decode(archivedDataJson);
        return archives[year.toString()];
      }

      return null;
    } catch (e) {
      print('Error getting archived fiscal year data: $e');
      return null;
    }
  }

  // Get all archived years
  Future<List<int>> getArchivedYears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final archivedDataJson = prefs.getString(_archivedDataKey);

      if (archivedDataJson != null) {
        final archives = json.decode(archivedDataJson);
        return archives.keys.map((key) => int.parse(key)).toList()
          ..sort((a, b) => b.compareTo(a)); // Sort descending
      }

      return [];
    } catch (e) {
      print('Error getting archived years: $e');
      return [];
    }
  }

  // Start monitoring for year-end
  void _startYearEndMonitoring() {
    Timer.periodic(const Duration(hours: 24), (timer) {
      _checkForYearEnd();
    });
  }

  // Check if year-end transition is needed
  Future<void> _checkForYearEnd() async {
    final now = DateTime.now();
    final currentYear = now.year;

    // Check if we're in a new year and need to transition
    if (_currentFiscalYear != null &&
        _currentFiscalYear!.year < currentYear) {

      // Auto-create new fiscal year if it doesn't exist
      final newFiscalYear = getFiscalYearByYear(currentYear);
      if (newFiscalYear == null) {
        await createFiscalYear(currentYear);
      }
    }
  }

  // Dispose service
  void dispose() {
    _fiscalYearController.close();
  }
}

