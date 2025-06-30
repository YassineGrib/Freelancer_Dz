import 'package:flutter/material.dart';

enum EventType {
  project,
  payment,
  tax,
  meeting,
  deadline,
  reminder,
  custom,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.project:
        return 'Project';
      case EventType.payment:
        return 'Payment';
      case EventType.tax:
        return 'Tax';
      case EventType.meeting:
        return 'Meeting';
      case EventType.deadline:
        return 'Deadline';
      case EventType.reminder:
        return 'Reminder';
      case EventType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.project:
        return Icons.work;
      case EventType.payment:
        return Icons.payment;
      case EventType.tax:
        return Icons.account_balance;
      case EventType.meeting:
        return Icons.people;
      case EventType.deadline:
        return Icons.schedule;
      case EventType.reminder:
        return Icons.notifications;
      case EventType.custom:
        return Icons.event;
    }
  }

  Color get color {
    switch (this) {
      case EventType.project:
        return Colors.blue;
      case EventType.payment:
        return Colors.green;
      case EventType.tax:
        return Colors.red;
      case EventType.meeting:
        return Colors.purple;
      case EventType.deadline:
        return Colors.orange;
      case EventType.reminder:
        return Colors.amber;
      case EventType.custom:
        return Colors.grey;
    }
  }
}

enum EventPriority {
  low,
  medium,
  high,
  urgent,
}

extension EventPriorityExtension on EventPriority {
  String get displayName {
    switch (this) {
      case EventPriority.low:
        return 'Low';
      case EventPriority.medium:
        return 'Medium';
      case EventPriority.high:
        return 'High';
      case EventPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case EventPriority.low:
        return Colors.green;
      case EventPriority.medium:
        return Colors.blue;
      case EventPriority.high:
        return Colors.orange;
      case EventPriority.urgent:
        return Colors.red;
    }
  }

  int get value {
    switch (this) {
      case EventPriority.low:
        return 1;
      case EventPriority.medium:
        return 2;
      case EventPriority.high:
        return 3;
      case EventPriority.urgent:
        return 4;
    }
  }
}

enum EventStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  overdue,
}

extension EventStatusExtension on EventStatus {
  String get displayName {
    switch (this) {
      case EventStatus.scheduled:
        return 'Scheduled';
      case EventStatus.inProgress:
        return 'In Progress';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
      case EventStatus.overdue:
        return 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.scheduled:
        return Colors.blue;
      case EventStatus.inProgress:
        return Colors.orange;
      case EventStatus.completed:
        return Colors.green;
      case EventStatus.cancelled:
        return Colors.grey;
      case EventStatus.overdue:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case EventStatus.scheduled:
        return Icons.schedule;
      case EventStatus.inProgress:
        return Icons.play_circle;
      case EventStatus.completed:
        return Icons.check_circle;
      case EventStatus.cancelled:
        return Icons.cancel;
      case EventStatus.overdue:
        return Icons.warning;
    }
  }
}

class CalendarEventModel {
  final String? id;
  final String title;
  final String? description;
  final EventType type;
  final EventPriority priority;
  final EventStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final String? location;
  final List<String> attendees;
  final String? relatedId; // ID of related project, payment, tax, etc.
  final String? googleEventId; // For Google Calendar sync
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CalendarEventModel({
    this.id,
    required this.title,
    this.description,
    required this.type,
    this.priority = EventPriority.medium,
    this.status = EventStatus.scheduled,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    this.location,
    this.attendees = const [],
    this.relatedId,
    this.googleEventId,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOverdue {
    if (status == EventStatus.completed || status == EventStatus.cancelled) {
      return false;
    }
    final now = DateTime.now();
    final eventEnd = endDate ?? startDate;
    return now.isAfter(eventEnd);
  }

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startDate.year, startDate.month, startDate.day);
    return eventDate == today;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return startDate.isAfter(now) && !isOverdue;
  }

  Duration get timeUntilStart {
    return startDate.difference(DateTime.now());
  }

  Duration get duration {
    if (endDate != null) {
      return endDate!.difference(startDate);
    }
    return const Duration(hours: 1); // Default duration
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_all_day': isAllDay ? 1 : 0, // Convert boolean to integer for SQLite
      'location': location,
      'attendees': attendees.isNotEmpty
          ? attendees.join(',')
          : '', // Convert list to comma-separated string
      'related_id': relatedId,
      'google_event_id': googleEventId,
      'metadata': metadata?.toString(), // Convert map to string
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      type: EventType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EventType.custom,
      ),
      priority: EventPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => EventPriority.medium,
      ),
      status: EventStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EventStatus.scheduled,
      ),
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isAllDay: (json['is_all_day'] is int)
          ? json['is_all_day'] == 1
          : (json['is_all_day'] ?? false), // Handle both int and bool
      location: json['location'],
      attendees: _parseAttendees(
          json['attendees']), // Parse comma-separated string or list
      relatedId: json['related_id'],
      googleEventId: json['google_event_id'],
      metadata: _parseMetadata(
          json['metadata']), // Parse string back to map if needed
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    EventPriority? priority,
    EventStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    String? location,
    List<String>? attendees,
    String? relatedId,
    String? googleEventId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      relatedId: relatedId ?? this.relatedId,
      googleEventId: googleEventId ?? this.googleEventId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to create event from tax payment
  factory CalendarEventModel.fromTaxPayment(dynamic taxPayment) {
    String taxTypeName;
    try {
      taxTypeName = taxPayment.type.displayName;
    } catch (e) {
      // Fallback if displayName is not available
      taxTypeName = taxPayment.type.toString().split('.').last.toUpperCase();
    }

    return CalendarEventModel(
      title: '$taxTypeName Payment Due',
      description:
          'Tax payment of ${taxPayment.amount.toStringAsFixed(0)} DA is due',
      type: EventType.tax,
      priority: EventPriority.high,
      startDate: taxPayment.dueDate,
      isAllDay: true,
      relatedId: taxPayment.id,
      createdAt: DateTime.now(),
    );
  }

  // Helper method to create event from project deadline
  factory CalendarEventModel.fromProjectDeadline(dynamic project) {
    return CalendarEventModel(
      title: '${project.projectName} Deadline',
      description: 'Project deadline for ${project.projectName}',
      type: EventType.deadline,
      priority: EventPriority.high,
      startDate: project.endDate ?? DateTime.now(),
      isAllDay: true,
      relatedId: project.id,
      createdAt: DateTime.now(),
    );
  }

  // Helper method to create event from payment due
  factory CalendarEventModel.fromPaymentDue(dynamic payment) {
    return CalendarEventModel(
      title: 'Payment Due: ${payment.amount.toStringAsFixed(0)} DA',
      description: 'Payment from ${payment.clientName ?? "Client"} is due',
      type: EventType.payment,
      priority: EventPriority.medium,
      startDate: payment.dueDate ?? DateTime.now(),
      isAllDay: true,
      relatedId: payment.id,
      createdAt: DateTime.now(),
    );
  }

  // Helper methods for parsing data from database
  static List<String> _parseAttendees(dynamic attendeesData) {
    if (attendeesData == null) return [];
    if (attendeesData is List) return List<String>.from(attendeesData);
    if (attendeesData is String) {
      if (attendeesData.isEmpty) return [];
      return attendeesData.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  static Map<String, dynamic>? _parseMetadata(dynamic metadataData) {
    if (metadataData == null) return null;
    if (metadataData is Map<String, dynamic>) return metadataData;
    if (metadataData is String && metadataData.isNotEmpty) {
      try {
        // For now, just return null for string metadata
        // In a real app, you might want to parse JSON here
        return null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
