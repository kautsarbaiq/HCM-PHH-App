import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/wms_store.dart';
import '../models/pick_list.dart';
import '../widgets/app_states.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_pill.dart';
import '../../../theme/app_colors.dart';

/// Picking · list of pick tasks (sales orders to fulfil).
class PickingListPage extends ConsumerWidget {
  const PickingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(wmsStoreProvider);
    final lists = store.pickLists;

    return Scaffold(
      appBar: AppBar(title: const Text('Picking List')),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: store.loading && lists.isEmpty
              ? const AppLoadingState()
              : store.error != null && lists.isEmpty
              ? AppErrorState(
                  message: store.error!,
                  onRetry: () => ref.read(wmsStoreProvider).load(),
                )
              : lists.isEmpty
              ? const AppEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'No pick tasks',
                  message: 'Pick lists assigned to you will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: lists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _PickCard(list: lists[i]),
                ),
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final PickList list;
  const _PickCard({required this.list});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/inventory/picking/${list.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  list.reference,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusPill(label: list.status.label, color: list.status.color, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            list.customer,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ProgressBar(value: list.progress, color: list.status.color)),
              const SizedBox(width: 10),
              Text(
                '${list.totalPicked}/${list.totalToPick}',
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
}
