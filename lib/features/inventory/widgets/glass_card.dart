import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Frosted-glass surface used for cards and tiles across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final double blurAmount;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.opacity = 0.65,
    this.blurAmount = 18.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.primaryWhite.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.glassBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(18.0),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}
