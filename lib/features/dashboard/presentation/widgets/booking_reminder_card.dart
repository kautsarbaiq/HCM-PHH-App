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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ClipPath(
          clipper: WaveClipper(),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE3F3FD), // Very light soft sky blue
                  Color(0xFFCBE7FC), // Soft pastel blue
                  Color(0xFFAFDDFC), // Slightly deeper soft blue at bottom right
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bottom-right decorative illustration icons (trees, bicycle, buildings)
                Positioned(
                  bottom: -15,
                  right: -10,
                  child: Opacity(
                    opacity: 0.08,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Icon(PhosphorIconsRegular.tree, size: 28, color: AppColors.deepSlate),
                        SizedBox(width: 4),
                        Icon(PhosphorIconsRegular.bicycle, size: 24, color: AppColors.deepSlate),
                        SizedBox(width: 4),
                        Icon(PhosphorIconsRegular.buildings, size: 36, color: AppColors.deepSlate),
                      ],
                    ),
                  ),
                ),
                
                // Main Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentTime,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepSlate.withOpacity(0.7),
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
                          color: AppColors.deepSlate,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Your '),
                          TextSpan(
                            text: 'gym booking',
                            style: TextStyle(
                              color: const Color(0xFF005682), // Deep blue/teal
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFF005682).withOpacity(0.3),
                            ),
                          ),
                          const TextSpan(text: ' is at '),
                          const TextSpan(
                            text: '7:00 PM today',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepSlate,
                            ),
                          ),
                          const TextSpan(text: '. Don\'t miss your session 💪'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Slider indicators at the bottom left
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.deepSlate.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.deepSlate.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.deepSlate.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.deepSlate.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    
    // Wave dipping down on the left
    final firstControlPoint = Offset(size.width * 0.25, size.height - 6);
    final firstEndPoint = Offset(size.width * 0.45, size.height - 24);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    // Wave rising up towards the right and dipping down at the right edge
    final secondControlPoint = Offset(size.width * 0.70, size.height - 54);
    final secondEndPoint = Offset(size.width, size.height - 12);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
