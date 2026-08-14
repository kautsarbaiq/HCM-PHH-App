import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Dashboard analytics (boss batch 08/08 point 14). Counts + charts modelled on
// the reference dashboard: KPI row, monthly collection with an average line,
// a breakdown by payment method, and visitor flow split QR vs walk-in.
// ============================================================================

/// Which period the dashboard is showing.
enum DashRange { thisYear, lastYear }

class MonthValue {
  final int month; // 1-12
  final double value;
  const MonthValue(this.month, this.value);
}

class NamedValue {
  final String name;
  final double value;
  const NamedValue(this.name, this.value);
}

class DashboardData {
  // KPI row
  final double totalCollection;
  final double avgPerMonth;
  final double thisMonthCollection;
  final int residents;
  final int registeredUsers;
  final int billsCreated;
  final int paymentsReceived;
  final double outstanding;

  // Charts
  final List<MonthValue> monthlyCollection;
  final List<NamedValue> byPaymentMethod;
  final int visitorsQr;
  final int visitorsWalkIn;
  final List<MonthValue> visitorsByMonth;

  const DashboardData({
    required this.totalCollection,
    required this.avgPerMonth,
    required this.thisMonthCollection,
    required this.residents,
    required this.registeredUsers,
    required this.billsCreated,
    required this.paymentsReceived,
    required this.outstanding,
    required this.monthlyCollection,
    required this.byPaymentMethod,
    required this.visitorsQr,
    required this.visitorsWalkIn,
    required this.visitorsByMonth,
  });

  /// How this month compares with the average month (for the ▲/▼ badge).
  double get thisMonthVsAvgPct {
    if (avgPerMonth <= 0) return 0;
    return ((thisMonthCollection - avgPerMonth) / avgPerMonth) * 100;
  }

  int get totalVisitors => visitorsQr + visitorsWalkIn;
  double get qrSharePct =>
      totalVisitors == 0 ? 0 : (visitorsQr / totalVisitors) * 100;
}

final dashRangeProvider = StateProvider<DashRange>((_) => DashRange.thisYear);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(Supabase.instance.client);
});

final dashboardDataProvider =
    FutureProvider.autoDispose<DashboardData>((ref) {
  final range = ref.watch(dashRangeProvider);
  return ref.watch(analyticsRepositoryProvider).load(range);
});

class AnalyticsRepository {
  final SupabaseClient _db;
  AnalyticsRepository(this._db);

  Future<DashboardData> load(DashRange range) async {
    final now = DateTime.now();
    final year = range == DashRange.thisYear ? now.year : now.year - 1;
    final from = DateTime(year, 1, 1).toIso8601String();
    final to = DateTime(year + 1, 1, 1).toIso8601String();

    // Bills for the selected year. RLS already scopes this to the admin's own
    // community, so no extra filtering is needed here.
    final bills = await _db
        .from('billings')
        .select('amount, status, paid_at, payment_method, created_at')
        .gte('created_at', from)
        .lt('created_at', to);

    final visitors = await _db
        .from('visitors')
        .select('registration_type, created_at')
        .gte('created_at', from)
        .lt('created_at', to);

    final residents = await _db
        .from('profiles')
        .count(CountOption.exact)
        .eq('role', 'resident');
    final registered = await _db.from('profiles').count(CountOption.exact);

    // --- money -------------------------------------------------------------
    final monthly = List<double>.filled(12, 0);
    final byMethod = <String, double>{};
    double total = 0;
    double outstanding = 0;
    int paidCount = 0;

    for (final b in (bills as List).cast<Map<String, dynamic>>()) {
      final amount = (b['amount'] as num?)?.toDouble() ?? 0;
      final isPaid = (b['status'] as String?) == 'paid';
      if (isPaid) {
        paidCount++;
        total += amount;
        // Bucket by the month the money actually came in.
        final paidAt = DateTime.tryParse('${b['paid_at'] ?? ''}') ??
            DateTime.tryParse('${b['created_at'] ?? ''}');
        if (paidAt != null && paidAt.year == year) {
          monthly[paidAt.month - 1] += amount;
        }
        final method =
            ((b['payment_method'] as String?) ?? 'Unspecified').trim();
        byMethod[method.isEmpty ? 'Unspecified' : method] =
            (byMethod[method.isEmpty ? 'Unspecified' : method] ?? 0) + amount;
      } else {
        outstanding += amount;
      }
    }

    // Average across months that actually have collection — an average over
    // all 12 would understate a mid-year snapshot.
    final activeMonths = monthly.where((v) => v > 0).length;
    final avg = activeMonths == 0 ? 0.0 : total / activeMonths;

    // --- visitors ----------------------------------------------------------
    var qr = 0;
    var walk = 0;
    final visitorMonthly = List<double>.filled(12, 0);
    for (final v in (visitors as List).cast<Map<String, dynamic>>()) {
      final type = (v['registration_type'] as String?) ?? '';
      // Walk-ins are registered by the guard on the spot; everything else
      // (pre-registered, event guests) enters by scanning a QR.
      if (type == 'walk-in') {
        walk++;
      } else {
        qr++;
      }
      final at = DateTime.tryParse('${v['created_at'] ?? ''}');
      if (at != null && at.year == year) {
        visitorMonthly[at.month - 1] += 1;
      }
    }

    final methods = byMethod.entries
        .map((e) => NamedValue(e.key, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DashboardData(
      totalCollection: total,
      avgPerMonth: avg,
      thisMonthCollection:
          range == DashRange.thisYear ? monthly[now.month - 1] : monthly.last,
      residents: residents,
      registeredUsers: registered,
      billsCreated: (bills).length,
      paymentsReceived: paidCount,
      outstanding: outstanding,
      monthlyCollection: [
        for (var i = 0; i < 12; i++) MonthValue(i + 1, monthly[i]),
      ],
      byPaymentMethod: methods,
      visitorsQr: qr,
      visitorsWalkIn: walk,
      visitorsByMonth: [
        for (var i = 0; i < 12; i++) MonthValue(i + 1, visitorMonthly[i]),
      ],
    );
  }
}
