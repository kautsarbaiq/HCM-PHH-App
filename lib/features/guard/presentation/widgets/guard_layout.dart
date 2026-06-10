import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuardLayout extends StatelessWidget {
  final Widget child;

  const GuardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Security Portal',
          style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.signOut, color: Colors.redAccent),
            onPressed: () => context.go('/guard'),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _SidebarItem(
                  icon: PhosphorIconsRegular.users,
                  label: 'Visitor Logs',
                  isSelected: location == '/guard/visitors',
                  onTap: () => context.go('/guard/visitors'),
                ),
                _SidebarItem(
                  icon: PhosphorIconsRegular.house,
                  label: 'House Directory',
                  isSelected: location == '/guard/houses',
                  onTap: () => context.go('/guard/houses'),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Divider(),
                ),
                _SidebarItem(
                  icon: PhosphorIconsRegular.qrCode,
                  label: 'Scan QR',
                  isSelected: location == '/guard/scan',
                  onTap: () => context.go('/guard/scan'),
                  isPrimary: true,
                ),
                _SidebarItem(
                  icon: PhosphorIconsRegular.userPlus,
                  label: 'Manual Registration',
                  isSelected: location == '/guard/register',
                  onTap: () => context.go('/guard/register'),
                  isPrimary: true,
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: child,
          ),
        ],
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
              : Colors.transparent,
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
                  color: isSelected ? Colors.white : const Color(0xFFA3AED0),
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
