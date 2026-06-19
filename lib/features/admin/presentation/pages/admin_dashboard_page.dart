import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef DashboardStats = ({int residents, int houses, int activeBillings, int todayVisitors});

final adminDashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

  final residents = await supabase.from('profiles').count(CountOption.exact).eq('role', 'resident');
  final houses = await supabase.from('houses').count(CountOption.exact);
  final activeBillings = await supabase.from('billings').count(CountOption.exact).eq('status', 'unpaid');
  final todayVisitors = await supabase.from('visitors').count(CountOption.exact).gte('created_at', startOfDay);

  return (residents: residents, houses: houses, activeBillings: activeBillings, todayVisitors: todayVisitors);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Welcome to PHH housing Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(adminDashboardStatsProvider),
                icon: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh, color: Color(0xFF4318FF)),
                tooltip: 'Refresh stats',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Here is an overview of the community.',
            style: TextStyle(fontSize: 16, color: Color(0xFFA3AED0)),
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            Text('Could not load stats: ${statsAsync.error}', style: const TextStyle(color: Color(0xFFEE5D50), fontSize: 13)),
          ],
          const SizedBox(height: 32),
          // Dashboard Cards — size to the available width so they fit phones.
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 24.0;
              final maxW = constraints.maxWidth;
              // One per row on narrow phones, two-up on mid widths, else flow.
              double cardWidth;
              if (maxW < 360) {
                cardWidth = maxW;
              } else if (maxW < 720) {
                cardWidth = (maxW - spacing) / 2;
              } else {
                cardWidth = 260;
              }
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildStatCard(cardWidth, 'Total Residents', fmt(stats?.residents), Icons.people_rounded, const Color(0xFF4318FF)),
                  _buildStatCard(cardWidth, 'Total Houses', fmt(stats?.houses), Icons.house_rounded, const Color(0xFF00B5D8)),
                  _buildStatCard(cardWidth, 'Active Billings', fmt(stats?.activeBillings), Icons.receipt_long_rounded, const Color(0xFFFFB547)),
                  _buildStatCard(cardWidth, 'Today Visitors', fmt(stats?.todayVisitors), Icons.badge_rounded, const Color(0xFF05CD99)),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          // Placeholder for charts or recent activities
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                ),
                SizedBox(height: 16),
                Text('No recent activities to show.', style: TextStyle(color: Color(0xFFA3AED0))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(double width, String title, String value, IconData icon, Color iconColor) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E5F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Color(0xFF2B3674), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
