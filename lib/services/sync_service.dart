// TEMPORARILY DISABLED - NEEDS CONVERSION TO NEW LOCAL DATABASE
/*
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/payment_model.dart';
import '../models/expense_model.dart';
import '../models/invoice_model.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _pendingChanges = 0;
  String _syncStatus = 'Ready';
  List<String> _syncErrors = [];

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingChanges => _pendingChanges;
  String get syncStatus => _syncStatus;
  List<String> get syncErrors => List.unmodifiable(_syncErrors);
  bool get hasErrors => _syncErrors.isNotEmpty;

  Future<void> initialize() async {
    await _loadSyncState();
    await _updatePendingChanges();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _onConnectivityChanged,
    );

    // Start periodic sync timer (every 5 minutes when online)
    _startPeriodicSync();

    debugPrint('🔄 SyncService initialized');
  }

  void _onConnectivityChanged(bool isOnline) {
    if (isOnline && _connectivityService.hasBeenOffline) {
      debugPrint('🔄 Device back online - triggering sync');
      syncWhenOnline();
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) {
        if (_connectivityService.isOnline && !_isSyncing) {
          syncInBackground();
        }
      },
    );
  }

  Future<void> _loadSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString('last_sync_time');
      if (lastSyncString != null) {
        _lastSyncTime = DateTime.parse(lastSyncString);
      }
    } catch (e) {
      debugPrint('Error loading sync state: $e');
    }
  }

  Future<void> _saveSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastSyncTime != null) {
        await prefs.setString('last_sync_time', _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving sync state: $e');
    }
  }

  Future<void> _updatePendingChanges() async {
    try {
      _pendingChanges = await LocalDatabaseService.getUnsyncedCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating pending changes: $e');
    }
  }

  // Manual sync trigger
  Future<bool> syncNow() async {
    if (_isSyncing) {
      debugPrint('🔄 Sync already in progress');
      return false;
    }

    if (!_connectivityService.isOnline) {
      _setSyncStatus('Offline - sync queued');
      return false;
    }

    return await _performSync(showProgress: true);
  }

  // Background sync (silent)
  Future<void> syncInBackground() async {
    if (_isSyncing || !_connectivityService.isOnline) return;
    await _performSync(showProgress: false);
  }

  // Sync when coming back online
  Future<void> syncWhenOnline() async {
    if (!_connectivityService.isOnline) return;

    // Wait a bit for connection to stabilize
    await Future.delayed(const Duration(seconds: 2));

    if (_connectivityService.isOnline) {
      await _performSync(showProgress: true);
      _connectivityService.resetOfflineFlag();
    }
  }

  Future<bool> _performSync({required bool showProgress}) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _syncErrors.clear();

    if (showProgress) {
      _setSyncStatus('Syncing...');
    }

    try {
      debugPrint('🔄 Starting sync process');

      // Get pending sync items
      final pendingItems = await LocalDatabaseService.getPendingSyncItems();

      if (pendingItems.isEmpty) {
        _setSyncStatus('Up to date');
        _lastSyncTime = DateTime.now();
        await _saveSyncState();
        return true;
      }

      debugPrint('🔄 Found ${pendingItems.length} items to sync');

      int successCount = 0;
      int errorCount = 0;

      // Process each pending item
      for (final item in pendingItems) {
        try {
          final success = await _syncItem(item);
          if (success) {
            successCount++;
            await LocalDatabaseService.markAsSynced(
              item['table_name'],
              item['record_id'],
            );
          } else {
            errorCount++;
            await LocalDatabaseService.incrementRetryCount(item['id']);
          }
        } catch (e) {
          errorCount++;
          _syncErrors.add('Error syncing ${item['table_name']}: $e');
          await LocalDatabaseService.incrementRetryCount(item['id']);
          debugPrint('🔄 Sync error for item ${item['id']}: $e');
        }
      }

      // Update status
      if (errorCount == 0) {
        _setSyncStatus('Synced successfully');
        _lastSyncTime = DateTime.now();
        await _saveSyncState();
      } else {
        _setSyncStatus('Sync completed with $errorCount errors');
      }

      debugPrint('🔄 Sync completed: $successCount success, $errorCount errors');

      await _updatePendingChanges();
      return errorCount == 0;

    } catch (e) {
      _syncErrors.add('Sync failed: $e');
      _setSyncStatus('Sync failed');
      debugPrint('🔄 Sync failed: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> _syncItem(Map<String, dynamic> item) async {
    final tableName = item['table_name'] as String;
    final recordId = item['record_id'] as String;
    final action = item['action'] as String;
    final dataJson = item['data'] as String?;

    try {
      switch (action) {
        case 'INSERT':
        case 'UPDATE':
          if (dataJson == null) return false;
          final data = jsonDecode(dataJson) as Map<String, dynamic>;
          return await _syncRecord(tableName, recordId, data, action);

        case 'DELETE':
          return await _deleteRecord(tableName, recordId);

        default:
          debugPrint('🔄 Unknown sync action: $action');
          return false;
      }
    } catch (e) {
      debugPrint('🔄 Error syncing item: $e');
      return false;
    }
  }

  Future<bool> _syncRecord(String tableName, String recordId, Map<String, dynamic> data, String action) async {
    try {
      // Simulate API call - replace with actual Supabase calls
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real implementation, you would:
      // 1. Convert local data to API format
      // 2. Make HTTP request to Supabase
      // 3. Handle response and errors
      // 4. Update local record with server data if needed

      debugPrint('🔄 Synced $action for $tableName:$recordId');
      return true;
    } catch (e) {
      debugPrint('🔄 Failed to sync $tableName:$recordId - $e');
      return false;
    }
  }

  Future<bool> _deleteRecord(String tableName, String recordId) async {
    try {
      // Simulate API call - replace with actual Supabase calls
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('🔄 Synced DELETE for $tableName:$recordId');
      return true;
    } catch (e) {
      debugPrint('🔄 Failed to delete $tableName:$recordId - $e');
      return false;
    }
  }

  void _setSyncStatus(String status) {
    _syncStatus = status;
    debugPrint('🔄 Sync status: $status');
    notifyListeners();
  }

  // Force sync of specific record
  Future<bool> forceSyncRecord(String tableName, String recordId) async {
    if (!_connectivityService.isOnline) return false;

    try {
      final record = await LocalDatabaseService.queryById(tableName, recordId);
      if (record == null) return false;

      return await _syncRecord(tableName, recordId, record, 'UPDATE');
    } catch (e) {
      debugPrint('🔄 Force sync failed: $e');
      return false;
    }
  }

  // Clear sync errors
  void clearErrors() {
    _syncErrors.clear();
    notifyListeners();
  }

  // Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'is_syncing': _isSyncing,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'pending_changes': _pendingChanges,
      'sync_status': _syncStatus,
      'error_count': _syncErrors.length,
      'connectivity_status': _connectivityService.getConnectivityStatusText(),
      'has_been_offline': _connectivityService.hasBeenOffline,
    };
  }

  // Reset sync state (for testing or troubleshooting)
  Future<void> resetSyncState() async {
    _lastSyncTime = null;
    _syncErrors.clear();
    _setSyncStatus('Reset');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_time');

    await _updatePendingChanges();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}

// Sync status enum for better type safety
enum SyncStatus {
  ready,
  syncing,
  success,
  error,
  offline,
}

extension SyncStatusExtension on SyncStatus {
  String get displayName {
    switch (this) {
      case SyncStatus.ready:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  String get icon {
    switch (this) {
      case SyncStatus.ready:
        return '⏳';
      case SyncStatus.syncing:
        return '🔄';
      case SyncStatus.success:
        return '✅';
      case SyncStatus.error:
        return '❌';
      case SyncStatus.offline:
        return '📴';
    }
  }
}
*/

// Temporary stub class to prevent compilation errors
import 'package:flutter/foundation.dart';

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  bool get isSyncing => false;
  DateTime? get lastSyncTime => null;
  int get pendingChanges => 0;
  String get syncStatus => 'Ready';
  List<String> get syncErrors => [];
  bool get hasErrors => false;

  Future<void> initialize() async {
    // Stub implementation
  }

  Future<bool> syncNow() async {
    return true;
  }

  Future<void> syncInBackground() async {
    // Stub implementation
  }

  Map<String, dynamic> getSyncStats() {
    return {
      'is_syncing': false,
      'last_sync_time': null,
      'pending_changes': 0,
      'sync_status': 'Ready',
      'error_count': 0,
      'connectivity_status': 'Online',
      'has_been_offline': false,
    };
  }

  void clearErrors() {
    // Stub implementation
  }
}

