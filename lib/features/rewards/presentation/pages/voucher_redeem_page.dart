import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/rewards_repository.dart';
import '../../../../theme/app_colors.dart';

/// PUBLIC page (no login) — the shop scans the owner's voucher QR, which opens
/// this page. It shows the voucher and lets the shop tap "Redeem now" once
/// (boss 28/07). Restaurants need no app account.
class VoucherRedeemPage extends ConsumerStatefulWidget {
  final String token;
  const VoucherRedeemPage({super.key, required this.token});

  @override
  ConsumerState<VoucherRedeemPage> createState() => _VoucherRedeemPageState();
}

class _VoucherRedeemPageState extends ConsumerState<VoucherRedeemPage> {
  VoucherInfo? _v;
  bool _loading = true;
  bool _redeeming = false;
  bool _justRedeemed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await ref.read(rewardsRepositoryProvider).voucherInfo(widget.token);
      setState(() {
        _v = v;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _v = null;
        _loading = false;
      });
    }
  }

  Future<void> _redeem() async {
    setState(() {
      _redeeming = true;
      _error = null;
    });
    try {
      final res =
          await ref.read(rewardsRepositoryProvider).redeemVoucher(widget.token);
      if (res['ok'] == true) {
        setState(() => _justRedeemed = true);
        await _load();
      } else {
        final code = res['error']?.toString();
        setState(() => _error = code == 'already'
            ? 'This voucher was already redeemed.'
            : code == 'not_active'
                ? 'This voucher is not active.'
                : 'Voucher not found.');
        await _load();
      }
    } catch (e) {
      setState(() => _error = 'Could not redeem — please try again.');
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('EEE, MMM d • HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors.brand),
                    )
                  : _v == null
                      ? _notFound()
                      : _voucherCard(_v!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );

  Widget _notFound() => _card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('Voucher not found',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            SizedBox(height: 6),
            Text('This QR code is not a valid reward voucher.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );

  Widget _voucherCard(VoucherInfo v) {
    final redeemed = v.isRedeemed || _justRedeemed;
    final active = v.isActive && !_justRedeemed;

    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Partner
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(20),
              image: (v.partnerLogo ?? '').isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(v.partnerLogo!), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: (v.partnerLogo ?? '').isEmpty
                ? const Icon(Icons.storefront_rounded,
                    color: AppColors.brand, size: 30)
                : null,
          ),
          const SizedBox(height: 12),
          Text(v.partnerName,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('${v.discountPercent}% OFF',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brand,
                  height: 1)),
          const SizedBox(height: 4),
          Text(v.offerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Customer: ${v.ownerName}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
          if ((v.voucherCode ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Code: ${v.voucherCode}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 20),

          if (redeemed) ...[
            _statusChip(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              label: 'REDEEMED',
            ),
            const SizedBox(height: 8),
            Text(
              'Redeemed ${_fmt(v.redeemedAt)}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ] else if (active) ...[
            _statusChip(
              icon: Icons.verified_rounded,
              color: AppColors.success,
              label: 'VALID VOUCHER',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _redeeming ? null : _redeem,
                icon: _redeeming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.redeem_rounded),
                label: const Text('Redeem now',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Shop staff: tap to mark this voucher used.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ] else ...[
            _statusChip(
              icon: Icons.info_outline_rounded,
              color: AppColors.warning,
              label: v.status == 'pending'
                  ? 'AWAITING APPROVAL'
                  : 'NOT ACTIVE',
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(
      {required IconData icon, required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}
