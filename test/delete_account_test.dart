import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/repositories/sub_login_repository.dart';
import 'package:hcm_app/core/widgets/delete_account_tile.dart';

/// The stores require an in-app way to delete the account (App Store 5.1.1(v),
/// Play data-deletion). A reviewer will look for the control AND will not
/// accept a one-tap destructive action, so the typed confirmation is part of
/// the requirement being tested here, not decoration.
Widget _host({List<SubLogin> subLogins = const []}) {
  return ProviderScope(
    overrides: [
      mySubLoginsProvider.overrideWith((ref) async => subLogins),
    ],
    child: const MaterialApp(
      home: Scaffold(body: Center(child: DeleteAccountTile())),
    ),
  );
}

void main() {
  testWidgets('the delete control is visible to the user', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('confirmation is refused until DELETE is typed',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    final cta = find.widgetWithText(TextButton, 'Delete my account');
    expect(cta, findsOneWidget);
    expect(
      tester.widget<TextButton>(cta).onPressed,
      isNull,
      reason: 'a single tap must not be able to destroy the account',
    );

    await tester.enterText(find.byType(TextField), 'delete me');
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(cta).onPressed, isNull,
        reason: 'near-miss text must not unlock deletion');

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(cta).onPressed, isNotNull);
  });

  testWidgets('warns that family logins go too', (tester) async {
    await tester.pumpWidget(_host(subLogins: [
      SubLogin(
        userId: 'u1',
        fullName: 'Wife',
        email: 'wife@example.com',
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('family logins', findRichText: true),
      findsOneWidget,
    );
  });
}
