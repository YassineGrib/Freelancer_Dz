// TEMPORARILY DISABLED - NEEDS CONVERSION TO NEW LOCAL DATABASE
/*
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import '../models/client_model.dart' as client_model;
import '../models/project_model.dart';
import '../models/payment_model.dart';
import '../models/expense_model.dart';
import '../models/invoice_model.dart';

class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final SyncService _syncService = SyncService();

  bool _isInitialized = false;
  Map<String, dynamic> _cachedData = {};
  DateTime? _lastCacheUpdate;

  bool get isInitialized => _isInitialized;
  bool get isOffline => _connectivityService.isOffline;
  bool get isOnline => _connectivityService.isOnline;
  DateTime? get lastCacheUpdate => _lastCacheUpdate;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _connectivityService.initialize();
      await _syncService.initialize();
      await _loadCachedData();

      _isInitialized = true;
      debugPrint('📱 OfflineService initialized');
    } catch (e) {
      debugPrint('📱 Error initializing OfflineService: $e');
    }
  }

  // Cache management
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString('cached_data');
      if (cachedDataString != null) {
        _cachedData = jsonDecode(cachedDataString);
      }

      final lastUpdateString = prefs.getString('last_cache_update');
      if (lastUpdateString != null) {
        _lastCacheUpdate = DateTime.parse(lastUpdateString);
      }
    } catch (e) {
      debugPrint('📱 Error loading cached data: $e');
      _cachedData = {};
    }
  }

  Future<void> _saveCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_data', jsonEncode(_cachedData));

      _lastCacheUpdate = DateTime.now();
      await prefs.setString('last_cache_update', _lastCacheUpdate!.toIso8601String());
    } catch (e) {
      debugPrint('📱 Error saving cached data: $e');
    }
  }

  // Client operations
  Future<List<client_model.ClientModel>> getClients() async {
    try {
      final results = await LocalDatabaseService.query(
        LocalDatabaseService.clientsTable,
        orderBy: 'name ASC',
      );

      return results.map((data) => client_model.ClientModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('📱 Error getting clients: $e');
      return [];
    }
  }

  Future<client_model.ClientModel?> getClient(String id) async {
    try {
      final result = await LocalDatabaseService.queryById(
        LocalDatabaseService.clientsTable,
        id,
      );

      return result != null ? client_model.ClientModel.fromJson(result) : null;
    } catch (e) {
      debugPrint('📱 Error getting client: $e');
      return null;
    }
  }

  Future<bool> saveClient(client_model.ClientModel client) async {
    try {
      final data = client.toJson();
      await LocalDatabaseService.insert(
        LocalDatabaseService.clientsTable,
        data,
      );

      await _updateCache('clients', await getClients());
      return true;
    } catch (e) {
      debugPrint('📱 Error saving client: $e');
      return false;
    }
  }

  Future<bool> updateClient(client_model.ClientModel client) async {
    try {
      final data = client.toJson();
      await LocalDatabaseService.update(
        LocalDatabaseService.clientsTable,
        data,
        client.id ?? '',
      );

      await _updateCache('clients', await getClients());
      return true;
    } catch (e) {
      debugPrint('📱 Error updating client: $e');
      return false;
    }
  }

  Future<bool> deleteClient(String id) async {
    try {
      await LocalDatabaseService.delete(
        LocalDatabaseService.clientsTable,
        id,
      );

      await _updateCache('clients', await getClients());
      return true;
    } catch (e) {
      debugPrint('📱 Error deleting client: $e');
      return false;
    }
  }

  // Project operations
  Future<List<ProjectModel>> getProjects() async {
    try {
      final results = await LocalDatabaseService.query(
        LocalDatabaseService.projectsTable,
        orderBy: 'created_at DESC',
      );

      return results.map((data) => ProjectModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('📱 Error getting projects: $e');
      return [];
    }
  }

  Future<ProjectModel?> getProject(String id) async {
    try {
      final result = await LocalDatabaseService.queryById(
        LocalDatabaseService.projectsTable,
        id,
      );

      return result != null ? ProjectModel.fromJson(result) : null;
    } catch (e) {
      debugPrint('📱 Error getting project: $e');
      return null;
    }
  }

  Future<bool> saveProject(ProjectModel project) async {
    try {
      final data = project.toJson();
      await LocalDatabaseService.insert(
        LocalDatabaseService.projectsTable,
        data,
      );

      await _updateCache('projects', await getProjects());
      return true;
    } catch (e) {
      debugPrint('📱 Error saving project: $e');
      return false;
    }
  }

  Future<bool> updateProject(ProjectModel project) async {
    try {
      final data = project.toJson();
      await LocalDatabaseService.update(
        LocalDatabaseService.projectsTable,
        data,
        project.id ?? '',
      );

      await _updateCache('projects', await getProjects());
      return true;
    } catch (e) {
      debugPrint('📱 Error updating project: $e');
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      await LocalDatabaseService.delete(
        LocalDatabaseService.projectsTable,
        id,
      );

      await _updateCache('projects', await getProjects());
      return true;
    } catch (e) {
      debugPrint('📱 Error deleting project: $e');
      return false;
    }
  }

  // Payment operations
  Future<List<PaymentModel>> getPayments() async {
    try {
      final results = await LocalDatabaseService.query(
        LocalDatabaseService.paymentsTable,
        orderBy: 'payment_date DESC',
      );

      return results.map((data) => PaymentModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('📱 Error getting payments: $e');
      return [];
    }
  }

  Future<bool> savePayment(PaymentModel payment) async {
    try {
      final data = payment.toJson();
      await LocalDatabaseService.insert(
        LocalDatabaseService.paymentsTable,
        data,
      );

      await _updateCache('payments', await getPayments());
      return true;
    } catch (e) {
      debugPrint('📱 Error saving payment: $e');
      return false;
    }
  }

  // Expense operations
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final results = await LocalDatabaseService.query(
        LocalDatabaseService.expensesTable,
        orderBy: 'expense_date DESC',
      );

      return results.map((data) => ExpenseModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('📱 Error getting expenses: $e');
      return [];
    }
  }

  Future<bool> saveExpense(ExpenseModel expense) async {
    try {
      final data = expense.toJson();
      await LocalDatabaseService.insert(
        LocalDatabaseService.expensesTable,
        data,
      );

      await _updateCache('expenses', await getExpenses());
      return true;
    } catch (e) {
      debugPrint('📱 Error saving expense: $e');
      return false;
    }
  }

  // Invoice operations
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final results = await LocalDatabaseService.query(
        LocalDatabaseService.invoicesTable,
        orderBy: 'issue_date DESC',
      );

      return results.map((data) => InvoiceModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('📱 Error getting invoices: $e');
      return [];
    }
  }

  Future<bool> saveInvoice(InvoiceModel invoice) async {
    try {
      final data = invoice.toJson();
      await LocalDatabaseService.insert(
        LocalDatabaseService.invoicesTable,
        data,
      );

      await _updateCache('invoices', await getInvoices());
      return true;
    } catch (e) {
      debugPrint('📱 Error saving invoice: $e');
      return false;
    }
  }

  // Cache operations
  Future<void> _updateCache(String key, dynamic data) async {
    _cachedData[key] = data;
    await _saveCachedData();
    notifyListeners();
  }

  T? getCachedData<T>(String key) {
    return _cachedData[key] as T?;
  }

  // Sync operations
  Future<bool> syncNow() async {
    if (isOffline) {
      debugPrint('📱 Cannot sync while offline');
      return false;
    }

    return await _syncService.syncNow();
  }

  Future<void> syncInBackground() async {
    if (isOnline) {
      await _syncService.syncInBackground();
    }
  }

  // Statistics
  Future<Map<String, int>> getOfflineStats() async {
    try {
      final clients = await getClients();
      final projects = await getProjects();
      final payments = await getPayments();
      final expenses = await getExpenses();
      final invoices = await getInvoices();
      final pendingChanges = await LocalDatabaseService.getUnsyncedCount();

      return {
        'clients': clients.length,
        'projects': projects.length,
        'payments': payments.length,
        'expenses': expenses.length,
        'invoices': invoices.length,
        'pending_changes': pendingChanges,
      };
    } catch (e) {
      debugPrint('📱 Error getting offline stats: $e');
      return {};
    }
  }

  // Clear all offline data
  Future<void> clearOfflineData() async {
    try {
      await LocalDatabaseService.clearAllData();
      _cachedData.clear();
      await _saveCachedData();
      notifyListeners();
      debugPrint('📱 Offline data cleared');
    } catch (e) {
      debugPrint('📱 Error clearing offline data: $e');
    }
  }

  // Check if data is stale
  bool isDataStale({Duration maxAge = const Duration(hours: 24)}) {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > maxAge;
  }

  // Get offline status info
  Map<String, dynamic> getOfflineInfo() {
    return {
      'is_offline': isOffline,
      'is_online': isOnline,
      'last_cache_update': _lastCacheUpdate?.toIso8601String(),
      'cache_age_hours': _lastCacheUpdate != null
          ? DateTime.now().difference(_lastCacheUpdate!).inHours
          : null,
      'connectivity_status': _connectivityService.getConnectivityStatusText(),
      'sync_status': _syncService.syncStatus,
      'pending_changes': _syncService.pendingChanges,
      'has_sync_errors': _syncService.hasErrors,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
*/

// Temporary stub class to prevent compilation errors
import 'package:flutter/foundation.dart';

class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool get isInitialized => true;
  bool get isOffline => false;
  bool get isOnline => true;

  Future<void> initialize() async {
    // Stub implementation
  }

  Future<List<dynamic>> getClients() async {
    return [];
  }

  Future<List<dynamic>> getProjects() async {
    return [];
  }

  Future<Map<String, int>> getOfflineStats() async {
    return {
      'clients': 0,
      'projects': 0,
      'payments': 0,
      'expenses': 0,
      'invoices': 0,
      'pending_changes': 0,
    };
  }

  Future<void> clearOfflineData() async {
    // Stub implementation
  }
}

