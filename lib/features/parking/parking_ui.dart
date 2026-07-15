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
                        b.plate == null && b.vehicleSummary == null
                            ? 'Unassigned'
                            : [
                                b.plate,
                                b.vehicleSummary,
                              ].whereType<String>().join(' — '),
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

/// RESIDENT (point 15): the resident's parking bays, rendered as extra rows
/// INSIDE the profile info card (below House Address). Tap the pencil to
/// assign/edit the car on that bay.
class MyParkingRows extends ConsumerWidget {
  const MyParkingRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baysAsync = ref.watch(myParkingProvider);
    final bays = baysAsync.valueOrNull ?? const <ParkingBay>[];
    return Column(
      children: [
        for (final b in bays) ...[
          const Divider(height: 32, thickness: 0.5),
          Row(
            children: [
              const GradientIconBadge(
                icon: PhosphorIconsRegular.car,
                gradient: AppColors.skyGradient,
                size: 44,
                iconSize: 20,
                radius: 13,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parking Bay ${b.bayNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.plate == null && b.vehicleSummary == null
                          ? 'Tap to assign your car'
                          : [
                              b.plate,
                              b.vehicleSummary,
                            ].whereType<String>().join(' — '),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.pencilSimple,
                  size: 18,
                  color: AppColors.brand,
                ),
                tooltip: 'Assign car',
                visualDensity: VisualDensity.compact,
                onPressed: () => _assign(context, ref, b),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    ParkingBay bay,
  ) async {
    final plateCtrl = TextEditingController(text: bay.plate ?? '');
    final makeCtrl = TextEditingController(text: bay.vehicleMake ?? '');
    final modelCtrl = TextEditingController(text: bay.vehicleModel ?? '');
    final yearCtrl = TextEditingController(text: bay.vehicleYear ?? '');
    final colorCtrl = TextEditingController(text: bay.vehicleColor ?? '');

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F6FB),
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
