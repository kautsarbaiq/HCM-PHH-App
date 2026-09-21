import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/account_admin_repository.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/set_password_dialog.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

class GuardsAdminPage extends ConsumerStatefulWidget {
  const GuardsAdminPage({super.key});

  @override
  ConsumerState<GuardsAdminPage> createState() => _GuardsAdminPageState();
}

class _GuardsAdminPageState extends ConsumerState<GuardsAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  Future<void> _resetPassword(Profile guard) async {
    final pw = await showSetPasswordDialog(
      context,
      title: 'Reset password',
      subtitle: 'Set a new password for ${guard.fullName}. Hand it to them '
          'in person and ask them to change it from their profile.',
      confirmLabel: 'Reset',
    );
    if (pw == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(accountAdminRepositoryProvider)
          .resetPassword(userId: guard.id, newPassword: pw);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Password reset for ${guard.fullName}.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showCreateForm() {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final confirm = TextEditingController();
    bool obscure = true;
    bool isSaving = false;
    String? error;

    InputDecoration deco(String label, {Widget? suffix}) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: suffix,
        );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Add security guard',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('guard-name'),
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: deco('Full name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('guard-email'),
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: deco('Email (used to log in)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: deco('Phone (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('guard-password'),
                    controller: password,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: deco(
                      'Password',
                      suffix: IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('guard-confirm'),
                    controller: confirm,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: deco('Confirm password'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error!,
                        key: const Key('guard-error'),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              key: const Key('guard-create'),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (name.text.trim().length < 2) {
                        setDialogState(() => error = 'Name is required');
                        return;
                      }
                      if (!email.text.contains('@')) {
                        setDialogState(() => error = 'Enter a valid email');
                        return;
                      }
                      final pwErr =
                          validateNewPassword(password.text, confirm.text);
                      if (pwErr != null) {
                        setDialogState(() => error = pwErr);
                        return;
                      }
                      final navigator = Navigator.of(context);
                      setDialogState(() {
                        error = null;
                        isSaving = true;
                      });
                      try {
                        await ref
                            .read(accountAdminRepositoryProvider)
                            .createGuard(
                              fullName: name.text,
                              email: email.text,
                              password: password.text,
                              phone: phone.text.trim().isEmpty
                                  ? null
                                  : phone.text.trim(),
                            );
                        ref.invalidate(adminGuardsProvider);
                        navigator.pop();
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          error = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showForm(Profile guard) {
    final shiftController = TextEditingController(text: guard.shift ?? '');
    final postController = TextEditingController(text: guard.post ?? '');
    bool onDuty = guard.onDuty;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                'Manage ${guard.fullName}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.success,
                        title: const Text(
                          'On Duty',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'On-duty guards are highlighted in the directory',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: onDuty,
                        onChanged: (val) =>
                            setDialogState(() => onDuty = val),
                      ),
                      _buildTextField(
                        shiftController,
                        'Shift (e.g. 8AM - 4PM)',
                        Icons.schedule,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        postController,
                        'Post (e.g. Main Gate)',
                        Icons.location_on,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  key: const Key('guard-reset-password'),
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(context);
                          _resetPassword(guard);
                        },
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text('Reset password'),
                ),
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          setDialogState(() => isSaving = true);
                          try {
                            await ref
                                .read(adminRepositoryProvider)
                                .updateGuardDuty(
                                  guard.id,
                                  shift: shiftController.text.isEmpty
                                      ? null
                                      : shiftController.text,
                                  post: postController.text.isEmpty
                                      ? null
                                      : postController.text,
                                  onDuty: onDuty,
                                );
                            ref.invalidate(adminGuardsProvider);
                            navigator.pop();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showError(e);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
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
            borderSide: const BorderSide(color: AppColors.brand),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardsAsync = ref.watch(adminGuardsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Security Guards',
                  subtitle: 'Manage guard duty status, shift and post',
                ),
              ),
              ElevatedButton.icon(
                key: const Key('add-guard'),
                onPressed: _showCreateForm,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add guard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: guardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminGuardsProvider),
              ),
              data: (guards) {
                if (guards.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.shield_rounded,
                    title: 'No guards found',
                    message:
                        'Guard accounts (role = guard) will appear here once created.',
                    gradient: AppColors.skyGradient,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminGuardsProvider),
                  child: ListView.builder(
                    itemCount: guards.length,
                    itemBuilder: (context, index) {
                      final g = guards[index];
                      final detail = [
                        g.post,
                        g.shift,
                      ].where((e) => e != null && e.isNotEmpty).join(' — ');
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GradientIconBadge(
                            icon: Icons.shield_rounded,
                            gradient: g.onDuty
                                ? AppColors.skyGradient
                                : AppColors.brandGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  g.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: g.onDuty ? 'ON DUTY' : 'OFF DUTY',
                                color: g.onDuty
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                dense: true,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              detail.isEmpty ? 'Security Guard' : detail,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.accentAmber,
                            ),
                            onPressed: () => _showForm(g),
                            tooltip: 'Edit Duty',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
