import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'local_database_extensions.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'freelancer_mobile.db';
  static const int _databaseVersion = 10;
  static const _uuid = Uuid();

  // Table names
  static const String _usersTable = 'users';
  static const String _clientsTable = 'clients';
  static const String _projectsTable = 'projects';
  static const String _paymentsTable = 'payments';
  static const String _expensesTable = 'expenses';
  static const String _invoicesTable = 'invoices';
  static const String _taxPaymentsTable = 'tax_payments';
  static const String _taxCalculationsTable = 'tax_calculations';
  static const String _calendarEventsTable = 'calendar_events';

  // Singleton pattern
  static LocalDatabaseService? _instance;
  static LocalDatabaseService get instance {
    _instance ??= LocalDatabaseService._internal();
    return _instance!;
  }

  LocalDatabaseService._internal();

  // Get database instance
  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
      // Only check tables once after initialization
      await _ensureAllTablesExist();
    }

    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Create users table (replaces Supabase auth)
    await db.execute('''
      CREATE TABLE $_usersTable (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        email_verified INTEGER DEFAULT 0,
        last_login TEXT
      )
    ''');

    // Create clients table
    await db.execute('''
      CREATE TABLE $_clientsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        client_type TEXT NOT NULL CHECK (client_type IN ('individualLocal', 'individualForeign', 'nationalCompany', 'companyInternational')),
        currency TEXT NOT NULL CHECK (currency IN ('da', 'usd', 'eur')),
        company_name TEXT,
        commercial_register_number TEXT,
        tax_identification_number TEXT,
        company_email TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create projects table
    await db.execute('''
      CREATE TABLE $_projectsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        project_name TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('notStarted', 'inProgress', 'onHold', 'completed', 'cancelled')) DEFAULT 'notStarted',
        pricing_type TEXT NOT NULL CHECK (pricing_type IN ('hourlyRate', 'fixedPrice')),
        hourly_rate REAL,
        fixed_amount REAL,
        estimated_hours REAL,
        actual_hours REAL,
        currency TEXT NOT NULL CHECK (currency IN ('da', 'usd', 'eur')),
        start_date TEXT,
        end_date TEXT,
        progress_percentage INTEGER DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE,
        FOREIGN KEY (client_id) REFERENCES $_clientsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_clients_user_id ON $_clientsTable (user_id)');
    await db.execute('CREATE INDEX idx_clients_name ON $_clientsTable (name)');
    await db
        .execute('CREATE INDEX idx_clients_email ON $_clientsTable (email)');
    await db.execute(
        'CREATE INDEX idx_clients_client_type ON $_clientsTable (client_type)');
    await db.execute(
        'CREATE INDEX idx_clients_created_at ON $_clientsTable (created_at)');

    await db.execute(
        'CREATE INDEX idx_projects_user_id ON $_projectsTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_projects_client_id ON $_projectsTable (client_id)');
    await db.execute(
        'CREATE INDEX idx_projects_status ON $_projectsTable (status)');
    await db.execute(
        'CREATE INDEX idx_projects_pricing_type ON $_projectsTable (pricing_type)');
    await db.execute(
        'CREATE INDEX idx_projects_created_at ON $_projectsTable (created_at)');
    await db.execute(
        'CREATE INDEX idx_projects_end_date ON $_projectsTable (end_date)');
    await db.execute(
        'CREATE INDEX idx_projects_project_name ON $_projectsTable (project_name)');

    // Create payments table
    await db.execute('''
      CREATE TABLE $_paymentsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        project_id TEXT,
        payment_amount REAL NOT NULL CHECK (payment_amount > 0),
        currency TEXT NOT NULL CHECK (currency IN ('da', 'usd', 'eur')),
        payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'bankTransfer', 'ccp', 'creditCard', 'debitCard', 'paypal', 'stripe', 'crypto', 'check', 'other')),
        payment_status TEXT NOT NULL CHECK (payment_status IN ('pending', 'completed', 'failed', 'cancelled', 'refunded', 'partial')) DEFAULT 'pending',
        payment_type TEXT NOT NULL CHECK (payment_type IN ('full', 'partial', 'advance', 'milestone', 'finalPayment')),
        payment_date TEXT NOT NULL,
        due_date TEXT,
        reference_number TEXT,
        description TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE,
        FOREIGN KEY (client_id) REFERENCES $_clientsTable (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES $_projectsTable (id) ON DELETE SET NULL
      )
    ''');

    // Create expenses table
    await db.execute('''
      CREATE TABLE $_expensesTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        project_id TEXT,
        client_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL CHECK (amount > 0),
        currency TEXT NOT NULL CHECK (currency IN ('da', 'usd', 'eur', 'gbp')),
        category TEXT NOT NULL CHECK (category IN ('office', 'travel', 'equipment', 'software', 'marketing', 'utilities', 'meals', 'transportation', 'communication', 'education', 'legal', 'tax', 'other')),
        payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'bankTransfer', 'creditCard', 'debitCard', 'paypal', 'ccp', 'other')),
        expense_date TEXT NOT NULL,
        receipt_url TEXT,
        vendor TEXT,
        notes TEXT,
        is_reimbursable INTEGER DEFAULT 0,
        is_recurring INTEGER DEFAULT 0,
        recurring_end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES $_projectsTable (id) ON DELETE SET NULL,
        FOREIGN KEY (client_id) REFERENCES $_clientsTable (id) ON DELETE SET NULL
      )
    ''');

    // Create invoices table
    await db.execute('''
      CREATE TABLE $_invoicesTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        project_id TEXT,
        invoice_number TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('client', 'project')) DEFAULT 'client',
        issue_date TEXT NOT NULL,
        due_date TEXT NOT NULL,
        currency TEXT NOT NULL CHECK (currency IN ('da', 'usd', 'eur')),
        items TEXT NOT NULL DEFAULT '[]',
        subtotal REAL NOT NULL,
        tax_rate REAL,
        tax_amount REAL,
        discount REAL,
        total REAL NOT NULL,
        notes TEXT,
        terms TEXT,
        payment_instructions TEXT,
        sent_date TEXT,
        paid_date TEXT,
        status TEXT NOT NULL CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')) DEFAULT 'draft',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        company_name TEXT,
        company_address TEXT,
        company_phone TEXT,
        company_email TEXT,
        company_website TEXT,
        company_logo TEXT,
        client_name TEXT,
        client_address TEXT,
        client_phone TEXT,
        client_email TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE,
        FOREIGN KEY (client_id) REFERENCES $_clientsTable (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES $_projectsTable (id) ON DELETE SET NULL
      )
    ''');

    // Create tax payments table
    await db.execute('''
      CREATE TABLE $_taxPaymentsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('irg', 'casnos')),
        year INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'overdue', 'exempted')) DEFAULT 'pending',
        due_date TEXT NOT NULL,
        paid_date TEXT,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create tax calculations table
    await db.execute('''
      CREATE TABLE $_taxCalculationsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        annual_income REAL NOT NULL,
        irg_amount REAL NOT NULL,
        casnos_amount REAL NOT NULL,
        total_taxes REAL NOT NULL,
        calculation_method TEXT NOT NULL,
        calculated_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create calendar events table
    await db.execute('''
      CREATE TABLE $_calendarEventsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL CHECK (type IN ('deadline', 'meeting', 'payment', 'tax', 'custom')),
        priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
        status TEXT NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled', 'overdue')) DEFAULT 'scheduled',
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_all_day INTEGER DEFAULT 0,
        location TEXT,
        attendees TEXT DEFAULT '[]',
        related_id TEXT,
        google_event_id TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for new tables
    await db.execute(
        'CREATE INDEX idx_payments_user_id ON $_paymentsTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_payments_client_id ON $_paymentsTable (client_id)');
    await db.execute(
        'CREATE INDEX idx_payments_project_id ON $_paymentsTable (project_id)');
    await db.execute(
        'CREATE INDEX idx_payments_status ON $_paymentsTable (payment_status)');
    await db.execute(
        'CREATE INDEX idx_payments_date ON $_paymentsTable (payment_date)');

    await db.execute(
        'CREATE INDEX idx_expenses_user_id ON $_expensesTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_expenses_project_id ON $_expensesTable (project_id)');
    await db.execute(
        'CREATE INDEX idx_expenses_client_id ON $_expensesTable (client_id)');
    await db.execute(
        'CREATE INDEX idx_expenses_date ON $_expensesTable (expense_date)');
    await db.execute(
        'CREATE INDEX idx_expenses_category ON $_expensesTable (category)');

    await db.execute(
        'CREATE INDEX idx_invoices_user_id ON $_invoicesTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_invoices_client_id ON $_invoicesTable (client_id)');
    await db.execute(
        'CREATE INDEX idx_invoices_project_id ON $_invoicesTable (project_id)');
    await db.execute(
        'CREATE INDEX idx_invoices_status ON $_invoicesTable (status)');
    await db.execute(
        'CREATE INDEX idx_invoices_number ON $_invoicesTable (invoice_number)');

    await db.execute(
        'CREATE INDEX idx_tax_payments_user_id ON $_taxPaymentsTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_tax_payments_type ON $_taxPaymentsTable (type)');
    await db.execute(
        'CREATE INDEX idx_tax_payments_year ON $_taxPaymentsTable (year)');
    await db.execute(
        'CREATE INDEX idx_tax_payments_status ON $_taxPaymentsTable (status)');

    await db.execute(
        'CREATE INDEX idx_tax_calculations_user_id ON $_taxCalculationsTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_tax_calculations_year ON $_taxCalculationsTable (year)');

    await db.execute(
        'CREATE INDEX idx_calendar_events_user_id ON $_calendarEventsTable (user_id)');
    await db.execute(
        'CREATE INDEX idx_calendar_events_type ON $_calendarEventsTable (type)');
    await db.execute(
        'CREATE INDEX idx_calendar_events_start_date ON $_calendarEventsTable (start_date)');
    await db.execute(
        'CREATE INDEX idx_calendar_events_status ON $_calendarEventsTable (status)');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 9) {
      // Update calendar events table to include missing columns
      try {
        // Check if the columns exist
        final tableInfo =
            await db.rawQuery('PRAGMA table_info($_calendarEventsTable)');
        final columnNames =
            tableInfo.map((row) => row['name'] as String).toSet();

        // Add missing columns if they don't exist
        if (!columnNames.contains('location')) {
          await db.execute(
              'ALTER TABLE $_calendarEventsTable ADD COLUMN location TEXT');
        }
        if (!columnNames.contains('attendees')) {
          await db.execute(
              'ALTER TABLE $_calendarEventsTable ADD COLUMN attendees TEXT DEFAULT \'\'');
        }
        if (!columnNames.contains('google_event_id')) {
          await db.execute(
              'ALTER TABLE $_calendarEventsTable ADD COLUMN google_event_id TEXT');
        }
        if (!columnNames.contains('metadata')) {
          await db.execute(
              'ALTER TABLE $_calendarEventsTable ADD COLUMN metadata TEXT');
        }
      } catch (e) {
        // If there's an error, recreate the table
        await db.execute('DROP TABLE IF EXISTS $_calendarEventsTable');
        await db.execute('''
          CREATE TABLE $_calendarEventsTable (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL CHECK (type IN ('deadline', 'meeting', 'payment', 'tax', 'custom')),
            priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
            status TEXT NOT NULL CHECK (status IN ('scheduled', 'completed', 'cancelled', 'overdue')) DEFAULT 'scheduled',
            start_date TEXT NOT NULL,
            end_date TEXT,
            is_all_day INTEGER DEFAULT 0,
            location TEXT,
            attendees TEXT DEFAULT '',
            related_id TEXT,
            google_event_id TEXT,
            metadata TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
          )
        ''');

        // Recreate indexes
        await db.execute(
            'CREATE INDEX idx_calendar_events_user_id ON $_calendarEventsTable (user_id)');
        await db.execute(
            'CREATE INDEX idx_calendar_events_type ON $_calendarEventsTable (type)');
        await db.execute(
            'CREATE INDEX idx_calendar_events_start_date ON $_calendarEventsTable (start_date)');
        await db.execute(
            'CREATE INDEX idx_calendar_events_status ON $_calendarEventsTable (status)');
      }
    }

    if (oldVersion < 10) {
      // Update expenses table to include 'tax' category
      try {
        // Since SQLite doesn't support modifying CHECK constraints directly,
        // we need to recreate the table
        await db.execute('ALTER TABLE $_expensesTable RENAME TO ${_expensesTable}_old');

        // Create new table with updated CHECK constraint
        await db.execute('''
          CREATE TABLE $_expensesTable (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            project_id TEXT,
            client_id TEXT,
            title TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL CHECK (amount > 0),
            currency TEXT NOT NULL CHECK (currency IN ('da', 'usd', 'eur', 'gbp')),
            category TEXT NOT NULL CHECK (category IN ('office', 'travel', 'equipment', 'software', 'marketing', 'utilities', 'meals', 'transportation', 'communication', 'education', 'legal', 'tax', 'other')),
            payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'bankTransfer', 'creditCard', 'debitCard', 'paypal', 'ccp', 'other')),
            expense_date TEXT NOT NULL,
            receipt_url TEXT,
            vendor TEXT,
            notes TEXT,
            is_reimbursable INTEGER DEFAULT 0,
            is_recurring INTEGER DEFAULT 0,
            recurring_end_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE,
            FOREIGN KEY (project_id) REFERENCES $_projectsTable (id) ON DELETE SET NULL,
            FOREIGN KEY (client_id) REFERENCES $_clientsTable (id) ON DELETE SET NULL
          )
        ''');

        // Copy data from old table
        await db.execute('''
          INSERT INTO $_expensesTable
          SELECT * FROM ${_expensesTable}_old
        ''');

        // Drop old table
        await db.execute('DROP TABLE ${_expensesTable}_old');

        // Recreate indexes
        await db.execute('CREATE INDEX idx_expenses_user_id ON $_expensesTable (user_id)');
        await db.execute('CREATE INDEX idx_expenses_project_id ON $_expensesTable (project_id)');
        await db.execute('CREATE INDEX idx_expenses_client_id ON $_expensesTable (client_id)');
        await db.execute('CREATE INDEX idx_expenses_category ON $_expensesTable (category)');
        await db.execute('CREATE INDEX idx_expenses_expense_date ON $_expensesTable (expense_date)');
      } catch (e) {
        print('Error updating expenses table: $e');
        // If there's an error, just continue - the table will be recreated in version 8 migration
      }
    }

    if (oldVersion < 8) {
      // Drop all tables and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS $_calendarEventsTable');
      await db.execute('DROP TABLE IF EXISTS $_taxCalculationsTable');
      await db.execute('DROP TABLE IF EXISTS $_taxPaymentsTable');
      await db.execute('DROP TABLE IF EXISTS $_invoicesTable');
      await db.execute('DROP TABLE IF EXISTS $_expensesTable');
      await db.execute('DROP TABLE IF EXISTS $_paymentsTable');
      await db.execute('DROP TABLE IF EXISTS $_projectsTable');
      await db.execute('DROP TABLE IF EXISTS $_clientsTable');
      await db.execute('DROP TABLE IF EXISTS $_usersTable');

      // Recreate all tables with new schema
      await _onCreate(db, newVersion);
    }
  }

  // Ensure all required tables exist
  Future<void> _ensureAllTablesExist() async {
    if (_database == null) return;

    try {
      // Check if all required tables exist
      final tables = [
        _usersTable,
        _clientsTable,
        _projectsTable,
        _paymentsTable,
        _expensesTable,
        _invoicesTable,
        _taxPaymentsTable,
        _taxCalculationsTable,
        _calendarEventsTable,
      ];

      for (final table in tables) {
        final result = await _database!.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");

        if (result.isEmpty) {
          // Table missing, recreate database
          await _recreateDatabase();
          return;
        }
      }
    } catch (e) {
      // Error checking tables, recreate database
      await _recreateDatabase();
    }
  }

  // Recreate database completely
  Future<void> _recreateDatabase() async {
    try {
      await _database?.close();
      _database = null;

      String path = join(await getDatabasesPath(), _databaseName);
      await deleteDatabase(path);

      _database = await _initDatabase();
    } catch (e) {
      // Error recreating database - will be handled by caller
      rethrow;
    }
  }

  // Utility methods
  static String generateId() => _uuid.v4();

  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String getCurrentTimestamp() => DateTime.now().toIso8601String();

  // User management methods
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final result = await db.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<String> createUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final db = await database;
    final id = generateId();
    final now = getCurrentTimestamp();

    await db.insert(_usersTable, {
      'id': id,
      'email': email,
      'password_hash': hashPassword(password),
      'full_name': fullName,
      'created_at': now,
      'email_verified': 1, // Auto-verify for local database
    });

    return id;
  }

  Future<void> updateUserLastLogin(String userId) async {
    final db = await database;
    await db.update(
      _usersTable,
      {'last_login': getCurrentTimestamp()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Client management methods
  Future<List<Map<String, dynamic>>> getClients(String userId) async {
    final db = await database;
    return await db.query(
      _clientsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createClient(
      String userId, Map<String, dynamic> clientData) async {
    final db = await database;
    final id = generateId();
    final now = getCurrentTimestamp();

    final data = Map<String, dynamic>.from(clientData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;

    await db.insert(_clientsTable, data);
    return id;
  }

  Future<void> updateClient(
      String clientId, Map<String, dynamic> clientData) async {
    final db = await database;
    final data = Map<String, dynamic>.from(clientData);
    data['updated_at'] = getCurrentTimestamp();

    await db.update(
      _clientsTable,
      data,
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  Future<void> deleteClient(String clientId) async {
    final db = await database;
    await db.delete(
      _clientsTable,
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  Future<Map<String, dynamic>?> getClientById(String clientId) async {
    final db = await database;
    final result = await db.query(
      _clientsTable,
      where: 'id = ?',
      whereArgs: [clientId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Project management methods
  Future<List<Map<String, dynamic>>> getProjects(String userId) async {
    final db = await database;
    return await db.query(
      _projectsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createProject(
      String userId, Map<String, dynamic> projectData) async {
    final db = await database;
    final id = generateId();
    final now = getCurrentTimestamp();

    final data = Map<String, dynamic>.from(projectData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;

    await db.insert(_projectsTable, data);
    return id;
  }

  Future<void> updateProject(
      String projectId, Map<String, dynamic> projectData) async {
    final db = await database;
    final data = Map<String, dynamic>.from(projectData);
    data['updated_at'] = getCurrentTimestamp();

    await db.update(
      _projectsTable,
      data,
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<void> deleteProject(String projectId) async {
    final db = await database;
    await db.delete(
      _projectsTable,
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<Map<String, dynamic>?> getProjectById(String projectId) async {
    final db = await database;
    final result = await db.query(
      _projectsTable,
      where: 'id = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Search and filter methods
  Future<List<Map<String, dynamic>>> searchClients(
      String userId, String query) async {
    final db = await database;
    return await db.query(
      _clientsTable,
      where:
          'user_id = ? AND (name LIKE ? OR email LIKE ? OR company_name LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> searchProjects(
      String userId, String query) async {
    final db = await database;
    return await db.query(
      _projectsTable,
      where: 'user_id = ? AND (project_name LIKE ? OR description LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getProjectsByStatus(
      String userId, String status) async {
    final db = await database;
    return await db.query(
      _projectsTable,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, status],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getProjectsByClient(
      String userId, String clientId) async {
    final db = await database;
    return await db.query(
      _projectsTable,
      where: 'user_id = ? AND client_id = ?',
      whereArgs: [userId, clientId],
      orderBy: 'created_at DESC',
    );
  }

  // Database maintenance
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_calendarEventsTable);
    await db.delete(_taxCalculationsTable);
    await db.delete(_taxPaymentsTable);
    await db.delete(_invoicesTable);
    await db.delete(_expensesTable);
    await db.delete(_paymentsTable);
    await db.delete(_projectsTable);
    await db.delete(_clientsTable);
    await db.delete(_usersTable);
  }

  // Reset database completely
  Future<void> resetDatabase() async {
    await closeDatabase();
    String path = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(path);
    _database = null;
    print('Database reset successfully - app will reload with fresh database');
  }

  // Static method to reset database from anywhere
  static Future<void> resetDatabaseStatic() async {
    await LocalDatabaseService.instance.resetDatabase();
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Payment management methods
  Future<List<Map<String, dynamic>>> getPayments(String userId) async {
    final db = await database;
    return await db.query(
      _paymentsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createPayment(
      String userId, Map<String, dynamic> paymentData) async {
    final db = await database;
    final id = generateId();
    final now = getCurrentTimestamp();

    final data = Map<String, dynamic>.from(paymentData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;

    await db.insert(_paymentsTable, data);
    return id;
  }

  Future<void> updatePayment(
      String paymentId, Map<String, dynamic> paymentData) async {
    try {
      final db = await database;

      final data = Map<String, dynamic>.from(paymentData);
      data['updated_at'] = getCurrentTimestamp();

      await db.update(
        _paymentsTable,
        data,
        where: 'id = ?',
        whereArgs: [paymentId],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePayment(String paymentId) async {
    final db = await database;
    await db.delete(
      _paymentsTable,
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  Future<Map<String, dynamic>?> getPaymentById(String paymentId) async {
    final db = await database;
    final result = await db.query(
      _paymentsTable,
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getPaymentsByProject(
      String userId, String projectId) async {
    final db = await database;
    return await db.query(
      _paymentsTable,
      where: 'user_id = ? AND project_id = ?',
      whereArgs: [userId, projectId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentsByClient(
      String userId, String clientId) async {
    final db = await database;
    return await db.query(
      _paymentsTable,
      where: 'user_id = ? AND client_id = ?',
      whereArgs: [userId, clientId],
      orderBy: 'created_at DESC',
    );
  }
}
