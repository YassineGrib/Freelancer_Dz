import '../models/payment_model.dart';
import 'local_database_service.dart';
import 'auth_service.dart';

class PaymentService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;

  static String? get _userId => AuthService.currentUser?['id'];

  static Future<List<PaymentModel>> getPayments() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final paymentsData = await _db.getPayments(_userId!);
      final payments = <PaymentModel>[];

      for (final paymentData in paymentsData) {
        try {
          // Create a mutable copy of the payment data
          final mutablePaymentData = Map<String, dynamic>.from(paymentData);

          final clientData = await _db.getClientById(paymentData['client_id']);
          if (clientData != null) {
            mutablePaymentData['clients'] = clientData;
          }

          if (paymentData['project_id'] != null) {
            final projectData = await _db.getProjectById(paymentData['project_id']);
            if (projectData != null) {
              mutablePaymentData['projects'] = projectData;
            }
          }

          final paymentModel = PaymentModel.fromJson(mutablePaymentData);
          payments.add(paymentModel);
        } catch (e) {
          print('Error processing payment ${paymentData['id']}: $e');
          // Continue with next payment
        }
      }

      return payments;
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  static Future<List<PaymentModel>> getPaymentsByProject(String projectId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final paymentsData = await _db.getPaymentsByProject(_userId!, projectId);
      final payments = <PaymentModel>[];

      for (final paymentData in paymentsData) {
        // Create a mutable copy of the payment data
        final mutablePaymentData = Map<String, dynamic>.from(paymentData);

        final clientData = await _db.getClientById(paymentData['client_id']);
        if (clientData != null) {
          mutablePaymentData['clients'] = clientData;
        }

        final projectData = await _db.getProjectById(paymentData['project_id']);
        if (projectData != null) {
          mutablePaymentData['projects'] = projectData;
        }

        payments.add(PaymentModel.fromJson(mutablePaymentData));
      }

      return payments;
    } catch (e) {
      throw Exception('Failed to fetch project payments: $e');
    }
  }

  static Future<List<PaymentModel>> getPaymentsByClient(String clientId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final paymentsData = await _db.getPaymentsByClient(_userId!, clientId);
      final payments = <PaymentModel>[];

      for (final paymentData in paymentsData) {
        // Create a mutable copy of the payment data
        final mutablePaymentData = Map<String, dynamic>.from(paymentData);

        final clientData = await _db.getClientById(paymentData['client_id']);
        if (clientData != null) {
          mutablePaymentData['clients'] = clientData;
        }

        if (paymentData['project_id'] != null) {
          final projectData = await _db.getProjectById(paymentData['project_id']);
          if (projectData != null) {
            mutablePaymentData['projects'] = projectData;
          }
        }

        payments.add(PaymentModel.fromJson(mutablePaymentData));
      }

      return payments;
    } catch (e) {
      throw Exception('Failed to fetch client payments: $e');
    }
  }

  static Future<PaymentModel> addPayment(PaymentModel payment) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final paymentData = payment.toJson();
      paymentData.remove('id');

      final paymentId = await _db.createPayment(_userId!, paymentData);

      final createdPayment = await getPaymentById(paymentId);
      if (createdPayment == null) {
        throw Exception('Failed to retrieve created payment');
      }

      return createdPayment;
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  static Future<PaymentModel> updatePayment(PaymentModel payment) async {
    try {
      print('✏️ UPDATE DEBUG: Starting updatePayment for ID: ${payment.id}');
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      if (payment.id == null) {
        throw Exception('Payment ID is required for update');
      }

      print('✏️ UPDATE DEBUG: Converting payment to JSON');
      final paymentData = payment.toJson();
      paymentData.remove('clients');
      paymentData.remove('projects');
      print('✏️ UPDATE DEBUG: Payment data keys: ${paymentData.keys.toList()}');

      print('✏️ UPDATE DEBUG: Calling database updatePayment');
      await _db.updatePayment(payment.id!, paymentData);
      print('✏️ UPDATE DEBUG: Database update completed');

      print('✏️ UPDATE DEBUG: Retrieving updated payment');
      final updatedPayment = await getPaymentById(payment.id!);
      if (updatedPayment == null) {
        throw Exception('Failed to retrieve updated payment');
      }

      print('✏️ UPDATE DEBUG: Update successful');
      return updatedPayment;
    } catch (e) {
      print('✏️ UPDATE DEBUG: Error in updatePayment: $e');
      throw Exception('Failed to update payment: $e');
    }
  }

  static Future<void> deletePayment(String paymentId) async {
    try {
      await _db.deletePayment(paymentId);
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  static Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final paymentData = await _db.getPaymentById(paymentId);
      if (paymentData == null) return null;

      // Create a mutable copy of the payment data
      final mutablePaymentData = Map<String, dynamic>.from(paymentData);

      final clientData = await _db.getClientById(paymentData['client_id']);
      if (clientData != null) {
        mutablePaymentData['clients'] = clientData;
      }

      if (paymentData['project_id'] != null) {
        final projectData = await _db.getProjectById(paymentData['project_id']);
        if (projectData != null) {
          mutablePaymentData['projects'] = projectData;
        }
      }

      return PaymentModel.fromJson(mutablePaymentData);
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  static Future<PaymentModel> changePaymentStatus(String paymentId, PaymentStatus status) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      final updatedPayment = payment.copyWith(
        paymentStatus: status,
        paymentDate: status == PaymentStatus.completed ? DateTime.now() : payment.paymentDate,
      );

      return await updatePayment(updatedPayment);
    } catch (e) {
      throw Exception('Failed to change payment status: $e');
    }
  }

  static Future<Map<String, dynamic>> getProjectPaymentStats(String projectId) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final payments = await getPaymentsByProject(projectId);

      double totalPaid = 0.0;
      double totalPending = 0.0;
      int completedPayments = 0;
      int pendingPayments = 0;
      String currency = 'DA';

      for (final payment in payments) {
        if (payment.paymentStatus == PaymentStatus.completed) {
          totalPaid += payment.paymentAmount;
          completedPayments++;
        } else if (payment.paymentStatus == PaymentStatus.pending) {
          totalPending += payment.paymentAmount;
          pendingPayments++;
        }
        currency = payment.currency.name.toUpperCase();
      }

      return {
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'totalPayments': payments.length,
        'currency': currency,
      };
    } catch (e) {
      throw Exception('Failed to get project payment stats: $e');
    }
  }

  static Future<Map<String, dynamic>> getOverallPaymentStats() async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      final payments = await getPayments();

      double totalPaid = 0.0;
      double totalPending = 0.0;
      double totalFailed = 0.0;
      int completedPayments = 0;
      int pendingPayments = 0;
      int failedPayments = 0;
      Map<String, double> currencyTotals = {};

      for (final payment in payments) {
        final currencyKey = payment.currency.name.toUpperCase();

        switch (payment.paymentStatus) {
          case PaymentStatus.completed:
            totalPaid += payment.paymentAmount;
            completedPayments++;
            currencyTotals[currencyKey] = (currencyTotals[currencyKey] ?? 0.0) + payment.paymentAmount;
            break;
          case PaymentStatus.pending:
            totalPending += payment.paymentAmount;
            pendingPayments++;
            break;
          case PaymentStatus.failed:
            totalFailed += payment.paymentAmount;
            failedPayments++;
            break;
          case PaymentStatus.cancelled:
          case PaymentStatus.refunded:
          case PaymentStatus.partial:
            break;
        }
      }

      return {
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'totalFailed': totalFailed,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'totalPayments': payments.length,
        'currencyTotals': currencyTotals,
      };
    } catch (e) {
      throw Exception('Failed to get payment statistics: $e');
    }
  }
}
