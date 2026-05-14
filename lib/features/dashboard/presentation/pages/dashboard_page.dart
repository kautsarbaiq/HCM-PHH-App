import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:hcm_app/theme/app_colors.dart';
import '../../../main/presentation/pages/main_navigation_page.dart';
import '../../../access/presentation/widgets/smart_access_modal.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';
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
              _buildHeader(context),
              const SizedBox(height: 32),
              const NoticeSlider().animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => mainScaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder, width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Center(child: Icon(PhosphorIconsRegular.list, color: AppColors.deepSlate, size: 22)),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning,', style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Alex Morgan', style: TextStyle(fontSize: 28, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ).animate().fade(duration: 400.ms).slideX(begin: -0.1, end: 0),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.sageGreen.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: AppColors.sageGreen.withOpacity(0.3), width: 1.5),
          ),
          child: const Center(child: Icon(PhosphorIconsRegular.bell, color: AppColors.sageGreen, size: 24)),
        ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)).animate().fade(duration: 400.ms),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: PhosphorIconsRegular.warningCircle,
              label: 'Panic\nButton',
              color: AppColors.error,
              onTap: () {
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (context) => const EmergencyBottomSheet());
              },
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.qrCode,
              label: 'Visitor\nAccess',
              color: AppColors.sageGreen,
              onTap: () => context.go('/access'),
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.receipt,
              label: 'Pay\nBills',
              color: AppColors.deepSlate,
              onTap: () => context.go('/bills'),
            ),
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: PhosphorIconsRegular.phone,
              label: 'Mobile\nIntercom',
              color: const Color(0xFF3B82F6),
              onTap: () {
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (context) => const SmartAccessModal());
              },
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.lockOpen,
              label: 'Access\nControl',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (context) => const SmartAccessModal());
              },
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.buildings,
              label: 'Book\nFacility',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/facility'),
            ),
          ],
        ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
