import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/repositories/facility_repository.dart';
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

class FacilityPage extends ConsumerWidget {
  const FacilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);

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
            title: const Text(
              'Book Facilities',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Could not load facilities: $err',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              data: (facilities) {
                if (facilities.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No facilities available.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        ],
      ),
    );
  }
}
