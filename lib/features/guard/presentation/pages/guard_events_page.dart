import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/event_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Guard view of community events (boss 01/08): security needs to know what is
/// happening in the area — when, where, and how many guests to expect — so they
/// can prepare the gate. Read-only; approved events only, upcoming first.
final guardEventsProvider =
    FutureProvider.autoDispose<List<CommunityEvent>>((ref) async {
  final all = await ref.watch(eventRepositoryProvider).getAllEvents();
  final approved = all.where((e) => e.status == 'approved').toList();
  DateTime when(CommunityEvent e) =>
      DateTime.tryParse(e.date) ?? DateTime(2100);
  // Upcoming first (soonest at top), then past events (most recent first).
  final now = DateTime.now();
  final upcoming = approved.where((e) => !when(e).isBefore(now)).toList()
    ..sort((a, b) => when(a).compareTo(when(b)));
  final past = approved.where((e) => when(e).isBefore(now)).toList()
    ..sort((a, b) => when(b).compareTo(when(a)));
  return [...upcoming, ...past];
});

class GuardEventsPage extends ConsumerWidget {
  const GuardEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(guardEventsProvider);
    final guestsAsync = ref.watch(eventGuestCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(guardEventsProvider);
          ref.invalidate(eventGuestCountsProvider);
        },
        child: eventsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          ),
          error: (e, _) => AppErrorState(
            message: 'Could not load events: $e',
            onRetry: () => ref.invalidate(guardEventsProvider),
          ),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No events',
                    message: 'Community events will appear here.',
                  ),
                ],
              );
            }
            final guests = guestsAsync.valueOrNull ?? const <String, int>{};
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: events.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Community Events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }
                final e = events[i - 1];
                return _EventCard(event: e, guests: guests[e.id] ?? 0);
              },
            );
          },
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CommunityEvent event;
  final int guests;
  const _EventCard({required this.event, required this.guests});

  bool get _isPast {
    final d = DateTime.tryParse(event.endDate ?? '') ??
        DateTime.tryParse(event.date);
    return d != null && d.isBefore(DateTime.now());
  }

  bool get _isToday {
    final d = DateTime.tryParse(event.date);
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  String get _dateLabel {
    final d = DateTime.tryParse(event.date);
    if (d == null) return event.date;
    return DateFormat('EEE, d MMM yyyy').format(d.toLocal());
  }

  String get _timeLabel {
    final d = DateTime.tryParse(event.date);
    if (d == null) return '';
    final start = DateFormat('HH:mm').format(d.toLocal());
    final end = DateTime.tryParse(event.endDate ?? '');
    return end == null
        ? start
        : '$start - ${DateFormat('HH:mm').format(end.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final total = event.attending + guests;
    return Opacity(
      opacity: _isPast ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isToday
                ? AppColors.brand.withOpacity(0.45)
                : const Color(0xFFE8EDF5),
            width: _isToday ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.sunsetGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if ((event.description ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            event.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isPast)
                  const StatusPill(
                      label: 'ENDED',
                      color: AppColors.textSecondary,
                      dense: true)
                else if (_isToday)
                  const StatusPill(
                      label: 'TODAY', color: AppColors.brand, dense: true),
              ],
            ),
            const SizedBox(height: 14),
            _row(PhosphorIconsRegular.calendarBlank, _dateLabel),
            const SizedBox(height: 6),
            _row(PhosphorIconsRegular.clock, _timeLabel),
            if (event.location.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _row(PhosphorIconsRegular.mapPin, event.location),
            ],
            const SizedBox(height: 6),
            _row(
              PhosphorIconsRegular.users,
              guests > 0
                  ? '$total expected  ($guests outside guest${guests == 1 ? '' : 's'})'
                  : '$total expected',
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
