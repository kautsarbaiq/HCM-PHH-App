import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuardLayout extends StatelessWidget {
  final Widget child;

  const GuardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Wide (tablet/desktop) → fixed sidebar. Narrow (phone) → hamburger drawer,
    // so the content isn't crushed by a 250px sidebar.
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      drawer: isWide ? null : Drawer(backgroundColor: Colors.white, child: _sidebar(context, isWide: false)),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B3674)),
        title: const Text(
          'Security Portal',
          style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.signOut, color: Colors.redAccent),
            onPressed: () async => Supabase.instance.client.auth.signOut(),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWide) SizedBox(width: 250, child: _sidebar(context, isWide: true)),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _sidebar(BuildContext context, {required bool isWide}) {
    final String location = GoRouterState.of(context).uri.path;

    void go(String path) {
      context.go(path);
      if (!isWide) Navigator.pop(context); // close the drawer on phones
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _SidebarItem(
              icon: PhosphorIconsRegular.users,
              label: 'Visitor Logs',
              isSelected: location == '/guard/visitors',
              onTap: () => go('/guard/visitors'),
            ),
            _SidebarItem(
              icon: PhosphorIconsRegular.house,
              label: 'House Directory',
              isSelected: location == '/guard/houses',
              onTap: () => go('/guard/houses'),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Divider(),
            ),
            _SidebarItem(
              icon: PhosphorIconsRegular.qrCode,
              label: 'Scan QR',
              isSelected: location == '/guard/scan',
              onTap: () => go('/guard/scan'),
              isPrimary: true,
            ),
            _SidebarItem(
              icon: PhosphorIconsRegular.userPlus,
              label: 'Manual Registration',
              isSelected: location == '/guard/register',
              onTap: () => go('/guard/register'),
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPrimary;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrimary ? const Color(0xFF10B981) : const Color(0xFF4318FF))
              : (isPrimary ? const Color(0xFF10B981).withOpacity(0.08) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isPrimary ? const Color(0xFF10B981) : const Color(0xFFA3AED0)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isPrimary ? const Color(0xFF10B981) : const Color(0xFFA3AED0)),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
