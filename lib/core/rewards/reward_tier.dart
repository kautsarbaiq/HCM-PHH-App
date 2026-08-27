import 'package:flutter/material.dart';

/// The three membership levels from the client mockup (27/08).
///
/// The level itself is decided in SQL (`public.owner_reward_tier`, migration
/// 35) so the web portal, the resident app and the merchant app can never
/// disagree. This file only holds how a level LOOKS and reads.
enum RewardTier { none, silver, gold, platinum }

extension RewardTierX on RewardTier {
  /// Parses the value returned by `owner_reward_tier` / `my_reward_tier`.
  static RewardTier fromName(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'platinum':
        return RewardTier.platinum;
      case 'gold':
        return RewardTier.gold;
      case 'silver':
        return RewardTier.silver;
      default:
        return RewardTier.none;
    }
  }

  /// The level an OFFER belongs to, from the streak it unlocks at.
  static RewardTier fromMinStreak(int minStreak) {
    if (minStreak >= 12) return RewardTier.platinum;
    if (minStreak >= 6) return RewardTier.gold;
    if (minStreak >= 3) return RewardTier.silver;
    return RewardTier.none;
  }

  String get label => switch (this) {
        RewardTier.platinum => 'PLATINUM',
        RewardTier.gold => 'GOLD',
        RewardTier.silver => 'SILVER',
        RewardTier.none => 'NO TIER YET',
      };

  /// What a resident must do to reach this level.
  String get criteria => switch (this) {
        RewardTier.platinum => "Paid a full year's maintenance fee in advance",
        RewardTier.gold => 'Paid on time for 6 consecutive months',
        RewardTier.silver => 'Paid on time for 3 consecutive months',
        RewardTier.none => 'Pay 3 bills on time to reach Silver',
      };

  String get blurb => switch (this) {
        RewardTier.platinum =>
          'Premium benefits for residents who commit early and stay ahead.',
        RewardTier.gold =>
          'Higher-value lifestyle benefits for more consistent payment habits.',
        RewardTier.silver =>
          'Example rewards from participating merchant partners.',
        RewardTier.none =>
          'Keep paying on time and your first tier unlocks automatically.',
      };

  /// Card background, matching the mockup's tinted rows.
  Color get surface => switch (this) {
        RewardTier.platinum => const Color(0xFFEAF1FB),
        RewardTier.gold => const Color(0xFFFDF4D6),
        RewardTier.silver => const Color(0xFFF2F4F8),
        RewardTier.none => const Color(0xFFF7F8FA),
      };

  /// Text / chip colour for this level.
  Color get accent => switch (this) {
        RewardTier.platinum => const Color(0xFF2C5C93),
        RewardTier.gold => const Color(0xFF9A6B08),
        RewardTier.silver => const Color(0xFF5A6478),
        RewardTier.none => const Color(0xFF8A93A6),
      };

  Color get border => switch (this) {
        RewardTier.platinum => const Color(0xFFC7DAF2),
        RewardTier.gold => const Color(0xFFF0DFA4),
        RewardTier.silver => const Color(0xFFDDE2EA),
        RewardTier.none => const Color(0xFFE6E9EF),
      };

  /// Medal colours, dark → light, used for the badge.
  List<Color> get medal => switch (this) {
        RewardTier.platinum =>
          const [Color(0xFF8FA6C4), Color(0xFFD7E3F4), Color(0xFF6E86A6)],
        RewardTier.gold =>
          const [Color(0xFFE0A83A), Color(0xFFFFDF87), Color(0xFFB9821D)],
        RewardTier.silver =>
          const [Color(0xFFA9B2C1), Color(0xFFE3E8EF), Color(0xFF8892A3)],
        RewardTier.none =>
          const [Color(0xFFC3C9D4), Color(0xFFE9ECF1), Color(0xFFAEB5C2)],
      };

  bool get isEarned => this != RewardTier.none;
}

/// A resident's current standing, as returned by `my_reward_tier()`.
class RewardStanding {
  final RewardTier tier;
  final int streak;
  final int prepaidMonths;

  const RewardStanding({
    required this.tier,
    required this.streak,
    required this.prepaidMonths,
  });

  factory RewardStanding.fromJson(Map<String, dynamic> j) => RewardStanding(
        tier: RewardTierX.fromName(j['tier'] as String?),
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        prepaidMonths: (j['prepaid_months'] as num?)?.toInt() ?? 0,
      );

  static const empty =
      RewardStanding(tier: RewardTier.none, streak: 0, prepaidMonths: 0);
}
