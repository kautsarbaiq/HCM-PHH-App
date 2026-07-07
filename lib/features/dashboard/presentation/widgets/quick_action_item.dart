import 'package:flutter/material.dart';
import '../../../../core/config/brand.dart';
import '../../../../theme/app_colors.dart';

/// Quick-action tile, themed per brand:
///  - PHH: the original vivid gradient icon badge on a white card.
///  - HCA: duotone icon (soft accent fill behind a navy outline) — the
///    "outlined sticker" style, no colored badge.
class QuickActionItem extends StatefulWidget {
  final IconData icon;

  /// Outline (Regular) variant of [icon]; used for the HCA duotone style.
  /// Falls back to [icon] alone when not provided.
  final IconData? outlineIcon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    super.key,
    required this.icon,
    this.outlineIcon,
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
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// PHH: vivid gradient badge with a white icon (original style).
  Widget _gradientBadge() {
    final c = widget.color;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c, Color.lerp(c, Colors.black, 0.20)!],
    );
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.32),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(widget.icon, color: Colors.white, size: 25),
    );
  }

  /// HCA: duotone icon — the Fill glyph in a soft accent tint sits behind the
  /// Regular (outline) glyph in navy. No badge box.
  Widget _duotoneIcon() {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(3, 3),
            child: Icon(widget.icon, color: AppColors.duotoneFill, size: 40),
          ),
          Icon(
            widget.outlineIcon ?? widget.icon,
            color: AppColors.deepSlate,
            size: 40,
          ),
        ],
      ),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A7BA8).withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child: Brand.isPhh ? _gradientBadge() : _duotoneIcon(),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
