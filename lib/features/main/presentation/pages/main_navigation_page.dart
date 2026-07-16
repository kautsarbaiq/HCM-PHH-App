import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:hcm_app/core/config/brand.dart';
import 'package:hcm_app/core/repositories/profile_repository.dart';
import 'package:hcm_app/theme/app_colors.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';
import '../../../../l10n/app_strings.dart';
import '../widgets/app_drawer.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

/// HCA point 17: a Tenant resident cannot see or reach billing anywhere.
/// Owners and all PHH users are unaffected. Shared by the nav bar, dashboard
/// and quick-access grid.
bool hideBillsForTenant(WidgetRef ref) {
  if (Brand.isPhh) return false;
  return ref.watch(currentProfileProvider).valueOrNull?.isTenant ?? false;
}

class MainNavigationPage extends ConsumerWidget {
  final Widget child;

  const MainNavigationPage({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/access')) return 1;
    if (location.startsWith('/bills')) return 2;
    if (location.startsWith('/community')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/access');
        break;
      case 2:
        context.go('/bills');
        break;
      case 3:
        context.go('/community');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int currentIndex = _calculateSelectedIndex(context);
    // HCA: while the keyboard is open the floating nav/SOS would ride up over
    // the form fields (boss feedback 15/07) — hide them until typing is done.
    final bool hideFloatingUi =
        !Brand.isPhh && MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      key: mainScaffoldKey,
      // HCA replaces the side drawer with the home Quick Access grid.
      drawer: Brand.isPhh ? const AppDrawer() : null,
      body: Stack(
        children: [
          child,
          // SOS FAB
          if (!hideFloatingUi)
            Positioned(
            right: 24,
            bottom: 120,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const EmergencyBottomSheet(),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIconsFill.warning,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Floating Nav Bar
          if (!hideFloatingUi)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: _buildFloatingNavBar(context, ref, currentIndex),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite.withOpacity(0.9),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: AppColors.brand.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(
                  context,
                  index: 0,
                  currentIndex: currentIndex,
                  icon: PhosphorIconsRegular.house,
                  activeIcon: PhosphorIconsFill.house,
                  label: ref.tr('nav.home'),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  index: 1,
                  currentIndex: currentIndex,
                  icon: PhosphorIconsRegular.qrCode,
                  activeIcon: PhosphorIconsFill.qrCode,
                  label: ref.tr('nav.access'),
                ),
              ),
              // Point 17: tenants don't see billing. Owners & PHH keep it.
              if (!hideBillsForTenant(ref))
                Expanded(
                  child: _buildNavItem(
                    context,
                    index: 2,
                    currentIndex: currentIndex,
                    icon: PhosphorIconsRegular.receipt,
                    activeIcon: PhosphorIconsFill.receipt,
                    label: ref.tr('nav.bills'),
                  ),
                ),
              Expanded(
                child: _buildNavItem(
                  context,
                  index: 3,
                  currentIndex: currentIndex,
                  icon: PhosphorIconsRegular.users,
                  activeIcon: PhosphorIconsFill.users,
                  label: ref.tr('nav.community'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            // PHH keeps the original subtle tint pill; HCA uses a solid
            // logo-gradient pill (teal → navy).
            gradient: isSelected
                ? (Brand.isPhh
                      ? LinearGradient(
                          colors: [
                            AppColors.brand.withOpacity(0.14),
                            AppColors.brand.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.brandGradient)
                : null,
            borderRadius: BorderRadius.circular(22),
            border: Brand.isPhh
                ? Border.all(
                    color: isSelected
                        ? AppColors.brand.withOpacity(0.24)
                        : Colors.transparent,
                    width: 1,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brand.withOpacity(
                        Brand.isPhh ? 0.08 : 0.30,
                      ),
                      blurRadius: Brand.isPhh ? 12 : 14,
                      offset: Offset(0, Brand.isPhh ? 4 : 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? (Brand.isPhh ? AppColors.brand : Colors.white)
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (Brand.isPhh ? AppColors.brand : Colors.white)
                        : AppColors.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Brand.isPhh ? AppColors.brand : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
