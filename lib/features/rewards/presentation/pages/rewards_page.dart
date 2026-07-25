import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/rewards_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Owner rewards (meeting 20/07 point 9): pay bills on time in a row to unlock
/// partner-brand discounts. Owners claim an offer here; an admin approves it
/// and issues a voucher code.
class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myOntimeStreakProvider);
    ref.invalidate(rewardOffersProvider);
    ref.invalidate(myRewardClaimsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(myOntimeStreakProvider);
    final offersAsync = ref.watch(rewardOffersProvider);
    final claimsAsync = ref.watch(myRewardClaimsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Rewards',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _StreakCard(streakAsync: streakAsync),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Available rewards',
              subtitle: 'Unlock more by paying bills on time',
            ),
            const SizedBox(height: 8),
            offersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.brand),
                ),
              ),
              error: (e, _) => AppErrorState(
                message: 'Could not load rewards: $e',
                onRetry: () => ref.invalidate(rewardOffersProvider),
              ),
              data: (offers) {
                if (offers.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.card_giftcard_rounded,
                    title: 'No rewards yet',
                    message: 'Partner offers from management will appear here.',
                  );
                }
                final streak = streakAsync.valueOrNull ?? 0;
                final claims = claimsAsync.valueOrNull ?? const <RewardClaim>[];
                return Column(
                  children: [
                    for (final o in offers)
                      _OfferCard(
                        offer: o,
                        streak: streak,
                        claim: _claimFor(claims, o.id),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'My vouchers',
              subtitle: 'Claims and their status',
            ),
            const SizedBox(height: 8),
            claimsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (claims) {
                if (claims.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No vouchers yet',
                    message: 'Claim a reward above to see it here.',
                  );
                }
                return Column(
                  children: [for (final c in claims) _ClaimCard(claim: c)],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  RewardClaim? _claimFor(List<RewardClaim> claims, String offerId) {
    for (final c in claims) {
      if (c.offerId == offerId && c.status != 'rejected') return c;
    }
    return null;
  }
}

class _StreakCard extends StatelessWidget {
  final AsyncValue<int> streakAsync;
  const _StreakCard({required this.streakAsync});

  @override
  Widget build(BuildContext context) {
    final streak = streakAsync.valueOrNull ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.medal, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak == 1
                      ? 'bill paid on time in a row'
                      : 'bills paid on time in a row',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep paying on time to unlock bigger discounts.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends ConsumerStatefulWidget {
  final RewardOffer offer;
  final int streak;
  final RewardClaim? claim;
  const _OfferCard({required this.offer, required this.streak, this.claim});

  @override
  ConsumerState<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<_OfferCard> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(rewardsRepositoryProvider).claimOffer(widget.offer.id);
      ref.invalidate(myRewardClaimsProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Claim submitted — management will review it.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final unlocked = widget.streak >= o.minStreak;
    final claim = widget.claim;

    Widget trailing;
    if (claim != null) {
      trailing = StatusPill(
        label: claim.status == 'approved' ? 'CLAIMED' : 'PENDING',
        color: claim.status == 'approved'
            ? AppColors.success
            : AppColors.warning,
        dense: true,
      );
    } else if (!unlocked) {
      final need = o.minStreak - widget.streak;
      trailing = StatusPill(
        label: '$need MORE',
        color: AppColors.textSecondary,
        dense: true,
      );
    } else if (_busy) {
      trailing = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      trailing = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _claim,
        child: const Text('Claim'),
      );
    }

    return Opacity(
      opacity: unlocked || claim != null ? 1 : 0.65,
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.sunsetGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '${o.discountPercent}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    '${o.partnerName} • unlock at ${o.minStreak} on-time bills',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final RewardClaim claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final approved = claim.status == 'approved';
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved
                ? PhosphorIconsFill.ticket
                : PhosphorIconsRegular.clock,
            color: approved ? AppColors.success : AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${claim.offerTitle ?? 'Reward'}'
                  '${claim.discountPercent != null ? ' — ${claim.discountPercent}%' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                if ((claim.partnerName ?? '').isNotEmpty)
                  Text(
                    claim.partnerName!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (approved && (claim.voucherCode ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Voucher: ${claim.voucherCode}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          StatusPill(
            label: claim.status.toUpperCase(),
            color: approved ? AppColors.success : AppColors.warning,
            dense: true,
          ),
        ],
      ),
    );
  }
}
