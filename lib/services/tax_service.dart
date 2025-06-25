import '../models/tax_model.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import 'local_database_service.dart';
import 'local_database_extensions.dart';
import 'auth_service.dart';

class TaxService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;

  static String? get _userId => AuthService.currentUser?["id"];

  static Future<List<TaxPaymentModel>> getAllTaxPayments() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final taxPaymentsData = await _db.getTaxPayments(_userId!);
      final taxPayments = <TaxPaymentModel>[];

      for (final taxPaymentData in taxPaymentsData) {
        taxPayments.add(TaxPaymentModel.fromJson(taxPaymentData));
      }

      return taxPayments;
    } catch (e) {
      throw Exception("Failed to fetch tax payments: $e");
    }
  }

  static Future<List<TaxPaymentModel>> getTaxPaymentsByYear(int year) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final taxPaymentsData = await _db.getTaxPaymentsByYear(_userId!, year);
      final taxPayments = <TaxPaymentModel>[];

      for (final taxPaymentData in taxPaymentsData) {
        taxPayments.add(TaxPaymentModel.fromJson(taxPaymentData));
      }

      return taxPayments;
    } catch (e) {
      throw Exception("Failed to fetch tax payments by year: $e");
    }
  }

  static Future<TaxPaymentModel?> getTaxPaymentById(String paymentId) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final taxPaymentData = await _db.getTaxPaymentById(paymentId);
      if (taxPaymentData == null) {
        return null;
      }

      return TaxPaymentModel.fromJson(taxPaymentData);
    } catch (e) {
      throw Exception("Failed to fetch tax payment: $e");
    }
  }

  static TaxCalculationModel calculateTotalTaxes(double annualIncome, int year) {
    // Algerian Tax Rules Implementation
    final double irgAmount = annualIncome < 2000000 ? 10000 : annualIncome * 0.005;
    const double casnosAmount = 24000;
    final double totalTax = irgAmount + casnosAmount;

    return TaxCalculationModel(
      annualIncome: annualIncome,
      totalTaxes: totalTax,
      year: year,
      irgAmount: irgAmount,
      casnosAmount: casnosAmount,
      calculationMethod: 'Algerian Tax Rules',
      calculatedAt: DateTime.now()
    );
  }

  static Future<List<TaxPaymentModel>> getUpcomingTaxPayments() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final allPayments = await getAllTaxPayments();
      final now = DateTime.now();

      return allPayments
          .where((payment) =>
              payment.status == TaxStatus.pending &&
              payment.dueDate.isAfter(now))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch upcoming tax payments: $e");
    }
  }

  static Future<List<TaxPaymentModel>> getOverdueTaxPayments() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final allPayments = await getAllTaxPayments();
      final now = DateTime.now();

      return allPayments
          .where((payment) =>
              payment.status == TaxStatus.pending &&
              payment.dueDate.isBefore(now))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch overdue tax payments: $e");
    }
  }

  static Future<double> calculateAnnualIncomeFromPayments(int year) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final paymentsData = await _db.getPayments(_userId!);
      double totalIncome = 0.0;

      for (final paymentData in paymentsData) {
        try {
          final paymentDate = DateTime.parse(
              paymentData["payment_date"] ?? paymentData["created_at"]);
          if (paymentDate.year == year &&
              paymentData["payment_status"] == "completed") {
            // Use the correct column name and handle null values
            final amount = paymentData["payment_amount"];
            if (amount != null) {
              totalIncome += (amount as num).toDouble();
            }
          }
        } catch (e) {
          print('Error processing payment data: $e');
          print('Payment data: $paymentData');
          // Continue processing other payments instead of failing completely
          continue;
        }
      }

      return totalIncome;
    } catch (e) {
      throw Exception("Failed to calculate annual income: $e");
    }
  }

  static Future<TaxCalculationModel> calculateTaxesFromPayments(
      int year) async {
    try {
      final annualIncome = await calculateAnnualIncomeFromPayments(year);
      return calculateTotalTaxes(annualIncome, year);
    } catch (e) {
      throw Exception("Failed to calculate taxes from payments: $e");
    }
  }


  static Future<void> saveTaxCalculation(
      TaxCalculationModel calculation) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final calculationData = calculation.toJson();
      await _db.createTaxCalculation(_userId!, calculationData);
    } catch (e) {
      throw Exception("Failed to save tax calculation: $e");
    }
  }

  static Future<void> generateTaxPaymentsForYear(
      int year, TaxCalculationModel calculation) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      // Generate a single IRG payment for the year
      if (calculation.irgAmount > 0) {
        // Due date: January 20th of the next year
        final dueDate = DateTime(year + 1, 1, 20);

        final irgPayment = {
          "type": "irg",
          "year": year,
          "amount": calculation.irgAmount,
          "status": "pending",
          "due_date": dueDate.toIso8601String(),
        };

        await _db.createTaxPayment(_userId!, irgPayment);
      }

      // Generate a single CASNOS payment for the year
      if (calculation.casnosAmount > 0) {
        // Due date: June 20th of the calculation year
        final dueDate = DateTime(year, 6, 20);

        final casnosPayment = {
          "type": "casnos",
          "year": year,
          "amount": calculation.casnosAmount,
          "status": "pending",
          "due_date": dueDate.toIso8601String(),
        };

        await _db.createTaxPayment(_userId!, casnosPayment);
      }
    } catch (e) {
      throw Exception("Failed to generate tax payments: $e");
    }
  }

  static Future<void> markTaxPaymentAsPaid(
      String paymentId, String paymentMethod,
      {String? notes}) async {
    try {
      // Get the tax payment details before updating
      final taxPayment = await getTaxPaymentById(paymentId);
      if (taxPayment == null) {
        throw Exception("Tax payment not found");
      }

      final paymentData = {
        "status": "paid",
        "paid_date": DateTime.now().toIso8601String(),
        "payment_method": paymentMethod,
        "notes": notes,
      };

      await _db.updateTaxPayment(paymentId, paymentData);

      // Automatically create an expense entry for this tax payment
      await _createTaxExpense(taxPayment, paymentMethod, notes);
    } catch (e) {
      throw Exception("Failed to mark tax payment as paid: $e");
    }
  }

  static Future<void> deleteTaxPayment(String paymentId) async {
    try {
      await _db.deleteTaxPayment(paymentId);
    } catch (e) {
      throw Exception("Failed to delete tax payment: $e");
    }
  }

  static Future<Map<String, dynamic>> getTaxStatistics() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final allPayments = await getAllTaxPayments();
      final currentYear = DateTime.now().year;
      final currentYearPayments =
          allPayments.where((p) => p.year == currentYear).toList();

      int paidPayments = 0;
      int overduePayments = 0;
      double totalPaidAmount = 0.0;
      double totalPendingAmount = 0.0;

      for (final payment in allPayments) {
        if (payment.status == TaxStatus.paid) {
          paidPayments++;
          totalPaidAmount += payment.amount;
        } else if (payment.isOverdue) {
          overduePayments++;
          totalPendingAmount += payment.amount;
        } else if (payment.status == TaxStatus.pending) {
          totalPendingAmount += payment.amount;
        }
      }

      return {
        "total_payments": allPayments.length,
        "current_year_payments": currentYearPayments.length,
        "paid_payments": paidPayments,
        "overdue_payments": overduePayments,
        "total_paid_amount": totalPaidAmount,
        "total_pending_amount": totalPendingAmount,
      };
    } catch (e) {
      throw Exception("Failed to get tax statistics: $e");
    }
  }

  /// Creates an expense entry for a tax payment
  static Future<void> _createTaxExpense(TaxPaymentModel taxPayment, String paymentMethod, String? notes) async {
    try {
      // Create expense entry
      final expense = ExpenseModel(
        title: '${taxPayment.type.displayName} - ${taxPayment.year}',
        description: 'Tax payment for ${taxPayment.type.fullName} (${taxPayment.year})',
        amount: taxPayment.amount,
        currency: Currency.da,
        category: ExpenseCategory.tax,
        paymentMethod: _mapPaymentMethod(paymentMethod),
        expenseDate: DateTime.now(),
        vendor: 'Government Tax Authority',
        notes: notes ?? 'Automatically created from tax payment',
        isReimbursable: false,
        isRecurring: false,
        createdAt: DateTime.now(),
      );

      await ExpenseService.addExpense(expense);
    } catch (e) {
      // Log the error but don't fail the tax payment marking
      // Note: Tax payment will still be marked as paid even if expense creation fails
    }
  }

  /// Maps tax payment method to expense payment method
  static PaymentMethod _mapPaymentMethod(String paymentMethod) {
    switch (paymentMethod) {
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'cash':
        return PaymentMethod.cash;
      case 'check':
        return PaymentMethod.other; // Map check to other since it doesn't exist
      case 'ccp':
        return PaymentMethod.ccp;
      default:
        return PaymentMethod.cash;
    }
  }


}
