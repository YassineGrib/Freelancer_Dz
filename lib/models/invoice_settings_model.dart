import 'package:flutter/material.dart';
import '../models/client_model.dart';

class InvoiceSettingsModel {
  final String? id;
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final InvoiceNumberFormat numberFormat;
  final int defaultDueDays;
  final String defaultTerms;
  final String defaultNotes;
  final bool includeCompanyLogo;
  final bool includePaymentInstructions;
  final String paymentInstructions;
  final Currency defaultCurrency;
  final bool enableTax;
  final double defaultTaxRate;
  final String taxLabel;
  final bool enableDiscount;
  final DiscountType defaultDiscountType;
  final double defaultDiscountValue;
  final InvoiceTemplate defaultTemplate;
  final Map<String, String> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceSettingsModel({
    this.id,
    required this.invoicePrefix,
    required this.nextInvoiceNumber,
    required this.numberFormat,
    required this.defaultDueDays,
    required this.defaultTerms,
    required this.defaultNotes,
    required this.includeCompanyLogo,
    required this.includePaymentInstructions,
    required this.paymentInstructions,
    required this.defaultCurrency,
    required this.enableTax,
    required this.defaultTaxRate,
    required this.taxLabel,
    required this.enableDiscount,
    required this.defaultDiscountType,
    required this.defaultDiscountValue,
    required this.defaultTemplate,
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  InvoiceSettingsModel copyWith({
    String? id,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    InvoiceNumberFormat? numberFormat,
    int? defaultDueDays,
    String? defaultTerms,
    String? defaultNotes,
    bool? includeCompanyLogo,
    bool? includePaymentInstructions,
    String? paymentInstructions,
    Currency? defaultCurrency,
    bool? enableTax,
    double? defaultTaxRate,
    String? taxLabel,
    bool? enableDiscount,
    DiscountType? defaultDiscountType,
    double? defaultDiscountValue,
    InvoiceTemplate? defaultTemplate,
    Map<String, String>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceSettingsModel(
      id: id ?? this.id,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      numberFormat: numberFormat ?? this.numberFormat,
      defaultDueDays: defaultDueDays ?? this.defaultDueDays,
      defaultTerms: defaultTerms ?? this.defaultTerms,
      defaultNotes: defaultNotes ?? this.defaultNotes,
      includeCompanyLogo: includeCompanyLogo ?? this.includeCompanyLogo,
      includePaymentInstructions: includePaymentInstructions ?? this.includePaymentInstructions,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      enableTax: enableTax ?? this.enableTax,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      taxLabel: taxLabel ?? this.taxLabel,
      enableDiscount: enableDiscount ?? this.enableDiscount,
      defaultDiscountType: defaultDiscountType ?? this.defaultDiscountType,
      defaultDiscountValue: defaultDiscountValue ?? this.defaultDiscountValue,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String generateInvoiceNumber() {
    final number = nextInvoiceNumber.toString().padLeft(numberFormat.digits, '0');
    switch (numberFormat) {
      case InvoiceNumberFormat.prefixNumber:
        return '$invoicePrefix$number';
      case InvoiceNumberFormat.prefixDashNumber:
        return '$invoicePrefix-$number';
      case InvoiceNumberFormat.prefixYearNumber:
        return '$invoicePrefix${DateTime.now().year}$number';
      case InvoiceNumberFormat.prefixYearDashNumber:
        return '$invoicePrefix${DateTime.now().year}-$number';
      case InvoiceNumberFormat.numberOnly:
        return number;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_prefix': invoicePrefix,
      'next_invoice_number': nextInvoiceNumber,
      'number_format': numberFormat.name,
      'default_due_days': defaultDueDays,
      'default_terms': defaultTerms,
      'default_notes': defaultNotes,
      'include_company_logo': includeCompanyLogo,
      'include_payment_instructions': includePaymentInstructions,
      'payment_instructions': paymentInstructions,
      'default_currency': defaultCurrency.name,
      'enable_tax': enableTax,
      'default_tax_rate': defaultTaxRate,
      'tax_label': taxLabel,
      'enable_discount': enableDiscount,
      'default_discount_type': defaultDiscountType.name,
      'default_discount_value': defaultDiscountValue,
      'default_template': defaultTemplate.name,
      'custom_fields': customFields,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory InvoiceSettingsModel.fromJson(Map<String, dynamic> json) {
    return InvoiceSettingsModel(
      id: json['id'],
      invoicePrefix: json['invoice_prefix'] ?? 'INV',
      nextInvoiceNumber: json['next_invoice_number'] ?? 1,
      numberFormat: InvoiceNumberFormat.values.firstWhere(
        (format) => format.name == json['number_format'],
        orElse: () => InvoiceNumberFormat.prefixYearDashNumber,
      ),
      defaultDueDays: json['default_due_days'] ?? 30,
      defaultTerms: json['default_terms'] ?? '',
      defaultNotes: json['default_notes'] ?? '',
      includeCompanyLogo: json['include_company_logo'] ?? true,
      includePaymentInstructions: json['include_payment_instructions'] ?? true,
      paymentInstructions: json['payment_instructions'] ?? '',
      defaultCurrency: Currency.values.firstWhere(
        (currency) => currency.name == json['default_currency'],
        orElse: () => Currency.da,
      ),
      enableTax: json['enable_tax'] ?? false,
      defaultTaxRate: (json['default_tax_rate'] ?? 0.0).toDouble(),
      taxLabel: json['tax_label'] ?? 'Tax',
      enableDiscount: json['enable_discount'] ?? false,
      defaultDiscountType: DiscountType.values.firstWhere(
        (type) => type.name == json['default_discount_type'],
        orElse: () => DiscountType.percentage,
      ),
      defaultDiscountValue: (json['default_discount_value'] ?? 0.0).toDouble(),
      defaultTemplate: InvoiceTemplate.values.firstWhere(
        (template) => template.name == json['default_template'],
        orElse: () => InvoiceTemplate.modern,
      ),
      customFields: Map<String, String>.from(json['custom_fields'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static InvoiceSettingsModel get defaultSettings => InvoiceSettingsModel(
    invoicePrefix: 'INV',
    nextInvoiceNumber: 1,
    numberFormat: InvoiceNumberFormat.prefixYearDashNumber,
    defaultDueDays: 30,
    defaultTerms: 'Payment is due within 30 days of invoice date.',
    defaultNotes: 'Thank you for your business!',
    includeCompanyLogo: true,
    includePaymentInstructions: true,
    paymentInstructions: 'Please make payment to the bank account details provided.',
    defaultCurrency: Currency.da,
    enableTax: false,
    defaultTaxRate: 0.0,
    taxLabel: 'Tax',
    enableDiscount: false,
    defaultDiscountType: DiscountType.percentage,
    defaultDiscountValue: 0.0,
    defaultTemplate: InvoiceTemplate.modern,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

enum InvoiceNumberFormat {
  prefixNumber,
  prefixDashNumber,
  prefixYearNumber,
  prefixYearDashNumber,
  numberOnly;

  String get displayName {
    switch (this) {
      case InvoiceNumberFormat.prefixNumber:
        return 'INV0001';
      case InvoiceNumberFormat.prefixDashNumber:
        return 'INV-0001';
      case InvoiceNumberFormat.prefixYearNumber:
        return 'INV20250001';
      case InvoiceNumberFormat.prefixYearDashNumber:
        return 'INV-2025-0001';
      case InvoiceNumberFormat.numberOnly:
        return '0001';
    }
  }

  int get digits {
    switch (this) {
      case InvoiceNumberFormat.prefixYearNumber:
      case InvoiceNumberFormat.prefixYearDashNumber:
        return 4;
      default:
        return 4;
    }
  }
}

enum DiscountType {
  percentage,
  fixed;

  String get displayName {
    switch (this) {
      case DiscountType.percentage:
        return 'Percentage (%)';
      case DiscountType.fixed:
        return 'Fixed Amount';
    }
  }

  IconData get icon {
    switch (this) {
      case DiscountType.percentage:
        return Icons.percent;
      case DiscountType.fixed:
        return Icons.attach_money;
    }
  }
}

enum InvoiceTemplate {
  modern,
  classic,
  minimal,
  professional;

  String get displayName {
    switch (this) {
      case InvoiceTemplate.modern:
        return 'Modern';
      case InvoiceTemplate.classic:
        return 'Classic';
      case InvoiceTemplate.minimal:
        return 'Minimal';
      case InvoiceTemplate.professional:
        return 'Professional';
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceTemplate.modern:
        return Icons.design_services;
      case InvoiceTemplate.classic:
        return Icons.article;
      case InvoiceTemplate.minimal:
        return Icons.minimize;
      case InvoiceTemplate.professional:
        return Icons.business_center;
    }
  }
}

