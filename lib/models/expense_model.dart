import 'package:flutter/material.dart';

enum ExpenseCategory {
  office,
  travel,
  equipment,
  software,
  marketing,
  utilities,
  meals,
  transportation,
  communication,
  education,
  legal,
  tax,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.office:
        return 'Office Supplies';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.software:
        return 'Software & Tools';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.meals:
        return 'Meals & Entertainment';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.communication:
        return 'Communication';
      case ExpenseCategory.education:
        return 'Education & Training';
      case ExpenseCategory.legal:
        return 'Legal & Professional';
      case ExpenseCategory.tax:
        return 'Tax & Government Fees';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get arabicName {
    switch (this) {
      case ExpenseCategory.office:
        return 'مستلزمات المكتب';
      case ExpenseCategory.travel:
        return 'السفر';
      case ExpenseCategory.equipment:
        return 'المعدات';
      case ExpenseCategory.software:
        return 'البرمجيات والأدوات';
      case ExpenseCategory.marketing:
        return 'التسويق';
      case ExpenseCategory.utilities:
        return 'المرافق';
      case ExpenseCategory.meals:
        return 'الوجبات والترفيه';
      case ExpenseCategory.transportation:
        return 'المواصلات';
      case ExpenseCategory.communication:
        return 'الاتصالات';
      case ExpenseCategory.education:
        return 'التعليم والتدريب';
      case ExpenseCategory.legal:
        return 'القانونية والمهنية';
      case ExpenseCategory.tax:
        return 'الضرائب والرسوم الحكومية';
      case ExpenseCategory.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.office:
        return Icons.business_center;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.equipment:
        return Icons.computer;
      case ExpenseCategory.software:
        return Icons.apps;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.utilities:
        return Icons.electrical_services;
      case ExpenseCategory.meals:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.communication:
        return Icons.phone;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.legal:
        return Icons.gavel;
      case ExpenseCategory.tax:
        return Icons.account_balance;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.office:
        return Colors.blue;
      case ExpenseCategory.travel:
        return Colors.green;
      case ExpenseCategory.equipment:
        return Colors.purple;
      case ExpenseCategory.software:
        return Colors.orange;
      case ExpenseCategory.marketing:
        return Colors.pink;
      case ExpenseCategory.utilities:
        return Colors.yellow;
      case ExpenseCategory.meals:
        return Colors.red;
      case ExpenseCategory.transportation:
        return Colors.teal;
      case ExpenseCategory.communication:
        return Colors.indigo;
      case ExpenseCategory.education:
        return Colors.cyan;
      case ExpenseCategory.legal:
        return Colors.brown;
      case ExpenseCategory.tax:
        return Colors.deepOrange;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }
}

enum PaymentMethod {
  cash,
  bankTransfer,
  creditCard,
  debitCard,
  paypal,
  ccp,
  other,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.ccp:
        return 'CCP';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get arabicName {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي';
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
      case PaymentMethod.debitCard:
        return 'بطاقة خصم';
      case PaymentMethod.paypal:
        return 'باي بال';
      case PaymentMethod.ccp:
        return 'بريد الجزائر';
      case PaymentMethod.other:
        return 'أخرى';
    }
  }
}

enum Currency {
  da, // Algerian Dinar
  usd, // US Dollar
  eur, // Euro
  gbp, // British Pound
}

extension CurrencyExtension on Currency {
  String get code {
    switch (this) {
      case Currency.da:
        return 'DA';
      case Currency.usd:
        return 'USD';
      case Currency.eur:
        return 'EUR';
      case Currency.gbp:
        return 'GBP';
    }
  }

  String get symbol {
    switch (this) {
      case Currency.da:
        return 'د.ج';
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.gbp:
        return '£';
    }
  }

  String get displayName {
    switch (this) {
      case Currency.da:
        return 'Algerian Dinar';
      case Currency.usd:
        return 'US Dollar';
      case Currency.eur:
        return 'Euro';
      case Currency.gbp:
        return 'British Pound';
    }
  }
}

class ExpenseModel {
  final String? id;
  final String? projectId;
  final String? clientId;
  final String title;
  final String? description;
  final double amount;
  final Currency currency;
  final String category;
  final PaymentMethod paymentMethod;
  final DateTime expenseDate;
  final String? receiptUrl;
  final String? vendor;
  final String? notes;
  final bool isReimbursable;
  final bool isRecurring;
  final DateTime? recurringEndDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    this.id,
    this.projectId,
    this.clientId,
    required this.title,
    this.description,
    required this.amount,
    this.currency = Currency.da,
    this.category = 'other',
    this.paymentMethod = PaymentMethod.cash,
    DateTime? expenseDate,
    this.receiptUrl,
    this.vendor,
    this.notes,
    this.isReimbursable = false,
    this.isRecurring = false,
    this.recurringEndDate,
    required this.createdAt,
    this.updatedAt,
  }) : expenseDate = expenseDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'client_id': clientId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency.name,
      'category': category,
      'payment_method': paymentMethod.name,
      'expense_date': expenseDate.toIso8601String(),
      'receipt_url': receiptUrl,
      'vendor': vendor,
      'notes': notes,
      'is_reimbursable': isReimbursable ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_end_date': recurringEndDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to convert SQLite INTEGER to bool
  static bool _convertToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      projectId: json['project_id'],
      clientId: json['client_id'],
      title: json['title'] ?? '',
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: Currency.values.firstWhere(
        (c) => c.name == json['currency'],
        orElse: () => Currency.da,
      ),
      category: (json['category'] as String?) ?? 'other',
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      expenseDate: DateTime.parse(json['expense_date']),
      receiptUrl: json['receipt_url'],
      vendor: json['vendor'],
      notes: json['notes'],
      isReimbursable: _convertToBool(json['is_reimbursable']),
      isRecurring: _convertToBool(json['is_recurring']),
      recurringEndDate: json['recurring_end_date'] != null
          ? DateTime.parse(json['recurring_end_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? projectId,
    String? clientId,
    String? title,
    String? description,
    double? amount,
    Currency? currency,
    String? category,
    PaymentMethod? paymentMethod,
    DateTime? expenseDate,
    String? receiptUrl,
    String? vendor,
    String? notes,
    bool? isReimbursable,
    bool? isRecurring,
    DateTime? recurringEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      vendor: vendor ?? this.vendor,
      notes: notes ?? this.notes,
      isReimbursable: isReimbursable ?? this.isReimbursable,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ExpenseCategoryDisplay {
  final String displayName;
  final IconData icon;
  final Color color;
  const ExpenseCategoryDisplay({
    required this.displayName,
    required this.icon,
    required this.color,
  });
}

ExpenseCategoryDisplay getExpenseCategoryDisplay(String categoryName) {
  final builtIn = ExpenseCategory.values.where((c) => c.name == categoryName);
  if (builtIn.isNotEmpty) {
    final c = builtIn.first;
    return ExpenseCategoryDisplay(
      displayName: c.displayName,
      icon: c.icon,
      color: c.color,
    );
  }
  return ExpenseCategoryDisplay(
    displayName: categoryName,
    icon: Icons.label,
    color: Colors.grey,
  );
}
