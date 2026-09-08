import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/delete_account_tile.dart';
import '../../../../core/repositories/merchant_repository.dart';
import '../../../../theme/app_colors.dart';

/// Shell for the Merchant portal (boss batch 08/08 point 2).
class MerchantLayout extends ConsumerWidget {
  final Widget child;
  const MerchantLayout({super.key, required this.child});

  static const _tabs = [
    ('/merchant/shop', Icons.storefront_rounded, 'My Shop'),
    ('/merchant/offers', Icons.local_offer_rounded, 'Offers'),
    ('/merchant/redeem', Icons.qr_code_scanner_rounded, 'Redeem'),
  ];

  int _indexFor(String loc) {
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final shopName =
        ref.watch(myShopProvider).valueOrNull?.shopName ?? 'Merchant';

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                shopName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon:
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                ),
              ],
            ),
      body: Row(
        children: [
          if (isDesktop) _sidebar(context, location, shopName),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _indexFor(location),
              onDestinationSelected: (i) => context.go(_tabs[i].$1),
              destinations: [
                for (final t in _tabs)
                  NavigationDestination(icon: Icon(t.$2), label: t.$3),
              ],
            ),
    );
  }

  Widget _sidebar(BuildContext context, String location, String shopName) {
    return Container(
      width: 250,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      shopName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 10),
            for (final t in _tabs)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Material(
                  color: location.startsWith(t.$1)
                      ? AppColors.brand
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go(t.$1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(t.$2,
                              size: 20,
                              color: location.startsWith(t.$1)
                                  ? Colors.white
                                  : AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            t.$3,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: location.startsWith(t.$1)
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Logout',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () => Supabase.instance.client.auth.signOut(),
            ),
            // App Store 5.1.1(v) / Play: merchants sign in on mobile, so they
            // need the same in-app deletion path as residents and guards.
            const DeleteAccountTile(dense: true),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
