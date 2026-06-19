import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      drawer: isDesktop ? null : _buildSidebar(context, isDesktop: false),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF2B3674)),
              title: const Text(
                'PHH housing',
                style: TextStyle(
                  color: Color(0xFF2B3674),
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFA3AED0)),
                  onPressed: () async => Supabase.instance.client.auth.signOut(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: child, // Removed the constrained white container so pages can define their own cards
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    String title = 'Dashboard';
    if (location.contains('residents')) title = 'Residents';
    else if (location.contains('houses')) title = 'Houses';
    else if (location.contains('announcements')) title = 'Announcements';
    else if (location.contains('banners')) title = 'Banners';
    else if (location.contains('billings')) title = 'Billings';
    else if (location.contains('visitors')) title = 'Visitors';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
                    color: Color(0xFFA3AED0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2B3674),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF4318FF),
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Admin',
                  style: TextStyle(
                    color: Color(0xFF2B3674),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFA3AED0)),
                  onPressed: () async => Supabase.instance.client.auth.signOut(),
                  tooltip: 'Logout',
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool isDesktop}) {
    final String location = GoRouterState.of(context).uri.path;
    // On desktop keep the full sidebar; as a drawer, cap to 80% of the screen
    // so it never swallows the whole viewport on small phones.
    final double sidebarWidth =
        isDesktop ? 280 : math.min(280, MediaQuery.of(context).size.width * 0.8);

    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF4318FF), size: 32),
              SizedBox(width: 12),
              Text(
                'PHH housing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B3674),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFF4F7FE), thickness: 2, height: 1),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  isSelected: location == '/admin/dashboard',
                  onTap: () {
                    context.go('/admin/dashboard');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
                _SidebarItem(
                  icon: Icons.people_alt_rounded,
                  title: 'Residents',
                  isSelected: location.startsWith('/admin/residents'),
                  onTap: () {
                    context.go('/admin/residents');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
                _SidebarItem(
                  icon: Icons.house_rounded,
                  title: 'Houses & Units',
                  isSelected: location.startsWith('/admin/houses'),
                  onTap: () {
                    context.go('/admin/houses');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
                _SidebarItem(
                  icon: Icons.campaign_rounded,
                  title: 'Announcements',
                  isSelected: location.startsWith('/admin/announcements'),
                  onTap: () {
                    context.go('/admin/announcements');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
                _SidebarItem(
                  icon: Icons.view_carousel_rounded,
                  title: 'Banners',
                  isSelected: location.startsWith('/admin/banners'),
                  onTap: () {
                    context.go('/admin/banners');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
                _SidebarItem(
                  icon: Icons.receipt_long_rounded,
                  title: 'Billings',
                  isSelected: location.startsWith('/admin/billings'),
                  onTap: () {
                    context.go('/admin/billings');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
                _SidebarItem(
                  icon: Icons.badge_rounded,
                  title: 'Visitors',
                  isSelected: location.startsWith('/admin/visitors'),
                  onTap: () {
                    context.go('/admin/visitors');
                    if (!isDesktop) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4318FF).withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF4318FF) : const Color(0xFFA3AED0),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF2B3674) : const Color(0xFFA3AED0),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4318FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
