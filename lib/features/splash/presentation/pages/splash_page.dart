import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/brand.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../theme/app_colors.dart';

/// Neutral, bright loading screen shown on cold start while the app resolves
/// whether a session exists and which role it belongs to. The router holds here
/// until that's known, then jumps straight to the right home — so the user
/// never sees the resident home flash before a login bounce.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Image.asset(Brand.logoAsset, fit: BoxFit.contain),
                  )
                  .animate()
                  .scale(
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                  )
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 26),
              const Text(
                Brand.appName,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 6),
              const Text(
                'Housing Community Management',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
              const SizedBox(height: 34),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.brand,
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
