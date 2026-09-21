import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/widgets/glass_text_field.dart';

/// Regression guard for the "Email or password is incorrect" reports.
///
/// The server accepted the exact credentials the users typed, so the only
/// remaining place they could be altered was the keyboard: autocorrect, word
/// suggestions and auto-capitalisation all silently rewrite a plain text
/// field on Android. A credential field must have all three switched off.
void main() {
  Future<TextField> pump(WidgetTester tester, GlassTextField field) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: field)));
    return tester.widget<TextField>(find.byType(TextField));
  }

  testWidgets('password fields never let the keyboard rewrite input',
      (tester) async {
    final tf = await pump(
      tester,
      const GlassTextField(hintText: 'Password', isPassword: true),
    );
    expect(tf.autocorrect, isFalse);
    expect(tf.enableSuggestions, isFalse);
    expect(tf.textCapitalization, TextCapitalization.none);
    expect(tf.obscureText, isTrue);
  });

  testWidgets('credential fields (email) are hardened the same way',
      (tester) async {
    final tf = await pump(
      tester,
      const GlassTextField(
        hintText: 'Email',
        isCredential: true,
        keyboardType: TextInputType.emailAddress,
      ),
    );
    expect(tf.autocorrect, isFalse);
    expect(tf.enableSuggestions, isFalse);
    expect(tf.textCapitalization, TextCapitalization.none);
    expect(tf.keyboardType, TextInputType.emailAddress);
  });

  testWidgets('ordinary fields keep keyboard help on', (tester) async {
    final tf = await pump(tester, const GlassTextField(hintText: 'Notes'));
    expect(tf.autocorrect, isTrue,
        reason: 'only credentials should lose autocorrect');
  });
}
