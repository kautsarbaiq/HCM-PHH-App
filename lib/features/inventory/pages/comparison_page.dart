import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/wms_store.dart';
import '../models/purchase_order.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Comparison · pick a received PO to reconcile expected vs received quantities.
class ComparisonPage extends ConsumerWidget {
  const ComparisonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(wmsStoreProvider);
    // Only POs that have had something received are worth comparing.
    final orders =
        store.orders.where((o) => o.status != ReceiveStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Comparison')),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: store.loading && store.orders.isEmpty
              ? const AppLoadingState()
              : store.error != null && store.orders.isEmpty
              ? AppErrorState(
                  message: store.error!,
                  onRetry: () => ref.read(wmsStoreProvider).load(),
                )
              : orders.isEmpty
              ? const AppEmptyState(
                  icon: Icons.compare_arrows_rounded,
                  title: 'Nothing to compare yet',
                  message: 'Receive against a PO first, then reconcile here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _CompareCard(order: orders[i]),
                ),
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final PurchaseOrder order;
  const _CompareCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final rows = order.items.map(ComparisonRow.fromItem).toList();
    final shortCount = rows.where((r) => r.type == VarianceType.short).length;
    final overCount = rows.where((r) => r.type == VarianceType.over).length;
    final matchCount = rows.where((r) => r.type == VarianceType.match).length;
    final clean = shortCount == 0 && overCount == 0;

    return GlassCard(
      onTap: () => context.push('/inventory/comparison/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.poNumber,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
              StatusPill(
                label: clean ? 'Reconciled' : 'Variance',
                color: clean ? AppColors.success : AppColors.warning,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.supplier,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(
            children: [
              _chip('$matchCount match', AppColors.success),
              const SizedBox(width: 8),
              if (shortCount > 0) _chip('$shortCount short', AppColors.error),
              if (shortCount > 0) const SizedBox(width: 8),
              if (overCount > 0) _chip('$overCount over', AppColors.warning),
              const Spacer(),
              Text('${order.totalReceived}/${order.totalExpected}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}
