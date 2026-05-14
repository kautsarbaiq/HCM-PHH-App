import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../theme/app_colors.dart';

final eventsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {
        'title': 'Community BBQ Night',
        'date': 'Nov 2, 2026 — 6:00 PM',
        'location': 'BBQ Pit, Level G',
        'attending': 34,
        'capacity': 50,
        'isRsvpd': false,
      },
      {
        'title': 'Yoga & Wellness Workshop',
        'date': 'Nov 8, 2026 — 8:00 AM',
        'location': 'Multipurpose Hall',
        'attending': 22,
        'capacity': 30,
        'isRsvpd': true,
      },
      {
        'title': 'Kids Art Competition',
        'date': 'Nov 15, 2026 — 10:00 AM',
        'location': 'Community Garden',
        'attending': 18,
        'capacity': 40,
        'isRsvpd': false,
      },
    ]);

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);

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
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = events[index];
                  final bool isRsvpd = event['isRsvpd'];
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
                                child: Text(event['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ),
                              if (isRsvpd)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.sageGreen.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('GOING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sageGreen, letterSpacing: 1)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(PhosphorIconsRegular.calendarBlank, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(event['date'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(PhosphorIconsRegular.mapPin, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(event['location'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${event['attending']}/${event['capacity']} attending', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              SizedBox(
                                width: 120,
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(isRsvpd ? 'RSVP cancelled' : 'RSVP confirmed!'), backgroundColor: AppColors.sageGreen),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRsvpd ? AppColors.backgroundGrey : AppColors.sageGreen,
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
            ),
          ),
        ],
      ),
    );
  }
}
