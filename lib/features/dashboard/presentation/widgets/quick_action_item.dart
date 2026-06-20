import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';

class QuickActionItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<QuickActionItem> createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<QuickActionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Build a soft, vivid gradient from the passed-in [color] so each tile gets
  /// a premium gradient badge while keeping the caller's chosen accent colour.
  Gradient _badgeGradient() {
    final hsl = HSLColor.fromColor(widget.color);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.10).clamp(0.0, 1.0))
        .toColor();
    final deeper = hsl
        .withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0))
        .toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lighter, deeper],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          radius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GradientIconBadge(
                icon: widget.icon,
                gradient: _badgeGradient(),
                size: 52,
                iconSize: 24,
                radius: 16,
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
