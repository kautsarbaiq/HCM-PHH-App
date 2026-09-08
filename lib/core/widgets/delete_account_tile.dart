import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../repositories/sub_login_repository.dart';
import '../services/account_deletion_service.dart';

/// "Delete Account" row, shown on every mobile login (resident, guard,
/// merchant).
///
/// Both stores require an in-app path to delete an account that was created in
/// the app — App Store guideline 5.1.1(v) and Play's data-deletion policy — and
/// a review will fail without it. It is deliberately placed with, but visually
/// separated from, sign-out, and asks the user to type DELETE so it cannot be
/// hit by accident on a phone.
class DeleteAccountTile extends ConsumerStatefulWidget {
  const DeleteAccountTile({super.key, this.dense = false});

  /// Compact form for the drawer/menu sheets used by guard and merchant.
  final bool dense;

  @override
  ConsumerState<DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends ConsumerState<DeleteAccountTile> {
  bool _busy = false;

  Future<void> _start() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(accountDeletionServiceProvider).deleteMyAccount();
      // On success the service signs out, and the router's auth listener
      // returns the app to the login page on its own.
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${ref.tr('account.deleteFailed')} $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = ref.tr('account.delete');
    if (widget.dense) {
      return ListTile(
        leading: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_forever_rounded, color: AppColors.error),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: _busy ? null : _start,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _start,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_forever_rounded, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final ok = _controller.text.trim().toUpperCase() == 'DELETE';
      if (ok != _canDelete) setState(() => _canDelete = ok);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only a parent account can own family logins, and they go with it.
    final hasFamily =
        (ref.watch(mySubLoginsProvider).valueOrNull ?? const []).isNotEmpty;

    return AlertDialog(
      title: Text(ref.tr('account.deleteTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ref.tr('account.deleteBody'),
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
            if (hasFamily) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ref.tr('account.deleteFamilyWarning'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: ref.tr('account.deleteConfirmHint'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(ref.tr('common.cancel')),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          child: Text(ref.tr('account.deleteCta')),
        ),
      ],
    );
  }
}
