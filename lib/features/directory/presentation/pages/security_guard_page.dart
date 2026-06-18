import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/directory_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import 'committee_page.dart' show initialsOf;

final guardsProvider = FutureProvider<List<Profile>>((ref) {
  return ref.read(directoryRepositoryProvider).getGuards();
});

class SecurityGuardPage extends ConsumerWidget {
  const SecurityGuardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardsAsync = ref.watch(guardsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('Security Guard', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: guardsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))))),
              data: (guards) {
                if (guards.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No guards listed.', style: TextStyle(color: AppColors.textSecondary)))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final g = guards[index];
                    final onDuty = g.onDuty;
                    final detail = [g.post, g.shift].where((e) => e != null && e.isNotEmpty).join(' — ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: onDuty ? AppColors.primaryBlue.withOpacity(0.12) : AppColors.backgroundGrey,
                              shape: BoxShape.circle,
                              border: Border.all(color: onDuty ? AppColors.primaryBlue.withOpacity(0.3) : AppColors.glassBorder, width: 2),
                            ),
                            child: Center(child: Text(initialsOf(g.fullName), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onDuty ? AppColors.primaryBlue : AppColors.textSecondary))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text(g.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                              const SizedBox(width: 8),
                              if (onDuty) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle)),
                            ]),
                            const SizedBox(height: 4),
                            Text(detail.isEmpty ? 'Security Guard' : detail, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: onDuty ? AppColors.primaryBlue.withOpacity(0.15) : AppColors.backgroundGrey, borderRadius: BorderRadius.circular(8)),
                            child: Text(onDuty ? 'ON DUTY' : 'OFF DUTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: onDuty ? AppColors.primaryBlue : AppColors.textSecondary)),
                          ),
                        ]),
                      ),
                    );
                  }, childCount: guards.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
