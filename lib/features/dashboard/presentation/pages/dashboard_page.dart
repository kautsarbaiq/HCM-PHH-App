import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/app_colors.dart';
import '../widgets/notice_slider.dart';
import '../widgets/quick_action_item.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              const NoticeSlider().animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 32),
              _buildQuickActions(),
              const SizedBox(height: 100), // Padding for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Alex Morgan',
              style: TextStyle(
                fontSize: 28,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ).animate().fade(duration: 400.ms).slideX(begin: -0.1, end: 0),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.sageGreen.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.sageGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Icon(
              PhosphorIconsRegular.bell,
              color: AppColors.sageGreen,
              size: 24,
            ),
          ),
        ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ).animate().fade(duration: 400.ms),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: PhosphorIconsRegular.warningCircle,
              label: 'Panic\nButton',
              color: AppColors.error,
              onTap: () {},
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.qrCode,
              label: 'Visitor\nAccess',
              color: AppColors.sageGreen,
              onTap: () {},
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.receipt,
              label: 'Pay\nBills',
              color: AppColors.deepSlate,
              onTap: () {},
            ),
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
