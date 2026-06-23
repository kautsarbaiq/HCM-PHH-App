import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/language_switcher.dart';
import '../../../../theme/app_colors.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      drawer: isDesktop ? null : _buildSidebar(context, isDesktop: false),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logoBadge(28),
                  const SizedBox(width: 10),
                  const Text(
                    'PHH Housing',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () async =>
                      Supabase.instance.client.auth.signOut(),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildSidebar(context, isDesktop: true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) _buildTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: child,
                  ),
                ),
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
        Icons.holiday_village_rounded,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    String title = 'Dashboard';
    if (location.contains('residents')) {
      title = 'Residents';
    } else if (location.contains('houses')) {
      title = 'Houses';
    } else if (location.contains('announcements')) {
      title = 'Announcements';
    } else if (location.contains('banners')) {
      title = 'Banners';
    } else if (location.contains('billings')) {
      title = 'Billings';
    } else if (location.contains('visitors')) {
      title = 'Visitors';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pages / Admin / $title',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A7BA8).withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () async =>
                      Supabase.instance.client.auth.signOut(),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isDesktop}) {
    final String location = GoRouterState.of(context).uri.path;
    final double sidebarWidth = isDesktop
        ? 270
        : math.min(280, MediaQuery.of(context).size.width * 0.82);

    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _logoBadge(40),
                const SizedBox(width: 12),
                const Text(
                  'PHH Housing',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(height: 1, color: const Color(0xFFEEF1FA)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _item(
                    context,
                    Icons.dashboard_rounded,
                    'Dashboard',
                    '/admin/dashboard',
                    location == '/admin/dashboard',
                    isDesktop,
                  ),
                  _item(
                    context,
                    Icons.people_alt_rounded,
                    'Residents',
                    '/admin/residents',
                    location.startsWith('/admin/residents'),
                    isDesktop,
                  ),
                  _item(
                    context,
                    Icons.house_rounded,
                    'Houses & Units',
                    '/admin/houses',
                    location.startsWith('/admin/houses'),
                    isDesktop,
                  ),
                  _item(
                    context,
                    Icons.campaign_rounded,
                    'Announcements',
                    '/admin/announcements',
                    location.startsWith('/admin/announcements'),
                    isDesktop,
                  ),
                  _item(
                    context,
                    Icons.view_carousel_rounded,
                    'Banners',
                    '/admin/banners',
                    location.startsWith('/admin/banners'),
                    isDesktop,
                  ),
                  _item(
                    context,
                    Icons.receipt_long_rounded,
                    'Billings',
                    '/admin/billings',
                    location.startsWith('/admin/billings'),
                    isDesktop,
                  ),
                  _item(
                    context,
                    Icons.badge_rounded,
                    'Visitors',
                    '/admin/visitors',
                    location.startsWith('/admin/visitors'),
                    isDesktop,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: LanguageSwitcher()),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _item(
                context,
                Icons.logout_rounded,
                'Logout',
                null,
                false,
                isDesktop,
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String? path,
    bool selected,
    bool isDesktop, {
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            if (isLogout) {
              await Supabase.instance.client.auth.signOut();
              return;
            }
            if (path != null) {
              context.go(path);
              if (!isDesktop) Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.brandGradient : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.brand.withOpacity(0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? Colors.white
                      : (isLogout ? AppColors.error : AppColors.textSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : (isLogout
                                ? AppColors.error
                                : AppColors.textPrimary),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                    ),
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
