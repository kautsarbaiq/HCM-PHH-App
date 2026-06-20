import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/repositories/contact_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

final contactsProvider = FutureProvider<List<EmergencyContact>>((ref) {
  return ref.read(contactRepositoryProvider).getContacts();
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

IconData _contactIcon(String? category) {
  switch (category) {
    case 'management':
      return PhosphorIconsRegular.buildings;
    case 'security':
      return PhosphorIconsRegular.shieldCheck;
    case 'maintenance':
      return PhosphorIconsRegular.wrench;
    case 'utility':
      return PhosphorIconsRegular.lightning;
    default:
      return PhosphorIconsRegular.phone;
  }
}

LinearGradient _contactGradient(String? category) {
  switch (category) {
    case 'management':
      return AppColors.brandGradient;
    case 'security':
      return AppColors.skyGradient;
    case 'maintenance':
      return AppColors.sunsetGradient;
    case 'utility':
      return AppColors.mintGradient;
    default:
      return AppColors.brandGradient;
  }
}

class EContactPage extends ConsumerWidget {
  const EContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
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
                'E-Contact',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: contactsAsync.when(
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
                      onRetry: () => ref.invalidate(contactsProvider),
                    ),
                  ),
                ),
                data: (contacts) {
                  if (contacts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.contact_phone_rounded,
                          title: 'No contacts listed',
                          message:
                              'Important community and emergency contacts will appear here.',
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final c = contacts[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            GradientIconBadge(
                              icon: _contactIcon(c.category),
                              gradient: _contactGradient(c.category),
                              size: 50,
                              iconSize: 24,
                              radius: 16,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  if (c.hours != null && c.hours!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        c.hours!,
                                        maxLines: 2,
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
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _dialPhone(context, c.name, c.phone),
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
                        ),
                      );
                    }, childCount: contacts.length),
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
