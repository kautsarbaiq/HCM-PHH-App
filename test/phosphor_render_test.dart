import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Proves the Phosphor font is really wired up at RUNTIME, not just that the
/// code compiles. `flutter analyze` and the codepoint tests both pass even if
/// the font file never loads — the app would then render empty boxes on every
/// screen, which is exactly what the phosphor_flutter -> phosphor_icons swap
/// risked.
Future<int> _opaquePixels(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(child: RepaintBoundary(child: child)),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final ui.Image image = await boundary.toImage();
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  var opaque = 0;
  for (var i = 3; i < data!.lengthInBytes; i += 4) {
    if (data.getUint8(i) > 0) opaque++;
  }
  return opaque;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The real .ttf shipped inside the phosphor_icons package.
    // A font declared with `fontPackage` resolves as
    // packages/<package>/<family> — registering the bare family name
    // silently leaves the icon on the fallback font.
    final loader = FontLoader('packages/phosphor_icons/PhosphorRegular')
      ..addFont(
        rootBundle.load('packages/phosphor_icons/lib/fonts/Phosphor.ttf'),
      );
    await loader.load();
  });

  testWidgets('a phosphor glyph actually paints pixels', (tester) async {
    late int painted;
    await tester.runAsync(() async {
      painted = await _opaquePixels(
        tester,
        const Icon(PhosphorIconsRegular.house, size: 64),
      );
    });
    expect(painted, greaterThan(100),
        reason: 'font did not load — icons would render as blank/tofu');
  });

  testWidgets('the phosphor font is used, not a fallback', (tester) async {
    late int real;
    late int bogus;
    await tester.runAsync(() async {
      real = await _opaquePixels(
        tester,
        const Icon(PhosphorIconsRegular.house, size: 64),
      );
      // Same codepoint, font family that does not exist -> fallback rendering.
      bogus = await _opaquePixels(
        tester,
        Icon(
          IconData(PhosphorIconsRegular.house.codePoint,
              fontFamily: 'NoSuchFontFamily'),
          size: 64,
        ),
      );
    });
    expect(real, isNot(equals(bogus)),
        reason: 'glyph identical to the no-font fallback — font not applied');
  });
}
