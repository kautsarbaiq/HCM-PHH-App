import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/report_table.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

// ============================================================================
// Reports (boss batch 08/08 point 4): one place to pull any list out of the
// system, with search, sorting and CSV/PDF export.
// ============================================================================

enum ReportKind { residents, visitors, bookings, payments, events }

extension _ReportKindX on ReportKind {
  String get label => switch (this) {
        ReportKind.residents => 'Residents',
        ReportKind.visitors => 'Visitors',
        ReportKind.bookings => 'Facility Bookings',
        ReportKind.payments => 'Payments',
        ReportKind.events => 'Events',
      };
  IconData get icon => switch (this) {
        ReportKind.residents => Icons.people_alt_rounded,
        ReportKind.visitors => Icons.badge_rounded,
        ReportKind.bookings => Icons.event_available_rounded,
        ReportKind.payments => Icons.payments_rounded,
        ReportKind.events => Icons.celebration_rounded,
      };
}

final reportKindProvider =
    StateProvider<ReportKind>((_) => ReportKind.residents);

/// Raw rows for the selected report. Kept as maps so one provider serves every
/// report kind; RLS already scopes each table to the admin's community.
final reportRowsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = Supabase.instance.client;
  switch (ref.watch(reportKindProvider)) {
    case ReportKind.residents:
      return (await db
              .from('profiles')
              .select('full_name, email, phone, role, resident_type, '
                  'approval_status, created_at, houses(house_number)')
              .order('created_at', ascending: false))
          .cast<Map<String, dynamic>>();
    case ReportKind.visitors:
      return (await db
              .from('visitors')
              .select('visitor_name, purpose, registration_type, status, '
                  'vehicle_plate, ic_last4, expected_at, checked_in_at, '
                  'checked_out_at, created_at, houses(house_number)')
              .order('created_at', ascending: false))
          .cast<Map<String, dynamic>>();
    case ReportKind.bookings:
      return (await db
              .from('bookings')
              .select()
              .order('created_at', ascending: false))
          .cast<Map<String, dynamic>>();
    case ReportKind.payments:
      return (await db
              .from('billings')
              .select('invoice_number, title, amount, status, due_date, '
                  'paid_at, payment_method, period, '
                  'profiles!billings_resident_id_fkey(full_name)')
              .order('created_at', ascending: false))
          .cast<Map<String, dynamic>>();
    case ReportKind.events:
      return (await db
              .from('events')
              .select('title, event_date, location, status, capacity, '
                  'created_at, profiles!events_created_by_fkey(full_name)')
              .order('created_at', ascending: false))
          .cast<Map<String, dynamic>>();
  }
});

class ReportsAdminPage extends ConsumerWidget {
  const ReportsAdminPage({super.key});

  static String _s(Map<String, dynamic> r, String key) {
    final v = r[key];
    if (v == null) return '-';
    return v.toString().isEmpty ? '-' : v.toString();
  }

  static String _nested(Map<String, dynamic> r, String join, String key) {
    final m = r[join];
    if (m is Map && m[key] != null) return m[key].toString();
    return '-';
  }

  static String _date(Map<String, dynamic> r, String key) {
    final raw = r[key];
    if (raw == null || raw.toString().isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm')
          .format(DateTime.parse(raw.toString()).toLocal());
    } catch (_) {
      return raw.toString();
    }
  }

