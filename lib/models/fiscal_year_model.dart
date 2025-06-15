import 'package:json_annotation/json_annotation.dart';

part 'fiscal_year_model.g.dart';

@JsonSerializable()
class FiscalYear {
  final String id;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final FiscalYearStatus status;
  final double totalRevenue;
  final double totalExpenses;
  final double totalTaxes;
  final double netProfit;
  final int totalClients;
  final int totalProjects;
  final int totalInvoices;
  final int totalPayments;
  final DateTime createdAt;
  final DateTime? closedAt;
  final bool isCurrent;

  FiscalYear({
    required this.id,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.totalRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.totalTaxes = 0.0,
    this.netProfit = 0.0,
    this.totalClients = 0,
    this.totalProjects = 0,
    this.totalInvoices = 0,
    this.totalPayments = 0,
    required this.createdAt,
    this.closedAt,
    this.isCurrent = false,
  });

  factory FiscalYear.create(int year) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31, 23, 59, 59);

    return FiscalYear(
      id: 'fy_${year}_${DateTime.now().millisecondsSinceEpoch}',
      year: year,
      startDate: startDate,
      endDate: endDate,
      status: FiscalYearStatus.active,
      createdAt: DateTime.now(),
      isCurrent: year == DateTime.now().year,
    );
  }

  factory FiscalYear.fromJson(Map<String, dynamic> json) =>
      _$FiscalYearFromJson(json);
  Map<String, dynamic> toJson() => _$FiscalYearToJson(this);

  FiscalYear copyWith({
    String? id,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    FiscalYearStatus? status,
    double? totalRevenue,
    double? totalExpenses,
    double? totalTaxes,
    double? netProfit,
    int? totalClients,
    int? totalProjects,
    int? totalInvoices,
    int? totalPayments,
    DateTime? createdAt,
    DateTime? closedAt,
    bool? isCurrent,
  }) {
    return FiscalYear(
      id: id ?? this.id,
      year: year ?? this.year,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalTaxes: totalTaxes ?? this.totalTaxes,
      netProfit: netProfit ?? this.netProfit,
      totalClients: totalClients ?? this.totalClients,
      totalProjects: totalProjects ?? this.totalProjects,
      totalInvoices: totalInvoices ?? this.totalInvoices,
      totalPayments: totalPayments ?? this.totalPayments,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  // Helper method to check if fiscal year can be closed
  bool get canBeClosed => status == FiscalYearStatus.active && !isCurrent;
}

enum FiscalYearStatus {
  active,
  closed,
  archived,
}

@JsonSerializable()
class YearEndTransition {
  final String id;
  final int fromYear;
  final int toYear;
  final YearEndTransitionStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<YearEndTransitionStep> steps;
  final String? errorMessage;

  YearEndTransition({
    required this.id,
    required this.fromYear,
    required this.toYear,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.steps,
    this.errorMessage,
  });

  factory YearEndTransition.fromJson(Map<String, dynamic> json) =>
      _$YearEndTransitionFromJson(json);
  Map<String, dynamic> toJson() => _$YearEndTransitionToJson(this);
}

enum YearEndTransitionStatus {
  pending,
  inProgress,
  completed,
  failed,
}

@JsonSerializable()
class YearEndTransitionStep {
  final String name;
  final String description;
  final YearEndStepStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const YearEndTransitionStep({
    required this.name,
    required this.description,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  factory YearEndTransitionStep.fromJson(Map<String, dynamic> json) =>
      _$YearEndTransitionStepFromJson(json);
  Map<String, dynamic> toJson() => _$YearEndTransitionStepToJson(this);
}

enum YearEndStepStatus {
  pending,
  inProgress,
  completed,
  failed,
}

@JsonSerializable()
class FiscalYearSummary {
  final String fiscalYearId;
  final int year;
  final double totalRevenue;
  final double totalExpenses;
  final double totalTaxes;
  final double netProfit;
  final int totalClients;
  final int totalProjects;
  final int totalInvoices;
  final int totalPayments;
  final Map<String, double> monthlyRevenue;
  final Map<String, double> monthlyExpenses;
  final Map<String, double> clientDistribution;
  final Map<String, double> projectTypeRevenue;
  final DateTime generatedAt;

  FiscalYearSummary({
    required this.fiscalYearId,
    required this.year,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalTaxes,
    required this.netProfit,
    required this.totalClients,
    required this.totalProjects,
    required this.totalInvoices,
    required this.totalPayments,
    required this.monthlyRevenue,
    required this.monthlyExpenses,
    required this.clientDistribution,
    required this.projectTypeRevenue,
    required this.generatedAt,
  });

  factory FiscalYearSummary.fromJson(Map<String, dynamic> json) =>
      _$FiscalYearSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$FiscalYearSummaryToJson(this);
}
