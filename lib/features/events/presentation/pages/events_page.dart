import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

import 'package:intl/intl.dart';

import '../../../../core/repositories/event_repository.dart';
import '../../../../core/repositories/profile_repository.dart';

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<CommunityEvent>>(() => EventsNotifier());

String _fmtDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

class EventsNotifier extends AsyncNotifier<List<CommunityEvent>> {
  @override
  Future<List<CommunityEvent>> build() async {
    final repo = ref.read(eventRepositoryProvider);
    return repo.getAllEvents();
  }

  Future<void> toggleRsvp(String eventId) async {
    await ref.read(eventRepositoryProvider).toggleRsvp(eventId);
    ref.invalidateSelf();
  }
}

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft),
              onPressed: () => context.pop(),
            ),
            title: const Text('Events (RSVP)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: eventsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              data: (events) {
                if (events.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Text('No upcoming events.', style: TextStyle(color: AppColors.textSecondary))));
                }
                final userId = profileAsync.value?.id ?? '';
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = events[index];
                      final bool isRsvpd = event.attendees.contains(userId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  ),
                                  if (isRsvpd)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('GOING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryBlue, letterSpacing: 1)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.calendarBlank, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(_fmtDate(event.date), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.mapPin, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(event.location, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${event.attending}/${event.capacity} attending', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                  SizedBox(
                                    width: 120,
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        try {
                                          await ref.read(eventsProvider.notifier).toggleRsvp(event.id);
                                        } catch (e) {
                                          messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isRsvpd ? AppColors.backgroundGrey : AppColors.primaryBlue,
                                        foregroundColor: isRsvpd ? AppColors.textSecondary : Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(isRsvpd ? 'Cancel' : 'RSVP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: events.length,
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
