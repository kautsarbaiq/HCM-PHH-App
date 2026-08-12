import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/repositories/super_admin_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Super admin → Merchants (boss batch 08/08 point 1, third bullet).
/// Lists every merchant shop and lets the super admin enable/disable them.
/// Merchants manage their own shop profile and offers in the merchant portal.
class SuperMerchantsPage extends ConsumerWidget {
  const SuperMerchantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantAccountsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Merchants',
            subtitle: 'Shops offering rewards to residents',
          ),
          const SizedBox(height: 8),
          const Text(
            'Merchant accounts are created from the Companies screen. A '
            'merchant signs in to their own portal to set up their shop and '
            'offers.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: merchantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load merchants: $e',
                onRetry: () => ref.invalidate(merchantAccountsProvider),
              ),
              data: (merchants) {
                if (merchants.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No merchants yet',
                    message:
                        'Create a merchant account to let a shop offer rewards.',
                  );
                }
                return ListView.separated(
                  itemCount: merchants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final m = merchants[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.surfaceTint,
                        backgroundImage: (m.logoUrl ?? '').isNotEmpty
                            ? NetworkImage(m.logoUrl!)
                            : null,
                        child: (m.logoUrl ?? '').isEmpty
                            ? const Icon(Icons.storefront_rounded,
                                color: AppColors.brand)
                            : null,
                      ),
                      title: Text(
                        m.shopName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if ((m.category ?? '').isNotEmpty) m.category!,
                          if ((m.communityName ?? '').isNotEmpty)
                            m.communityName!,
                          if ((m.ownerEmail ?? '').isNotEmpty) m.ownerEmail!,
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(
                            label: m.isActive ? 'ACTIVE' : 'DISABLED',
                            color: m.isActive
                                ? AppColors.success
                                : AppColors.textSecondary,
                            dense: true,
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: m.isActive,
                            onChanged: (v) async {
                              await ref
                                  .read(superAdminRepositoryProvider)
                                  .setMerchantActive(m.id, v);
                              ref.invalidate(merchantAccountsProvider);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
