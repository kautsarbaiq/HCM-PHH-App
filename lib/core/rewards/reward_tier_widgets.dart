import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'reward_tier.dart';

/// The medal disc used on tier cards and badges.
class RewardTierMedal extends StatelessWidget {
  final RewardTier tier;
  final double size;
  const RewardTierMedal({super.key, required this.tier, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final c = tier.medal;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c[1], c[0]],
        ),
        border: Border.all(color: c[2], width: size * 0.045),
        boxShadow: [
          BoxShadow(
            color: c[2].withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Icon(Icons.star_rounded, color: Colors.white, size: size * 0.52),
    );
  }
}

/// Compact tier chip for lists, tables and offer rows.
class RewardTierBadge extends StatelessWidget {
  final RewardTier tier;
  final bool dense;
  const RewardTierBadge({super.key, required this.tier, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tier.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: tier.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RewardTierMedal(tier: tier, size: dense ? 13 : 16),
          SizedBox(width: dense ? 5 : 6),
          Text(
            tier.label,
            style: TextStyle(
              fontSize: dense ? 9.5 : 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: tier.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three-level ladder from the client mockup (27/08).
///
/// Pass [current] to highlight the level the resident is on; leave it null on
/// admin/merchant screens, where this is just a reference of the scheme.
/// [partnersFor] supplies the example brand chips per level.
class RewardTierLadder extends StatelessWidget {
  final RewardTier? current;
  final List<String> Function(RewardTier tier)? partnersFor;

  const RewardTierLadder({super.key, this.current, this.partnersFor});

  static const _order = [
    RewardTier.platinum,
    RewardTier.gold,
    RewardTier.silver,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in _order) ...[
          _TierCard(
            tier: t,
            isCurrent: current == t,
            partners: partnersFor?.call(t) ?? const [],
          ),
          if (t != _order.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final RewardTier tier;
  final bool isCurrent;
  final List<String> partners;

  const _TierCard({
    required this.tier,
    required this.isCurrent,
    required this.partners,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tier.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? tier.accent : tier.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          // On a phone the medal + text side by side gets cramped, so the
          // partner chips wrap underneath instead of squeezing the copy.
          final narrow = c.maxWidth < 380;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  RewardTierMedal(tier: tier, size: narrow ? 42 : 54),
                  const SizedBox(height: 6),
                  Text(
                    tier.label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: tier.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tier.criteria,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tier.accent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.blurb,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (partners.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final p in partners)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: tier.border),
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: tier.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
