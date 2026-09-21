import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/widgets/set_password_dialog.dart';

/// The one place password rules live for guard creation, office resets and
/// self-service change. Mirrors the server functions' MIN_PASSWORD = 6.
void main() {
  group('validateNewPassword', () {
    test('rejects anything shorter than the server minimum', () {
      expect(validateNewPassword('12345', '12345'), isNotNull);
      expect(validateNewPassword('123456', '123456'), isNull);
    });

    test('rejects a mismatch even when both are long enough', () {
      expect(validateNewPassword('abcdefg', 'abcdefh'), 'Passwords do not match');
    });

    test('length is checked before match, so the first fix is the right one',
        () {
      expect(validateNewPassword('abc', 'xyz'), contains('at least'));
    });
  });

  group('showSetPasswordDialog', () {
    Future<String?> open(WidgetTester tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              result = await showSetPasswordDialog(ctx, title: 'Reset');
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('refuses to close with a mismatch and shows why',
        (tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const Key('new-password')), 'abcdef');
      await tester.enterText(
          find.byKey(const Key('confirm-password')), 'abcdeX');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('password-error')), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'dialog must stay open on a validation error');
    });

    testWidgets('returns the password once both fields agree',
        (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              result = await showSetPasswordDialog(ctx, title: 'Reset');
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('new-password')), 'secret1');
      await tester.enterText(
          find.byKey(const Key('confirm-password')), 'secret1');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'secret1');
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('password fields never autocorrect', (tester) async {
      await open(tester);
      for (final k in ['new-password', 'confirm-password']) {
        final tf = tester.widget<TextField>(find.byKey(Key(k)));
        expect(tf.autocorrect, isFalse, reason: k);
        expect(tf.enableSuggestions, isFalse, reason: k);
        expect(tf.obscureText, isTrue, reason: k);
      }
    });
  });
}
