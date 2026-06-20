import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Wraps content in a bright, subtle page-background wash plus a couple of soft
/// colour "blobs" for depth — giving the whole app an airy, premium canvas
/// without any dark surfaces. Cheap to render (no blur, const gradients).
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showBlobs;

  const GradientBackground({
    super.key,
    required this.child,
    this.showBlobs = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.canvasGradient),
      child: showBlobs
          ? Stack(
              children: [
                Positioned(
                  top: -90,
                  right: -60,
                  child: _blob(220, AppColors.brand.withOpacity(0.10)),
                ),
                Positioned(
                  top: 120,
                  left: -80,
                  child: _blob(200, AppColors.accentSky.withOpacity(0.10)),
                ),
                child,
              ],
            )
          : child,
    );
  }

  Widget _blob(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
