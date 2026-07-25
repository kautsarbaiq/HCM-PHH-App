import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/wms_store.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/primary_button.dart';
import '../../../theme/app_colors.dart';

/// Hub of the warehouse/inventory module (boss flow 20/07): entry point for
/// Receiving → Placement → Picking → Comparison, running against the shared
/// PHH-Inventory ("canvas") backend.
class InventoryHomePage extends ConsumerWidget {
  const InventoryHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(inventoryAuthProvider);
    // The WMS API requires a signed-in warehouse account (better-auth on the
    // inventory server — separate from the housing app's Supabase login).
    if (!auth.signedIn) return const _InventoryLoginView();

    final store = ref.watch(wmsStoreProvider);

    final modules = <_Module>[
      _Module(
        'Receiving',
        'Receive against POs',
        Icons.move_to_inbox_rounded,
        AppColors.brandGradient,
        '/inventory/receiving',
        store.pendingReceivingCount,
      ),
      _Module(
        'Picking',
        'Pick sales orders',
        Icons.shopping_cart_checkout_rounded,
        AppColors.skyGradient,
        '/inventory/picking',
        store.openPickCount,
      ),
      _Module(
        'Placement',
        'Put-away to bins',
        Icons.shelves,
        AppColors.mintGradient,
        '/inventory/placement',
        store.awaitingPlacementCount,
      ),
      _Module(
        'Comparison',
        'Expected vs received',
        Icons.compare_arrows_rounded,
        AppColors.sunsetGradient,
        '/inventory/comparison',
        store.varianceCount,
      ),
    ];

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.warehouse_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Warehouse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Inventory operations',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Sign out of warehouse',
                    onPressed: () => ref.read(inventoryAuthProvider).signOut(),
                    icon: const Icon(Icons.logout_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
                children: modules.map((m) => _ModuleTile(module: m)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String route;
  final int badge;
  _Module(this.title, this.subtitle, this.icon, this.gradient, this.route, this.badge);
}

/// Sign-in card shown until the warehouse account session exists.
class _InventoryLoginView extends ConsumerStatefulWidget {
  const _InventoryLoginView();

  @override
  ConsumerState<_InventoryLoginView> createState() =>
      _InventoryLoginViewState();
}

class _InventoryLoginViewState extends ConsumerState<_InventoryLoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(inventoryAuthProvider);

    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlassCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.warehouse_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Warehouse sign in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Use your inventory-portal account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: deco('Email', Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: deco('Password', Icons.lock_outline),
                        onSubmitted: (_) => _submit(),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Sign in',
                        icon: Icons.login_rounded,
                        loading: auth.busy,
                        onPressed: auth.busy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    ref
        .read(inventoryAuthProvider)
        .signIn(_email.text.trim(), _password.text);
  }
}

class _ModuleTile extends StatelessWidget {
  final _Module module;
  const _ModuleTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(module.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: module.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: module.gradient.colors.first.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(module.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              if (module.badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${module.badge}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            module.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            module.subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
