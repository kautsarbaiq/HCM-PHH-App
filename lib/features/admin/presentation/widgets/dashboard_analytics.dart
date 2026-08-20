import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/analytics_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';

/// Analytics block on the admin dashboard (boss batch 08/08 point 14),
/// modelled on the reference dashboard: a KPI row, monthly collection with an
/// average line, a payment-method breakdown, and visitor flow QR vs walk-in.
class DashboardAnalytics extends ConsumerWidget {
  const DashboardAnalytics({super.key});

  static final _money = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardDataProvider);
    final range = ref.watch(dashRangeProvider);
    final wide = MediaQuery.of(context).size.width >= 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period switch
        Row(
          children: [
            _rangeChip(ref, ref.tr('adash.thisYear'), DashRange.thisYear, range),
            const SizedBox(width: 8),
            _rangeChip(ref, ref.tr('adash.lastYear'), DashRange.lastYear, range),
            const Spacer(),
            IconButton(
              tooltip: ref.tr('common.refresh'),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.brand),
              onPressed: () => ref.invalidate(dashboardDataProvider),
            ),
          ],
        ),
        const SizedBox(height: 14),
        dataAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AppErrorState(
            message: 'Could not load analytics: $e',
            onRetry: () => ref.invalidate(dashboardDataProvider),
          ),
          data: (d) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kpiRow(ref, d, wide),
              const SizedBox(height: 22),
              _sectionLabel(ref.tr('adash.revenueAnalysis')),
              const SizedBox(height: 12),
              if (wide)
                SizedBox(
                  height: 320,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _methodCard(d)),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: _collectionCard(d)),
                    ],
                  ),
                )
              else ...[
                SizedBox(height: 260, child: _methodCard(d)),
                const SizedBox(height: 14),
                SizedBox(height: 300, child: _collectionCard(d)),
              ],
              const SizedBox(height: 22),
              _sectionLabel(ref.tr('adash.visitorFlow')),
              const SizedBox(height: 12),
              if (wide)
                SizedBox(
                  height: 300,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _visitorSplitCard(d)),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: _visitorMonthCard(d)),
                    ],
                  ),
                )
              else ...[
                SizedBox(height: 260, child: _visitorSplitCard(d)),
                const SizedBox(height: 14),
                SizedBox(height: 280, child: _visitorMonthCard(d)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _rangeChip(
      WidgetRef ref, String label, DashRange value, DashRange current) {
    final on = value == current;
    return GestureDetector(
      onTap: () => ref.read(dashRangeProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: on ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: on ? AppColors.brand : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: on ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.25))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.25))),
        ],
      );

  // ---- KPI row -------------------------------------------------------------
  Widget _kpiRow(WidgetRef ref, DashboardData d, bool wide) {
    final pct = d.thisMonthVsAvgPct;
    final tiles = <Widget>[
      _kpi(Icons.account_balance_wallet_rounded, ref.tr('adash.totalCollection'),
          _money.format(d.totalCollection), AppColors.brand),
      _kpi(Icons.bar_chart_rounded, ref.tr('adash.avgMonth'),
          _money.format(d.avgPerMonth), AppColors.info),
      _kpi(
        Icons.calendar_month_rounded,
        ref.tr('adash.thisMonth'),
        _money.format(d.thisMonthCollection),
        AppColors.success,
        delta: pct,
      ),
      _kpi(Icons.people_alt_rounded, ref.tr('adash.totalResidents'), '${d.residents}',
          AppColors.brandViolet),
      _kpi(Icons.receipt_long_rounded, ref.tr('adash.billsPaid'),
          '${d.billsCreated} / ${d.paymentsReceived}', AppColors.accentAmber),
      _kpi(Icons.pending_actions_rounded, ref.tr('adash.outstanding'),
          _money.format(d.outstanding), AppColors.error),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 6 : 2,
      // Boss 19/08: flatter tiles so the whole analytics block fits the fold.
      childAspectRatio: wide ? 2.0 : 1.9,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: tiles,
    );
  }

  Widget _kpi(IconData icon, String label, String value, Color color,
      {double? delta}) {
    // Same shape as the Overview stat cards: icon tile on the left, label
    // above the number, identical type scale (boss 19/08).
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
                  ),
                ),
                if (delta != null && delta.abs() > 0.01)
                  Row(
                    children: [
                      Icon(
                        delta >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color:
                            delta >= 0 ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${delta.abs().toStringAsFixed(1)}% vs avg',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: delta >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- payment method (horizontal bars) ------------------------------------
  Widget _methodCard(DashboardData d) {
    final items = d.byPaymentMethod.take(6).toList();
    final max = items.isEmpty
        ? 1.0
        : items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No payments yet',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final it = items[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(it.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Text(_money.format(it.value),
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: max == 0 ? 0 : it.value / max,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFEEF2F7),
                              valueColor: AlwaysStoppedAnimation(
                                _palette(i),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---- monthly collection (bars + average line) ----------------------------
  Widget _collectionCard(DashboardData d) {
    final vals = d.monthlyCollection;
    final maxV = vals.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxV <= 0 ? 100.0 : maxV * 1.25;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Collection',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              Text('Avg: ${_money.format(d.avgPerMonth)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: top,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _months[v.toInt().clamp(0, 11)],
                          style: const TextStyle(
                              fontSize: 9.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                extraLinesData: d.avgPerMonth > 0
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: d.avgPerMonth,
                          color: AppColors.textSecondary,
                          strokeWidth: 1.2,
                          dashArray: [6, 4],
                        ),
                      ])
                    : const ExtraLinesData(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${_months[group.x]}\n${_money.format(rod.toY)}',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < vals.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: vals[i].value,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        color: vals[i].value >= d.avgPerMonth &&
                                vals[i].value > 0
                            ? AppColors.brand
                            : AppColors.accentAmber,
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- visitor split (donut) -----------------------------------------------
  Widget _visitorSplitCard(DashboardData d) {
    final total = d.totalVisitors;
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Entry Type',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Expanded(
            child: total == 0
                ? const Center(
                    child: Text('No visitors yet',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5)))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 46,
                          sections: [
                            PieChartSectionData(
                              value: d.visitorsQr.toDouble(),
                              color: AppColors.brand,
                              radius: 22,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: d.visitorsWalkIn.toDouble(),
                              color: AppColors.accentAmber,
                              radius: 22,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${d.qrSharePct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                          const Text('by QR',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          _legend(AppColors.brand, 'QR / pre-registered', d.visitorsQr),
          const SizedBox(height: 4),
          _legend(AppColors.accentAmber, 'Walk-in', d.visitorsWalkIn),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label, int n) => Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ),
          Text('$n',
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
        ],
      );

  // ---- visitors per month (line) -------------------------------------------
  Widget _visitorMonthCard(DashboardData d) {
    final vals = d.visitorsByMonth;
    final maxV = vals.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Visitors per Month',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxV <= 0 ? 5 : maxV * 1.3,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _months[v.toInt().clamp(0, 11)],
                          style: const TextStyle(
                              fontSize: 9.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.brand,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brand.withValues(alpha: 0.12),
                    ),
                    spots: [
                      for (var i = 0; i < vals.length; i++)
                        FlSpot(i.toDouble(), vals[i].value),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _palette(int i) => [
        AppColors.brand,
        AppColors.success,
        AppColors.accentAmber,
        AppColors.error,
        AppColors.brandViolet,
        AppColors.info,
      ][i % 6];
}
