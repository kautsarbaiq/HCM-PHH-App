import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/emergency_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../theme/app_colors.dart';

/// Admin: full history of panic/emergency alerts (point 11) — who pressed it,
/// which house, and how it was cleared (by whom + remarks, point 12).
class AlertsAdminPage extends ConsumerWidget {
  const AlertsAdminPage({super.key});

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat(
        'MMM dd, yyyy • HH:mm',
      ).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                icon: const Icon(Icons.refresh_rounded, color: AppColors.brand),
                onPressed: () => ref.invalidate(alertHistoryProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load alert history: $e',
                onRetry: () => ref.invalidate(alertHistoryProvider),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'No alerts yet',
                    message: 'Panic and emergency alerts will appear here.',
                    gradient: AppColors.mintGradient,
                  );
                }
                return ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = alerts[i];
                    final active = a.status == 'Active';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  (active
                                          ? AppColors.error
                                          : AppColors.success)
                                      .withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              active
                                  ? PhosphorIconsFill.siren
                                  : PhosphorIconsRegular.checkCircle,
                              color: active
                                  ? AppColors.error
                                  : AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        a.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusPill(
                                      label: a.status.toUpperCase(),
                                      color: active
                                          ? AppColors.error
                                          : AppColors.success,
                                      dense: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  [
                                    if (a.houseNumber != null)
                                      'House ${a.houseNumber}',
                                    if (a.triggeredByName != null)
                                      'by ${a.triggeredByName}',
                                    a.subtitle,
                                  ].join(' • '),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Raised ${_fmt(a.createdAt)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (!active) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceTint,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cleared ${_fmt(a.clearedAt)}'
                                          '${a.clearedByName != null ? ' by ${a.clearedByName}' : ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (a.clearRemarks?.isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Remarks: ${a.clearRemarks}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
