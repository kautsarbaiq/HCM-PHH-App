import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/repositories/merchant_repository.dart';
import '../../../../core/repositories/rewards_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Merchant portal → Redeem (boss batch 08/08 point 2, second bullet).
/// Scan the resident's voucher QR to redeem it, and see every redemption.
class MerchantRedeemPage extends ConsumerStatefulWidget {
  const MerchantRedeemPage({super.key});

  @override
  ConsumerState<MerchantRedeemPage> createState() =>
      _MerchantRedeemPageState();
}

class _MerchantRedeemPageState extends ConsumerState<MerchantRedeemPage> {
  final _manual = TextEditingController();
  bool _busy = false;
  String? _result;
  bool _resultOk = false;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _redeem(String raw) async {
    final token = MerchantRepository.tokenFromScan(raw);
    if (token == null) {
      setState(() {
        _result = 'That QR code is not a reward voucher.';
        _resultOk = false;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(rewardsRepositoryProvider);
      final info = await repo.voucherInfo(token);
      if (info == null) {
        setState(() {
          _result = 'Voucher not found.';
          _resultOk = false;
        });
        return;
      }
      if (info.isRedeemed) {
        setState(() {
          _result = 'Already redeemed — ${info.offerTitle}.';
          _resultOk = false;
        });
        return;
      }
      final res = await repo.redeemVoucher(token);
      if (res['ok'] == true) {
        setState(() {
          _result =
              'Redeemed: ${info.discountPercent}% off for ${info.ownerName}';
          _resultOk = true;
        });
        ref.invalidate(myRedemptionsProvider);
      } else {
        setState(() {
          _result = res['error'] == 'already'
              ? 'This voucher was already used.'
              : 'Could not redeem this voucher.';
          _resultOk = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _resultOk = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openScanner() async {
    final code = await showDialog<String>(
      context: context,
      builder: (d) => Dialog(
        child: SizedBox(
          width: 420,
          height: 420,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Scan the resident\'s voucher QR',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final list = capture.barcodes;
                    if (list.isNotEmpty && list.first.rawValue != null) {
                      Navigator.pop(d, list.first.rawValue);
                    }
                  },
                ),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(d),
                  child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
    if (code != null) await _redeem(code);
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('d MMM yyyy • HH:mm')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(myRedemptionsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Redeem vouchers',
            subtitle: 'Scan a resident\'s QR, or type the voucher code',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Camera scanning needs a real camera — on desktop web the manual
              // box below is the practical path.
              if (!kIsWeb)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _busy ? null : _openScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR'),
                ),
              if (!kIsWeb) const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _manual,
                  decoration: const InputDecoration(
                    labelText: 'Voucher link or code',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (v) => _redeem(v),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _busy ? null : () => _redeem(_manual.text),
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Redeem'),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_resultOk ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _resultOk
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: _resultOk ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _result!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            _resultOk ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          const Text('Redemption history',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(myRedemptionsProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No redemptions yet',
                    message: 'Vouchers you redeem will be listed here.',
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        r.isRedeemed
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        color: r.isRedeemed
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      title: Text(
                        '${r.residentName ?? 'Resident'} — ${r.offerTitle ?? 'Reward'}'
                        '${r.discountPercent != null ? ' (${r.discountPercent}%)' : ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        r.isRedeemed
                            ? 'Redeemed ${_fmt(r.redeemedAt)}'
                            : 'Claimed ${_fmt(r.createdAt)} — not used yet',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: StatusPill(
                        label: r.isRedeemed ? 'USED' : r.status.toUpperCase(),
                        color: r.isRedeemed
                            ? AppColors.textSecondary
                            : AppColors.warning,
                        dense: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
