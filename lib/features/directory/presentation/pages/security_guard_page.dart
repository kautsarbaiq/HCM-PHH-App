import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final guardsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {'name': 'Encik Roslan', 'shift': 'Day Shift (7AM - 7PM)', 'post': 'Main Gate', 'initials': 'ER', 'isOnDuty': true},
      {'name': 'Mr. Suresh', 'shift': 'Day Shift (7AM - 7PM)', 'post': 'Lobby', 'initials': 'MS', 'isOnDuty': true},
      {'name': 'Mr. Bakar', 'shift': 'Night Shift (7PM - 7AM)', 'post': 'Main Gate', 'initials': 'MB', 'isOnDuty': false},
      {'name': 'Mr. Tan Wei', 'shift': 'Night Shift (7PM - 7AM)', 'post': 'Patrol', 'initials': 'TW', 'isOnDuty': false},
    ]);

class SecurityGuardPage extends ConsumerWidget {
  const SecurityGuardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guards = ref.watch(guardsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey, pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('Security Guard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
              final g = guards[index];
              final bool onDuty = g['isOnDuty'];
              return Padding(padding: const EdgeInsets.only(bottom: 16), child: GlassCard(padding: const EdgeInsets.all(20), child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: onDuty ? AppColors.sageGreen.withOpacity(0.12) : AppColors.backgroundGrey, shape: BoxShape.circle,
                  border: Border.all(color: onDuty ? AppColors.sageGreen.withOpacity(0.3) : AppColors.glassBorder, width: 2)),
                  child: Center(child: Text(g['initials'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onDuty ? AppColors.sageGreen : AppColors.textSecondary)))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(g['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    if (onDuty) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.sageGreen, shape: BoxShape.circle)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${g['post']} — ${g['shift']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(
                  color: onDuty ? AppColors.sageGreen.withOpacity(0.15) : AppColors.backgroundGrey, borderRadius: BorderRadius.circular(8)),
                  child: Text(onDuty ? 'ON DUTY' : 'OFF DUTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: onDuty ? AppColors.sageGreen : AppColors.textSecondary))),
              ])));
            }, childCount: guards.length)),
          ),
        ],
      ),
    );
  }
}
