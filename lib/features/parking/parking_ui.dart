import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/repositories/parking_repository.dart';
import '../../core/widgets/premium_card.dart';
import '../../theme/app_colors.dart';

/// ADMIN (point 14): manage a house's parking bays — add numbered bays,
/// delete them. Opened from the houses admin page. Bottom sheet on phones,
/// centered dialog on laptop/desktop widths.
Future<void> showAdminParkingSheet(
  BuildContext context,
  String houseId,
  String houseNumber,
) {
  final isWide = MediaQuery.of(context).size.width >= 700;
  if (isWide) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _AdminParkingSheet(houseId: houseId, houseNumber: houseNumber),
        ),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _AdminParkingSheet(houseId: houseId, houseNumber: houseNumber),
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
        child: SingleChildScrollView(
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
                  // Same card format the resident sees (boss 16/07): a soft
                  // badge tile with the bay number and assigned car.
                  for (final b in bays)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
                        b.plate == null && b.vehicleSummary == null
                            ? 'Unassigned'
                            : [
                                b.plate,
                                b.vehicleSummary,
                              ].whereType<String>().join(' • '),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          // Root container: survives the sheet being
                          // dismissed while the request is in flight, so the
                          // houses-page Parking column still refreshes.
                          final container = ProviderScope.containerOf(
                            context,
                            listen: false,
                          );
                          await ref
                              .read(parkingRepositoryProvider)
                              .deleteBay(b.id);
                          container.invalidate(houseParkingProvider(houseId));
                          container.invalidate(allParkingBaysProvider);
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
                final container = ProviderScope.containerOf(
                  context,
                  listen: false,
                );
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
                  await container
                      .read(parkingRepositoryProvider)
                      .addBay(houseId, ctrl.text.trim());
                  container.invalidate(houseParkingProvider(houseId));
                  container.invalidate(allParkingBaysProvider);
                }
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// RESIDENT (point 15): the resident's parking bays as their OWN section on
/// the profile — a "My Parking" header plus a card of bays (boss 17/07: it
/// must stay separate, not mixed into the profile info card). Tap the pencil
/// to assign/edit the car on that bay.
class MyParkingSection extends ConsumerWidget {
  const MyParkingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baysAsync = ref.watch(myParkingProvider);
    final bays = baysAsync.valueOrNull ?? const <ParkingBay>[];
    if (bays.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: const [
            Icon(PhosphorIconsFill.car, color: AppColors.brand, size: 20),
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
        const SizedBox(height: 16),
        PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              for (final b in bays)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF0F5),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    b.plate == null && b.vehicleSummary == null
                        ? 'Tap to assign your car'
                        : [
                            b.plate,
                            b.vehicleSummary,
                          ].whereType<String>().join(' • '),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(
                    PhosphorIconsRegular.pencilSimple,
                    size: 18,
                    color: AppColors.brand,
                  ),
                  onTap: () => _assign(context, ref, b),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    ParkingBay bay,
  ) async {
    // Cars saved before the structured form live in the legacy free-text
    // `vehicle_details` (e.g. "Proton x70"). Without this the edit dialog came
    // up blank and looked like the saved car had been lost (boss 17/07).
    String legacyMake = '';
    String legacyModel = '';
    final hasStructured = [
      bay.vehicleMake,
      bay.vehicleModel,
      bay.vehicleYear,
      bay.vehicleColor,
    ].any((v) => (v ?? '').trim().isNotEmpty);
    if (!hasStructured && (bay.vehicleDetails ?? '').trim().isNotEmpty) {
      final parts = bay.vehicleDetails!.trim().split(RegExp(r'\s+'));
      legacyMake = parts.first;
      if (parts.length > 1) legacyModel = parts.sublist(1).join(' ');
    }

    final plateCtrl = TextEditingController(text: bay.plate ?? '');
    final makeCtrl = TextEditingController(
      text: bay.vehicleMake ?? (legacyMake.isEmpty ? '' : legacyMake),
    );
    final modelCtrl = TextEditingController(
      text: bay.vehicleModel ?? (legacyModel.isEmpty ? '' : legacyModel),
    );
    final yearCtrl = TextEditingController(text: bay.vehicleYear ?? '');
    final colorCtrl = TextEditingController(text: bay.vehicleColor ?? '');

    // hintText (not labelText) in a light grey, so the examples clearly read
    // as placeholders instead of looking like already-filled values.
    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.45),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bay ${bay.bayNumber} — my car'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plateCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: deco('Plate no. (e.g. WXY 1234)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: makeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: deco('Make (e.g. Honda)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: modelCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: deco('Model (e.g. Civic)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: deco('Year (e.g. 2020)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: colorCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: deco('Color (e.g. Red)'),
                ),
              ],
            ),
          ),
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
          .assignVehicle(
            bay.id,
            plate: plateCtrl.text,
            make: makeCtrl.text,
            model: modelCtrl.text,
            year: yearCtrl.text,
            color: colorCtrl.text,
          );
      ref.invalidate(myParkingProvider);
      ref.invalidate(allParkingBaysProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
