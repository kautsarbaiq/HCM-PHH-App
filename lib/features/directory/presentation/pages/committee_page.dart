import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final committeeProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {'name': 'Datin Sri Hartini', 'role': 'Chairperson', 'unit': 'A-12-01', 'initials': 'DH'},
      {'name': 'Mr. Rajesh Kumar', 'role': 'Secretary', 'unit': 'B-08-15', 'initials': 'RK'},
      {'name': 'Ms. Emily Tan', 'role': 'Treasurer', 'unit': 'C-05-02', 'initials': 'ET'},
      {'name': 'Mr. Ahmad Faizal', 'role': 'Building Manager', 'unit': 'Office LG', 'initials': 'AF'},
    ]);

class CommitteePage extends ConsumerWidget {
  const CommitteePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(committeeProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey, pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('Committee', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
              final m = members[index];
              return Padding(padding: const EdgeInsets.only(bottom: 16), child: GlassCard(padding: const EdgeInsets.all(20), child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.sageGreen.withOpacity(0.12), shape: BoxShape.circle),
                  child: Center(child: Text(m['initials'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageGreen)))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(m['role'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sageGreen)),
                  Text('Unit ${m['unit']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.sageGreen.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(PhosphorIconsRegular.phone, color: AppColors.sageGreen, size: 20)),
              ])));
            }, childCount: members.length)),
          ),
        ],
      ),
    );
  }
}
