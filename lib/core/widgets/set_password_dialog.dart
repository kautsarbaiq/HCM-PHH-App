import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Asks the office for a new password, typed twice. Returns it, or null if
/// cancelled. Used both when creating a guard and when resetting anyone's
/// password, so the rules (length, match) live in exactly one place.
///
/// Autocorrect and suggestions are off: a phone keyboard "helpfully" fixing a
/// password is how people end up locked out with "Invalid login credentials".
Future<String?> showSetPasswordDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _SetPasswordDialog(
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
    ),
  );
}

/// Minimum accepted by the server functions; kept in sync with them.
const kMinPasswordLength = 6;

/// Pure validation so it can be unit-tested without a widget tree.
String? validateNewPassword(String password, String confirm) {
  if (password.length < kMinPasswordLength) {
    return 'Password must be at least $kMinPasswordLength characters';
  }
  if (password != confirm) return 'Passwords do not match';
  return null;
}

class _SetPasswordDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String confirmLabel;
  const _SetPasswordDialog({
    required this.title,
    this.subtitle,
    required this.confirmLabel,
  });

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final err = validateNewPassword(_password.text, _confirm.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, _password.text);
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              key: const Key('new-password'),
              controller: _password,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _decoration('New password'),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('confirm-password'),
              controller: _confirm,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _decoration('Confirm password'),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                key: const Key('password-error'),
                style: const TextStyle(color: AppColors.error, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
