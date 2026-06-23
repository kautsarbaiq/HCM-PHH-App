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
import '../../../../l10n/app_strings.dart';
import '../../../main/presentation/pages/main_navigation_page.dart';
import '../../../emergency/presentation/widgets/emergency_bottom_sheet.dart';
import '../../../emergency/presentation/widgets/active_emergency_banner.dart';
import '../widgets/quick_action_item.dart';
import '../widgets/home_banner_carousel.dart';

// autoDispose so a previous account's bills/bookings/announcements aren't shown
// to the next user after a logout→login on the same device.
final dashboardOutstandingProvider = FutureProvider.autoDispose<List<Billing>>((
  ref,
) {
  return ref.read(billingRepositoryProvider).getMyBillings();
});

final dashboardBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
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
              ref.invalidate(homeBannersProvider);
              ref.invalidate(homeAnnouncementsProvider);
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
                const SizedBox(height: 18),
                // Live emergency broadcasts (from admin/guard) appear here.
                const ActiveEmergencyBanner(),
                _hero(context, ref)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.10, end: 0),
                const SizedBox(height: 16),
                const HomeBannerCarousel(),
                _upcoming(
                  context,
                  ref,
                ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
                const SizedBox(height: 28),
                _quickActions(
                  context,
                  ref,
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
              Text(
                ref.tr('dash.welcomeBack'),
                style: const TextStyle(
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                top: -28,
                right: -20,
                child: _circle(96, Colors.white.withOpacity(0.12)),
              ),
              Positioned(
                bottom: -40,
                right: 34,
                child: _circle(84, Colors.white.withOpacity(0.08)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            PhosphorIconsFill.wallet,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          cleared
                              ? ref.tr('dash.accountStatus')
                              : ref.tr('dash.outstanding'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: amount,
                    ),
                    if (sub != null) ...[const SizedBox(height: 4), sub],
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => context.go('/bills'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cleared
                                  ? ref.tr('dash.viewInvoices')
                                  : ref.tr('dash.payNow'),
                              style: const TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              PhosphorIconsBold.arrowRight,
                              color: AppColors.brand,
                              size: 14,
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      error: (_, __) => shell(
        amount: const Text(
          'Unavailable',
          style: TextStyle(
            fontSize: 20,
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
            amount: Text(
              ref.tr('dash.allCleared'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8,
              ),
            ),
            sub: Text(
              ref.tr('dash.paidUp'),
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
              fontSize: 29,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.tr('dash.noBookings'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ref.tr('dash.tapToBook'),
                    style: const TextStyle(
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
  Widget _quickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: ref.tr('dash.quickActions'),
          subtitle: ref.tr('dash.quickActionsSub'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.bellSimpleRinging,
                label: ref.tr('dash.emergency'),
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
                label: ref.tr('dash.visitorPass'),
                color: AppColors.brand,
                onTap: () => context.go('/access'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.wallet,
                label: ref.tr('dash.billsPay'),
                color: AppColors.accentSky,
                onTap: () => context.go('/bills'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionItem(
                icon: PhosphorIconsFill.calendarCheck,
                label: ref.tr('dash.bookings'),
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
