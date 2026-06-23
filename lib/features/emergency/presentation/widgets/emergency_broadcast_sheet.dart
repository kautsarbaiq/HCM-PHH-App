import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/emergency_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';

/// Sheet for ADMIN & GUARD to broadcast an emergency alert to every user. Opens
/// via showModalBottomSheet(isScrollControlled: true, backgroundColor:
/// transparent). On success the alert appears on every active-emergency banner.
class EmergencyBroadcastSheet extends ConsumerStatefulWidget {
  const EmergencyBroadcastSheet({super.key});

  @override
  ConsumerState<EmergencyBroadcastSheet> createState() =>
      _EmergencyBroadcastSheetState();
}

class _EmergencyBroadcastSheetState
    extends ConsumerState<EmergencyBroadcastSheet> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  static const _red = Color(0xFFEF4444);

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sentMsg = ref.tr('emergency.sent'); // resolve before any pop()/await
    final title = _title.text.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ref.tr('emergency.alertTitle')),
          backgroundColor: _red,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) throw Exception('Not signed in.');
      await ref
          .read(emergencyRepositoryProvider)
          .broadcastEmergency(
            title: title,
            message: _message.text.trim(),
            triggeredBy: profile.id,
          );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(sentMsg), backgroundColor: _red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: _red),
      );
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _red),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.glassBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.megaphone,
                        color: _red,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.tr('emergency.broadcastTitle'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ref.tr('emergency.broadcastSub'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _title,
                  decoration: _dec(ref.tr('emergency.alertTitle')),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _message,
                  maxLines: 3,
                  decoration: _dec(ref.tr('emergency.message')),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(PhosphorIconsFill.siren, size: 18),
                    label: Text(ref.tr('emergency.send')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
