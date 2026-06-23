import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/language_switcher.dart';
import '../../../../theme/app_colors.dart';
import '../../../emergency/presentation/widgets/active_emergency_banner.dart';
import '../../../emergency/presentation/widgets/emergency_broadcast_sheet.dart';

class GuardLayout extends StatelessWidget {
  final Widget child;

  const GuardLayout({super.key, required this.child});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access the security portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await Supabase.instance.client.auth.signOut();
      // The router's auth-state redirect moves to /login once signed out.
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not sign out: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;
    final sidebarWidth = (width * 0.26).clamp(230.0, 300.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: Colors.white,
              child: _sidebar(context, isWide: false),
            ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _logoBadge(28),
            const SizedBox(width: 10),
            const Text(
              'Security Portal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              PhosphorIconsFill.megaphone,
              color: AppColors.error,
            ),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const EmergencyBroadcastSheet(),
            ),
            tooltip: 'Broadcast emergency alert',
          ),
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.signOut,
              color: AppColors.error,
            ),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: sidebarWidth,
              child: _sidebar(context, isWide: true),
            ),
          Expanded(
            child: Column(
              children: [
                // Live emergency feed on every guard screen; guards can resolve.
                const ActiveEmergencyBanner(canResolve: true),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoBadge(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        PhosphorIconsFill.shieldCheck,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  Widget _sidebar(BuildContext context, {required bool isWide}) {
    final String location = GoRouterState.of(context).uri.path;

    void go(String path) {
      context.go(path);
      if (!isWide) Navigator.pop(context);
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _SidebarItem(
              icon: PhosphorIconsRegular.users,
              activeIcon: PhosphorIconsFill.users,
              label: 'Visitor Logs',
              isSelected: location == '/guard/visitors',
              onTap: () => go('/guard/visitors'),
            ),
            _SidebarItem(
              icon: PhosphorIconsRegular.house,
              activeIcon: PhosphorIconsFill.house,
              label: 'House Directory',
              isSelected: location == '/guard/houses',
              onTap: () => go('/guard/houses'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(height: 1, color: const Color(0xFFEEF1FA)),
                  ),
                ],
              ),
            ),
            _SidebarItem(
              icon: PhosphorIconsRegular.qrCode,
              activeIcon: PhosphorIconsFill.qrCode,
              label: 'Scan QR',
              isSelected: location == '/guard/scan',
              onTap: () => go('/guard/scan'),
              accent: AppColors.mintGradient,
            ),
            _SidebarItem(
              icon: PhosphorIconsRegular.userPlus,
              activeIcon: PhosphorIconsFill.userPlus,
              label: 'Manual Registration',
              isSelected: location == '/guard/register',
              onTap: () => go('/guard/register'),
              accent: AppColors.mintGradient,
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: LanguageSwitcher()),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _SidebarItem(
                icon: PhosphorIconsRegular.signOut,
                activeIcon: PhosphorIconsRegular.signOut,
                label: 'Logout',
                isSelected: false,
                onTap: () => _handleLogout(context),
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Gradient? accent;
  final bool isLogout;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accent,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = accent ?? AppColors.brandGradient;
    final tint = (accent?.colors.first) ?? AppColors.brand;
    final restColor = isLogout ? AppColors.error : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected ? gradient : null,
              color: !isSelected && accent != null
                  ? tint.withOpacity(0.08)
                  : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: tint.withOpacity(0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected
                      ? Colors.white
                      : (accent != null ? tint : restColor),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (accent != null
                                ? tint
                                : (isLogout
                                      ? AppColors.error
                                      : AppColors.textPrimary)),
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
