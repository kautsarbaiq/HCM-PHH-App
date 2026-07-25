import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Bright, airy page background with a couple of soft colour "blobs" for depth.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showBlobs;

  const GradientBackground({super.key, required this.child, this.showBlobs = true});

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
                  child: _blob(220, AppColors.brand.withValues(alpha: 0.10)),
                ),
                Positioned(
                  top: 140,
                  left: -80,
                  child: _blob(200, AppColors.accentSky.withValues(alpha: 0.10)),
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
