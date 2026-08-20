// Smoke test: the splash screen is pure UI (no Supabase/dotenv), so it builds
// without backend initialisation and is a safe, meaningful sanity check that
// the theme + core widgets render.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hcm_app/core/config/brand.dart';
import 'package:hcm_app/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders the active brand', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashPage()));
    await tester.pump(const Duration(milliseconds: 600));

    // White-label: the splash shows whichever brand this build targets
    // (PHH Housing or HomeCloudAsia), so assert against Brand itself
    // rather than the long-gone 'HCM' placeholder.
    expect(find.text(Brand.appName), findsOneWidget);
    expect(find.text('Housing Community Management'), findsOneWidget);
  });
}
