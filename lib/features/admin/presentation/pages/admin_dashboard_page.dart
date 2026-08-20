import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/brand.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../emergency/presentation/widgets/active_emergency_banner.dart';
import '../../../emergency/presentation/widgets/emergency_broadcast_sheet.dart';
import '../widgets/admin_attention_feed.dart';
import '../widgets/dashboard_analytics.dart';

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

/// Boss 19/08: the dashboard is split into two tabs so the admin can jump
/// straight to the priority list instead of scrolling past the charts.
enum _DashTab { dashboard, tasks }

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  _DashTab _tab = _DashTab.dashboard;

  @override
  Widget build(BuildContext context) {
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
          // Boss 19/08: the big welcome card was taking the space that the
          // priority task list should own. Reduced to a slim strip that keeps
          // the emergency broadcast (buzzer) prominent and nothing else.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Brand.appName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                // The buzzer stays big — it is the one urgent action here.
                Tooltip(
                  message: 'Broadcast emergency alert',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const EmergencyBroadcastSheet(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_rounded,
                              color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Broadcast',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => ref.invalidate(adminDashboardStatsProvider),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 20),
                  tooltip: 'Refresh stats',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TabSwitch(
            tab: _tab,
            onChanged: (t) => setState(() => _tab = t),
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
          if (_tab == _DashTab.dashboard) ...[
          const SizedBox(height: 28),
          SectionHeader(
            title: ref.tr('adash.overview'),
            subtitle: ref.tr('adash.overviewSub'),
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
                    ref.tr('adash.totalResidents'),
                    fmt(stats?.residents),
                    Icons.people_rounded,
                    AppColors.brandGradient,
                  ),
                  _buildStatCard(
                    cardWidth,
                    ref.tr('adash.totalHouses'),
                    fmt(stats?.houses),
                    Icons.house_rounded,
                    AppColors.skyGradient,
                  ),
                  _buildStatCard(
                    cardWidth,
                    ref.tr('adash.activeBillings'),
                    fmt(stats?.activeBillings),
                    Icons.receipt_long_rounded,
                    AppColors.sunsetGradient,
                  ),
                  _buildStatCard(
                    cardWidth,
                    ref.tr('adash.todayVisitors'),
                    fmt(stats?.todayVisitors),
                    Icons.badge_rounded,
                    AppColors.mintGradient,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
          // Analytics block (boss batch 08/08 point 14): KPI counts, monthly
          // collection vs average, payment-method split and visitor flow.
          const SectionHeader(
            title: 'Analytics',
            subtitle: 'Collections, billing and visitor flow',
          ),
          const SizedBox(height: 18),
          const DashboardAnalytics(),
          ] else ...[
            // Tasks tab — the approvals and reviews the admin must act on.
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Needs Your Attention',
              subtitle: 'Approvals and reviews waiting for you',
            ),
            const SizedBox(height: 18),
            const AdminAttentionFeed(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Boss 18/08: the counts are the first thing on the portal, so they carry
  /// the design — a tinted accent band behind a gradient icon tile, the number
  /// as the loudest element, and the label above it.
  Widget _buildStatCard(
    double width,
    String title,
    String value,
    IconData icon,
    Gradient gradient,
  ) {
    final accent = gradient.colors.first;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Soft colour wash so each metric is identifiable at a glance.
            Positioned(
              right: -26,
              top: -26,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ],
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

/// DASHBOARD | TASKS switch shown at the top of the admin dashboard
/// (boss 19/08).
class _TabSwitch extends StatelessWidget {
  final _DashTab tab;
  final ValueChanged<_DashTab> onChanged;
  const _TabSwitch({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E9F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(Icons.dashboard_rounded, 'DASHBOARD', _DashTab.dashboard),
          _seg(Icons.task_alt_rounded, 'TASKS', _DashTab.tasks),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, String label, _DashTab value) {
    final active = tab == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF6A7BA8).withValues(alpha: 0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? AppColors.brand : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: active ? AppColors.brand : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
