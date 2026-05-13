import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../theme/app_colors.dart';

class MainNavigationPage extends StatelessWidget {
  final Widget child;

  const MainNavigationPage({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/access')) return 1;
    if (location.startsWith('/bills')) return 2;
    if (location.startsWith('/profile')) return 3;
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
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Stack(
        children: [
          child,
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _buildFloatingNavBar(context, currentIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context, int currentIndex) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite.withOpacity(0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                currentIndex: currentIndex,
                icon: PhosphorIconsRegular.house,
                activeIcon: PhosphorIconsFill.house,
                label: 'Home',
              ),
              _buildNavItem(
                context,
                index: 1,
                currentIndex: currentIndex,
                icon: PhosphorIconsRegular.qrCode,
                activeIcon: PhosphorIconsFill.qrCode,
                label: 'Access',
              ),
              _buildNavItem(
                context,
                index: 2,
                currentIndex: currentIndex,
                icon: PhosphorIconsRegular.receipt,
                activeIcon: PhosphorIconsFill.receipt,
                label: 'Bills',
              ),
              _buildNavItem(
                context,
                index: 3,
                currentIndex: currentIndex,
                icon: PhosphorIconsRegular.user,
                activeIcon: PhosphorIconsFill.user,
                label: 'Profile',
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sageGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.sageGreen : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.sageGreen : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
