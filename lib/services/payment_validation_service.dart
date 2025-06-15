import '../models/payment_model.dart';
import 'payment_service.dart';
import 'project_service.dart';

/// Validation result class
class PaymentValidationResult {
  final bool isValid;
  final String? errorMessage;
  final double? maxAllowedAmount;
  final double? currentCompletedTotal;
  final double? projectTotalValue;

  PaymentValidationResult({
    required this.isValid,
    this.errorMessage,
    this.maxAllowedAmount,
    this.currentCompletedTotal,
    this.projectTotalValue,
  });

  PaymentValidationResult.valid() :
    isValid = true,
    errorMessage = null,
    maxAllowedAmount = null,
    currentCompletedTotal = null,
    projectTotalValue = null;

  PaymentValidationResult.invalid({
    required String error,
    double? maxAllowed,
    double? completedTotal,
    double? projectTotal,
  }) :
    isValid = false,
    errorMessage = error,
    maxAllowedAmount = maxAllowed,
    currentCompletedTotal = completedTotal,
    projectTotalValue = projectTotal;
}

/// Comprehensive payment validation service to ensure payment integrity
class PaymentValidationService {

  /// Calculate total completed payments for a project (excluding a specific payment if provided)
  static Future<double> _calculateCompletedPaymentsTotal(
    String projectId, {
    String? excludePaymentId,
  }) async {
    try {
      final payments = await PaymentService.getPaymentsByProject(projectId);

      double total = 0.0;
      for (final payment in payments) {
        // Skip the payment being excluded (useful for edit scenarios)
        if (excludePaymentId != null && payment.id == excludePaymentId) {
          continue;
        }

        // Only count completed payments
        if (payment.paymentStatus == PaymentStatus.completed) {
          total += payment.paymentAmount;
        }
      }

      return total;
    } catch (e) {
      throw Exception('Failed to calculate completed payments total: $e');
    }
  }

  /// Get project total value
  static Future<double?> _getProjectTotalValue(String projectId) async {
    try {
      final project = await ProjectService.getProjectById(projectId);
      return project?.totalValue;
    } catch (e) {
      throw Exception('Failed to get project total value: $e');
    }
  }

  /// Validate payment creation
  static Future<PaymentValidationResult> validatePaymentCreation({
    required String projectId,
    required double paymentAmount,
    required PaymentStatus paymentStatus,
  }) async {
    try {
      // Get project total value
      final projectTotalValue = await _getProjectTotalValue(projectId);
      if (projectTotalValue == null || projectTotalValue <= 0) {
        return PaymentValidationResult.invalid(
          error: 'Project total value is not set or invalid',
        );
      }

      // If the new payment is not completed, no need to validate against total
      if (paymentStatus != PaymentStatus.completed) {
        return PaymentValidationResult.valid();
      }

      // Calculate current completed payments total
      final currentCompletedTotal = await _calculateCompletedPaymentsTotal(projectId);

      // Check if adding this payment would exceed project total
      final newTotal = currentCompletedTotal + paymentAmount;
      if (newTotal > projectTotalValue) {
        final maxAllowed = projectTotalValue - currentCompletedTotal;
        return PaymentValidationResult.invalid(
          error: 'Payment amount would exceed project total value.\n'
                 'Project Total: ${projectTotalValue.toStringAsFixed(2)}\n'
                 'Already Completed: ${currentCompletedTotal.toStringAsFixed(2)}\n'
                 'Maximum Allowed: ${maxAllowed.toStringAsFixed(2)}',
          maxAllowed: maxAllowed,
          completedTotal: currentCompletedTotal,
          projectTotal: projectTotalValue,
        );
      }

      return PaymentValidationResult.valid();
    } catch (e) {
      return PaymentValidationResult.invalid(
        error: 'Validation failed: $e',
      );
    }
  }

