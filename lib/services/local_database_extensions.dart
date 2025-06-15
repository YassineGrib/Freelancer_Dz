import 'local_database_service.dart';

// Extension methods for LocalDatabaseService to handle additional tables
extension LocalDatabaseExtensions on LocalDatabaseService {
  
  // Expense management methods
  Future<List<Map<String, dynamic>>> getExpenses(String userId) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createExpense(String userId, Map<String, dynamic> expenseData) async {
    final db = await database;
    final id = LocalDatabaseService.generateId();
    final now = LocalDatabaseService.getCurrentTimestamp();
    
    final data = Map<String, dynamic>.from(expenseData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;
    
    await db.insert('expenses', data);
    return id;
  }

  Future<void> updateExpense(String expenseId, Map<String, dynamic> expenseData) async {
    final db = await database;
    final data = Map<String, dynamic>.from(expenseData);
    data['updated_at'] = LocalDatabaseService.getCurrentTimestamp();
    
    await db.update(
      'expenses',
      data,
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  Future<List<Map<String, dynamic>>> getExpensesByProject(String userId, String projectId) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'user_id = ? AND project_id = ?',
      whereArgs: [userId, projectId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getExpensesByClient(String userId, String clientId) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'user_id = ? AND client_id = ?',
      whereArgs: [userId, clientId],
      orderBy: 'created_at DESC',
    );
  }

  // Invoice management methods
  Future<List<Map<String, dynamic>>> getInvoices(String userId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createInvoice(String userId, Map<String, dynamic> invoiceData) async {
    final db = await database;
    final id = LocalDatabaseService.generateId();
    final now = LocalDatabaseService.getCurrentTimestamp();
    
    final data = Map<String, dynamic>.from(invoiceData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;
    
    await db.insert('invoices', data);
    return id;
  }

  Future<void> updateInvoice(String invoiceId, Map<String, dynamic> invoiceData) async {
    final db = await database;
    final data = Map<String, dynamic>.from(invoiceData);
    data['updated_at'] = LocalDatabaseService.getCurrentTimestamp();
    
    await db.update(
      'invoices',
      data,
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<void> deleteInvoice(String invoiceId) async {
    final db = await database;
    await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    final db = await database;
    final result = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getInvoicesByProject(String userId, String projectId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'user_id = ? AND project_id = ?',
      whereArgs: [userId, projectId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getInvoicesByClient(String userId, String clientId) async {
    final db = await database;
    return await db.query(
      'invoices',
      where: 'user_id = ? AND client_id = ?',
      whereArgs: [userId, clientId],
      orderBy: 'created_at DESC',
    );
  }

  // Tax management methods
  Future<List<Map<String, dynamic>>> getTaxPayments(String userId) async {
    final db = await database;
    return await db.query(
      'tax_payments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<String> createTaxPayment(String userId, Map<String, dynamic> taxPaymentData) async {
    final db = await database;
    final id = LocalDatabaseService.generateId();
    final now = LocalDatabaseService.getCurrentTimestamp();
    
    final data = Map<String, dynamic>.from(taxPaymentData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;
    
    await db.insert('tax_payments', data);
    return id;
  }

  Future<void> updateTaxPayment(String taxPaymentId, Map<String, dynamic> taxPaymentData) async {
    final db = await database;
    final data = Map<String, dynamic>.from(taxPaymentData);
    data['updated_at'] = LocalDatabaseService.getCurrentTimestamp();
    
    await db.update(
      'tax_payments',
      data,
      where: 'id = ?',
      whereArgs: [taxPaymentId],
    );
  }

  Future<void> deleteTaxPayment(String taxPaymentId) async {
    final db = await database;
    await db.delete(
      'tax_payments',
      where: 'id = ?',
      whereArgs: [taxPaymentId],
    );
  }

  Future<List<Map<String, dynamic>>> getTaxPaymentsByYear(String userId, int year) async {
    final db = await database;
    return await db.query(
      'tax_payments',
      where: 'user_id = ? AND year = ?',
      whereArgs: [userId, year],
      orderBy: 'created_at DESC',
    );
  }

  // Tax calculation methods
  Future<List<Map<String, dynamic>>> getTaxCalculations(String userId) async {
    final db = await database;
    return await db.query(
      'tax_calculations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'year DESC',
    );
  }

  Future<String> createTaxCalculation(String userId, Map<String, dynamic> calculationData) async {
    final db = await database;
    final id = LocalDatabaseService.generateId();
    final now = LocalDatabaseService.getCurrentTimestamp();
    
    final data = Map<String, dynamic>.from(calculationData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;
    
    await db.insert('tax_calculations', data);
    return id;
  }

  Future<Map<String, dynamic>?> getTaxCalculationByYear(String userId, int year) async {
    final db = await database;
    final result = await db.query(
      'tax_calculations',
      where: 'user_id = ? AND year = ?',
      whereArgs: [userId, year],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Calendar events methods
  Future<List<Map<String, dynamic>>> getCalendarEvents(String userId) async {
    final db = await database;
    return await db.query(
      'calendar_events',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_date ASC',
    );
  }

  Future<String> createCalendarEvent(String userId, Map<String, dynamic> eventData) async {
    final db = await database;
    final id = LocalDatabaseService.generateId();
    final now = LocalDatabaseService.getCurrentTimestamp();
    
    final data = Map<String, dynamic>.from(eventData);
    data['id'] = id;
    data['user_id'] = userId;
    data['created_at'] = now;
    
    await db.insert('calendar_events', data);
    return id;
  }

  Future<void> updateCalendarEvent(String eventId, Map<String, dynamic> eventData) async {
    final db = await database;
    final data = Map<String, dynamic>.from(eventData);
    data['updated_at'] = LocalDatabaseService.getCurrentTimestamp();
    
    await db.update(
      'calendar_events',
      data,
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    final db = await database;
    await db.delete(
      'calendar_events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<List<Map<String, dynamic>>> getCalendarEventsByDate(String userId, String date) async {
    final db = await database;
    return await db.query(
      'calendar_events',
      where: 'user_id = ? AND DATE(start_date) = DATE(?)',
      whereArgs: [userId, date],
      orderBy: 'start_date ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getCalendarEventsByDateRange(String userId, String startDate, String endDate) async {
    final db = await database;
    return await db.query(
      'calendar_events',
      where: 'user_id = ? AND start_date >= ? AND start_date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'start_date ASC',
    );
  }
}
