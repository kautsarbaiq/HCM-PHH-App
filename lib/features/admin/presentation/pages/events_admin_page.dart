import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/event_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/app_states.dart';

final adminEventsProvider =
    AsyncNotifierProvider<AdminEventsNotifier, List<CommunityEvent>>(
      () => AdminEventsNotifier(),
    );

class AdminEventsNotifier extends AsyncNotifier<List<CommunityEvent>> {
  @override
  Future<List<CommunityEvent>> build() async {
    final repo = ref.read(eventRepositoryProvider);
    return repo.getAllEvents();
  }

  Future<void> addEvent({
    required String title,
    String? description,
    String? location,
    required DateTime eventDate,
    DateTime? endDate,
    int capacity = 100,
    String? imageUrl,
  }) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.createEvent(
      title: title,
      description: description,
      location: location,
      eventDate: eventDate,
      endDate: endDate,
      capacity: capacity,
      imageUrl: imageUrl,
    );
    ref.invalidateSelf();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.updateEvent(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteEvent(String id) async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.deleteEvent(id);
    ref.invalidateSelf();
  }
}

class EventsAdminPage extends ConsumerStatefulWidget {
  const EventsAdminPage({super.key});

  @override
  ConsumerState<EventsAdminPage> createState() => _EventsAdminPageState();
}

class _EventsAdminPageState extends ConsumerState<EventsAdminPage> {
  String _formatDateTime(String iso) {
    if (iso.isEmpty) return 'No date';
    try {
      return DateFormat(
        'MMM dd, yyyy • HH:mm',
      ).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  /// Picks a date then a time and combines them into a single DateTime.
  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return null;
    if (!mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return null;
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  void _showRsvps(CommunityEvent event) {
    final repo = ref.read(eventRepositoryProvider);
    final ids = event.attendees.map((e) => e.toString()).toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RSVPs — ${event.title}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.attending}/${event.capacity} attending',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: repo.getAttendeeProfiles(ids),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(
                          'Failed to load attendees: ${snapshot.error}',
                          style: const TextStyle(color: AppColors.error),
                        );
                      }
                      final profiles = snapshot.data ?? [];
                      if (profiles.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No one has RSVP\'d yet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: profiles.map((p) {
                          final name =
                              (p['full_name'] as String?)?.trim().isNotEmpty ==
                                  true
                              ? p['full_name'] as String
                              : 'Unknown resident';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceTint,
                              child: Icon(
                                Icons.person,
                                color: AppColors.brand,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.brand),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showForm({CommunityEvent? event}) {
    final isEdit = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    final locationController = TextEditingController(
      text: event?.location ?? '',
    );
    final capacityController = TextEditingController(
      text: (event?.capacity ?? 100).toString(),
    );

    DateTime? eventDate;
    if (isEdit && event.date.isNotEmpty) {
      eventDate = DateTime.tryParse(event.date)?.toLocal();
    }
    DateTime? endDate;
    if (isEdit && event.endDate != null && event.endDate!.isNotEmpty) {
      endDate = DateTime.tryParse(event.endDate!)?.toLocal();
    }
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                isEdit ? 'Edit Event' : 'Create Event',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(titleController, 'Title', Icons.title),
                      const SizedBox(height: 4),
                      _buildTextField(
                        descriptionController,
                        'Description',
                        Icons.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        locationController,
                        'Location',
                        Icons.place,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        capacityController,
                        'Capacity',
                        Icons.people,
                        isNumeric: true,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await _pickDateTime(
                            eventDate ?? DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => eventDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'Start Date & Time',
                            Icons.calendar_today,
                          ),
                          child: Text(
                            eventDate == null
                                ? 'Select date & time'
                                : DateFormat(
                                    'MMM dd, yyyy • HH:mm',
                                  ).format(eventDate!),
                            style: TextStyle(
                              color: eventDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await _pickDateTime(
                            endDate ?? eventDate ?? DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: _inputDecoration(
                            'End Date & Time (optional)',
                            Icons.event_available,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  endDate == null
                                      ? 'Select end date & time'
                                      : DateFormat(
                                          'MMM dd, yyyy • HH:mm',
                                        ).format(endDate!),
                                  style: TextStyle(
                                    color: endDate == null
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (endDate != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () =>
                                      setDialogState(() => endDate = null),
                                  tooltip: 'Clear end date',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (titleController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter an event title.'),
                              ),
                            );
                            return;
                          }
                          if (eventDate == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a start date & time.',
                                ),
                              ),
                            );
                            return;
                          }
                          final capacity =
                              int.tryParse(capacityController.text.trim()) ??
                              100;
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminEventsProvider.notifier)
                                  .updateEvent(event.id, {
                                    'title': titleController.text,
                                    'description':
                                        descriptionController.text.isEmpty
                                        ? null
                                        : descriptionController.text,
                                    'location': locationController.text,
                                    'event_date': eventDate!
                                        .toUtc()
                                        .toIso8601String(),
                                    'end_date': endDate
                                        ?.toUtc()
                                        .toIso8601String(),
                                    'capacity': capacity,
                                  });
                            } else {
                              await ref
                                  .read(adminEventsProvider.notifier)
                                  .addEvent(
                                    title: titleController.text,
                                    description:
                                        descriptionController.text.isEmpty
                                        ? null
                                        : descriptionController.text,
                                    location: locationController.text,
                                    eventDate: eventDate!,
                                    endDate: endDate,
                                    capacity: capacity,
                                  );
                            }
                            navigator.pop();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showError(e);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.textSecondary)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brand),
          ),
        ),
      ),
    );
  }

  void _deleteEvent(CommunityEvent event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: const Text(
            'Delete Event',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text('Are you sure you want to delete "${event.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref
                      .read(adminEventsProvider.notifier)
                      .deleteEvent(event.id);
                  navigator.pop();
                } catch (e) {
                  _showError(e);
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Events',
                  subtitle: 'Schedule and manage community events',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminEventsProvider),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.event_rounded,
                    title: 'No events scheduled yet',
                    message:
                        'Create your first community event for residents to RSVP.',
                    actionLabel: 'Create Event',
                    onAction: () => _showForm(),
                    gradient: AppColors.sunsetGradient,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminEventsProvider),
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final e = events[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const GradientIconBadge(
                            icon: Icons.celebration_rounded,
                            gradient: AppColors.sunsetGradient,
                            size: 46,
                          ),
                          title: Text(
                            e.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 13,
                                      color: AppColors.brand,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _formatDateTime(e.date),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place,
                                      size: 13,
                                      color: AppColors.accentCoral,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        e.location.isEmpty
                                            ? 'No location'
                                            : e.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      size: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${e.attending}/${e.capacity} attending',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: AppColors.brand,
                                ),
                                onPressed: () => _showRsvps(e),
                                tooltip: 'View RSVPs',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.accentAmber,
                                ),
                                onPressed: () => _showForm(event: e),
                                tooltip: 'Edit Event',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteEvent(e),
                                tooltip: 'Delete Event',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