  /// Validate payment editing
  static Future<PaymentValidationResult> validatePaymentEdit({
    required String paymentId,
    required String projectId,
    required double newPaymentAmount,
    required PaymentStatus newPaymentStatus,
  }) async {
    try {
      // Get project total value
      final projectTotalValue = await _getProjectTotalValue(projectId);
      if (projectTotalValue == null || projectTotalValue <= 0) {
        return PaymentValidationResult.invalid(
          error: 'Project total value is not set or invalid',
        );
      }

      // If the edited payment is not completed, no need to validate against total
      if (newPaymentStatus != PaymentStatus.completed) {
        return PaymentValidationResult.valid();
      }

      // Calculate current completed payments total (excluding the payment being edited)
      final currentCompletedTotal = await _calculateCompletedPaymentsTotal(
        projectId,
        excludePaymentId: paymentId,
      );

      // Check if the edited payment would exceed project total
      final newTotal = currentCompletedTotal + newPaymentAmount;
      if (newTotal > projectTotalValue) {
        final maxAllowed = projectTotalValue - currentCompletedTotal;
        return PaymentValidationResult.invalid(
          error: 'Edited payment amount would exceed project total value.\n'
                 'Project Total: ${projectTotalValue.toStringAsFixed(2)}\n'
                 'Other Completed Payments: ${currentCompletedTotal.toStringAsFixed(2)}\n'
                 'Maximum Allowed for this Payment: ${maxAllowed.toStringAsFixed(2)}',
          maxAllowed: maxAllowed,
          completedTotal: currentCompletedTotal,
          projectTotal: projectTotalValue,
        );
      }

      return PaymentValidationResult.valid();
    } catch (e) {
      return PaymentValidationResult.invalid(
        error: 'Validation failed: $e',
      );
    }
  }

  /// Validate payment status change
  static Future<PaymentValidationResult> validateStatusChange({
    required String paymentId,
    required String projectId,
    required double paymentAmount,
    required PaymentStatus currentStatus,
    required PaymentStatus newStatus,
  }) async {
    try {
      // If changing from completed to something else, or to non-completed status, allow it
      if (currentStatus == PaymentStatus.completed || newStatus != PaymentStatus.completed) {
        return PaymentValidationResult.valid();
      }

      // If changing TO completed status, validate against project total
      return await validatePaymentEdit(
        paymentId: paymentId,
        projectId: projectId,
        newPaymentAmount: paymentAmount,
        newPaymentStatus: newStatus,
      );
    } catch (e) {
      return PaymentValidationResult.invalid(
        error: 'Status change validation failed: $e',
      );
    }
  }

  /// Get payment summary for a project
  static Future<Map<String, dynamic>> getProjectPaymentSummary(String projectId) async {
    try {
      final projectTotalValue = await _getProjectTotalValue(projectId);
      final completedTotal = await _calculateCompletedPaymentsTotal(projectId);
      final payments = await PaymentService.getPaymentsByProject(projectId);

      double pendingTotal = 0.0;
      int completedCount = 0;
      int pendingCount = 0;

      for (final payment in payments) {
        if (payment.paymentStatus == PaymentStatus.completed) {
          completedCount++;
        } else if (payment.paymentStatus == PaymentStatus.pending) {
          pendingTotal += payment.paymentAmount;
          pendingCount++;
        }
      }

      final remainingAmount = (projectTotalValue ?? 0.0) - completedTotal;
      final paymentProgress = projectTotalValue != null && projectTotalValue > 0
          ? (completedTotal / projectTotalValue) * 100
          : 0.0;

      return {
        'projectTotalValue': projectTotalValue,
        'completedTotal': completedTotal,
        'pendingTotal': pendingTotal,
        'remainingAmount': remainingAmount,
        'paymentProgress': paymentProgress,
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'totalPayments': payments.length,
      };
    } catch (e) {
      throw Exception('Failed to get project payment summary: $e');
    }
  }
}

