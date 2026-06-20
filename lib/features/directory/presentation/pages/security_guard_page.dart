import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/directory_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
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
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Security Guard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: guardsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AppErrorState(
                      message: '$e',
                      onRetry: () => ref.invalidate(guardsProvider),
                    ),
                  ),
                ),
                data: (guards) {
                  if (guards.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.shield_rounded,
                          title: 'No guards listed',
                          message:
                              'On-duty and off-duty security guards will appear here.',
                          gradient: AppColors.skyGradient,
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final g = guards[index];
                      final onDuty = g.onDuty;
                      final detail = [
                        g.post,
                        g.shift,
                      ].where((e) => e != null && e.isNotEmpty).join(' — ');
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: onDuty ? AppColors.skyGradient : null,
                                color: onDuty ? null : AppColors.surfaceTint,
                                shape: BoxShape.circle,
                                boxShadow: onDuty
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentSky
                                              .withOpacity(0.32),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  initialsOf(g.fullName),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: onDuty
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    detail.isEmpty ? 'Security Guard' : detail,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(
                              label: onDuty ? 'ON DUTY' : 'OFF DUTY',
                              color: onDuty
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              dense: true,
                            ),
                          ],
                        ),
                      );
                    }, childCount: guards.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
