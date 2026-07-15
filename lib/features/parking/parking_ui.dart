import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/repositories/parking_repository.dart';
import '../../theme/app_colors.dart';

/// ADMIN (point 14): manage a house's parking bays — add numbered bays,
/// delete them. Opened from the houses admin page.
Future<void> showAdminParkingSheet(
  BuildContext context,
  String houseId,
  String houseNumber,
) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AdminParkingSheet(houseId: houseId, houseNumber: houseNumber),
  );
}

class _AdminParkingSheet extends ConsumerWidget {
  final String houseId;
  final String houseNumber;
  const _AdminParkingSheet({required this.houseId, required this.houseNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baysAsync = ref.watch(houseParkingProvider(houseId));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parking bays — House $houseNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            baysAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (bays) => Column(
                children: [
                  if (bays.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No bays yet. Add the bay numbers for this house.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  for (final b in bays)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        PhosphorIconsRegular.car,
                        color: AppColors.brand,
                      ),
                      title: Text(
                        'Bay ${b.bayNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        b.plate == null
                            ? 'Unassigned'
                            : '${b.plate}${b.vehicleDetails != null ? ' • ${b.vehicleDetails}' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          await ref
                              .read(parkingRepositoryProvider)
                              .deleteBay(b.id);
                          ref.invalidate(houseParkingProvider(houseId));
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
              icon: const Icon(Icons.add),
              label: const Text('Add bay'),
              onPressed: () async {
                final ctrl = TextEditingController();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text('Add parking bay'),
                    content: TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Bay number (e.g. A-12)',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
                if (ok == true && ctrl.text.trim().isNotEmpty) {
                  await ref
                      .read(parkingRepositoryProvider)
                      .addBay(houseId, ctrl.text.trim());
                  ref.invalidate(houseParkingProvider(houseId));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// RESIDENT (point 15): the resident's parking bays on their profile, tap a
/// bay to assign/edit their car plate.
class MyParkingSection extends ConsumerWidget {
  const MyParkingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baysAsync = ref.watch(myParkingProvider);
    return baysAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (bays) {
        if (bays.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(PhosphorIconsFill.car, color: AppColors.brand, size: 18),
                SizedBox(width: 8),
                Text(
                  'My Parking',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A7BA8).withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final b in bays)
                    ListTile(
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.car,
                          color: AppColors.brand,
                        ),
                      ),
                      title: Text(
                        'Bay ${b.bayNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        b.plate == null
                            ? 'Tap to assign your car'
                            : '${b.plate}${b.vehicleDetails != null ? ' • ${b.vehicleDetails}' : ''}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.brand,
                        size: 18,
                      ),
                      onTap: () => _assign(context, ref, b),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    ParkingBay bay,
  ) async {
    final plateCtrl = TextEditingController(text: bay.plate ?? '');
    final detailCtrl = TextEditingController(text: bay.vehicleDetails ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bay ${bay.bayNumber} — my car'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Car plate (e.g. WXY 1234)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: detailCtrl,
              decoration: const InputDecoration(
                labelText: 'Car details — optional (e.g. Red Honda)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(parkingRepositoryProvider)
          .assignPlate(bay.id, plateCtrl.text, detailCtrl.text);
      ref.invalidate(myParkingProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
