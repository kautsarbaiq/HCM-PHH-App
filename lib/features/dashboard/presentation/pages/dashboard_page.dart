import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:hcm_app/theme/app_colors.dart';
import '../../../main/presentation/pages/main_navigation_page.dart';
import '../../../access/presentation/widgets/smart_access_modal.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';
import '../widgets/booking_reminder_card.dart';
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
              const BookingReminderCard().animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Inner Pill for Profile & Name
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryWhite,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://i.pravatar.cc/150?u=alex',
                          errorBuilder: (context, error, stackTrace) => const Icon(PhosphorIconsRegular.user, color: AppColors.sageGreen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Alex Morgan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsRegular.houseLine, size: 20, color: AppColors.deepSlate),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Menu Button (replacing the QR in the image)
          GestureDetector(
            onTap: () => mainScaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sageGreen.withOpacity(0.3),
                  style: BorderStyle.none, // Match the dashed look if needed, but let's keep it clean
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Dotted border effect simulation
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      value: 0.8,
                      strokeWidth: 1,
                      backgroundColor: Colors.transparent,
                      color: AppColors.sageGreen,
                    ),
                  ),
                  const Icon(PhosphorIconsRegular.list, color: AppColors.deepSlate, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0);
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
