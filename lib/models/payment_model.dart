import 'package:freelancer_mobile/models/project_model.dart';
import 'package:freelancer_mobile/models/client_model.dart';

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded,
  partial,
}

enum PaymentType {
  full,
  partial,
  advance,
  milestone,
  finalPayment,
}

enum PaymentMethod {
  cash,
  bankTransfer,
  ccp,
  creditCard,
  debitCard,
  paypal,
  stripe,
  crypto,
  check,
  other,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partial:
        return 'Partial';
    }
  }

  String get arabicName {
    switch (this) {
      case PaymentStatus.pending:
        return 'في الانتظار';
      case PaymentStatus.completed:
        return 'مكتمل';
      case PaymentStatus.failed:
        return 'فاشل';
      case PaymentStatus.cancelled:
        return 'ملغي';
      case PaymentStatus.refunded:
        return 'مسترد';
      case PaymentStatus.partial:
        return 'جزئي';
    }
  }
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.full:
        return 'Full Payment';
      case PaymentType.partial:
        return 'Partial Payment';
      case PaymentType.advance:
        return 'Advance Payment';
      case PaymentType.milestone:
        return 'Milestone Payment';
      case PaymentType.finalPayment:
        return 'Final Payment';
    }
  }

  String get arabicName {
    switch (this) {
      case PaymentType.full:
        return 'دفعة كاملة';
      case PaymentType.partial:
        return 'دفعة جزئية';
      case PaymentType.advance:
        return 'دفعة مقدمة';
      case PaymentType.milestone:
        return 'دفعة مرحلية';
      case PaymentType.finalPayment:
        return 'دفعة نهائية';
    }
  }

  /// Get suggested payment type based on amount and project total
  static PaymentType getSuggestedPaymentType(
      double paymentAmount, double projectTotal) {
    if (paymentAmount >= projectTotal) {
      return PaymentType.full;
    } else if (paymentAmount <= projectTotal * 0.3) {
      return PaymentType.advance;
    } else {
      return PaymentType.partial;
    }
  }

  /// Get available payment types for smart selection
  static List<PaymentType> getAvailablePaymentTypes(
      double paymentAmount, double projectTotal) {
    List<PaymentType> availableTypes = [];

    if (paymentAmount >= projectTotal) {
      availableTypes.add(PaymentType.full);
    } else {
      availableTypes.addAll([
        PaymentType.partial,
        PaymentType.advance,
        PaymentType.milestone,
      ]);
    }

    return availableTypes;
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.ccp:
        return 'CCP Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.crypto:
        return 'Cryptocurrency';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get arabicName {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدي';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.ccp:
        return 'تحويل CCP';
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
      case PaymentMethod.debitCard:
        return 'بطاقة خصم';
      case PaymentMethod.paypal:
        return 'باي بال';
      case PaymentMethod.stripe:
        return 'سترايب';
      case PaymentMethod.crypto:
        return 'عملة رقمية';
      case PaymentMethod.check:
        return 'شيك';
      case PaymentMethod.other:
        return 'أخرى';
    }
  }

  /// Get available payment methods based on currency
  static List<PaymentMethod> getAvailableMethodsForCurrency(Currency currency) {
    if (currency == Currency.da) {
      // Algerian Dinar - Local payment methods
      return [
        PaymentMethod.cash,
        PaymentMethod.bankTransfer,
        PaymentMethod.ccp,
      ];
    } else {
      // Foreign currencies (USD, EUR) - International payment methods
      return [
        PaymentMethod.creditCard,
        PaymentMethod.debitCard,
        PaymentMethod.paypal,
      ];
    }
  }

  /// Check if payment method is available for currency
  bool isAvailableForCurrency(Currency currency) {
    return PaymentMethodExtension.getAvailableMethodsForCurrency(currency)
        .contains(this);
  }
}

class PaymentModel {
  final String? id;
  final String projectId;
  final String clientId;
  final double paymentAmount;
  final Currency currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final PaymentType paymentType;
  final DateTime paymentDate;
  final DateTime? dueDate;
  final String? referenceNumber;
  final String? description;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Related objects (populated when fetched with joins)
  final ProjectModel? project;
  final ClientModel? client;

