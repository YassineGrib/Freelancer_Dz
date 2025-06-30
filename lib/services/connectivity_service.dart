import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool _hasBeenOffline = false;
  DateTime? _lastOfflineTime;
  DateTime? _lastOnlineTime;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get hasBeenOffline => _hasBeenOffline;
  DateTime? get lastOfflineTime => _lastOfflineTime;
  DateTime? get lastOnlineTime => _lastOnlineTime;

  // Stream for connectivity changes
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('Connectivity error: $error');
      },
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(connectivityResults);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateConnectivityStatus([ConnectivityResult.none]);
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectivityStatus(results);
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final bool wasOnline = _isOnline;

    // Check if any connection is available
    _isOnline = results.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );

    // Update timestamps and flags
    if (wasOnline && !_isOnline) {
      // Just went offline
      _lastOfflineTime = DateTime.now();
      _hasBeenOffline = true;
      debugPrint('📱 Device went OFFLINE at $_lastOfflineTime');
    } else if (!wasOnline && _isOnline) {
      // Just came back online
      _lastOnlineTime = DateTime.now();
      debugPrint('📱 Device came back ONLINE at $_lastOnlineTime');
    }

    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      notifyListeners();
      _connectivityController.add(_isOnline);
    }

    // debugPrint('📶 Connectivity Status: ${_isOnline ? "ONLINE" : "OFFLINE"} - Results: $results'); // Disabled for local-only app
  }

  String getConnectivityStatusText() {
    if (_isOnline) {
      return 'Connected';
    } else {
      return 'Offline';
    }
  }

  String getDetailedConnectivityInfo() {
    final buffer = StringBuffer();

    buffer.writeln('Status: ${getConnectivityStatusText()}');

    if (_lastOfflineTime != null) {
      buffer.writeln('Last offline: ${_formatDateTime(_lastOfflineTime!)}');
    }

    if (_lastOnlineTime != null) {
      buffer.writeln('Last online: ${_formatDateTime(_lastOnlineTime!)}');
    }

    if (_isOnline && _hasBeenOffline && _lastOfflineTime != null && _lastOnlineTime != null) {
      final offlineDuration = _lastOnlineTime!.difference(_lastOfflineTime!);
      buffer.writeln('Offline duration: ${_formatDuration(offlineDuration)}');
    }

    return buffer.toString().trim();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Force refresh connectivity status
  Future<void> refresh() async {
    await _checkConnectivity();
  }

  // Check if we should sync (online and has been offline)
  bool shouldSync() {
    return _isOnline && _hasBeenOffline;
  }

  // Reset offline flag (call after successful sync)
  void resetOfflineFlag() {
    _hasBeenOffline = false;
    notifyListeners();
  }

  // Simulate offline mode for testing
  void simulateOffline() {
    if (_isOnline) {
      _updateConnectivityStatus([ConnectivityResult.none]);
    }
  }

  // Simulate online mode for testing
  void simulateOnline() {
    if (!_isOnline) {
      _updateConnectivityStatus([ConnectivityResult.wifi]);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    super.dispose();
  }
}

// Extension for easier access
extension ConnectivityExtension on ConnectivityService {
  // Quick check methods
  bool get canSync => isOnline && hasBeenOffline;
  bool get needsSync => hasBeenOffline;

  // Status indicators
  String get statusIcon => isOnline ? '🟢' : '🔴';
  String get statusText => isOnline ? 'Online' : 'Offline';

  // Duration helpers
  Duration? get offlineDuration {
    if (lastOfflineTime == null) return null;
    final endTime = lastOnlineTime ?? DateTime.now();
    return endTime.difference(lastOfflineTime!);
  }

  Duration? get onlineDuration {
    if (lastOnlineTime == null) return null;
    return DateTime.now().difference(lastOnlineTime!);
  }
}

