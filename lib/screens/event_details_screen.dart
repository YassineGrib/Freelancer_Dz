import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/calendar_event_model.dart';
import '../services/calendar_service.dart';
import '../widgets/custom_button.dart';
import 'add_event_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final CalendarEventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late CalendarEventModel _event;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _markAsCompleted() async {
    setState(() => _isLoading = true);

    try {
      final updatedEvent = await CalendarService.markEventAsCompleted(_event.id!);
      setState(() => _event = updatedEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event marked as completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating event: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await CalendarService.deleteEvent(_event.id!);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime, bool isAllDay) {
    if (isAllDay) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Event Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEventScreen(event: _event),
                ),
              );
              if (result == true) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.edit, color: AppColors.primary),
          ),
          IconButton(
            onPressed: _deleteEvent,
            icon: const Icon(Icons.delete, color: AppColors.error),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: _event.type.color.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: _event.type.color.withOpacity( 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _event.type.color.withOpacity( 0.2),
                        ),
                        child: Icon(
                          _event.type.icon,
                          color: _event.type.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _event.title,
                              style: GoogleFonts.poppins(
                                fontSize: AppConstants.textLarge,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _event.type.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: AppConstants.textMedium,
                                color: _event.type.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_event.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _event.description!,
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.textMedium,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Event Details
            _buildDetailCard(
              title: 'Event Information',
              children: [
                _buildDetailRow(
                  icon: Icons.schedule,
                  label: 'Start Date',
                  value: _formatDateTime(_event.startDate, _event.isAllDay),
                ),
                if (_event.endDate != null)
                  _buildDetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'End Date',
                    value: _formatDateTime(_event.endDate!, _event.isAllDay),
                  ),
                if (_event.location != null)
                  _buildDetailRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: _event.location!,
                  ),
                _buildDetailRow(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _event.isAllDay ? 'All Day' : '${_event.duration.inHours}h ${_event.duration.inMinutes % 60}m',
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Status & Priority
            _buildDetailCard(
              title: 'Status & Priority',
              children: [
                _buildDetailRow(
                  icon: _event.status.icon,
                  label: 'Status',
                  value: _event.status.displayName,
                  valueColor: _event.status.color,
                ),
                _buildDetailRow(
                  icon: Icons.flag,
                  label: 'Priority',
                  value: _event.priority.displayName,
                  valueColor: _event.priority.color,
                ),
                if (_event.isOverdue)
                  _buildDetailRow(
                    icon: Icons.warning,
                    label: 'Overdue',
                    value: 'This event is overdue',
                    valueColor: AppColors.error,
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Metadata
            if (_event.createdAt != null || _event.updatedAt != null)
              _buildDetailCard(
                title: 'Metadata',
                children: [
                  _buildDetailRow(
                    icon: Icons.add_circle,
                    label: 'Created',
                    value: _formatDateTime(_event.createdAt, false),
                  ),
                  if (_event.updatedAt != null)
                    _buildDetailRow(
                      icon: Icons.update,
                      label: 'Last Updated',
                      value: _formatDateTime(_event.updatedAt!, false),
                    ),
                ],
              ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Action Buttons
            if (_event.status != EventStatus.completed && _event.status != EventStatus.cancelled) ...[
              CustomButton(
                text: 'Mark as Completed',
                onPressed: _markAsCompleted,
                icon: Icons.check_circle,
                isLoading: _isLoading,
                backgroundColor: AppColors.success,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            CustomButton(
              text: 'Edit Event',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEventScreen(event: _event),
                  ),
                );
                if (result == true) {
                  Navigator.of(context).pop(true);
                }
              },
              icon: Icons.edit,
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: AppConstants.textMedium,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

