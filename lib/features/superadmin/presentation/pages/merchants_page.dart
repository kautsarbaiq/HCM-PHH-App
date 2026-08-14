import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/repositories/super_admin_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Super admin → Merchants (boss batch 08/08 point 1, third bullet).
/// Lists every merchant shop and lets the super admin enable/disable them.
/// Merchants manage their own shop profile and offers in the merchant portal.
class SuperMerchantsPage extends ConsumerWidget {
  const SuperMerchantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(merchantAccountsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Merchants',
                  subtitle: 'Shops offering rewards to residents',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => const _CreateMerchantDialog(),
                  );
                  ref.invalidate(merchantAccountsProvider);
                },
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Add merchant'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Creating a merchant makes their login and their shop in one step. '
            'The merchant then signs in to their own portal to add photos, '
            'offers and to redeem resident vouchers.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: merchantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load merchants: $e',
                onRetry: () => ref.invalidate(merchantAccountsProvider),
              ),
              data: (merchants) {
                if (merchants.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No merchants yet',
                    message:
                        'Create a merchant account to let a shop offer rewards.',
                  );
                }
                // Boss batch 08/08 point 12: thumbnail grid, not a plain list.
                return LayoutBuilder(
                  builder: (context, c) {
                    final cols = (c.maxWidth / 240).floor().clamp(1, 5);
                    return GridView.builder(
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: merchants.length,
                      itemBuilder: (context, i) {
                        final m = merchants[i];
                        return _MerchantTile(
                          merchant: m,
                          onToggle: (v) async {
                            await ref
                                .read(superAdminRepositoryProvider)
                                .setMerchantActive(m.id, v);
                            ref.invalidate(merchantAccountsProvider);
                          },
                        );
                      },
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

/// Thumbnail card for one merchant (boss batch 08/08 point 12).
class _MerchantTile extends StatelessWidget {
  final MerchantAccount merchant;
  final ValueChanged<bool> onToggle;
  const _MerchantTile({required this.merchant, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final m = merchant;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A7BA8).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo / cover
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: (m.logoUrl ?? '').isNotEmpty
                  ? Image.network(
                      m.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  [
                    if ((m.category ?? '').isNotEmpty) m.category!,
                    if ((m.communityName ?? '').isNotEmpty) m.communityName!,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusPill(
                      label: m.isActive ? 'ACTIVE' : 'OFF',
                      color: m.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      dense: true,
                    ),
                    const Spacer(),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(value: m.isActive, onChanged: onToggle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.surfaceTint,
        alignment: Alignment.center,
        child: const Icon(Icons.storefront_rounded,
            color: AppColors.brand, size: 36),
      );
}

/// Creates a merchant login + its shop row in one step (boss batch 08/08
/// point 1, third bullet).
class _CreateMerchantDialog extends ConsumerStatefulWidget {
  const _CreateMerchantDialog();

  @override
  ConsumerState<_CreateMerchantDialog> createState() =>
      _CreateMerchantDialogState();
}

class _CreateMerchantDialogState
    extends ConsumerState<_CreateMerchantDialog> {
  final _shop = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _category = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  String? _communityId; // null = available to every community
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _shop.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _category.dispose();
    _contact.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_shop.text.trim().length < 2) {
      setState(() => _error = 'Enter the shop name.');
      return;
    }
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter the owner\'s name.');
      return;
    }
    if (!_email.text.trim().contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(superAdminRepositoryProvider).createMerchantAccount(
            shopName: _shop.text.trim(),
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            communityId: _communityId,
            category: _category.text.trim(),
            contact: _contact.text.trim(),
            address: _address.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${_shop.text.trim()} created.'),
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
    final companies = ref.watch(companiesProvider).valueOrNull ?? const [];
    return AlertDialog(
      title: const Text('Add merchant'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_shop, 'Shop name'),
              const SizedBox(height: 12),
              _field(_category, 'Category (e.g. Restaurant, Cafe)'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _communityId,
                decoration: const InputDecoration(
                  labelText: 'Community',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All communities'),
                  ),
                  for (final c in companies)
                    DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text('${c.code} — ${c.name}'),
                    ),
                ],
                onChanged: (v) => setState(() => _communityId = v),
              ),
              const SizedBox(height: 12),
              _field(_contact, 'Contact number (optional)'),
              const SizedBox(height: 12),
              _field(_address, 'Address (optional)'),
              const Divider(height: 28),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Merchant portal login',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field(_name, 'Owner full name'),
              const SizedBox(height: 12),
              _field(_email, 'Email',
                  keyboard: TextInputType.emailAddress),
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
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.error),
                ),
              ],
            ],
          ),
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
              : const Text('Create merchant'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
