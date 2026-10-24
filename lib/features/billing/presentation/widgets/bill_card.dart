import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

class BillCard extends StatelessWidget {
  final String title;
  final String period;
  final double amount;
  final String status;
  final String dueDate;
  final VoidCallback onPay;

  /// Uploading proof of a bank transfer. Null hides the button — used for
  /// bills that are already paid or already awaiting confirmation.
  final VoidCallback? onUploadReceipt;

  /// True once the resident has sent a receipt the office has not checked yet.
  final bool awaitingConfirmation;

  /// True while the upload is in flight.
  final bool uploading;

  const BillCard({
    super.key,
    required this.title,
    required this.period,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.onPay,
    this.onUploadReceipt,
    this.awaitingConfirmation = false,
    this.uploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'RM ',
      decimalDigits: 0,
    );

    final isUnpaid = status.toLowerCase() == 'unpaid';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      period,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isUnpaid
                      ? AppColors.error.withOpacity(0.15)
                      : AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isUnpaid ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(amount),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isUnpaid ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (awaitingConfirmation) ...[
            const SizedBox(height: 20),
            // The resident has done their part; say so plainly instead of
            // leaving a "Pay Now" button that invites a second payment.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Receipt sent — waiting for the management office to '
                      'confirm your payment.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onUploadReceipt != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('replace-receipt'),
                onPressed: uploading ? null : onUploadReceipt,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Send a different receipt'),
              ),
            ],
          ] else if (isUnpaid) ...[
            const SizedBox(height: 24),
            ActionButton(
              label: 'Pay Now',
              onPressed: onPay,
              height: 48,
              backgroundColor: AppColors.primaryBlue,
            ),
            if (onUploadReceipt != null) ...[
              const SizedBox(height: 10),
              // Residents here pay by bank transfer, so proof of payment is
              // the real "payment" path until a provider is wired up.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('upload-receipt'),
                  onPressed: uploading ? null : onUploadReceipt,
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(
                    uploading ? 'Uploading…' : 'Upload payment receipt',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
