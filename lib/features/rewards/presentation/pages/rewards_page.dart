import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/brand.dart';
import '../../../../core/repositories/rewards_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/rewards/reward_tier.dart';
import '../../../../core/rewards/reward_tier_widgets.dart';
import '../../../../theme/app_colors.dart';

/// The URL a shop opens when it scans a voucher QR — the public redeem page.
String voucherRedeemUrl(String token) =>
    '${Brand.webBaseUrl}/#/redeem/$token';

/// Owner rewards (meeting 20/07 point 9): pay bills on time in a row to unlock
/// partner-brand discounts. Owners claim an offer here; an admin approves it
/// and issues a voucher code.
/// Partner brand chips for a tier, taken from the offers actually published
/// for that level — so the ladder shows real merchants, not placeholders.
List<String> _partnerNamesFor(WidgetRef ref, RewardTier tier) {
  final offers = ref.read(rewardOffersProvider).valueOrNull ?? const [];
  final names = <String>{};
  for (final o in offers) {
    if (RewardTierX.fromMinStreak(o.minStreak) != tier) continue;
    final n = o.partnerName.trim();
    if (n.isNotEmpty) names.add(n);
  }
  return names.take(4).toList();
}

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
    final standing = ref.watch(myRewardStandingProvider).valueOrNull;
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
            // Client mockup 27/08: the three membership levels, with the
            // resident's own level highlighted.
            const SectionHeader(
              title: 'Reward Tiers',
              subtitle: 'Membership levels',
            ),
            const SizedBox(height: 8),
            RewardTierLadder(
              current: standing?.tier,
              partnersFor: (tier) => _partnerNamesFor(ref, tier),
            ),
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
              title: 'My coupons',
              subtitle: 'Show the QR at the shop to redeem',
            ),
            const SizedBox(height: 8),
            claimsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (claims) {
                if (claims.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No coupons yet',
                    message: 'Claim a reward above to see it here.',
                  );
                }
                // Active coupons first, then pending, then used.
                int rank(RewardClaim c) => c.isActive
                    ? 0
                    : c.status == 'pending'
                        ? 1
                        : 2;
                final sorted = [...claims]
                  ..sort((a, b) => rank(a).compareTo(rank(b)));
                return Column(
                  children: [for (final c in sorted) _CouponCard(claim: c)],
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
            // Partner logo (boss 27/07) with the discount % as a corner badge.
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: (o.partnerLogo ?? '').isEmpty
                          ? AppColors.sunsetGradient
                          : null,
                      color: (o.partnerLogo ?? '').isEmpty
                          ? null
                          : AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(14),
                      image: (o.partnerLogo ?? '').isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(o.partnerLogo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (o.partnerLogo ?? '').isEmpty
                        ? Text(
                            '${o.discountPercent}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  if ((o.partnerLogo ?? '').isNotEmpty)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${o.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
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

/// A coupon in the owner's wallet. Active coupons carry a QR the shop scans;
/// used coupons are dimmed; pending ones await approval (boss 28/07).
class _CouponCard extends StatelessWidget {
  final RewardClaim claim;
  const _CouponCard({required this.claim});

  void _showQr(BuildContext context) {
    final token = claim.voucherToken;
    if (token == null || token.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${claim.discountPercent ?? ''}% OFF • ${claim.partnerName ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: voucherRedeemUrl(token),
                version: QrVersions.auto,
                size: 240,
                foregroundColor: AppColors.deepSlate,
              ),
              const SizedBox(height: 14),
              const Text(
                'Show this to the shop. They scan it to apply your discount.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = claim.isActive;
    final redeemed = claim.isRedeemed;
    final pending = claim.status == 'pending';
    final token = claim.voucherToken;

    return Opacity(
      opacity: redeemed ? 0.6 : 1,
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        onTap: active && token != null ? () => _showQr(context) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Partner logo / discount
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: (claim.partnerLogo ?? '').isEmpty
                    ? AppColors.sunsetGradient
                    : null,
                color: (claim.partnerLogo ?? '').isEmpty
                    ? null
                    : AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(14),
                image: (claim.partnerLogo ?? '').isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(claim.partnerLogo!),
                        fit: BoxFit.cover)
                    : null,
              ),
              alignment: Alignment.center,
              child: (claim.partnerLogo ?? '').isEmpty
                  ? Text('${claim.discountPercent ?? 0}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13))
                  : null,
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
                        fontSize: 14),
                  ),
                  if ((claim.partnerName ?? '').isNotEmpty)
                    Text(claim.partnerName!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  if (active)
                    Row(
                      children: const [
                        Icon(PhosphorIconsFill.qrCode,
                            size: 13, color: AppColors.brand),
                        SizedBox(width: 4),
                        Text('Tap to show QR at the shop',
                            style: TextStyle(
                                color: AppColors.brand,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700)),
                      ],
                    )
                  else if (redeemed)
                    Text('Used ${_fmtDate(claim.redeemedAt)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11.5))
                  else if (pending)
                    const Text('Waiting for management approval',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Mini QR (active) or status pill
            if (active && token != null)
              QrImageView(
                data: voucherRedeemUrl(token),
                version: QrVersions.auto,
                size: 46,
                foregroundColor: AppColors.deepSlate,
              )
            else
              StatusPill(
                label: redeemed ? 'USED' : claim.status.toUpperCase(),
                color: redeemed
                    ? AppColors.textSecondary
                    : pending
                        ? AppColors.warning
                        : AppColors.success,
                dense: true,
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('MMM d').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }
}
