import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

import 'package:intl/intl.dart';

import '../../../../core/repositories/event_repository.dart';
import '../../../../core/repositories/profile_repository.dart';

final eventsProvider =
    AsyncNotifierProvider<EventsNotifier, List<CommunityEvent>>(
      () => EventsNotifier(),
    );

String _fmtDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    return DateFormat(
      'MMM dd, yyyy • HH:mm',
    ).format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

class EventsNotifier extends AsyncNotifier<List<CommunityEvent>> {
  @override
  Future<List<CommunityEvent>> build() async {
    final repo = ref.read(eventRepositoryProvider);
    final all = await repo.getAllEvents();
    // Upcoming events first (soonest on top), past ones pushed to the bottom —
    // a freshly created event is immediately visible, not buried under old
    // ones.
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    DateTime parse(CommunityEvent e) =>
        DateTime.tryParse(e.date) ?? DateTime(2000);
    final upcoming = all.where((e) => parse(e).isAfter(cutoff)).toList()
      ..sort((a, b) => parse(a).compareTo(parse(b)));
    final past = all.where((e) => !parse(e).isAfter(cutoff)).toList()
      ..sort((a, b) => parse(b).compareTo(parse(a)));
    return [...upcoming, ...past];
  }

  Future<void> toggleRsvp(String eventId) async {
    await ref.read(eventRepositoryProvider).toggleRsvp(eventId);
    ref.invalidateSelf();
  }
}

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  final Set<String> _pendingRsvp = {};

  Future<void> _toggleRsvp(String eventId) async {
    if (_pendingRsvp.contains(eventId)) return;
    setState(() => _pendingRsvp.add(eventId));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(eventsProvider.notifier).toggleRsvp(eventId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _pendingRsvp.remove(eventId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Events (RSVP)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: eventsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AppErrorState(
                      message: '$err',
                      onRetry: () => ref.invalidate(eventsProvider),
                    ),
                  ),
                ),
                data: (events) {
                  if (events.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.event_rounded,
                          title: 'No upcoming events',
                          message:
                              'Community events will appear here once they are scheduled.',
                          gradient: AppColors.sunsetGradient,
                        ),
                      ),
                    );
                  }
                  final userId = profileAsync.value?.id ?? '';

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = events[index];
                      final bool isRsvpd = event.attendees.contains(userId);
                      final bool isPending = _pendingRsvp.contains(event.id);
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const GradientIconBadge(
                                  icon: Icons.celebration_rounded,
                                  gradient: AppColors.sunsetGradient,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isRsvpd) ...[
                                  const SizedBox(width: 8),
                                  const StatusPill(
                                    label: 'GOING',
                                    color: AppColors.success,
                                    dense: true,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.calendarBlank,
                                  size: 16,
                                  color: AppColors.brand,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtDate(event.date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.mapPin,
                                  size: 16,
                                  color: AppColors.accentCoral,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        PhosphorIconsRegular.users,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${event.attending}/${event.capacity} attending',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _RsvpButton(
                                  isRsvpd: isRsvpd,
                                  isPending: isPending,
                                  onPressed: () => _toggleRsvp(event.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }, childCount: events.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RSVP action: a vivid brand-gradient pill when not yet attending, and a soft
/// neutral "Cancel" button once the user is going.
class _RsvpButton extends StatelessWidget {
  final bool isRsvpd;
  final bool isPending;
  final VoidCallback onPressed;

  const _RsvpButton({
    required this.isRsvpd,
    required this.isPending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color contentColor = isRsvpd ? AppColors.textSecondary : Colors.white;

    final child = Center(
      child: isPending
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: contentColor,
              ),
            )
          : Text(
              isRsvpd ? 'Cancel' : 'RSVP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: contentColor,
              ),
            ),
    );

    return Opacity(
      opacity: isPending ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isPending ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 120,
            height: 42,
            decoration: BoxDecoration(
              gradient: isRsvpd ? null : AppColors.brandGradient,
              color: isRsvpd ? AppColors.surfaceTint : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isRsvpd
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.brand.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
