import 'dart:convert';
import 'package:flutter/material.dart';

enum InvoiceType {
  client,
  project,
}

extension InvoiceTypeExtension on InvoiceType {
  String get displayName {
    switch (this) {
      case InvoiceType.client:
        return 'Client Invoice';
      case InvoiceType.project:
        return 'Project Invoice';
    }
  }

  String get arabicName {
    switch (this) {
      case InvoiceType.client:
        return 'فاتورة عميل';
      case InvoiceType.project:
        return 'فاتورة مشروع';
    }
  }

  String get description {
    switch (this) {
      case InvoiceType.client:
        return 'General invoice with custom items';
      case InvoiceType.project:
        return 'Auto-generated invoice from project';
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceType.client:
        return Icons.person;
      case InvoiceType.project:
        return Icons.work;
    }
  }

  Color get color {
    switch (this) {
      case InvoiceType.client:
        return Colors.blue;
      case InvoiceType.project:
        return Colors.green;
    }
  }
}

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled,
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get arabicName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'مسودة';
      case InvoiceStatus.sent:
        return 'مرسلة';
      case InvoiceStatus.paid:
        return 'مدفوعة';
      case InvoiceStatus.overdue:
        return 'متأخرة';
      case InvoiceStatus.cancelled:
        return 'ملغية';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.sent:
        return Icons.send;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.overdue:
        return Icons.warning;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
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

class InvoiceItemModel {
  final String? id;
  final String description;
  final int quantity;
  final double unitPrice;
  final double? discount;
  final double total;

  const InvoiceItemModel({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total': total,
    };
  }

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'],
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      discount: json['discount']?.toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
    );
  }

  InvoiceItemModel copyWith({
    String? id,
    String? description,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? total,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }
}

class InvoiceModel {
  final String? id;
  final String invoiceNumber;
  final InvoiceType type;
  final String? projectId;
  final String? clientId;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime dueDate;
  final Currency currency;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double? taxRate;
  final double? taxAmount;
  final double? discount;
  final double total;
  final String? notes;
  final String? terms;
  final String? paymentInstructions;
  final DateTime? sentDate;
  final DateTime? paidDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Company information
  final String? companyName;
  final String? companyAddress;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyWebsite;
  final String? companyLogo;

  // Client information (cached for PDF generation)
  final String? clientName;
  final String? clientAddress;
  final String? clientPhone;
  final String? clientEmail;

  const InvoiceModel({
    this.id,
    required this.invoiceNumber,
    required this.type,
    this.projectId,
    this.clientId,
    required this.status,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.items,
    required this.subtotal,
    this.taxRate,
    this.taxAmount,
    this.discount,
    required this.total,
    this.notes,
    this.terms,
    this.paymentInstructions,
    this.sentDate,
    this.paidDate,
    required this.createdAt,
    this.updatedAt,
    this.companyName,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.companyWebsite,
    this.companyLogo,
    this.clientName,
    this.clientAddress,
    this.clientPhone,
    this.clientEmail,
  });

  // Calculate if invoice is overdue
  bool get isOverdue {
    if (status == InvoiceStatus.paid || status == InvoiceStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate);
  }

  // Calculate days until due
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference;
  }

  // Calculate days overdue
  int get daysOverdue {
    if (!isOverdue) return 0;
    final now = DateTime.now();
    return now.difference(dueDate).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'type': type.name,
      'project_id': projectId,
      'client_id': clientId,
      'status': status.name,
      'issue_date': issueDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'currency': currency.code.toLowerCase(),
      'items': jsonEncode(items.map((item) => item.toJson()).toList()),
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount': discount,
      'total': total,
      'notes': notes,
      'terms': terms,
      'payment_instructions': paymentInstructions,
      'sent_date': sentDate?.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'company_name': companyName,
      'company_address': companyAddress,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'company_website': companyWebsite,
      'company_logo': companyLogo,
      'client_name': clientName,
      'client_address': clientAddress,
      'client_phone': clientPhone,
      'client_email': clientEmail,
    };
  }

  // Helper method to parse items from JSON string or List
  static List<InvoiceItemModel> _parseItems(dynamic itemsData) {
    if (itemsData == null) return [];

    try {
      List<dynamic> itemsList;

      if (itemsData is String) {
        // Parse JSON string
        itemsList = jsonDecode(itemsData) as List<dynamic>;
      } else if (itemsData is List) {
        // Already a list
        itemsList = itemsData;
      } else {
        return [];
      }

      return itemsList
          .map(
              (item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      invoiceNumber: json['invoice_number'] ?? '',
      type: InvoiceType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => InvoiceType.client,
      ),
      projectId: json['project_id'],
      clientId: json['client_id'],
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      issueDate: DateTime.parse(json['issue_date']),
      dueDate: DateTime.parse(json['due_date']),
      currency: Currency.values.firstWhere(
        (c) =>
            c.code.toLowerCase() ==
            (json['currency'] as String?)?.toLowerCase(),
        orElse: () => Currency.da,
      ),
      items: _parseItems(json['items']),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      taxRate: json['tax_rate']?.toDouble(),
      taxAmount: json['tax_amount']?.toDouble(),
      discount: json['discount']?.toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      notes: json['notes'],
      terms: json['terms'],
      paymentInstructions: json['payment_instructions'],
      sentDate:
          json['sent_date'] != null ? DateTime.parse(json['sent_date']) : null,
      paidDate:
          json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      companyName: json['company_name'],
      companyAddress: json['company_address'],
      companyPhone: json['company_phone'],
      companyEmail: json['company_email'],
      companyWebsite: json['company_website'],
      companyLogo: json['company_logo'],
      clientName: json['client_name'],
      clientAddress: json['client_address'],
      clientPhone: json['client_phone'],
      clientEmail: json['client_email'],
    );
  }

  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    InvoiceType? type,
    String? projectId,
    String? clientId,
    InvoiceStatus? status,
    DateTime? issueDate,
    DateTime? dueDate,
    Currency? currency,
    List<InvoiceItemModel>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? discount,
    double? total,
    String? notes,
    String? terms,
    String? paymentInstructions,
    DateTime? sentDate,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyWebsite,
    String? companyLogo,
    String? clientName,
    String? clientAddress,
    String? clientPhone,
    String? clientEmail,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      sentDate: sentDate ?? this.sentDate,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyLogo: companyLogo ?? this.companyLogo,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
    );
  }
}
