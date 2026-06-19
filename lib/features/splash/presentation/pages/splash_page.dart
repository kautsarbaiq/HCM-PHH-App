import 'package:flutter/material.dart';

/// Neutral loading screen shown on cold start while the app resolves whether a
/// session exists and, if so, which role it belongs to. The router redirect
/// holds here until that is known, then jumps straight to the right home — so
/// the user never sees the resident home flash by before a login bounce.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF4318FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'HCM',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B3674),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Housing Community Management',
              style: TextStyle(color: Color(0xFFA3AED0), fontSize: 13),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF4318FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