  PaymentModel({
    this.id,
    required this.projectId,
    required this.clientId,
    required this.paymentAmount,
    this.currency = Currency.da,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.completed,
    this.paymentType = PaymentType.partial,
    DateTime? paymentDate,
    this.dueDate,
    this.referenceNumber,
    this.description,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.project,
    this.client,
  }) : paymentDate = paymentDate ?? DateTime.now();

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    try {
      ProjectModel? project;
      ClientModel? client;

      // Handle project data safely
      if (json['projects'] != null) {
        try {
          project =
              ProjectModel.fromJson(json['projects'] as Map<String, dynamic>);
        } catch (e) {
          print('Error processing project data: $e');
          project = null;
        }
      }

      // Handle client data safely
      if (json['clients'] != null) {
        try {
          client =
              ClientModel.fromJson(json['clients'] as Map<String, dynamic>);
        } catch (e) {
          print('Error processing client data: $e');
          client = null;
        }
      }

      return PaymentModel(
        id: json['id'] as String?,
        projectId: json['project_id'] as String? ?? '',
        clientId: json['client_id'] as String? ?? '',
        paymentAmount: (json['payment_amount'] as num?)?.toDouble() ?? 0.0,
        currency: Currency.values.firstWhere(
          (curr) => curr.code == (json['currency'] as String?),
          orElse: () => Currency.da,
        ),
        paymentMethod: PaymentMethod.values.firstWhere(
          (method) => method.name == (json['payment_method'] as String?),
          orElse: () => PaymentMethod.cash,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (status) => status.name == (json['payment_status'] as String?),
          orElse: () => PaymentStatus.pending,
        ),
        paymentType: PaymentType.values.firstWhere(
          (type) => type.name == (json['payment_type'] as String?),
          orElse: () => PaymentType.partial,
        ),
        paymentDate:
            json['payment_date'] != null && json['payment_date'] is String
                ? DateTime.parse(json['payment_date'] as String)
                : DateTime.now(),
        dueDate: json['due_date'] != null && json['due_date'] is String
            ? DateTime.parse(json['due_date'] as String)
            : null,
        referenceNumber: json['reference_number'] as String?,
        description: json['description'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null && json['created_at'] is String
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null && json['updated_at'] is String
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        // Related objects
        project: project,
        client: client,
      );
    } catch (e) {
      print('Error in PaymentModel.fromJson: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'client_id': clientId,
      'payment_amount': paymentAmount,
      'currency': currency.code,
      'payment_method': paymentMethod.name,
      'payment_status': paymentStatus.name,
      'payment_type': paymentType.name,
      'payment_date': paymentDate.toIso8601String().split('T')[0], // Date only
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? projectId,
    String? clientId,
    double? paymentAmount,
    Currency? currency,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    PaymentType? paymentType,
    DateTime? paymentDate,
    DateTime? dueDate,
    String? referenceNumber,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectModel? project,
    ClientModel? client,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentType: paymentType ?? this.paymentType,
      paymentDate: paymentDate ?? this.paymentDate,
      dueDate: dueDate ?? this.dueDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      project: project ?? this.project,
      client: client ?? this.client,
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, projectId: $projectId, clientId: $clientId, paymentAmount: $paymentAmount, currency: $currency, paymentMethod: $paymentMethod, paymentStatus: $paymentStatus, paymentType: $paymentType, paymentDate: $paymentDate, dueDate: $dueDate, referenceNumber: $referenceNumber, description: $description, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentModel &&
        other.id == id &&
        other.projectId == projectId &&
        other.clientId == clientId &&
        other.paymentAmount == paymentAmount &&
        other.currency == currency &&
        other.paymentMethod == paymentMethod &&
        other.paymentStatus == paymentStatus &&
        other.paymentType == paymentType &&
        other.paymentDate == paymentDate &&
        other.dueDate == dueDate &&
        other.referenceNumber == referenceNumber &&
        other.description == description &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        projectId.hashCode ^
        clientId.hashCode ^
        paymentAmount.hashCode ^
        currency.hashCode ^
        paymentMethod.hashCode ^
        paymentStatus.hashCode ^
        paymentType.hashCode ^
        paymentDate.hashCode ^
        dueDate.hashCode ^
        referenceNumber.hashCode ^
        description.hashCode ^
        notes.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
