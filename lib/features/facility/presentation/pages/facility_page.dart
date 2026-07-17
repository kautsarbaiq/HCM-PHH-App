import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/repositories/facility_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/booking_bottom_sheet.dart';
import '../widgets/facility_card.dart';

final facilitiesProvider = FutureProvider<List<Facility>>((ref) {
  return ref.read(facilityRepositoryProvider).getAllFacilities();
});

/// Current user's bookings. Invalidate this after creating a booking so any
/// bookings list refreshes instead of showing stale data.
final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return <Booking>[];
  return ref.read(facilityRepositoryProvider).getMyBookings(uid);
});

IconData _facilityIcon(String? iconName) {
  switch (iconName) {
    case 'swimming':
      return PhosphorIconsRegular.swimmingPool;
    case 'gym':
      return PhosphorIconsRegular.barbell;
    case 'bbq':
      return PhosphorIconsRegular.fire;
    case 'tennis':
      return PhosphorIconsRegular.tennisBall;
    case 'hall':
      return PhosphorIconsRegular.buildings;
    case 'playground':
      return PhosphorIconsRegular.baby;
    default:
      return PhosphorIconsRegular.buildings;
  }
}

/// Booking slot as a DateTime, so a slot earlier today counts as past.
DateTime? bookingSlot(Booking b) {
  try {
    final d = DateTime.parse(b.date);
    final p = b.time.split(':');
    return DateTime(
      d.year,
      d.month,
      d.day,
      int.parse(p[0]),
      p.length > 1 ? int.parse(p[1]) : 0,
    );
  } catch (_) {
    return null;
  }
}

({String label, Color color}) _bookingStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'confirmed':
    case 'approved':
      return (label: 'APPROVED', color: AppColors.success);
    case 'rejected':
      return (label: 'REJECTED', color: AppColors.error);
    case 'cancelled':
      return (label: 'CANCELLED', color: AppColors.textSecondary);
    default:
      return (label: 'PENDING', color: AppColors.warning);
  }
}

class FacilityPage extends ConsumerWidget {
  const FacilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

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
                'Book Facilities',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: SectionHeader(
                  title: 'Community amenities',
                  subtitle: 'Reserve a slot for shared facilities',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: facilitiesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: AppErrorState(
                    message: 'Could not load facilities: $err',
                    onRetry: () => ref.invalidate(facilitiesProvider),
                  ),
                ),
                data: (facilities) {
                  if (facilities.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: AppEmptyState(
                        icon: PhosphorIconsRegular.buildings,
                        title: 'No facilities available',
                        message: 'Bookable amenities will appear here.',
                        gradient: AppColors.skyGradient,
                      ),
                    );
                  }
                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final facility = facilities[index];
                      return FacilityCard(
                        icon: _facilityIcon(facility.iconName),
                        name: facility.name,
                        onBook: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                BookingBottomSheet(facilityName: facility.name),
                          );
                        },
                      );
                    }, childCount: facilities.length),
                  );
                },
              ),
            ),
            // Boss 17/07: residents had no way to see their bookings or
            // whether management approved them.
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: SectionHeader(
                  title: 'My Bookings',
                  subtitle: 'Your requests and their approval status',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              sliver: _MyBookingsSliver(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyBookingsSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    return bookingsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: AppErrorState(
          message: 'Could not load your bookings: $err',
          onRetry: () => ref.invalidate(myBookingsProvider),
        ),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const SliverToBoxAdapter(
            child: AppEmptyState(
              icon: PhosphorIconsRegular.calendarCheck,
              title: 'No bookings yet',
              message: 'Book a facility above and it will appear here.',
              gradient: AppColors.skyGradient,
            ),
          );
        }
        // Newest slot first, so the latest request is on top.
        final list = [...bookings]
          ..sort((a, b) {
            final da = bookingSlot(a), db = bookingSlot(b);
            if (da == null || db == null) return b.date.compareTo(a.date);
            return db.compareTo(da);
          });
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, i) {
            final b = list[i];
            final st = _bookingStatus(b.status);
            final slot = bookingSlot(b);
            final isPast = slot != null && slot.isBefore(DateTime.now());
            return Opacity(
              opacity: isPast ? 0.55 : 1,
              child: PremiumCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GradientIconBadge(
                      icon: PhosphorIconsRegular.calendarCheck,
                      gradient: AppColors.skyGradient,
                      size: 44,
                      iconSize: 20,
                      radius: 13,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.facilityName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            slot == null
                                ? '${b.date} · ${b.time}'
                                : '${DateFormat('EEE, MMM d, yyyy').format(slot)} · ${b.time}'
                                      '${isPast ? ' · past' : ''}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(label: st.label, color: st.color, dense: true),
                  ],
                ),
              ),
            );
          }, childCount: list.length),
        );
      },
    );
  }
}
