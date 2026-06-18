import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/directory_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final committeeProvider = FutureProvider<List<Profile>>((ref) {
  return ref.read(directoryRepositoryProvider).getCommittee();
});

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

class CommitteePage extends ConsumerWidget {
  const CommitteePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(committeeProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('Committee', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: membersAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))))),
              data: (members) {
                if (members.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No committee members listed.', style: TextStyle(color: AppColors.textSecondary)))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final m = members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), shape: BoxShape.circle),
                            child: Center(child: Text(initialsOf(m.fullName), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(m.position ?? 'Committee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryBlue)),
                            if (m.email != null && m.email!.isNotEmpty) Text(m.email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ])),
                          if (m.phone != null && m.phone!.isNotEmpty)
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(PhosphorIconsRegular.phone, color: AppColors.primaryBlue, size: 20)),
                        ]),
                      ),
                    );
                  }, childCount: members.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
