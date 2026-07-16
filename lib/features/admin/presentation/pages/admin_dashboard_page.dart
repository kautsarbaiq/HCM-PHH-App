import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/brand.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../emergency/presentation/widgets/active_emergency_banner.dart';
import '../../../emergency/presentation/widgets/emergency_broadcast_sheet.dart';
import '../widgets/admin_attention_feed.dart';

typedef DashboardStats = ({
  int residents,
  int houses,
  int activeBillings,
  int todayVisitors,
});

final adminDashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  final startOfDay = DateTime(
    now.year,
    now.month,
    now.day,
  ).toUtc().toIso8601String();

  final residents = await supabase
      .from('profiles')
      .count(CountOption.exact)
      .eq('role', 'resident');
  final houses = await supabase.from('houses').count(CountOption.exact);
  // "Active" = anything not settled yet (covers unpaid AND overdue).
  final activeBillings = await supabase
      .from('billings')
      .count(CountOption.exact)
      .neq('status', 'paid');
  final todayVisitors = await supabase
      .from('visitors')
      .count(CountOption.exact)
      .gte('created_at', startOfDay);

  return (
    residents: residents,
    houses: houses,
    activeBillings: activeBillings,
    todayVisitors: todayVisitors,
  );
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final isLoading = statsAsync.isLoading;
    final hasError = statsAsync.hasError;

    String fmt(int? n) {
      if (hasError) return '—';
      if (n == null) return '…';
      return NumberFormat.decimalPattern().format(n);
    }

    return SingleChildScrollView(
      // Full-width dashboard reaching the right edge on web.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live emergency feed (resident panic alerts + broadcasts). Admin can
          // resolve. Renders nothing when there are no active emergencies.
          const ActiveEmergencyBanner(canResolve: true),
          // Hero welcome banner — brand gradient with a logo badge.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withOpacity(0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: EdgeInsets.all(Brand.isPhh ? 0 : 6),
                  decoration: BoxDecoration(
                    color: Brand.isPhh
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Brand.isPhh
                      ? const Icon(
                          Icons.holiday_village_rounded,
                          color: Colors.white,
                          size: 30,
                        )
                      : Image.asset(Brand.logoAsset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to ${Brand.appName}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Here is an overview of the community.',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const EmergencyBroadcastSheet(),
                  ),
                  icon: const Icon(Icons.campaign_rounded, color: Colors.white),
                  tooltip: 'Broadcast emergency alert',
                ),
                IconButton(
                  onPressed: () => ref.invalidate(adminDashboardStatsProvider),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Could not load stats: ${statsAsync.error}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Overview',
            subtitle: 'Key community metrics at a glance',
          ),
          const SizedBox(height: 18),
          // Dashboard Cards — balanced multi-column grid that fills the row
          // on wide laptops and stacks down to one/two-up on phones.
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 18.0;
              final maxW = constraints.maxWidth;
              // Columns scale with width; cards share the row evenly so they
              // neither stretch too wide nor leave large empty gaps.
              int columns;
              if (maxW < 360) {
                columns = 1;
              } else if (maxW < 720) {
                columns = 2;
              } else {
                columns = 4;
              }
              final cardWidth = (maxW - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildStatCard(
                    cardWidth,
                    'Total Residents',
                    fmt(stats?.residents),
                    Icons.people_rounded,
                    AppColors.brandGradient,
                  ),
                  _buildStatCard(
                    cardWidth,
                    'Total Houses',
                    fmt(stats?.houses),
                    Icons.house_rounded,
                    AppColors.skyGradient,
                  ),
                  _buildStatCard(
                    cardWidth,
                    'Active Billings',
                    fmt(stats?.activeBillings),
                    Icons.receipt_long_rounded,
                    AppColors.sunsetGradient,
                  ),
                  _buildStatCard(
                    cardWidth,
                    'Today Visitors',
                    fmt(stats?.todayVisitors),
                    Icons.badge_rounded,
                    AppColors.mintGradient,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
          // HCA (boss 16/07): a real "needs your attention" feed — pending
          // signups (approve/reject in-app), event proposals, bookings and
          // form submissions waiting for review. PHH keeps the placeholder.
          if (Brand.isPhh) ...[
            const SectionHeader(
              title: 'Recent Activities',
              subtitle: 'Latest community updates',
            ),
            const SizedBox(height: 18),
            PremiumCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.history_rounded,
                    gradient: AppColors.brandGradient,
                    size: 50,
                    iconSize: 24,
                    radius: 16,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No recent activities',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New activity will appear here.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SectionHeader(
              title: 'Needs Your Attention',
              subtitle: 'Approvals and reviews waiting for you',
            ),
            const SizedBox(height: 18),
            const AdminAttentionFeed(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    double width,
    String title,
    String value,
    IconData icon,
    Gradient gradient,
  ) {
    return SizedBox(
      width: width,
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            GradientIconBadge(
              icon: icon,
              gradient: gradient,
              size: 52,
              iconSize: 26,
              radius: 16,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
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
}
