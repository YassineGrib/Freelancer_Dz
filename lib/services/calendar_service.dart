import '../models/calendar_event_model.dart';
import 'local_database_service.dart';
import 'local_database_extensions.dart';
import 'auth_service.dart';

class CalendarService {
  static final LocalDatabaseService _db = LocalDatabaseService.instance;

  static String? get _userId => AuthService.currentUser?["id"];

  static Future<List<CalendarEventModel>> getAllEvents() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final eventsData = await _db.getCalendarEvents(_userId!);
      final events = <CalendarEventModel>[];

      for (final eventData in eventsData) {
        events.add(CalendarEventModel.fromJson(eventData));
      }

      return events;
    } catch (e) {
      throw Exception("Failed to fetch calendar events: $e");
    }
  }

  static Future<List<CalendarEventModel>> getEventsForDate(
      DateTime date) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final dateString = date.toIso8601String().split("T")[0];
      final eventsData =
          await _db.getCalendarEventsByDate(_userId!, dateString);
      final events = <CalendarEventModel>[];

      for (final eventData in eventsData) {
        events.add(CalendarEventModel.fromJson(eventData));
      }

      return events;
    } catch (e) {
      throw Exception("Failed to fetch events for date: $e");
    }
  }

  static Future<List<CalendarEventModel>> getUpcomingEvents() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      final eventsData = await _db.getCalendarEventsByDateRange(
          _userId!, now.toIso8601String(), endDate.toIso8601String());

      final events = <CalendarEventModel>[];

      for (final eventData in eventsData) {
        final event = CalendarEventModel.fromJson(eventData);
        if (event.status == EventStatus.scheduled) {
          events.add(event);
        }
      }

      return events;
    } catch (e) {
      throw Exception("Failed to fetch upcoming events: $e");
    }
  }

  static Future<Map<DateTime, List<CalendarEventModel>>> getEventsForMonth(
      int year, int month) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final eventsData = await _db.getCalendarEventsByDateRange(
          _userId!, startDate.toIso8601String(), endDate.toIso8601String());

      final Map<DateTime, List<CalendarEventModel>> eventsByDate = {};

      for (final eventData in eventsData) {
        final event = CalendarEventModel.fromJson(eventData);
        final eventDate = DateTime(
            event.startDate.year, event.startDate.month, event.startDate.day);

        if (eventsByDate[eventDate] == null) {
          eventsByDate[eventDate] = [];
        }
        eventsByDate[eventDate]!.add(event);
      }

      return eventsByDate;
    } catch (e) {
      throw Exception("Failed to fetch events for month: $e");
    }
  }

  static Future<List<CalendarEventModel>> getOverdueEvents() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final allEvents = await getAllEvents();
      final now = DateTime.now();

      return allEvents
          .where((event) =>
              event.status == EventStatus.scheduled &&
              event.startDate.isBefore(now))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch overdue events: $e");
    }
  }

  static Future<CalendarEventModel> addEvent(CalendarEventModel event) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final eventData = event.toJson();
      eventData.remove("id");

      final eventId = await _db.createCalendarEvent(_userId!, eventData);

      final createdEventData = await _db.database.then((db) => db.query(
            "calendar_events",
            where: "id = ?",
            whereArgs: [eventId],
            limit: 1,
          ));

      if (createdEventData.isEmpty) {
        throw Exception("Failed to retrieve created event");
      }

      return CalendarEventModel.fromJson(createdEventData.first);
    } catch (e) {
      throw Exception("Failed to create calendar event: $e");
    }
  }

  static Future<CalendarEventModel> updateEvent(
      CalendarEventModel event) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      if (event.id == null) {
        throw Exception("Event ID is required for update");
      }

      final eventData = event.toJson();
      await _db.updateCalendarEvent(event.id!, eventData);

      final updatedEventData = await _db.database.then((db) => db.query(
            "calendar_events",
            where: "id = ?",
            whereArgs: [event.id],
            limit: 1,
          ));

      if (updatedEventData.isEmpty) {
        throw Exception("Failed to retrieve updated event");
      }

      return CalendarEventModel.fromJson(updatedEventData.first);
    } catch (e) {
      throw Exception("Failed to update calendar event: $e");
    }
  }

  static Future<CalendarEventModel> markEventAsCompleted(String eventId) async {
    try {
      final eventData = await _db.database.then((db) => db.query(
            "calendar_events",
            where: "id = ?",
            whereArgs: [eventId],
            limit: 1,
          ));

      if (eventData.isEmpty) {
        throw Exception("Event not found");
      }

      final event = CalendarEventModel.fromJson(eventData.first);
      final updatedEvent = event.copyWith(status: EventStatus.completed);

      return await updateEvent(updatedEvent);
    } catch (e) {
      throw Exception("Failed to mark event as completed: $e");
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    try {
      await _db.deleteCalendarEvent(eventId);
    } catch (e) {
      throw Exception("Failed to delete calendar event: $e");
    }
  }

  // Helper method to remove existing system-generated events
  static Future<void> _removeSystemGeneratedEvents() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      // Get all events
      final allEvents = await getAllEvents();

      // Filter system-generated events (those with relatedId)
      final systemEvents = allEvents
          .where((event) =>
              event.relatedId != null &&
              (event.type == EventType.tax ||
                  event.type == EventType.deadline ||
                  event.type == EventType.payment))
          .toList();

      // Delete system-generated events
      for (final event in systemEvents) {
        if (event.id != null) {
          await deleteEvent(event.id!);
        }
      }
    } catch (e) {
      // Don't throw error here, just log it
      print('Error removing system events: $e');
    }
  }

  static Future<Map<String, List<CalendarEventModel>>>
      syncAllSystemEvents() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final Map<String, List<CalendarEventModel>> syncedEvents = {
        "tax": [],
        "project": [],
        "payment": [],
      };

      // First, remove existing system-generated events to avoid duplicates
      await _removeSystemGeneratedEvents();

      // Sync tax payment due dates
      final taxPaymentsData = await _db.getTaxPayments(_userId!);
      for (final taxPayment in taxPaymentsData) {
        if (taxPayment["status"] == "pending") {
          final dueDate = DateTime.parse(taxPayment["due_date"]);
          final taxEvent = CalendarEventModel(
            title:
                "Tax Payment Due: ${taxPayment["type"].toString().toUpperCase()}",
            description: "Tax payment of ${taxPayment["amount"]} DA is due",
            type: EventType.tax,
            priority: EventPriority.high,
            status: EventStatus.scheduled,
            startDate: dueDate,
            isAllDay: true,
            relatedId: taxPayment["id"],
            createdAt: DateTime.now(),
          );

          // Save to database
          await addEvent(taxEvent);
          syncedEvents["tax"]!.add(taxEvent);
        }
      }

      // Sync project deadlines
      final projectsData = await _db.getProjects(_userId!);
      for (final project in projectsData) {
        if (project["end_date"] != null && project["status"] != "completed") {
          final endDate = DateTime.parse(project["end_date"]);
          final projectEvent = CalendarEventModel(
            title: "Project Deadline: ${project["project_name"]}",
            description: "Project ${project["project_name"]} is due",
            type: EventType.deadline,
            priority: EventPriority.high,
            status: EventStatus.scheduled,
            startDate: endDate,
            isAllDay: true,
            relatedId: project["id"],
            createdAt: DateTime.now(),
          );

          // Save to database
          await addEvent(projectEvent);
          syncedEvents["project"]!.add(projectEvent);
        }
      }

      // Sync payment due dates
      final paymentsData = await _db.getPayments(_userId!);
      for (final payment in paymentsData) {
        if (payment["due_date"] != null &&
            payment["payment_status"] == "pending") {
          final dueDate = DateTime.parse(payment["due_date"]);
          final paymentEvent = CalendarEventModel(
            title: "Payment Due: ${payment["description"] ?? "Payment"}",
            description:
                "Payment of ${payment["payment_amount"]} ${payment["currency"]} is due",
            type: EventType.payment,
            priority: EventPriority.medium,
            status: EventStatus.scheduled,
            startDate: dueDate,
            isAllDay: true,
            relatedId: payment["id"],
            createdAt: DateTime.now(),
          );

          // Save to database
          await addEvent(paymentEvent);
          syncedEvents["payment"]!.add(paymentEvent);
        }
      }

      return syncedEvents;
    } catch (e) {
      throw Exception("Failed to sync system events: $e");
    }
  }

  static Future<Map<String, dynamic>> getCalendarStatistics() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final allEvents = await getAllEvents();
      final upcomingEvents = await getUpcomingEvents();
      final overdueEvents = await getOverdueEvents();

      Map<String, int> eventsByType = {};
      Map<String, int> eventsByStatus = {};

      for (final event in allEvents) {
        eventsByType[event.type.name] =
            (eventsByType[event.type.name] ?? 0) + 1;
        eventsByStatus[event.status.name] =
            (eventsByStatus[event.status.name] ?? 0) + 1;
      }

      return {
        "total_events": allEvents.length,
        "upcoming_events": upcomingEvents.length,
        "overdue_events": overdueEvents.length,
        "events_by_type": eventsByType,
        "events_by_status": eventsByStatus,
      };
    } catch (e) {
      throw Exception("Failed to get calendar statistics: $e");
    }
  }
}
