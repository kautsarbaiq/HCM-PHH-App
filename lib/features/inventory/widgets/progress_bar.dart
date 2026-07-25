import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Thin rounded progress bar used on PO / pick cards.
class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.brand,
    this.height = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.surfaceTint,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
