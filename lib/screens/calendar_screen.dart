import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:table_calendar/table_calendar.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/calendar_event_model.dart';
import '../services/calendar_service.dart';

import '../widgets/loading_widget.dart';

import 'add_event_screen.dart';
import 'event_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEventModel>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<CalendarEventModel>> _events = {};

  bool _isLoading = true;
  bool _isSyncing = false;
  bool _showColorGuide = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadCalendarData();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<CalendarEventModel> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    try {
      // First sync system events to ensure we have the latest deadlines
      await CalendarService.syncAllSystemEvents();

      // Then load events for current month
      final monthEvents = await CalendarService.getEventsForMonth(
        _focusedDay.year,
        _focusedDay.month,
      );

      setState(() {
        _events = monthEvents;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calendar: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncSystemEvents() async {
    setState(() => _isSyncing = true);

    try {
      await CalendarService.syncAllSystemEvents();
      await _loadCalendarData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System events synced successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing events: $e')),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadCalendarData(); // Reload events for new month
  }

  Widget _buildEventMarker(List<CalendarEventModel> events) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 1,
      right: 1,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _getEventsPriorityColor(events),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${events.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventsPriorityColor(List<CalendarEventModel> events) {
    if (events.any((e) => e.priority == EventPriority.urgent)) {
      return Colors.red;
    } else if (events.any((e) => e.priority == EventPriority.high)) {
      return Colors.orange;
    } else if (events.any((e) => e.priority == EventPriority.medium)) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  Widget _buildColorGuide() {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
      ),
      child: Column(
        children: [
          // Header with toggle
          InkWell(
            onTap: () {
              setState(() {
                _showColorGuide = !_showColorGuide;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  const Icon(
                    Icons.palette,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Event Priority Indicators',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showColorGuide ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible content
          if (_showColorGuide) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorGuideItem(
                          color: Colors.red,
                          label: 'Urgent',
                          icon: Icons.priority_high,
                        ),
                      ),
                      Expanded(
                        child: _buildColorGuideItem(
                          color: Colors.orange,
                          label: 'High',
                          icon: Icons.keyboard_arrow_up,
                        ),
                      ),
                      Expanded(
                        child: _buildColorGuideItem(
                          color: Colors.blue,
                          label: 'Medium',
                          icon: Icons.remove,
                        ),
                      ),
                      Expanded(
                        child: _buildColorGuideItem(
                          color: Colors.green,
                          label: 'Low',
                          icon: Icons.keyboard_arrow_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Colored circles on calendar dates show the highest priority event for that day',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textSmall,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorGuideItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: AppConstants.textSmall,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false, // Left alignment
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : _syncSystemEvents,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEventScreen(),
                ),
              );
              if (result == true) {
                _loadCalendarData();
              }
            },
            icon: const Icon(Icons.add, color: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Calendar Widget
                Container(
                  margin: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: const BoxDecoration(
                    color: AppColors.cardBackground,
                  ),
                  child: TableCalendar<CalendarEventModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle:
                          GoogleFonts.poppins(color: AppColors.error),
                      holidayTextStyle:
                          GoogleFonts.poppins(color: AppColors.error),
                      defaultTextStyle:
                          GoogleFonts.poppins(color: AppColors.textPrimary),
                      selectedTextStyle: GoogleFonts.poppins(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      todayTextStyle: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.rectangle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.rectangle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: const BoxDecoration(
                        color: AppColors.primary,
                      ),
                      formatButtonTextStyle: GoogleFonts.poppins(
                        color: AppColors.textWhite,
                        fontSize: 12,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: AppColors.primary,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                      ),
                      titleTextStyle: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: _onDaySelected,
                    onFormatChanged: _onFormatChanged,
                    onPageChanged: _onPageChanged,
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        return _buildEventMarker(events);
                      },
                    ),
                  ),
                ),

                // Color Guide
                _buildColorGuide(),
                const SizedBox(height: AppConstants.paddingMedium),

                // Selected Day Events
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Events for ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
                          style: GoogleFonts.poppins(
                            fontSize: AppConstants.textLarge,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              ValueListenableBuilder<List<CalendarEventModel>>(
                            valueListenable: _selectedEvents,
                            builder: (context, events, _) {
                              if (events.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.event_busy,
                                        size: 48,
                                        color: AppColors.textLight,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No events for this day',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  return _buildEventCard(event);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventCard(CalendarEventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: event.type.color.withOpacity(0.1),
          ),
          child: Icon(
            event.type.icon,
            color: event.type.color,
            size: 20,
          ),
        ),
        title: Text(
          event.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null)
              Text(
                event.description!,
                style: GoogleFonts.poppins(
                  fontSize: AppConstants.textSmall,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: event.priority.color.withOpacity(0.1),
                  ),
                  child: Text(
                    event.priority.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: event.priority.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: event.status.color.withOpacity(0.1),
                  ),
                  child: Text(
                    event.status.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: event.status.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textLight,
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );
          if (result == true) {
            _loadCalendarData();
          }
        },
      ),
    );
  }
}
