import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'local_database_service.dart';
import 'business_profile_service.dart';

class DatabaseBackupService {
  static const String _backupFileExtension = '.freelancer_backup';
  static const String _backupVersion = '1.0';

  // Export complete database to backup file
  static Future<String?> createBackup() async {
    try {
      // Request appropriate permissions based on Android version
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
            'Storage permission denied. Please grant storage permission in app settings to create backups.');
      }

      final dbService = LocalDatabaseService.instance;
      final db = await dbService.database;
      final businessProfileService = BusinessProfileService.instance;

      // Get all table data
      final backupData = <String, dynamic>{
        'metadata': {
          'version': _backupVersion,
          'created_at': DateTime.now().toIso8601String(),
          'app_version': '1.0.0', // You can get this from package_info
        },
        'data': {},
        'business_profile': {},
      };

      // Export all tables
      final tables = [
        'users',
        'clients',
        'projects',
        'payments',
        'expenses',
        'invoices',
        'tax_payments',
        'tax_calculations',
        'calendar_events',
      ];

      for (final table in tables) {
        try {
          final tableData = await db.query(table);
          backupData['data'][table] = tableData;
          debugPrint('📦 Exported ${tableData.length} records from $table');
        } catch (e) {
          debugPrint('⚠️ Error exporting table $table: $e');
          // Continue with other tables even if one fails
          backupData['data'][table] = [];
        }
      }

