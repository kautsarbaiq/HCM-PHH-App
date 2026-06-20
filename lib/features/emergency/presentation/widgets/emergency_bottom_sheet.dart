import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/repositories/emergency_repository.dart';
import '../../../../core/repositories/profile_repository.dart';

class EmergencyBottomSheet extends ConsumerStatefulWidget {
  const EmergencyBottomSheet({super.key});

  @override
  ConsumerState<EmergencyBottomSheet> createState() =>
      _EmergencyBottomSheetState();
}

class _EmergencyBottomSheetState extends ConsumerState<EmergencyBottomSheet> {
  String? _sendingType;

  bool get _isSending => _sendingType != null;

  Future<void> _trigger({
    required String type,
    required String title,
    required String subtitle,
    required Color color,
  }) async {
    if (_isSending) return;
    setState(() => _sendingType = type);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) {
        throw Exception('You must be logged in to send an emergency alert.');
      }

      final alert = EmergencyAlert(
        id: '',
        type: type,
        title: title,
        subtitle: subtitle,
        triggeredBy: profile.id,
        status: 'Active',
        createdAt: '',
      );
      await ref.read(emergencyRepositoryProvider).triggerAlert(alert);

      // Only confirm success once the alert is actually persisted.
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$title activated! Guards alerted.'),
          backgroundColor: color,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingType = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not send alert. Please try again. ($e)'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

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
              top: BorderSide(
                color: AppColors.primaryWhite.withOpacity(0.5),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsFill.warning,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Emergency Options',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select an action to alert authorities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildEmergencyAction(
                    type: 'panic',
                    icon: PhosphorIconsFill.siren,
                    title: 'Panic Button',
                    subtitle: 'Instantly alert all security guards',
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyAction(
                    type: 'community',
                    icon: PhosphorIconsFill.megaphone,
                    title: 'Community Emergency',
                    subtitle: 'Trigger building evacuation notice',
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyAction(
                    type: 'rollcall',
                    icon: PhosphorIconsFill.usersThree,
                    title: 'Emergency Roll Call',
                    subtitle: 'Verify all residents are accounted for',
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _buildEmergencyAction(
                    type: 'contact',
                    icon: PhosphorIconsFill.phone,
                    title: 'Emergency Contacts',
                    subtitle: 'Call fire, police, or medical services',
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyAction({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final bool isThisSending = _sendingType == type;
    // While any action is in flight, all actions are disabled to prevent
    // duplicate alerts from a panicking user tapping repeatedly.
    final bool disabled = _isSending;

    return GestureDetector(
      onTap: disabled
          ? null
          : () => _trigger(
              type: type,
              title: title,
              subtitle: subtitle,
              color: color,
            ),
      child: Opacity(
        opacity: disabled && !isThisSending ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isThisSending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      PhosphorIconsRegular.caretRight,
                      color: color,
                      size: 18,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
