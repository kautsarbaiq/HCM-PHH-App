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
import '../../../../core/widgets/gradient_background.dart';
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

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async {
              ref.invalidate(dashboardOutstandingProvider);
              ref.invalidate(dashboardBookingsProvider);
              ref.invalidate(currentProfileProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
              children: [
                _greeting(context, ref)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: -0.12, end: 0),
                const SizedBox(height: 22),
                _hero(context, ref)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.10, end: 0),
                const SizedBox(height: 16),
                _upcoming(
                  context,
                  ref,
                ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                const SizedBox(height: 28),
                _quickActions(
                  context,
                ).animate().fadeIn(duration: 400.ms, delay: 140.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Greeting row -------------------------------------------------------
  Widget _greeting(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final avatarUrl = profile?.avatarUrl;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'Resident';

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          PhosphorIconsFill.user,
                          color: AppColors.brand,
                          size: 22,
                        ),
                      )
                    : const Icon(
                        PhosphorIconsFill.user,
                        color: AppColors.brand,
                        size: 22,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _circleButton(
          icon: PhosphorIconsRegular.list,
          onTap: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  // ---- Hero "outstanding" card -------------------------------------------
  Widget _hero(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(dashboardOutstandingProvider);

    Widget shell({required Widget amount, Widget? sub, bool cleared = false}) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.38),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: -34,
                right: -24,
                child: _circle(120, Colors.white.withOpacity(0.12)),
              ),
              Positioned(
                bottom: -50,
                right: 40,
                child: _circle(110, Colors.white.withOpacity(0.08)),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            PhosphorIconsFill.wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          cleared ? 'Account status' : 'Your outstanding',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: amount,
                    ),
                    if (sub != null) ...[const SizedBox(height: 6), sub],
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.go('/bills'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cleared ? 'View invoices' : 'Pay now',
                              style: const TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              PhosphorIconsBold.arrowRight,
                              color: AppColors.brand,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return billsAsync.when(
      loading: () => shell(
        amount: const Text(
          'Loading…',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      error: (_, __) => shell(
        amount: const Text(
          'Unavailable',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        sub: Text(
          'Pull down to refresh.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      data: (bills) {
        final unpaid = bills.where((b) => b.status != 'paid').toList();
        final total = unpaid.fold<double>(0, (s, b) => s + b.amount);
        if (unpaid.isEmpty) {
          return shell(
            cleared: true,
            amount: const Text(
              'All cleared',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
            sub: Text(
              "You're all paid up 🎉",
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return shell(
          amount: Text(
            _currency.format(total),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          sub: Text(
            '${unpaid.length} unpaid bill${unpaid.length > 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ---- Upcoming booking ---------------------------------------------------
  Widget _upcoming(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(dashboardBookingsProvider);
    final bookings = bookingsAsync.valueOrNull ?? <Booking>[];
    final loading = bookingsAsync.isLoading && !bookingsAsync.hasValue;

    Widget card(Widget child) => GestureDetector(
      onTap: () => context.push('/facility'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
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
        child: child,
      ),
    );

    Widget badge() => Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: AppColors.sunsetGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentAmber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        PhosphorIconsFill.calendarCheck,
        color: Colors.white,
        size: 22,
      ),
    );

    if (loading) {
      return card(
        Row(
          children: [
            badge(),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Loading bookings…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (bookings.isEmpty) {
      return card(
        Row(
          children: [
            badge(),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No upcoming bookings',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to book a facility',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIconsBold.arrowRight,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      );
    }
    final b = bookings.first;
    return card(
      Row(
        children: [
          badge(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.facilityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (bookings.length > 1)
                      Text(
                        '+${bookings.length - 1} more',
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_bookingDateLabel(b.date)} · ${b.time}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Quick actions ------------------------------------------------------
  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Quick Actions',
          subtitle: 'Everything one tap away',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.bellSimpleRinging,
                label: 'Emergency',
                color: AppColors.accentCoral,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const EmergencyBottomSheet(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.identificationCard,
                label: 'Visitor Pass',
                color: AppColors.brand,
                onTap: () => context.go('/access'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.wallet,
                label: 'Bills & Pay',
                color: AppColors.accentSky,
                onTap: () => context.go('/bills'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.phoneCall,
                label: 'Intercom',
                color: AppColors.accentCyan,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const SmartAccessModal(initialView: 1),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.shieldCheck,
                label: 'Smart Lock',
                color: AppColors.brandViolet,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const SmartAccessModal(initialView: 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.calendarCheck,
                label: 'Bookings',
                color: AppColors.accentAmber,
                onTap: () => context.push('/facility'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
