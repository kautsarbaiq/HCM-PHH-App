import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/brand.dart';
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
    final raw = await repo.getAllEvents();
    // Point 8: residents only see APPROVED events, plus their own proposals
    // (so a proposer can track pending/rejected). PHH shows everything.
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final all = Brand.isPhh
        ? raw
        : raw
              .where((e) => e.status == 'approved' || e.createdBy == myId)
              .toList();
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

  Future<void> _proposeEvent() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '100');
    DateTime? when;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setD) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Propose an Event',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Event title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Capacity (max attendees)',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      when == null
                          ? 'Pick date & time'
                          : DateFormat('MMM d, yyyy • HH:mm').format(when!),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: dctx,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (d == null) return;
                      final t = await showTimePicker(
                        context: dctx,
                        initialTime: TimeOfDay.now(),
                      );
                      setD(
                        () => when = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t?.hour ?? 9,
                          t?.minute ?? 0,
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Your event will be reviewed by management before it appears.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || when == null) return;
                Navigator.pop(dctx, true);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(eventRepositoryProvider)
          .createEventByResident(
            title: titleCtrl.text.trim(),
            description: descCtrl.text.trim(),
            location: locCtrl.text.trim(),
            eventDate: when!,
            capacity: (int.tryParse(capacityCtrl.text.trim()) ?? 100).clamp(
              1,
              100000,
            ),
          );
      ref.invalidate(eventsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event submitted for management approval.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// HCA (boss 16/07): share the public registration link so people from
  /// outside the community can register and receive a QR gate pass.
  Future<void> _shareInvite(CommunityEvent event) async {
    // The web app uses hash routing, so the path lives after `#`.
    final url = '${Brand.webBaseUrl}/#/event-invite/${event.id}';
    final text =
        "You're invited to ${event.title}! 🎉\n"
        '${_fmtDate(event.date)}'
        '${event.location.isNotEmpty ? ' • ${event.location}' : ''}\n'
        'Register here to get your gate pass for entry:\n'
        '$url';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// HCA: popup listing who has RSVP'd to an event.
  Future<void> _showAttendees(CommunityEvent event) async {
    List<String> names = [];
    try {
      names = await ref
          .read(eventRepositoryProvider)
          .getAttendeeNames(event.id);
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Attendees — ${event.title}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 360,
          child: event.attendees.isEmpty
              ? const Text(
                  'No one has RSVP\'d yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final n in names)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            PhosphorIconsRegular.userCircle,
                            color: AppColors.brand,
                          ),
                          title: Text(
                            n,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (names.length < event.attendees.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+ ${event.attendees.length - names.length} other'
                            '${event.attendees.length - names.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      // Point 8 (HCA): residents can propose an event for admin approval.
      floatingActionButton: Brand.isPhh
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.brand,
              onPressed: _proposeEvent,
              icon: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
              label: const Text(
                'Propose event',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
                                // HCA point 8: the proposer tracks their
                                // event's review status, like the web portal.
                                if (!Brand.isPhh &&
                                    event.status != 'approved') ...[
                                  const SizedBox(width: 8),
                                  StatusPill(
                                    label: event.status == 'pending'
                                        ? 'PENDING'
                                        : 'REJECTED',
                                    color: event.status == 'pending'
                                        ? AppColors.warning
                                        : AppColors.error,
                                    dense: true,
                                  ),
                                ] else if (isRsvpd) ...[
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
                            // HCA: a rejected proposal shows management's
                            // remarks so the resident knows why.
                            if (!Brand.isPhh &&
                                event.status == 'rejected' &&
                                (event.adminRemarks?.isNotEmpty ??
                                    false)) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.chatCircleText,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Management: ${event.adminRemarks}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // HCA (boss 16/07): the host can invite people
                            // from OUTSIDE the community — share a public
                            // registration link; guests get a QR gate pass.
                            if (!Brand.isPhh &&
                                event.status == 'approved' &&
                                event.createdBy == userId) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.brand,
                                    side: const BorderSide(
                                      color: AppColors.brand,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    PhosphorIconsRegular.shareNetwork,
                                    size: 18,
                                  ),
                                  label: const Text('Invite outside guests'),
                                  onPressed: () => _shareInvite(event),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  // HCA: tap the count to see who's coming.
                                  child: InkWell(
                                    onTap: Brand.isPhh
                                        ? null
                                        : () => _showAttendees(event),
                                    borderRadius: BorderRadius.circular(8),
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
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Brand.isPhh
                                                  ? AppColors.textPrimary
                                                  : AppColors.brand,
                                              decoration: Brand.isPhh
                                                  ? null
                                                  : TextDecoration.underline,
                                              decorationColor: AppColors.brand,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // HCA: only an approved event accepts RSVPs —
                                // pending/rejected proposals don't collect
                                // attendees — and a full event shows FULL
                                // instead of the RSVP button.
                                if (!Brand.isPhh &&
                                    event.status == 'approved' &&
                                    !isRsvpd &&
                                    event.capacity > 0 &&
                                    event.attending >= event.capacity)
                                  const StatusPill(
                                    label: 'FULL',
                                    color: AppColors.textSecondary,
                                    dense: true,
                                  )
                                else if (Brand.isPhh ||
                                    event.status == 'approved')
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
