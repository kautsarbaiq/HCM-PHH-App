import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../theme/app_colors.dart';
import '../widgets/booking_bottom_sheet.dart';
import '../widgets/facility_card.dart';

// State Management
final facilitiesProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {
        'id': 'f1',
        'name': 'Swimming Pool',
        'icon': PhosphorIconsRegular.swimmingPool,
      },
      {
        'id': 'f2',
        'name': 'Gym Fitness Center',
        'icon': PhosphorIconsRegular.barbell,
      },
      {
        'id': 'f3',
        'name': 'BBQ Pit',
        'icon': PhosphorIconsRegular.fire,
      },
      {
        'id': 'f4',
        'name': 'Tennis Court',
        'icon': PhosphorIconsRegular.tennisBall,
      },
      {
        'id': 'f5',
        'name': 'Multipurpose Hall',
        'icon': PhosphorIconsRegular.buildings,
      },
      {
        'id': 'f6',
        'name': 'Children Playground',
        'icon': PhosphorIconsRegular.baby,
      },
    ]);

class FacilityPage extends ConsumerWidget {
  const FacilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = ref.watch(facilitiesProvider);

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
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final facility = facilities[index];
                  return FacilityCard(
                    icon: facility['icon'],
                    name: facility['name'],
                    onBook: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => BookingBottomSheet(
                          facilityName: facility['name'],
                        ),
                      );
                    },
                  );
                },
                childCount: facilities.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
