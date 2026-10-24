import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/repositories/billing_repository.dart';
import 'package:hcm_app/features/billing/presentation/widgets/bill_card.dart';

/// Boss request (PHH screenshots 4 & 5): residents pay by bank transfer, so
/// they upload a receipt, the bill goes to 'submitted', and only the office
/// moves it to 'paid'.
///
/// The rule worth protecting: 'submitted' must never read as settled. An
/// uploaded photo is a claim, and a resident must not be able to clear their
/// own debt by sending a picture.
Billing _bill({required String status, String? receipt}) => Billing(
      id: 'b1',
      invoiceNumber: 'INV-1',
      title: 'Monthly Maintenance',
      amount: 200,
      status: status,
      residentId: 'r1',
      houseId: 'h1',
      receiptUrl: receipt,
      receiptUploadedAt: receipt == null ? null : '2026-10-23T09:00:00Z',
    );

void main() {
  group('billing model', () {
    test('a receipt is only "present" when there is really a path', () {
      expect(_bill(status: 'unpaid').hasReceipt, isFalse);
      expect(_bill(status: 'unpaid', receipt: '').hasReceipt, isFalse);
      expect(_bill(status: 'submitted', receipt: 'u/1.jpg').hasReceipt, isTrue);
    });

    test('submitted is its own state, not paid', () {
      final submitted = _bill(status: 'submitted', receipt: 'u/1.jpg');
      expect(submitted.awaitingConfirmation, isTrue);
      expect(submitted.status, isNot('paid'),
          reason: 'a resident upload must never settle the bill by itself');
      expect(_bill(status: 'paid').awaitingConfirmation, isFalse);
    });
  });

  group('resident bill card', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
        );

    testWidgets('unpaid shows both pay and upload', (tester) async {
      await pump(
        tester,
        BillCard(
          title: 'Monthly Maintenance',
          period: 'Oct 2026',
          amount: 200,
          status: 'Unpaid',
          dueDate: 'Nov 06, 2026',
          onPay: () {},
          onUploadReceipt: () {},
        ),
      );
      expect(find.byKey(const Key('upload-receipt')), findsOneWidget);
      expect(find.text('Pay Now'), findsOneWidget);
    });

    testWidgets('after submitting, Pay Now is gone so nobody pays twice',
        (tester) async {
      await pump(
        tester,
        BillCard(
          title: 'Monthly Maintenance',
          period: 'Oct 2026',
          amount: 200,
          status: 'Submitted',
          dueDate: 'Nov 06, 2026',
          onPay: () {},
          onUploadReceipt: () {},
          awaitingConfirmation: true,
        ),
      );
      expect(find.text('Pay Now'), findsNothing,
          reason: 'inviting a second transfer is worse than no button');
      expect(find.textContaining('waiting for the management office'),
          findsOneWidget);
      expect(find.byKey(const Key('replace-receipt')), findsOneWidget);
    });

    testWidgets('upload is disabled while in flight', (tester) async {
      var taps = 0;
      await pump(
        tester,
        BillCard(
          title: 'Monthly Maintenance',
          period: 'Oct 2026',
          amount: 200,
          status: 'Unpaid',
          dueDate: 'Nov 06, 2026',
          onPay: () {},
          onUploadReceipt: () => taps++,
          uploading: true,
        ),
      );
      await tester.tap(find.byKey(const Key('upload-receipt')));
      expect(taps, 0, reason: 'a double tap must not upload twice');
      expect(find.text('Uploading…'), findsOneWidget);
    });
  });
}
