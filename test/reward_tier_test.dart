import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/rewards/reward_tier.dart';
import 'package:hcm_app/core/rewards/reward_tier_widgets.dart';

/// Client mockup 27/08 — three membership levels shown everywhere rewards
/// appear. The level itself is decided in SQL; these cover the mapping and
/// the layout.
void main() {
  group('tier mapping', () {
    test('an offer lands in the level its streak unlocks', () {
      expect(RewardTierX.fromMinStreak(0), RewardTier.none);
      expect(RewardTierX.fromMinStreak(2), RewardTier.none);
      expect(RewardTierX.fromMinStreak(3), RewardTier.silver);
      expect(RewardTierX.fromMinStreak(5), RewardTier.silver);
      expect(RewardTierX.fromMinStreak(6), RewardTier.gold);
      expect(RewardTierX.fromMinStreak(11), RewardTier.gold);
      expect(RewardTierX.fromMinStreak(12), RewardTier.platinum);
    });

    test('parses what the SQL function returns', () {
      expect(RewardTierX.fromName('platinum'), RewardTier.platinum);
      expect(RewardTierX.fromName('GOLD'), RewardTier.gold);
      expect(RewardTierX.fromName('silver'), RewardTier.silver);
      expect(RewardTierX.fromName('none'), RewardTier.none);
      expect(RewardTierX.fromName(null), RewardTier.none);
    });

    test('each level carries the wording from the mockup', () {
      expect(RewardTier.silver.criteria, contains('3 consecutive months'));
      expect(RewardTier.gold.criteria, contains('6 consecutive months'));
      expect(RewardTier.platinum.criteria, contains('full year'));
    });

    test('the three levels are visually distinct', () {
      final surfaces = {
        RewardTier.silver.surface,
        RewardTier.gold.surface,
        RewardTier.platinum.surface,
      };
      expect(surfaces.length, 3, reason: 'tiers must not share a colour');
    });
  });

  group('ladder layout', () {
    Future<void> pump(WidgetTester tester, Size size,
        {RewardTier? current}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RewardTierLadder(
                  current: current,
                  partnersFor: (t) => const ['Zuno Coffee', 'KFry'],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('all three levels fit a 390px phone', (tester) async {
      await pump(tester, const Size(390, 844));
      expect(find.text('PLATINUM'), findsOneWidget);
      expect(find.text('GOLD'), findsOneWidget);
      expect(find.text('SILVER'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the resident sees which level is theirs', (tester) async {
      await pump(tester, const Size(390, 844), current: RewardTier.gold);
      expect(find.text('YOU'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on a desktop portal too', (tester) async {
      await pump(tester, const Size(1440, 900));
      expect(find.text('PLATINUM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('medal', () {
    testWidgets('each earned tier draws its own medal colour',
        (tester) async {
      for (final tier in [
        RewardTier.silver,
        RewardTier.gold,
        RewardTier.platinum,
      ]) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: RewardTierMedal(tier: tier))),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RewardTierMedal), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('badge shows the tier name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RewardTierBadge(tier: RewardTier.gold)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('GOLD'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
