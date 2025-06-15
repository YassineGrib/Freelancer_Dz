import 'package:flutter/material.dart';
import 'client_model.dart';

enum ProjectStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  onHold('On Hold'),
  completed('Completed'),
  cancelled('Cancelled');

  const ProjectStatus(this.displayName);
  final String displayName;
}

enum PricingType {
  hourlyRate('Hourly Rate'),
  fixedPrice('Fixed Price');

  const PricingType(this.displayName);
  final String displayName;
}

class ProjectModel {
  final String? id;
  final String clientId;
  final String projectName;
  final String description;
  final ProjectStatus status;
  final PricingType pricingType;
  final double? hourlyRate;
  final double? fixedAmount;
  final double? estimatedHours;
  final double? actualHours;
  final Currency currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final int progressPercentage; // 0-100
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Client information (populated when fetched with join)
  final ClientModel? client;

  ProjectModel({
    this.id,
    required this.clientId,
    required this.projectName,
    required this.description,
    required this.status,
    required this.pricingType,
    this.hourlyRate,
    this.fixedAmount,
    this.estimatedHours,
    this.actualHours,
    required this.currency,
    this.startDate,
    this.endDate,
    this.progressPercentage = 0,
    required this.createdAt,
    this.updatedAt,
    this.client,
  });

  // Get status color for UI
  static Color getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.notStarted:
        return const Color(0xFF9CA3AF); // Gray
      case ProjectStatus.inProgress:
        return const Color(0xFF3B82F6); // Blue
      case ProjectStatus.onHold:
        return const Color(0xFFF59E0B); // Yellow
      case ProjectStatus.completed:
        return const Color(0xFF10B981); // Green
      case ProjectStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }

  // Check if project is overdue
  bool get isOverdue {
    if (endDate == null ||
        status == ProjectStatus.completed ||
        status == ProjectStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(endDate!);
  }

  // Get total project value based on pricing type
  double? get totalValue {
    switch (pricingType) {
      case PricingType.fixedPrice:
        return fixedAmount;
      case PricingType.hourlyRate:
        if (hourlyRate != null && actualHours != null) {
          return hourlyRate! * actualHours!;
        } else if (hourlyRate != null && estimatedHours != null) {
          return hourlyRate! * estimatedHours!;
        }
        return null;
    }
  }

  // Get estimated value for hourly projects
  double? get estimatedValue {
    if (pricingType == PricingType.hourlyRate &&
        hourlyRate != null &&
        estimatedHours != null) {
      return hourlyRate! * estimatedHours!;
    }
    return totalValue;
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String?,
      clientId: json['client_id'] as String? ?? '',
      projectName: json['project_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: ProjectStatus.values.firstWhere(
        (status) => status.name == (json['status'] as String?),
        orElse: () => ProjectStatus.notStarted,
      ),
      pricingType: PricingType.values.firstWhere(
        (type) => type.name == (json['pricing_type'] as String?),
        orElse: () => PricingType.fixedPrice,
      ),
      hourlyRate: json['hourly_rate'] != null
          ? (json['hourly_rate'] as num).toDouble()
          : null,
      fixedAmount: json['fixed_amount'] != null
          ? (json['fixed_amount'] as num).toDouble()
          : null,
      estimatedHours: json['estimated_hours'] != null
          ? (json['estimated_hours'] as num).toDouble()
          : null,
      actualHours: json['actual_hours'] != null
          ? (json['actual_hours'] as num).toDouble()
          : null,
      currency: Currency.values.firstWhere(
        (curr) => curr.code == (json['currency'] as String?)?.toLowerCase(),
        orElse: () => Currency.da,
      ),
      startDate: json['start_date'] != null && json['start_date'] is String
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null && json['end_date'] is String
          ? DateTime.parse(json['end_date'] as String)
          : null,
      progressPercentage: json['progress_percentage'] as int? ?? 0,
      createdAt: json['created_at'] != null && json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null && json['updated_at'] is String
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Client data if included in join
      client: json['clients'] != null
          ? ClientModel.fromJson(json['clients'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'client_id': clientId,
      'project_name': projectName,
      'description': description,
      'status': status.name,
      'pricing_type': pricingType.name,
      if (hourlyRate != null) 'hourly_rate': hourlyRate,
      if (fixedAmount != null) 'fixed_amount': fixedAmount,
      if (estimatedHours != null) 'estimated_hours': estimatedHours,
      if (actualHours != null) 'actual_hours': actualHours,
      'currency': currency.code,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'progress_percentage': progressPercentage,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? clientId,
    String? projectName,
    String? description,
    ProjectStatus? status,
    PricingType? pricingType,
    double? hourlyRate,
    double? fixedAmount,
    double? estimatedHours,
    double? actualHours,
    Currency? currency,
    DateTime? startDate,
    DateTime? endDate,
    int? progressPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
    ClientModel? client,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      status: status ?? this.status,
      pricingType: pricingType ?? this.pricingType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, clientId: $clientId, projectName: $projectName, status: $status, pricingType: $pricingType, currency: $currency, progressPercentage: $progressPercentage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel &&
        other.id == id &&
        other.clientId == clientId &&
        other.projectName == projectName &&
        other.description == description &&
        other.status == status &&
        other.pricingType == pricingType &&
        other.hourlyRate == hourlyRate &&
        other.fixedAmount == fixedAmount &&
        other.estimatedHours == estimatedHours &&
        other.actualHours == actualHours &&
        other.currency == currency &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.progressPercentage == progressPercentage &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clientId.hashCode ^
        projectName.hashCode ^
        description.hashCode ^
        status.hashCode ^
        pricingType.hashCode ^
        hourlyRate.hashCode ^
        fixedAmount.hashCode ^
        estimatedHours.hashCode ^
        actualHours.hashCode ^
        currency.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        progressPercentage.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
