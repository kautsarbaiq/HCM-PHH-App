import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';

import 'package:hcm_app/theme/app_colors.dart';
import '../../../main/presentation/pages/main_navigation_page.dart';
import '../../../access/presentation/widgets/smart_access_modal.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';
import '../widgets/quick_action_item.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _activePage = 0;
  late final PageController _pageController;

  final List<Map<String, dynamic>> _bookings = [
    {
      'type': 'gym booking',
      'time': '7:00 PM today',
      'icon': PhosphorIconsFill.sun,
      'iconColor': Colors.orangeAccent,
      'emoji': '💪',
      'phrase': 'Don\'t miss your session',
      'route': '/facility',
    },
    {
      'type': 'swimming booking',
      'time': '9:00 AM tomorrow',
      'icon': PhosphorIconsFill.drop,
      'iconColor': Colors.blueAccent,
      'emoji': '🏊',
      'phrase': 'Ready for a refreshing splash?',
      'route': '/facility',
    },
    {
      'type': 'tennis booking',
      'time': '4:30 PM this Friday',
      'icon': PhosphorIconsFill.calendar,
      'iconColor': Colors.green,
      'emoji': '🎾',
      'phrase': 'Challenge your neighbor!',
      'route': '/facility',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: _buildOutstandingBanner(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _buildQuickActions(context),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F3FD), // Soft baby sky blue
            Color(0xFFFEF9C3), // Soft pale golden yellow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Outstanding',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withOpacity(0.8),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF10B981), // Vibrant modern emerald green
                            Color(0xFF059669), // Premium forest green
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          PhosphorIconsBold.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'All Cleared!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepSlate,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/bills'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'View Invoice',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Inner Pill for Profile & Name
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryWhite,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&h=150&q=80',
                          errorBuilder: (context, error, stackTrace) => const Icon(PhosphorIconsRegular.user, color: AppColors.sageGreen),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Alex Morgan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsRegular.houseLine, size: 20, color: AppColors.deepSlate),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Menu Button (replacing the QR in the image)
          GestureDetector(
            onTap: () => mainScaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundGrey.withOpacity(0.5),
                border: Border.all(
                  color: Colors.black.withOpacity(0.03),
                  width: 1,
                ),
              ),
              child: const Icon(
                PhosphorIconsRegular.list,
                color: AppColors.deepSlate,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)).animate().fade(duration: 400.ms),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: PhosphorIconsRegular.warningCircle,
              label: 'Panic\nButton',
              color: AppColors.error,
              onTap: () {
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (context) => const EmergencyBottomSheet());
              },
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.qrCode,
              label: 'Visitor\nAccess',
              color: AppColors.sageGreen,
              onTap: () => context.go('/access'),
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.receipt,
              label: 'Pay\nBills',
              color: AppColors.deepSlate,
              onTap: () => context.go('/bills'),
            ),
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: PhosphorIconsRegular.phone,
              label: 'Mobile\nIntercom',
              color: const Color(0xFF3B82F6),
              onTap: () {
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (context) => const SmartAccessModal());
              },
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.lockOpen,
              label: 'Access\nControl',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (context) => const SmartAccessModal());
              },
            ),
            QuickActionItem(
              icon: PhosphorIconsRegular.buildings,
              label: 'Book\nFacility',
              color: const Color(0xFFF59E0B),
              onTap: () => context.push('/facility'),
            ),
          ],
        ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipPath(
        clipper: TopHeaderWaveClipper(),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 40),
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
              // Beautiful Cityscape Skyline Silhouette
              // 🌳 Tree 1 (Large) positioned perfectly on the left part of the wave
              Positioned(
                bottom: -8,
                right: 160,
                child: Opacity(
                  opacity: 0.08,
                  child: const Icon(
                    PhosphorIconsFill.tree,
                    size: 48,
                    color: AppColors.deepSlate,
                  ),
                ),
              ),
              
              // 🌳 Tree 2 (Medium) positioned in the middle-left, sitting perfectly on the wave curve
              Positioned(
                bottom: 4,
                right: 110,
                child: Opacity(
                  opacity: 0.08,
                  child: const Icon(
                    PhosphorIconsFill.tree,
                    size: 38,
                    color: AppColors.deepSlate,
                  ),
                ),
              ),
              
              // 🏢 Buildings (Apartment) positioned further down on the far right dipping part of the wave
              Positioned(
                bottom: -20,
                right: -4,
                child: Opacity(
                  opacity: 0.08,
                  child: const Icon(
                    PhosphorIconsFill.building,
                    size: 92,
                    color: AppColors.deepSlate,
                  ),
                ),
              ),
              
              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  
                  // Slider container
                  SizedBox(
                    height: 155,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _activePage = index;
                        });
                      },
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        final String currentTime = DateFormat('hh:mm a').format(DateTime.now());
                        
                        return GestureDetector(
                          onTap: () => context.push(booking['route']),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
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
                                  Icon(
                                    booking['icon'],
                                    size: 20,
                                    color: booking['iconColor'],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: RichText(
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
                                        text: booking['type'],
                                        style: const TextStyle(
                                          color: Color(0xFF005682), // Deep blue/teal
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: ' is at '),
                                      TextSpan(
                                        text: booking['time'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.deepSlate,
                                        ),
                                      ),
                                      TextSpan(text: '. ${booking['phrase']} ${booking['emoji']}'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Slider indicators at the bottom left with micro-animations
                  Row(
                    children: List.generate(_bookings.length, (index) {
                      final isActive = index == _activePage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 4),
                        width: isActive ? 24 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.deepSlate.withOpacity(isActive ? 0.3 : 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class TopHeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 32);
    
    // Wave dipping down on the left
    final firstControlPoint = Offset(size.width * 0.25, size.height - 8);
    final firstEndPoint = Offset(size.width * 0.48, size.height - 32);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    // Wave rising up towards the right and dipping down at the right edge
    final secondControlPoint = Offset(size.width * 0.73, size.height - 72);
    final secondEndPoint = Offset(size.width, size.height - 16);
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
