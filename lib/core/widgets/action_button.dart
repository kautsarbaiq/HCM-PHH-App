import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double width;
  final double height;
  final double borderRadius;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.backgroundColor,
    this.foregroundColor,
    this.width = double.infinity,
    this.height = 56.0,
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isPrimary ? AppColors.deepSlate : AppColors.primaryWhite);
    final fgColor = foregroundColor ?? (isPrimary ? AppColors.primaryWhite : AppColors.deepSlate);
    final borderSide = isPrimary
        ? BorderSide.none
        : const BorderSide(color: AppColors.deepSlate, width: 1.5);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: isPrimary ? 4 : 0,
          shadowColor: AppColors.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: borderSide,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