  List<ReportColumn<Map<String, dynamic>>> _columns(ReportKind kind) {
    switch (kind) {
      case ReportKind.residents:
        return [
          ReportColumn(label: 'Name', value: (r) => _s(r, 'full_name')),
          ReportColumn(label: 'Email', value: (r) => _s(r, 'email')),
          ReportColumn(label: 'Phone', value: (r) => _s(r, 'phone')),
          ReportColumn(
              label: 'House', value: (r) => _nested(r, 'houses', 'house_number')),
          ReportColumn(label: 'Role', value: (r) => _s(r, 'role')),
          ReportColumn(label: 'Type', value: (r) => _s(r, 'resident_type')),
          ReportColumn(
            label: 'Approval',
            value: (r) => _s(r, 'approval_status'),
            cell: (r) => StatusPill(
              label: _s(r, 'approval_status').toUpperCase(),
              color: _s(r, 'approval_status') == 'approved'
                  ? AppColors.success
                  : AppColors.warning,
              dense: true,
            ),
          ),
          ReportColumn(
              label: 'Joined',
              value: (r) => _date(r, 'created_at'),
              sortKey: (r) => _s(r, 'created_at')),
        ];
      case ReportKind.visitors:
        return [
          ReportColumn(label: 'Visitor', value: (r) => _s(r, 'visitor_name')),
          ReportColumn(label: 'Purpose', value: (r) => _s(r, 'purpose')),
          ReportColumn(
              label: 'House', value: (r) => _nested(r, 'houses', 'house_number')),
          ReportColumn(
              label: 'Entry', value: (r) => _s(r, 'registration_type')),
          ReportColumn(label: 'Plate', value: (r) => _s(r, 'vehicle_plate')),
          ReportColumn(label: 'IC last 4', value: (r) => _s(r, 'ic_last4')),
          ReportColumn(label: 'Status', value: (r) => _s(r, 'status')),
          ReportColumn(
              label: 'Checked in',
              value: (r) => _date(r, 'checked_in_at'),
              sortKey: (r) => _s(r, 'checked_in_at')),
          ReportColumn(
              label: 'Checked out', value: (r) => _date(r, 'checked_out_at')),
        ];
      case ReportKind.bookings:
        return [
          ReportColumn(label: 'Facility', value: (r) => _s(r, 'facility_name')),
          ReportColumn(label: 'Date', value: (r) => _s(r, 'date')),
          ReportColumn(label: 'Time', value: (r) => _s(r, 'time')),
          ReportColumn(label: 'Status', value: (r) => _s(r, 'status')),
          ReportColumn(
              label: 'Booked at',
              value: (r) => _date(r, 'created_at'),
              sortKey: (r) => _s(r, 'created_at')),
        ];
      case ReportKind.payments:
        return [
          ReportColumn(label: 'Invoice', value: (r) => _s(r, 'invoice_number')),
          ReportColumn(label: 'Title', value: (r) => _s(r, 'title')),
          ReportColumn(
              label: 'Resident',
              value: (r) => _nested(r, 'profiles', 'full_name')),
          ReportColumn(
            label: 'Amount (RM)',
            numeric: true,
            value: (r) =>
                ((r['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
            sortKey: (r) => (r['amount'] as num?)?.toDouble() ?? 0,
          ),
          ReportColumn(label: 'Period', value: (r) => _s(r, 'period')),
          ReportColumn(label: 'Due', value: (r) => _s(r, 'due_date')),
          ReportColumn(
            label: 'Status',
            value: (r) => _s(r, 'status'),
            cell: (r) => StatusPill(
              label: _s(r, 'status').toUpperCase(),
              color: _s(r, 'status') == 'paid'
                  ? AppColors.success
                  : AppColors.error,
              dense: true,
            ),
          ),
          ReportColumn(label: 'Paid at', value: (r) => _date(r, 'paid_at')),
          ReportColumn(label: 'Method', value: (r) => _s(r, 'payment_method')),
        ];
      case ReportKind.events:
        return [
          ReportColumn(label: 'Event', value: (r) => _s(r, 'title')),
          ReportColumn(
              label: 'When',
              value: (r) => _date(r, 'event_date'),
              sortKey: (r) => _s(r, 'event_date')),
          ReportColumn(label: 'Location', value: (r) => _s(r, 'location')),
          ReportColumn(
              label: 'Host', value: (r) => _nested(r, 'profiles', 'full_name')),
          ReportColumn(label: 'Status', value: (r) => _s(r, 'status')),
          ReportColumn(
              label: 'Capacity',
              numeric: true,
              value: (r) => _s(r, 'capacity'),
              sortKey: (r) => (r['capacity'] as num?)?.toInt() ?? 0),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(reportKindProvider);
    final rowsAsync = ref.watch(reportRowsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Reports',
                  subtitle: 'Search, sort and export any list as CSV or PDF',
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.brand),
                onPressed: () => ref.invalidate(reportRowsProvider),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in ReportKind.values)
                ChoiceChip(
                  avatar: Icon(k.icon,
                      size: 16,
                      color: kind == k ? Colors.white : AppColors.brand),
                  label: Text(k.label),
                  selected: kind == k,
                  onSelected: (_) =>
                      ref.read(reportKindProvider.notifier).state = k,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: rowsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load report: $e',
                onRetry: () => ref.invalidate(reportRowsProvider),
              ),
              data: (rows) => ReportTable<Map<String, dynamic>>(
                title: '${kind.label} report',
                subtitle: 'Generated from ${kind.label.toLowerCase()}',
                exportBaseName:
                    '${kind.label.toLowerCase().replaceAll(' ', '-')}-'
                    '${DateFormat('yyyyMMdd').format(DateTime.now())}',
                emptyMessage: 'No ${kind.label.toLowerCase()} found.',
                rows: rows,
                columns: _columns(kind),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
