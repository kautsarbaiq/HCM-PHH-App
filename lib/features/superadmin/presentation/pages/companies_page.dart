import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/repositories/super_admin_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Super admin → Companies (boss batch 08/08 point 1).
/// Each row is a community/company: its admin account, resident count, and the
/// app modules that company is allowed to show.
class CompaniesPage extends ConsumerWidget {
  const CompaniesPage({super.key});

  Future<void> _addCompany(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add company'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Company / community name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Join code (3-6 digits)',
                  helperText: 'Residents type this when they register',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              if (!RegExp(r'^\d{3,6}$').hasMatch(code.text.trim())) return;
              Navigator.pop(d, true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(superAdminRepositoryProvider)
          .createCompany(code.text.trim(), name.text.trim());
      ref.invalidate(companiesProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  /// Creates the company's admin login (boss batch 08/08 point 1, first
  /// bullet). Auth users need the service_role key, so this goes through the
  /// `super-create-account` edge function.
  Future<void> _createAdmin(
      BuildContext context, WidgetRef ref, Company c) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CreateAdminDialog(company: c),
    );
    ref.invalidate(companiesProvider);
  }

  Future<void> _manageModules(
      BuildContext context, WidgetRef ref, Company c) async {
    await showDialog<void>(
      context: context,
      builder: (d) => _ModulesDialog(company: c),
    );
    ref.invalidate(companiesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Companies',
                  subtitle: 'Communities, their admin account and app modules',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addCompany(context, ref),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Add company'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: companiesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load companies: $e',
                onRetry: () => ref.invalidate(companiesProvider),
              ),
              data: (companies) {
                if (companies.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.apartment_rounded,
                    title: 'No companies yet',
                    message: 'Create the first community to get started.',
                  );
                }
                return ListView.separated(
                  itemCount: companies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = companies[i];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brand,
                        child: Text(
                          c.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        [
                          c.adminEmail == null
                              ? 'No admin account yet'
                              : 'Admin: ${c.adminName ?? c.adminEmail}',
                          '${c.residentCount} residents',
                        ].join('  •  '),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusPill(
                            label:
                                '${c.enabledCount}/${kAppModules.length} MODULES',
                            color: AppColors.info,
                            dense: true,
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _createAdmin(context, ref, c),
                            icon: const Icon(
                                Icons.admin_panel_settings_rounded, size: 18),
                            label: Text(c.adminEmail == null
                                ? 'Create admin'
                                : 'Add admin'),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () => _manageModules(context, ref, c),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Modules'),
                          ),
                        ],
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

/// Toggle which modules a company's residents can see.
class _ModulesDialog extends ConsumerStatefulWidget {
  final Company company;
  const _ModulesDialog({required this.company});

  @override
  ConsumerState<_ModulesDialog> createState() => _ModulesDialogState();
}

class _ModulesDialogState extends ConsumerState<_ModulesDialog> {
  late Map<String, bool> _state = {
    for (final k in kAppModules.keys) k: widget.company.isModuleOn(k),
  };
  bool _busy = false;

  Future<void> _toggle(String key, bool value) async {
    setState(() {
      _state[key] = value;
      _busy = true;
    });
    try {
      await ref
          .read(superAdminRepositoryProvider)
          .setModule(widget.company.id, key, value);
    } catch (e) {
      if (mounted) {
        setState(() => _state[key] = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modules — ${widget.company.name}'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Switch off what this company should not see in the app.',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                children: [
                  for (final e in kAppModules.entries)
                    SwitchListTile(
                      dense: true,
                      title: Text(e.value),
                      value: _state[e.key] ?? true,
                      onChanged: (v) => _toggle(e.key, v),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Creates the admin login for one company (boss batch 08/08 point 1).
class _CreateAdminDialog extends ConsumerStatefulWidget {
  final Company company;
  const _CreateAdminDialog({required this.company});

  @override
  ConsumerState<_CreateAdminDialog> createState() =>
      _CreateAdminDialogState();
}

class _CreateAdminDialogState extends ConsumerState<_CreateAdminDialog> {
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
      setState(() => _error = 'Enter the admin\'s name.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
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
      await ref.read(superAdminRepositoryProvider).createCompanyAdmin(
            communityId: widget.company.id,
            fullName: name,
            email: email,
            password: pass,
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$name can now sign in to the web portal.'),
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
      title: Text('Admin account — ${widget.company.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This login manages that company only: its residents, billing, '
              'visitors and announcements. Management accounts cannot sign in '
              'on the mobile app.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password (min 6 characters)',
                border: const OutlineInputBorder(),
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
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create account'),
        ),
      ],
    );
  }
}
