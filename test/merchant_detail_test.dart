import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/repositories/super_admin_repository.dart';
import 'package:hcm_app/features/superadmin/presentation/pages/merchants_page.dart';

/// Boss 19/08 asked two things on the Super Admin → Merchants screen:
///   1. how to see a merchant's details
///   2. how to upload his logo / picture
/// Tapping a tile now opens a detail sheet that answers both.
void main() {
  final merchant = MerchantAccount(
    id: 'm1',
    shopName: 'Kopi Kenangan',
    category: 'Café',
    communityName: 'Home Cloud Asia Residence',
    ownerName: 'Kopi Kenangan Owner',
    ownerEmail: 'merchant@homecloudasia.com',
    contact: '0123456789',
    address: 'Lot 5, Jalan Utama',
    description: 'Coffee and pastries',
    createdAt: DateTime(2026, 8, 1),
    isActive: true,
  );

  Future<void> pumpGrid(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          merchantAccountsProvider.overrideWith((ref) async => [merchant]),
        ],
        child: const MaterialApp(home: Scaffold(body: SuperMerchantsPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a merchant opens its details', (tester) async {
    await pumpGrid(tester, const Size(1440, 900));
    expect(find.text('Kopi Kenangan'), findsOneWidget);

    await tester.tap(find.text('Kopi Kenangan'));
    await tester.pumpAndSettle();

    // Question 1 — the details are visible.
    expect(find.text('merchant@homecloudasia.com'), findsOneWidget);
    expect(find.text('Kopi Kenangan Owner'), findsOneWidget);
    expect(find.text('Home Cloud Asia Residence'), findsOneWidget);
    // Question 2 — the logo upload is right there.
    expect(find.text('Upload logo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('merchant details fit a 390px phone', (tester) async {
    await pumpGrid(tester, const Size(390, 844));
    await tester.tap(find.text('Kopi Kenangan'));
    await tester.pumpAndSettle();
    expect(find.text('Upload logo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
