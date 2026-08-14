import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/emergency_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/report_table.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Admin: full history of panic/emergency alerts, as a sortable, searchable
/// table with CSV/PDF export (boss batch 08/08 point 10). Shows who pressed it,
/// which house, and how it was cleared (type, by whom, remarks).
class AlertsAdminPage extends ConsumerStatefulWidget {
  const AlertsAdminPage({super.key});

  @override
  ConsumerState<AlertsAdminPage> createState() => _AlertsAdminPageState();
}

class _AlertsAdminPageState extends ConsumerState<AlertsAdminPage> {
  // 'all' | 'Active' | 'Resolved'
  String _status = 'all';

  static String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm')
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  static String _typeLabel(String t) => switch (t) {
        'panic' => 'Panic',
        'broadcast' => 'Broadcast',
        'community' => 'Community',
        'rollcall' => 'Roll call',
        'contact' => 'Contacts',
        _ => t,
      };

  static String _resolution(EmergencyAlert a) {
    if (a.status == 'Active') return 'Open';
    return switch (a.clearType) {
      'false_alarm' => 'False alarm',
      'attended' => 'Attended',
      _ => 'Cleared',
    };
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(alertHistoryProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Alert History',
                  subtitle:
                      'Every panic & emergency alert, with clearing details',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.brand),
                onPressed: () => ref.invalidate(alertHistoryProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load alert history: $e',
                onRetry: () => ref.invalidate(alertHistoryProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'No alerts yet',
                    message: 'Panic and emergency alerts will appear here.',
                    gradient: AppColors.mintGradient,
                  );
                }
                final rows = _status == 'all'
                    ? all
                    : all.where((a) => a.status == _status).toList();

                return ReportTable<EmergencyAlert>(
                  title: 'Alert History',
                  subtitle: _status == 'all'
                      ? 'All alerts'
                      : 'Status: $_status',
                  exportBaseName:
                      'alert-history-${DateFormat('yyyyMMdd').format(DateTime.now())}',
                  emptyMessage: 'No alerts match your filter.',
                  rows: rows,
                  filters: Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ['all', 'Active', 'Resolved'])
                        ChoiceChip(
                          label: Text(s == 'all' ? 'All' : s),
                          selected: _status == s,
                          onSelected: (_) => setState(() => _status = s),
                        ),
                    ],
                  ),
                  columns: [
                    ReportColumn(
                      label: 'Raised',
                      value: (a) => _fmt(a.createdAt),
                      sortKey: (a) => a.createdAt,
                    ),
                    ReportColumn(
                      label: 'Type',
                      value: (a) => _typeLabel(a.type),
                    ),
                    ReportColumn(
                      label: 'Title',
                      value: (a) => a.title,
                    ),
                    ReportColumn(
                      label: 'House',
                      value: (a) => a.houseNumber ?? '-',
                    ),
                    ReportColumn(
                      label: 'Raised by',
                      value: (a) => a.triggeredByName ?? '-',
                    ),
                    ReportColumn(
                      label: 'Status',
                      value: (a) => a.status,
                      cell: (a) => StatusPill(
                        label: a.status.toUpperCase(),
                        color: a.status == 'Active'
                            ? AppColors.error
                            : AppColors.success,
                        dense: true,
                      ),
                    ),
                    ReportColumn(
                      label: 'Resolution',
                      value: _resolution,
                    ),
                    ReportColumn(
                      label: 'Cleared',
                      value: (a) => _fmt(a.clearedAt),
                      sortKey: (a) => a.clearedAt ?? '',
                    ),
                    ReportColumn(
                      label: 'Cleared by',
                      value: (a) => a.clearedByName ?? '-',
                    ),
                    ReportColumn(
                      label: 'Remarks',
                      value: (a) => a.clearRemarks ?? '-',
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
}
