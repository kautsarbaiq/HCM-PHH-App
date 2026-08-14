import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/repositories/sub_login_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';

/// Boss batch 08/08 point 5: the main resident login can create a login for a
/// wife or child. The sub-account inherits the same house and community, so it
/// opens on exactly the same interface and data.
///
/// Hidden entirely when the signed-in account IS a family login (no chains).
class FamilyLoginsSection extends ConsumerWidget {
  const FamilyLoginsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSub = ref.watch(isSubLoginProvider).valueOrNull ?? false;
    if (isSub) return const SizedBox.shrink();

    final async = ref.watch(mySubLoginsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        SectionHeader(
          title: ref.tr('profile.familyLogins'),
          trailing: GestureDetector(
            onTap: () => _showAddDialog(context, ref),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 15, color: AppColors.brand),
                  const SizedBox(width: 4),
                  Text(
                    ref.tr('common.add'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PremiumCard(
          padding: const EdgeInsets.all(16),
          child: async.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              'Could not load family logins.\n$e',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Text(
                  ref.tr('profile.familyLoginsSub'),
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return Column(
                children: [
                  for (final s in list)
                    _SubLoginRow(
                      sub: s,
                      onDelete: () => _confirmDelete(context, ref, s),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SubLogin sub,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Remove this login?'),
        content: Text(
          '${sub.email} will no longer be able to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subLoginRepositoryProvider).remove(sub.userId);
      ref.invalidate(mySubLoginsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${sub.fullName} removed.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _AddFamilyLoginDialog(),
    );
  }
}

class _SubLoginRow extends StatelessWidget {
  final SubLogin sub;
  final VoidCallback onDelete;
  const _SubLoginRow({required this.sub, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brand.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded,
                size: 18, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.fullName.isEmpty ? sub.email : sub.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  sub.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.error,
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _AddFamilyLoginDialog extends ConsumerStatefulWidget {
  const _AddFamilyLoginDialog();

  @override
  ConsumerState<_AddFamilyLoginDialog> createState() =>
      _AddFamilyLoginDialogState();
}

class _AddFamilyLoginDialogState
    extends ConsumerState<_AddFamilyLoginDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    if (name.length < 2) {
      setState(() => _error = 'Please enter their name.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(subLoginRepositoryProvider).create(
            fullName: name,
            email: email,
            password: pass,
          );
      ref.invalidate(mySubLoginsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$name can now sign in with $email.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(ref.tr('profile.addFamilyLogin')),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'They will see the same home, bills and visitors as you.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name (wife / child)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password (min 6 characters)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create login'),
        ),
      ],
    );
  }
}
