import 'package:flutter/material.dart';

enum TaxType {
  irg, // Impôt sur le Revenu Global (IRG Simplifié)
  casnos, // Caisse Nationale de Sécurité Sociale des Non-Salariés
}

extension TaxTypeExtension on TaxType {
  String get displayName {
    switch (this) {
      case TaxType.irg:
        return 'IRG Simplifié';
      case TaxType.casnos:
        return 'CASNOS';
    }
  }

  String get englishName {
    switch (this) {
      case TaxType.irg:
        return 'Income Tax Simplified';
      case TaxType.casnos:
        return 'Social Security';
    }
  }

  String get fullName {
    switch (this) {
      case TaxType.irg:
        return 'Impôt sur le Revenu Global Simplifié';
      case TaxType.casnos:
        return 'Caisse Nationale de Sécurité Sociale des Non-Salariés';
    }
  }

  String get description {
    switch (this) {
      case TaxType.irg:
        return 'Annual income tax - Due before January 10';
      case TaxType.casnos:
        return 'Social security contribution - Due before June 20';
    }
  }

  IconData get icon {
    switch (this) {
      case TaxType.irg:
        return Icons.account_balance;
      case TaxType.casnos:
        return Icons.health_and_safety;
    }
  }

  Color get color {
    switch (this) {
      case TaxType.irg:
        return Colors.red;
      case TaxType.casnos:
        return Colors.blue;
    }
  }

  DateTime getDueDate(int year) {
    switch (this) {
      case TaxType.irg:
        return DateTime(year, 1, 10); // 10 janvier
      case TaxType.casnos:
        return DateTime(year, 6, 20); // 20 juin
    }
  }

  List<DateTime> getReminderDates(int year) {
    switch (this) {
      case TaxType.irg:
        return [
          DateTime(year, 1, 1), // 01 janvier (premier تنبيه)
          DateTime(year, 1, 8), // 08 janvier (تنبيه نهائي)
        ];
      case TaxType.casnos:
        return [
          DateTime(year, 6, 1), // 01 juin (premier تنبيه)
          DateTime(year, 6, 18), // 18 juin (تنبيه نهائي)
        ];
    }
  }
}

enum TaxStatus {
  pending,
  paid,
  overdue,
  exempted,
}

extension TaxStatusExtension on TaxStatus {
  String get displayName {
    switch (this) {
      case TaxStatus.pending:
        return 'Pending';
      case TaxStatus.paid:
        return 'Paid';
      case TaxStatus.overdue:
        return 'Overdue';
      case TaxStatus.exempted:
        return 'Exempted';
    }
  }

  String get englishName {
    switch (this) {
      case TaxStatus.pending:
        return 'Pending';
      case TaxStatus.paid:
        return 'Paid';
      case TaxStatus.overdue:
        return 'Overdue';
      case TaxStatus.exempted:
        return 'Exempted';
    }
  }

  IconData get icon {
    switch (this) {
      case TaxStatus.pending:
        return Icons.schedule;
      case TaxStatus.paid:
        return Icons.check_circle;
      case TaxStatus.overdue:
        return Icons.warning;
      case TaxStatus.exempted:
        return Icons.block;
    }
  }

  Color get color {
    switch (this) {
      case TaxStatus.pending:
        return Colors.orange;
      case TaxStatus.paid:
        return Colors.green;
      case TaxStatus.overdue:
        return Colors.red;
      case TaxStatus.exempted:
        return Colors.grey;
    }
  }
}

class TaxCalculationModel {
  final int year;
  final double annualIncome;
  final double irgAmount;
  final double casnosAmount;
  final double totalTaxes;
  final String calculationMethod;
  final DateTime calculatedAt;

  const TaxCalculationModel({
    required this.year,
    required this.annualIncome,
    required this.irgAmount,
    required this.casnosAmount,
    required this.totalTaxes,
    required this.calculationMethod,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'annual_income': annualIncome,
      'irg_amount': irgAmount,
      'casnos_amount': casnosAmount,
      'total_taxes': totalTaxes,
      'calculation_method': calculationMethod,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }

  factory TaxCalculationModel.fromJson(Map<String, dynamic> json) {
    return TaxCalculationModel(
      year: json['year'] ?? DateTime.now().year,
      annualIncome: (json['annual_income'] ?? 0.0).toDouble(),
      irgAmount: (json['irg_amount'] ?? 0.0).toDouble(),
      casnosAmount: (json['casnos_amount'] ?? 0.0).toDouble(),
      totalTaxes: (json['total_taxes'] ?? 0.0).toDouble(),
      calculationMethod: json['calculation_method'] ?? '',
      calculatedAt: DateTime.parse(json['calculated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  TaxCalculationModel copyWith({
    int? year,
    double? annualIncome,
    double? irgAmount,
    double? casnosAmount,
    double? totalTaxes,
    String? calculationMethod,
    DateTime? calculatedAt,
  }) {
    return TaxCalculationModel(
      year: year ?? this.year,
      annualIncome: annualIncome ?? this.annualIncome,
      irgAmount: irgAmount ?? this.irgAmount,
      casnosAmount: casnosAmount ?? this.casnosAmount,
      totalTaxes: totalTaxes ?? this.totalTaxes,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }
}

class TaxPaymentModel {
  final String? id;
  final TaxType type;
  final int year;
  final double amount;
  final TaxStatus status;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TaxPaymentModel({
    this.id,
    required this.type,
    required this.year,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paidDate,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue {
    if (status == TaxStatus.paid || status == TaxStatus.exempted) return false;
    return DateTime.now().isAfter(dueDate);
  }

  int get daysUntilDue {
    if (status == TaxStatus.paid || status == TaxStatus.exempted) return 0;
    return dueDate.difference(DateTime.now()).inDays;
  }

  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'year': year,
      'amount': amount,
      'status': status.name,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TaxPaymentModel.fromJson(Map<String, dynamic> json) {
    // Handle different type formats from database
    TaxType parsedType;
    final typeValue = json['type'];
    if (typeValue is String) {
      // Try to match by name first
      try {
        parsedType = TaxType.values.firstWhere(
          (t) => t.name.toLowerCase() == typeValue.toLowerCase(),
        );
      } catch (e) {
        // Try to match by display name or fallback
        if (typeValue.toLowerCase().contains('irg') || typeValue.toLowerCase().contains('income')) {
          parsedType = TaxType.irg;
        } else if (typeValue.toLowerCase().contains('casnos') || typeValue.toLowerCase().contains('social')) {
          parsedType = TaxType.casnos;
        } else {
          parsedType = TaxType.irg; // Default fallback
        }
      }
    } else {
      parsedType = TaxType.irg; // Default fallback
    }

    return TaxPaymentModel(
      id: json['id'],
      type: parsedType,
      year: json['year'] ?? DateTime.now().year,
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: TaxStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaxStatus.pending,
      ),
      dueDate: DateTime.parse(json['due_date']),
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  TaxPaymentModel copyWith({
    String? id,
    TaxType? type,
    int? year,
    double? amount,
    TaxStatus? status,
    DateTime? dueDate,
    DateTime? paidDate,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaxPaymentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

