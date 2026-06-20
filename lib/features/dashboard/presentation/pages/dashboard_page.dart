import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hcm_app/theme/app_colors.dart';
import '../../../../core/repositories/billing_repository.dart';
import '../../../../core/repositories/facility_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../main/presentation/pages/main_navigation_page.dart';
import '../../../access/presentation/widgets/smart_access_modal.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';
import '../widgets/quick_action_item.dart';

final dashboardOutstandingProvider = FutureProvider<List<Billing>>((ref) {
  return ref.read(billingRepositoryProvider).getMyBillings();
});

final dashboardBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];
  return ref.read(facilityRepositoryProvider).getMyBookings(uid);
});

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'RM ',
  decimalDigits: 0,
);

String _bookingDateLabel(String iso) {
  try {
    return DateFormat('EEE, MMM dd').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _activePage = 0;
  late final PageController _pageController;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildQuickActions(context),
            ),
            const SizedBox(height: 124),
          ],
        ),
      ),
    );
  }

  Widget _buildOutstandingBanner(BuildContext context) {
    final billsAsync = ref.watch(dashboardOutstandingProvider);

    return billsAsync.when(
      loading: () => _buildOutstandingShell(
        context,
        amountChild: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.deepSlate,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading…',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepSlate.withOpacity(0.6),
              ),
            ),
          ],
        ),
        secondaryChild: null,
      ),
      error: (_, __) => _buildOutstandingShell(
        context,
        amountChild: const Text(
          'Unavailable',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.deepSlate,
          ),
        ),
        secondaryChild: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Could not load your bills. Pull to refresh.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.error.withOpacity(0.9),
            ),
          ),
        ),
      ),
      data: (bills) {
        final unpaid = bills.where((b) => b.status != 'paid').toList();
        final total = unpaid.fold<double>(0, (sum, b) => sum + b.amount);
        return _buildOutstandingShell(
          context,
          amountChild: unpaid.isEmpty
              ? Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                )
              : Text(
                  _currency.format(total),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepSlate,
                    letterSpacing: -0.5,
                  ),
                ),
          secondaryChild: unpaid.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${unpaid.length} unpaid bill${unpaid.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOutstandingShell(
    BuildContext context, {
    required Widget amountChild,
    Widget? secondaryChild,
  }) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
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
                    color: AppColors.textSecondary.withOpacity(0.9),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: amountChild,
                ),
                if (secondaryChild != null) secondaryChild,
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/bills'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
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
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final avatarUrl = profile?.avatarUrl;
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
                        child: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? Image.network(
                                avatarUrl,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      PhosphorIconsRegular.user,
                                      color: AppColors.primaryBlue,
                                    ),
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                PhosphorIconsRegular.user,
                                color: AppColors.primaryBlue,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (profile?.fullName.isNotEmpty ?? false)
                            ? profile!.fullName
                            : 'Resident',
                        style: const TextStyle(
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
                      child: const Icon(
                        PhosphorIconsRegular.houseLine,
                        size: 20,
                        color: AppColors.deepSlate,
                      ),
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
                color: AppColors.surfaceTint,
                border: Border.all(
                  color: AppColors.brand.withOpacity(0.10),
                  width: 1,
                ),
              ),
              child: const Icon(
                PhosphorIconsRegular.list,
                color: AppColors.brand,
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
        const SectionHeader(
          title: 'Quick Actions',
        ).animate().fade(duration: 400.ms),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.bellSimpleRinging,
                label: 'Emergency',
                color: AppColors.accentCoral,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const EmergencyBottomSheet(),
                  );
                },
              ),
            ),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.identificationCard,
                label: 'Visitor Pass',
                color: AppColors.brand,
                onTap: () => context.go('/access'),
              ),
            ),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.wallet,
                label: 'Bills & Pay',
                color: AppColors.accentSky,
                onTap: () => context.go('/bills'),
              ),
            ),
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 16),
        Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: QuickActionItem(
                    icon: PhosphorIconsFill.phoneCall,
                    label: 'Intercom',
                    color: AppColors.accentSky,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            const SmartAccessModal(initialView: 1),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: QuickActionItem(
                    icon: PhosphorIconsFill.shieldCheck,
                    label: 'Smart Lock',
                    color: AppColors.brandViolet,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            const SmartAccessModal(initialView: 2),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: QuickActionItem(
                    icon: PhosphorIconsFill.calendarCheck,
                    label: 'Bookings',
                    color: AppColors.accentAmber,
                    onTap: () => context.push('/facility'),
                  ),
                ),
              ],
            )
            .animate()
            .fade(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bookingsAsync = ref.watch(dashboardBookingsProvider);
    final bookings = bookingsAsync.valueOrNull ?? <Booking>[];
    final isLoadingBookings =
        bookingsAsync.isLoading && !bookingsAsync.hasValue;

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
          padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 24),
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Beautiful Cityscape Skyline Silhouette
              // 🌳 Tree 1 (Large) positioned perfectly on the left part of the wave
              Positioned(
                bottom: -8,
                right: 160,
                child: Opacity(
                  opacity: 0.16,
                  child: const Icon(
                    PhosphorIconsFill.tree,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              // 🌳 Tree 2 (Medium) positioned in the middle-left, sitting perfectly on the wave curve
              Positioned(
                bottom: 4,
                right: 110,
                child: Opacity(
                  opacity: 0.16,
                  child: const Icon(
                    PhosphorIconsFill.tree,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),

              // 🏢 Buildings (Apartment) positioned further down on the far right dipping part of the wave
              Positioned(
                bottom: -20,
                right: -4,
                child: Opacity(
                  opacity: 0.16,
                  child: const Icon(
                    PhosphorIconsFill.building,
                    size: 92,
                    color: Colors.white,
                  ),
                ),
              ),

              // Main content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // Slider container — upcoming facility bookings
                  SizedBox(
                    height: 140,
                    child: isLoadingBookings
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEE, MMM dd',
                                    ).format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                  Icon(
                                    PhosphorIconsFill.calendar,
                                    size: 20,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          )
                        : bookings.isEmpty
                        ? GestureDetector(
                            onTap: () => context.push('/facility'),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'EEE, MMM dd',
                                      ).format(DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                    Icon(
                                      PhosphorIconsFill.calendar,
                                      size: 20,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Expanded(
                                  child: Text(
                                    'No upcoming bookings. Tap to book a facility 📅',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) =>
                                setState(() => _activePage = index),
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final b = bookings[index];
                              return GestureDetector(
                                onTap: () => context.push('/facility'),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _bookingDateLabel(b.date),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          PhosphorIconsFill.calendarCheck,
                                          size: 20,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            height: 1.4,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Your '),
                                            TextSpan(
                                              text: b.facilityName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: ' booking is at ',
                                            ),
                                            TextSpan(
                                              text: b.time,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: '. See you there! 🎉',
                                            ),
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
                  if (bookings.length > 1)
                    Row(
                      children: List.generate(bookings.length, (index) {
                        final isActive = index == _activePage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 4),
                          width: isActive ? 24 : 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              isActive ? 0.9 : 0.4,
                            ),
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
