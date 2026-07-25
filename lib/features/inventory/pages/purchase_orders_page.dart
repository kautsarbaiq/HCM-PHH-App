import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/wms_store.dart';
import '../models/purchase_order.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Receiving · list of purchase orders to receive against.
class PurchaseOrdersPage extends ConsumerWidget {
  const PurchaseOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(wmsStoreProvider);
    final orders = store.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: store.loading && orders.isEmpty
              ? const AppLoadingState()
              : store.error != null && orders.isEmpty
              ? AppErrorState(
                  message: store.error!,
                  onRetry: () => ref.read(wmsStoreProvider).load(),
                )
              : orders.isEmpty
              ? const AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No purchase orders',
                  message: 'New purchase orders will appear here to receive.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _PoCard(order: orders[i]),
                ),
        ),
      ),
    );
  }
}

class _PoCard extends StatelessWidget {
  final PurchaseOrder order;
  const _PoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');
    return GlassCard(
      onTap: () => context.push('/inventory/receiving/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.poNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(label: order.status.label, color: order.status.color, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.supplier,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _meta(Icons.list_alt_rounded, '${order.lineCount} items'),
              const SizedBox(width: 16),
              _meta(Icons.event_outlined, df.format(order.expectedDate)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProgressBar(
                  value: order.progress,
                  color: order.status.color,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${order.totalReceived}/${order.totalExpected}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
