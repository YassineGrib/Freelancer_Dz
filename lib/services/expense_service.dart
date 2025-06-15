import '../models/expense_model.dart';
import 'local_database_service.dart';
import 'local_database_extensions.dart';
import 'auth_service.dart';

class ExpenseService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;

  static String? get _userId => AuthService.currentUser?["id"];

  static Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final expensesData = await _db.getExpenses(_userId!);
      final expenses = <ExpenseModel>[];

      for (final expenseData in expensesData) {
        if (expenseData["client_id"] != null) {
          final clientData = await _db.getClientById(expenseData["client_id"]);
          if (clientData != null) {
            expenseData["clients"] = clientData;
          }
        }

        if (expenseData["project_id"] != null) {
          final projectData = await _db.getProjectById(expenseData["project_id"]);
          if (projectData != null) {
            expenseData["projects"] = projectData;
          }
        }

        expenses.add(ExpenseModel.fromJson(expenseData));
      }

      return expenses;
    } catch (e) {
      throw Exception("Failed to fetch expenses: $e");
    }
  }

  static Future<List<ExpenseModel>> getExpensesByProject(String projectId) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final expensesData = await _db.getExpensesByProject(_userId!, projectId);
      final expenses = <ExpenseModel>[];

      for (final expenseData in expensesData) {
        if (expenseData["client_id"] != null) {
          final clientData = await _db.getClientById(expenseData["client_id"]);
          if (clientData != null) {
            expenseData["clients"] = clientData;
          }
        }

        final projectData = await _db.getProjectById(expenseData["project_id"]);
        if (projectData != null) {
          expenseData["projects"] = projectData;
        }

        expenses.add(ExpenseModel.fromJson(expenseData));
      }

      return expenses;
    } catch (e) {
      throw Exception("Failed to fetch project expenses: $e");
    }
  }

  static Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final expenseData = expense.toJson();
      expenseData.remove("id");

      final expenseId = await _db.createExpense(_userId!, expenseData);

      final createdExpenseData = await _db.database.then((db) => db.query(
        "expenses",
        where: "id = ?",
        whereArgs: [expenseId],
        limit: 1,
      ));

      if (createdExpenseData.isEmpty) {
        throw Exception("Failed to retrieve created expense");
      }

      final expenseDataWithRelations = createdExpenseData.first;

      if (expenseDataWithRelations["client_id"] != null) {
        final clientData = await _db.getClientById(expenseDataWithRelations["client_id"].toString());
        if (clientData != null) {
          expenseDataWithRelations["clients"] = clientData;
        }
      }

      if (expenseDataWithRelations["project_id"] != null) {
        final projectData = await _db.getProjectById(expenseDataWithRelations["project_id"].toString());
        if (projectData != null) {
          expenseDataWithRelations["projects"] = projectData;
        }
      }

      return ExpenseModel.fromJson(expenseDataWithRelations);
    } catch (e) {
      throw Exception("Failed to create expense: $e");
    }
  }

  static Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      if (expense.id == null) {
        throw Exception("Expense ID is required for update");
      }

      final expenseData = expense.toJson();
      expenseData.remove("clients");
      expenseData.remove("projects");

      await _db.updateExpense(expense.id!, expenseData);

      final updatedExpenseData = await _db.database.then((db) => db.query(
        "expenses",
        where: "id = ?",
        whereArgs: [expense.id],
        limit: 1,
      ));

      if (updatedExpenseData.isEmpty) {
        throw Exception("Failed to retrieve updated expense");
      }

      final expenseDataWithRelations = updatedExpenseData.first;

      if (expenseDataWithRelations["client_id"] != null) {
        final clientData = await _db.getClientById(expenseDataWithRelations["client_id"].toString());
        if (clientData != null) {
          expenseDataWithRelations["clients"] = clientData;
        }
      }

      if (expenseDataWithRelations["project_id"] != null) {
        final projectData = await _db.getProjectById(expenseDataWithRelations["project_id"].toString());
        if (projectData != null) {
          expenseDataWithRelations["projects"] = projectData;
        }
      }

      return ExpenseModel.fromJson(expenseDataWithRelations);
    } catch (e) {
      throw Exception("Failed to update expense: $e");
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    try {
      await _db.deleteExpense(expenseId);
    } catch (e) {
      throw Exception("Failed to delete expense: $e");
    }
  }

  static Future<double> getTotalExpensesForProject(String projectId) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final expenses = await getExpensesByProject(projectId);
      double total = 0.0;

      for (final expense in expenses) {
        total += expense.amount;
      }

      return total;
    } catch (e) {
      throw Exception("Failed to calculate project expenses: $e");
    }
  }

  static Future<double> getTotalExpensesForClient(String clientId) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final expensesData = await _db.getExpensesByClient(_userId!, clientId);
      double total = 0.0;

      for (final expenseData in expensesData) {
        total += (expenseData["amount"] as num).toDouble();
      }

      return total;
    } catch (e) {
      throw Exception("Failed to calculate client expenses: $e");
    }
  }
}
