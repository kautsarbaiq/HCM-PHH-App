import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wms_store.dart';
import '../models/placement_item.dart';
import '../widgets/scanner_page.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Placement (put-away) · scan a location tag to place received goods into a bin.
class PlacementPage extends ConsumerWidget {
  const PlacementPage({super.key});

  Future<void> _place(BuildContext context, WidgetRef ref, PlacementItem item) async {
    final code = await ScannerPage.open(
      context,
      title: 'Scan Location Tag',
      subtitle: 'Scan the bin/rack tag to place ${item.sku}',
    );
    if (code == null || !context.mounted) return;
    final result =
        await ref.read(wmsStoreProvider).placeByBarcodes(item.id, code);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? AppColors.success : AppColors.error,
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(wmsStoreProvider);
    final items = store.placements;
    final awaiting = items.where((i) => i.status == PlacementStatus.awaiting).toList();
    final placed = items.where((i) => i.status == PlacementStatus.placed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Placement')),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: store.loading && items.isEmpty
              ? const AppLoadingState()
              : store.error != null && items.isEmpty
              ? AppErrorState(
                  message: store.error!,
                  onRetry: () => ref.read(wmsStoreProvider).load(),
                )
              : items.isEmpty
              ? const AppEmptyState(
                  icon: Icons.shelves,
                  title: 'Nothing to place',
                  message: 'Received goods awaiting put-away will appear here.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    if (awaiting.isNotEmpty) ...[
                      _sectionLabel('Awaiting placement', awaiting.length),
                      ...awaiting.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AwaitingCard(
                              item: item,
                              onPlace: () => _place(context, ref, item),
                            ),
                          )),
                    ],
                    if (placed.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionLabel('Placed', placed.length),
                      ...placed.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PlacedCard(item: item),
                          )),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, int count) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          '$text · $count',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );
}

class _AwaitingCard extends StatelessWidget {
  final PlacementItem item;
  final VoidCallback onPlace;
  const _AwaitingCard({required this.item, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${item.sku}  ·  ${item.qty} units  ·  ${item.sourcePo}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusPill(label: item.status.label, color: item.status.color, dense: true),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlace,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan Location Tag'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacedCard extends StatelessWidget {
  final PlacementItem item;
  const _PlacedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.5,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(item.binCode ?? '-',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('  ·  ${item.qty} units',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}
