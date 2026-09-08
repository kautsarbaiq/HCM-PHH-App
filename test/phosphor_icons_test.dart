import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Guards the phosphor_flutter -> phosphor_icons migration (Flutter 3.44).
///
/// phosphor_flutter is abandoned at 2.1.0 and cannot compile since Flutter made
/// IconData a final class. The replacement must keep the SAME codepoints and be
/// wired to the SAME font files, otherwise every icon in the app silently turns
/// into a wrong glyph or a tofu box — something `flutter analyze` cannot catch.
void main() {
  group('phosphor icons', () {
    test('icons resolve to the phosphor_icons font package', () {
      const icon = PhosphorIconsRegular.user;
      expect(icon.fontPackage, 'phosphor_icons');
      expect(icon.fontFamily, 'PhosphorRegular');
    });

    test('each style maps to its own font family', () {
      expect(PhosphorIconsRegular.house.fontFamily, 'PhosphorRegular');
      expect(PhosphorIconsBold.house.fontFamily, 'PhosphorBold');
      expect(PhosphorIconsFill.house.fontFamily, 'PhosphorFill');
    });

    test('codepoints still match the ones phosphor_flutter shipped', () {
      // Sampled from phosphor_flutter 2.1.0 before the swap. If a future
      // package bump renumbers the font, these break instead of the UI.
      expect(PhosphorIconsRegular.acorn.codePoint, 0xeb9a);
      expect(PhosphorIconsRegular.addressBook.codePoint, 0xe6f8);
    });

    testWidgets('an icon actually builds in a widget tree', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Icon(PhosphorIconsRegular.user),
        ),
      );
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
