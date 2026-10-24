import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/billing_repository.dart';
import '../../../../theme/app_colors.dart';
import '../pages/billing_page.dart' show myBillingsProvider;
import 'bill_card.dart';

/// A [BillCard] that can also take proof of a bank transfer.
///
/// WHY THIS EXISTS
///   "Pay Now" only told the resident that online payment is not connected to
///   a provider — a dead end. People here already pay by bank transfer; what
///   was missing was a way to prove it and a way for the office to see the
///   proof. The resident uploads a receipt, the bill goes to 'submitted', and
///   someone in the office confirms it.
///
///   This is a separate widget only because the page is a ConsumerWidget and
///   the upload needs per-bill in-flight state.
class ReceiptBillCard extends ConsumerStatefulWidget {
  final Billing bill;
  final VoidCallback onPay;
  final String dueDateLabel;

  const ReceiptBillCard({
    super.key,
    required this.bill,
    required this.onPay,
    required this.dueDateLabel,
  });

  @override
  ConsumerState<ReceiptBillCard> createState() => _ReceiptBillCardState();
}

class _ReceiptBillCardState extends ConsumerState<ReceiptBillCard> {
  static const _maxBytes = 10 * 1024 * 1024;
  bool _uploading = false;

  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true, // needed on web AND to upload without a file path
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return;

    if (file.bytes!.lengthInBytes > _maxBytes) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('File is too large — please upload under 10 MB.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await ref.read(billingRepositoryProvider).submitReceipt(
            billingId: widget.bill.id,
            bytes: file.bytes!,
            fileName: file.name,
          );
      ref.read(myBillingsProvider.notifier).refresh();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Receipt sent. The management office will confirm your payment.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return BillCard(
      title: bill.title,
      period: bill.period?.isNotEmpty == true
          ? bill.period!
          : 'Invoice ${bill.invoiceNumber}',
      amount: bill.amount,
      status: bill.awaitingConfirmation
          ? 'Submitted'
          : bill.status == 'overdue'
              ? 'Overdue'
              : 'Unpaid',
      dueDate: widget.dueDateLabel,
      onPay: widget.onPay,
      onUploadReceipt: _upload,
      awaitingConfirmation: bill.awaitingConfirmation,
      uploading: _uploading,
    );
  }
}

/// Formats a receipt timestamp for the office-side list.
String formatReceiptStamp(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  return DateFormat('d MMM yyyy, HH:mm').format(d.toLocal());
}