      // Add business profile data
      try {
        final businessProfile =
            await businessProfileService.exportBusinessProfile();
        backupData['business_profile'] = businessProfile;
        debugPrint('📦 Exported business profile data');
      } catch (e) {
        debugPrint('⚠️ Error exporting business profile: $e');
        // Continue with backup even if business profile fails
        backupData['business_profile'] = {};
      }

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'freelancer_backup_$timestamp$_backupFileExtension';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      debugPrint('📦 Backup created successfully: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Error creating backup: $e');
      throw Exception('Failed to create backup: $e');
    }
  }

  // Share backup file
  static Future<void> shareBackup(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'FreeLancer Mobile Database Backup',
        subject: 'Database Backup - ${DateTime.now().toString().split(' ')[0]}',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  // Create and share backup in one action
  static Future<void> createAndShareBackup() async {
    try {
      final filePath = await createBackup();
      if (filePath != null) {
        await shareBackup(filePath);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Pick and restore from backup file
  static Future<bool> restoreFromBackup() async {
    try {
      // Use FileType.any to avoid extension filter issues
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        dialogTitle: 'Select Backup File',
      );

      if (result == null || result.files.isEmpty) {
        return false; // User cancelled
      }

      final file = File(result.files.first.path!);

      // Validate file extension (optional - we can be more lenient)
      if (!file.path.endsWith(_backupFileExtension)) {
        debugPrint(
            '⚠️ Selected file does not have expected extension: ${file.path}');
        // Still try to restore - the file content validation will catch invalid files
      }

      return await _restoreFromFile(file);
    } catch (e) {
      debugPrint('❌ Error picking backup file: $e');
      throw Exception('Failed to pick backup file: $e');
    }
  }

  // Restore from specific file
  static Future<bool> _restoreFromFile(File backupFile) async {
    try {
      // Read and parse backup file
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (!_validateBackupFormat(backupData)) {
        throw Exception('Invalid backup file format');
      }

      final dbService = LocalDatabaseService.instance;
      final db = await dbService.database;
      final businessProfileService = BusinessProfileService.instance;

      // Start transaction for atomic restore
      await db.transaction((txn) async {
        // Clear existing data (optional - you might want to ask user)
        await _clearAllTables(txn);

        // Restore data for each table
        final data = backupData['data'] as Map<String, dynamic>;

        for (final entry in data.entries) {
          final tableName = entry.key;
          final tableData = entry.value as List<dynamic>;

          try {
            for (final row in tableData) {
              await txn.insert(tableName, row as Map<String, dynamic>);
            }
            debugPrint('📥 Restored ${tableData.length} records to $tableName');
          } catch (e) {
            debugPrint('⚠️ Error restoring table $tableName: $e');
            // Continue with other tables
          }
        }
      });

      // Restore business profile data
      try {
        if (backupData.containsKey('business_profile') &&
            backupData['business_profile'] is Map<String, dynamic> &&
            (backupData['business_profile'] as Map<String, dynamic>)
                .isNotEmpty) {
          final businessProfileData =
              backupData['business_profile'] as Map<String, dynamic>;
          final success = await businessProfileService
              .importBusinessProfile(businessProfileData);
          if (success) {
            debugPrint('📥 Business profile restored successfully');
          } else {
            debugPrint('⚠️ Failed to restore business profile');
          }
        } else {
          debugPrint('📝 No business profile data found in backup');
        }
      } catch (e) {
        debugPrint('⚠️ Error restoring business profile: $e');
        // Continue even if business profile restoration fails
      }

      debugPrint('✅ Database and business profile restored successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring backup: $e');
      throw Exception('Failed to restore backup: $e');
    }
  }

  // Validate backup file format
  static bool _validateBackupFormat(Map<String, dynamic> backupData) {
    try {
      // Check required fields
      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('data')) {
        return false;
      }

      // Business profile is optional for backward compatibility
      if (backupData.containsKey('business_profile') &&
          backupData['business_profile'] is! Map<String, dynamic>) {
        return false;
      }

      final metadata = backupData['metadata'] as Map<String, dynamic>;
      if (!metadata.containsKey('version') ||
          !metadata.containsKey('created_at')) {
        return false;
      }

      // Check if data is a map
      if (backupData['data'] is! Map<String, dynamic>) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear all tables (for restore)
  static Future<void> _clearAllTables(dynamic txn) async {
    final tables = [
      'calendar_events',
      'tax_calculations',
      'tax_payments',
      'invoices',
      'expenses',
      'payments',
      'projects',
      'clients',
      'users',
    ];

    for (final table in tables) {
      try {
        await txn.delete(table);
      } catch (e) {
        debugPrint('⚠️ Error clearing table $table: $e');
      }
    }
  }

  // Get backup file info without restoring
  static Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!_validateBackupFormat(backupData)) {
        return null;
      }

      final metadata = backupData['metadata'] as Map<String, dynamic>;
      final data = backupData['data'] as Map<String, dynamic>;

      // Count total records
      int totalRecords = 0;
      final tableCounts = <String, int>{};

      for (final entry in data.entries) {
        final count = (entry.value as List).length;
        tableCounts[entry.key] = count;
        totalRecords += count;
      }

      // Check business profile
      bool hasBusinessProfile = false;
      String? businessProfileCompany;
      if (backupData.containsKey('business_profile') &&
          backupData['business_profile'] is Map<String, dynamic>) {
        final businessProfile =
            backupData['business_profile'] as Map<String, dynamic>;
        hasBusinessProfile = businessProfile.isNotEmpty;
        businessProfileCompany = businessProfile['company_name'] as String?;
      }

      return {
        'version': metadata['version'],
        'created_at': metadata['created_at'],
        'app_version': metadata['app_version'],
        'total_records': totalRecords,
        'table_counts': tableCounts,
        'has_business_profile': hasBusinessProfile,
        'business_profile_company': businessProfileCompany,
      };
    } catch (e) {
      debugPrint('❌ Error reading backup info: $e');
      return null;
    }
  }

  // Request storage permission based on Android version
  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Check Android version
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 30) {
          // Android 11+ (API 30+) - Check for MANAGE_EXTERNAL_STORAGE
          debugPrint(
              '📱 Android 11+ detected - checking MANAGE_EXTERNAL_STORAGE');

          var status = await Permission.manageExternalStorage.status;
          if (status.isDenied) {
            status = await Permission.manageExternalStorage.request();
          }

          if (status.isPermanentlyDenied) {
            debugPrint(
                '❌ MANAGE_EXTERNAL_STORAGE permission permanently denied');
            // For Android 11+, we can still use app-specific directories without this permission
            debugPrint('📱 Falling back to app-specific storage');
            return true;
          }

          debugPrint('📱 Android 11+ storage permission: ${status.name}');
          return true; // We can always use app-specific directories
        } else if (androidInfo >= 23) {
          // Android 6+ (API 23+) - Request runtime permissions
          debugPrint(
              '📱 Android 6-10 detected - requesting storage permission');

          var status = await Permission.storage.status;
          if (status.isDenied) {
            status = await Permission.storage.request();
          }

          if (status.isPermanentlyDenied) {
            debugPrint('❌ Storage permission permanently denied');
            return false;
          }

          return status.isGranted;
        } else {
          // Android 5 and below - permissions granted at install time
          debugPrint('📱 Android 5 and below - permissions granted at install');
          return true;
        }
      } else {
        // iOS or other platforms
        debugPrint('📱 Non-Android platform detected');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error checking storage permission: $e');
      // If we can't check permissions, assume we have them
      // This prevents the backup from failing due to permission check errors
      return true;
    }
  }

  // Get Android API level
  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error getting Android version: $e');
      return 30; // Default to modern Android
    }
  }
}
