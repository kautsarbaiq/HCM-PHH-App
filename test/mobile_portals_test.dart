import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hcm_app/core/repositories/emergency_repository.dart';
import 'package:hcm_app/core/repositories/merchant_repository.dart';
import 'package:hcm_app/features/guard/presentation/widgets/guard_layout.dart';
import 'package:hcm_app/features/merchant/presentation/widgets/merchant_layout.dart';

/// Boss 19/08: Guard and Merchant moved off the web build onto mobile.
/// Their shells must therefore render properly at phone width — a usable
/// AppBar / bottom nav, and no overflow.
void main() {
  // The emergency banner reads Supabase.instance directly, so the client must
  // exist before these shells build. No network happens: the alerts provider
  // is overridden below, and no session is signed in.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://localhost.invalid',
      anonKey: 'test-anon-key',
    );
  });

  /// Both shells read GoRouterState, so they need a real router above them.
  Future<void> pump(
    WidgetTester tester, {
    required String initial,
    required Widget Function(Widget child) shell,
    required Size size,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: initial,
      routes: [
        ShellRoute(
          builder: (context, state, child) => shell(child),
          routes: [
            GoRoute(
              path: initial,
              builder: (_, __) => const Center(child: Text('portal body')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('guard portal renders on a 390px phone', (tester) async {
    await pump(
      tester,
      initial: '/guard/visitors',
      shell: (child) => GuardLayout(child: child),
      size: const Size(390, 844),
      // The banner hits Supabase; stub it so the test measures layout only.
      overrides: [activeEmergenciesProvider
            .overrideWith((ref) => Stream<List<EmergencyAlert>>.value([]))],
    );
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Security'), findsOneWidget); // shortened on phones
    expect(find.text('portal body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('merchant portal renders on a 390px phone', (tester) async {
    final shop = Merchant(id: 'm1', shopName: 'Kopi Kenangan');
    await pump(
      tester,
      initial: '/merchant/shop',
      shell: (child) => MerchantLayout(child: child),
      size: const Size(390, 844),
      overrides: [
        myShopProvider.overrideWith((ref) async => shop),
        activeEmergenciesProvider
            .overrideWith((ref) => Stream<List<EmergencyAlert>>.value([])),
      ],
    );
    expect(find.byType(AppBar), findsOneWidget);
    // Mobile chrome: bottom nav carrying the three merchant tabs.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('My Shop'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(find.text('Redeem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
