import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import 'package:intl/intl.dart';

class BookingReminderCard extends StatelessWidget {
  const BookingReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentTime = DateFormat('hh:mm a').format(DateTime.now());

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      opacity: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTime,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Icon(
                PhosphorIconsFill.sun,
                size: 20,
                color: Colors.orangeAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'Your '),
                TextSpan(
                  text: 'gym booking',
                  style: TextStyle(
                    color: AppColors.sageGreen,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.sageGreen.withOpacity(0.3),
                  ),
                ),
                const TextSpan(text: ' is at '),
                const TextSpan(
                  text: '7:00 PM today',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '. Don\'t miss your session 💪'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
