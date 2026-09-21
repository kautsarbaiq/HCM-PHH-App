import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import 'set_password_dialog.dart';

/// Lets a signed-in user pick a new password from their profile. Pairs with
/// the office-side "Reset password": after a reset, the person signs in with
/// the password the office gave them and immediately replaces it here, so the
/// office never keeps a working credential.
///
/// No server function needed — Supabase lets an authenticated user change
/// their own password directly.
class ChangePasswordTile extends StatefulWidget {
  /// Compact [ListTile] form for the guard / merchant drawers.
  final bool dense;
  const ChangePasswordTile({super.key, this.dense = false});

  @override
  State<ChangePasswordTile> createState() => _ChangePasswordTileState();
}

class _ChangePasswordTileState extends State<ChangePasswordTile> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    final pw = await showSetPasswordDialog(
      context,
      title: 'Change password',
      subtitle: 'Choose a new password for your account.',
      confirmLabel: 'Change',
    );
    if (pw == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pw),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password changed.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dense) {
      return ListTile(
        key: const Key('change-password'),
        leading: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_reset_rounded, color: AppColors.brand),
        title: const Text(
          'Change password',
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: _busy ? null : _start,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('change-password'),
        onPressed: _busy ? null : _start,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_reset_rounded, size: 18),
        label: const Text('Change password'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
