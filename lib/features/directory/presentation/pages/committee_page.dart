import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/directory_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

final committeeProvider = FutureProvider<List<Profile>>((ref) {
  return ref.read(directoryRepositoryProvider).getCommittee();
});

Future<void> _dialPhone(BuildContext context, String name, String phone) async {
  final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri(scheme: 'tel', path: sanitized);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open dialer for $name.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open dialer for $name.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// A small palette of vivid gradients cycled across avatars so the list reads
/// bright and lively rather than monotone.
const List<LinearGradient> _avatarGradients = [
  AppColors.brandGradient,
  AppColors.skyGradient,
  AppColors.mintGradient,
  AppColors.sunsetGradient,
];

class CommitteePage extends ConsumerWidget {
  const CommitteePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(committeeProvider);
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
                'Committee',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: membersAsync.when(
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
                      onRetry: () => ref.invalidate(committeeProvider),
                    ),
                  ),
                ),
                data: (members) {
                  if (members.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.groups_rounded,
                          title: 'No committee members listed',
                          message:
                              'Your residents’ committee members will appear here.',
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final m = members[index];
                      final gradient =
                          _avatarGradients[index % _avatarGradients.length];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: gradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: gradient.colors.first.withOpacity(
                                      0.32,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initialsOf(m.fullName),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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
                                    m.fullName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.position ?? 'Committee',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  if (m.email != null && m.email!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        m.email!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (m.phone != null && m.phone!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _dialPhone(context, m.fullName, m.phone!),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    PhosphorIconsRegular.phone,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }, childCount: members.length),
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
