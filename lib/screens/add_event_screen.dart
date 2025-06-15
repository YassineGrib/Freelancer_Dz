import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../models/calendar_event_model.dart';
import '../services/calendar_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddEventScreen extends StatefulWidget {
  final CalendarEventModel? event;

  const AddEventScreen({super.key, this.event});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  EventType _selectedType = EventType.custom;
  EventPriority _selectedPriority = EventPriority.medium;
  EventStatus _selectedStatus = EventStatus.scheduled;
  DateTime _selectedStartDate = DateTime.now();
  DateTime? _selectedEndDate;
  bool _isAllDay = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location ?? '';
    _selectedType = event.type;
    _selectedPriority = event.priority;
    _selectedStatus = event.status;
    _selectedStartDate = event.startDate;
    _selectedEndDate = event.endDate;
    _isAllDay = event.isAllDay;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event title is required';
    }
    return null;
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      if (!_isAllDay) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedStartDate),
        );
        if (time != null) {
          setState(() {
            _selectedStartDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      } else {
        setState(() {
          _selectedStartDate = DateTime(date.year, date.month, date.day);
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate.add(const Duration(hours: 1)),
      firstDate: _selectedStartDate,
      lastDate: DateTime(2030),
    );

    if (date != null) {
      if (!_isAllDay) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
            _selectedEndDate ?? _selectedStartDate.add(const Duration(hours: 1)),
          ),
        );
        if (time != null) {
          setState(() {
            _selectedEndDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      } else {
        setState(() {
          _selectedEndDate = DateTime(date.year, date.month, date.day);
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final event = CalendarEventModel(
        id: widget.event?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        status: _selectedStatus,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        isAllDay: _isAllDay,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: widget.event != null ? DateTime.now() : null,
      );

      if (widget.event == null) {
        await CalendarService.addEvent(event);
      } else {
        await CalendarService.updateEvent(event);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.event == null ? 'Add Event' : 'Edit Event',
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            // Title
            CustomTextField(
              controller: _titleController,
              label: 'Event Title',
              hint: 'Enter event title',
              validator: _validateTitle,
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'Enter event description',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Location
            CustomTextField(
              controller: _locationController,
              label: 'Location (Optional)',
              hint: 'Enter event location',
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Event Type
            _buildDropdownField<EventType>(
              label: 'Event Type',
              value: _selectedType,
              items: EventType.values,
              onChanged: (value) => setState(() => _selectedType = value!),
              getDisplayText: (type) => type.displayName,
              getIcon: (type) => type.icon,
              getColor: (type) => type.color,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Priority
            _buildDropdownField<EventPriority>(
              label: 'Priority',
              value: _selectedPriority,
              items: EventPriority.values,
              onChanged: (value) => setState(() => _selectedPriority = value!),
              getDisplayText: (priority) => priority.displayName,
              getColor: (priority) => priority.color,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Status
            _buildDropdownField<EventStatus>(
              label: 'Status',
              value: _selectedStatus,
              items: EventStatus.values,
              onChanged: (value) => setState(() => _selectedStatus = value!),
              getDisplayText: (status) => status.displayName,
              getIcon: (status) => status.icon,
              getColor: (status) => status.color,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // All Day Toggle
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Day Event',
                    style: GoogleFonts.poppins(
                      fontSize: AppConstants.textMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Switch(
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Start Date
            _buildDateTimeField(
              label: 'Start Date & Time',
              dateTime: _selectedStartDate,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // End Date (Optional)
            _buildDateTimeField(
              label: 'End Date & Time (Optional)',
              dateTime: _selectedEndDate,
              onTap: _selectEndDate,
              isOptional: true,
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Save Button
            CustomButton(
              text: widget.event == null ? 'Add Event' : 'Update Event',
              onPressed: _saveEvent,
              icon: widget.event == null ? Icons.add : Icons.update,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) getDisplayText,
    IconData Function(T)? getIcon,
    Color Function(T)? getColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Row(
                  children: [
                    if (getIcon != null) ...[
                      Icon(
                        getIcon(item),
                        size: 16,
                        color: getColor?.call(item) ?? AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      getDisplayText(item),
                      style: GoogleFonts.poppins(
                        color: getColor?.call(item) ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? dateTime,
    required VoidCallback onTap,
    bool isOptional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppConstants.textSmall,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateTime != null
                      ? _isAllDay
                          ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
                          : '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                      : isOptional
                          ? 'Not set'
                          : 'Select date & time',
                  style: GoogleFonts.poppins(
                    color: dateTime != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

