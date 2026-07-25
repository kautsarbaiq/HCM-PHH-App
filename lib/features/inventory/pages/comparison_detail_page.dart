import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wms_store.dart';
import '../models/purchase_order.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Comparison detail · per-line expected vs received reconciliation.
class ComparisonDetailPage extends ConsumerWidget {
  final String poId;
  const ComparisonDetailPage({super.key, required this.poId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(wmsStoreProvider).orderById(poId);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comparison')),
        body: const AppEmptyState(icon: Icons.error_outline, title: 'PO not found'),
      );
    }

    final rows = order.items.map(ComparisonRow.fromItem).toList();
    final totalExpected = order.totalExpected;
    final totalReceived = order.totalReceived;
    final totalVariance = totalReceived - totalExpected;

    return Scaffold(
      appBar: AppBar(title: Text('${order.poNumber} · Compare')),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GlassCard(
                child: Row(
                  children: [
                    _summary('Expected', '$totalExpected', AppColors.textPrimary),
                    _divider(),
                    _summary('Received', '$totalReceived', AppColors.brand),
                    _divider(),
                    _summary(
                      'Variance',
                      totalVariance > 0 ? '+$totalVariance' : '$totalVariance',
                      totalVariance == 0
                          ? AppColors.success
                          : (totalVariance < 0 ? AppColors.error : AppColors.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    const _HeaderRow(),
                    const Divider(height: 1),
                    ...rows.map((r) => _Row(row: r)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 34, color: const Color(0xFFE6EAF5));
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary);
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('ITEM', style: style)),
          Expanded(flex: 2, child: Text('EXP', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('RECV', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text('VARIANCE', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final ComparisonRow row;
  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.sku,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 1),
                Text(row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${row.expected}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: Text('${row.received}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: StatusPill(
                label: row.variance == 0
                    ? row.type.label
                    : '${row.type.label} ${row.variance > 0 ? '+' : ''}${row.variance}',
                color: row.type.color,
                dense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
