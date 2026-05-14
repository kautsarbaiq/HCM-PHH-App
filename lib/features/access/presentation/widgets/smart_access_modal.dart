import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../theme/app_colors.dart';

class SmartAccessModal extends StatefulWidget {
  const SmartAccessModal({super.key});

  @override
  State<SmartAccessModal> createState() => _SmartAccessModalState();
}

class _SmartAccessModalState extends State<SmartAccessModal> {
  int _currentView = 0; // 0 = menu, 1 = intercom, 2 = gate control

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryWhite.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: AppColors.primaryWhite.withOpacity(0.5), width: 1.5),
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentView == 0
                  ? _buildMenu()
                  : _currentView == 1
                      ? _buildIntercom()
                      : _buildGateControl(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      key: const ValueKey('menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Smart Access',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your home access remotely.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildAccessOption(
                icon: PhosphorIconsRegular.phone,
                title: 'Mobile\nIntercom',
                color: AppColors.sageGreen,
                onTap: () => setState(() => _currentView = 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAccessOption(
                icon: PhosphorIconsRegular.lockOpen,
                title: 'Gate\nControl',
                color: AppColors.deepSlate,
                onTap: () => setState(() => _currentView = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAccessOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntercom() {
    return Column(
      key: const ValueKey('intercom'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _currentView = 0),
              child: const Icon(PhosphorIconsRegular.caretLeft, size: 24, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mobile Intercom',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.sageGreen.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.sageGreen.withOpacity(0.3), width: 2),
          ),
          child: const Icon(PhosphorIconsFill.userCircle, color: AppColors.sageGreen, size: 48),
        ),
        const SizedBox(height: 16),
        const Text(
          'Guard Post A',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Main Gate Security',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCallButton(
              icon: PhosphorIconsFill.phone,
              label: 'Call',
              color: AppColors.sageGreen,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Calling Guard Post A...'),
                    backgroundColor: AppColors.sageGreen,
                  ),
                );
              },
            ),
            _buildCallButton(
              icon: PhosphorIconsFill.videoCamera,
              label: 'Video',
              color: AppColors.deepSlate,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Opening video intercom...'),
                    backgroundColor: AppColors.deepSlate,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildGateControl() {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Column(
          key: const ValueKey('gate'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _currentView = 0),
                  child: const Icon(PhosphorIconsRegular.caretLeft, size: 24, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Gate Control',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.deepSlate.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.deepSlate.withOpacity(0.15), width: 2),
              ),
              child: const Icon(PhosphorIconsRegular.lockOpen, color: AppColors.deepSlate, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Main Entrance Gate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bluetooth / NFC unlock',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Gate unlocked successfully!'),
                      backgroundColor: AppColors.sageGreen,
                    ),
                  );
                },
                icon: const Icon(PhosphorIconsFill.lockOpen, size: 20),
                label: const Text('Unlock Gate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepSlate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  shadowColor: AppColors.deepSlate.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
