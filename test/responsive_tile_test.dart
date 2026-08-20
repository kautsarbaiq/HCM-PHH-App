import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/widgets/responsive.dart';
import 'package:hcm_app/core/widgets/status_pill.dart';
import 'package:hcm_app/theme/app_colors.dart';

/// Reproduces the merchant "My offers" row the user screenshotted at 390 px:
/// avatar + title + subtitle, with a LIVE pill, a Switch and a delete button.
Widget _offerRow() => ResponsiveListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.brand,
        child: Text('10%'),
      ),
      title: const Text('10% off coffee'),
      subtitle: const Text('Unlocks at 3 on-time bills'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusPill(label: 'LIVE', color: AppColors.success, dense: true),
          Switch(value: true, onChanged: (_) {}),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {},
          ),
        ],
      ),
    );

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ListView(children: [_offerRow()]))),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offer row does not overflow on a 390px phone', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);

    // The real bug: the title was squeezed so hard it wrapped one word per
    // line. Assert it now gets a usable share of the width.
    final titleWidth = tester.getSize(find.text('10% off coffee')).width;
    expect(titleWidth, greaterThan(120),
        reason: 'title was crushed into a narrow column again');
  });

  testWidgets('offer row still uses trailing on desktop', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(tester.takeException(), isNull);
    expect(find.byType(Switch), findsOneWidget);
  });
}
