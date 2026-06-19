import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/visitor_repository.dart';

final guardVisitorsProvider = AsyncNotifierProvider<GuardVisitorsNotifier, List<Visitor>>(() => GuardVisitorsNotifier());

class GuardVisitorsNotifier extends AsyncNotifier<List<Visitor>> {
  @override
  Future<List<Visitor>> build() async {
    final repo = ref.read(visitorRepositoryProvider);
    return repo.getAllVisitors();
  }

  Future<void> updateStatus(String id, String status) async {
    final repo = ref.read(visitorRepositoryProvider);
    await repo.updateVisitorStatus(id, status);
    ref.invalidateSelf();
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'expected':
      return const Color(0xFFF59E0B);
    case 'checked_in':
      return const Color(0xFF10B981);
    case 'checked_out':
      return const Color(0xFF6B7280);
    default:
      return const Color(0xFF3B82F6);
  }
}

String _visitorDate(Visitor visitor) {
  // Prefer when the visitor actually arrived (walk-ins set checked_in_at and
  // have no expected_at); fall back to the scheduled time.
  final raw = visitor.checkedInAt ?? visitor.expectedAt;
  if (raw == null) return '-';
  return DateFormat('MMM d, yyyy HH:mm').format(DateTime.parse(raw).toLocal());
}

class GuardVisitorsPage extends ConsumerWidget {
  const GuardVisitorsPage({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(guardVisitorsProvider.notifier).updateStatus(id, status);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update visitor: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitorsAsync = ref.watch(guardVisitorsProvider);
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visitor Logs',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2B3674),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Today's active and completed visitor registrations",
            style: TextStyle(color: const Color(0xFFA3AED0), fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: visitorsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _ErrorState(
                    message: 'Error: $error',
                    onRetry: () => ref.invalidate(guardVisitorsProvider),
                  ),
                  data: (visitors) {
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(guardVisitorsProvider),
                      child: visitors.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: 200.h),
                                const Center(
                                  child: Text('No visitors found.', style: TextStyle(color: Color(0xFFA3AED0))),
                                ),
                              ],
                            )
                          : isNarrow
                              ? _VisitorCardList(visitors: visitors, onUpdate: _updateStatus)
                              : _VisitorTable(visitors: visitors, onUpdate: _updateStatus),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _StatusUpdater = Future<void> Function(
  BuildContext context,
  WidgetRef ref,
  String id,
  String status,
);

class _VisitorTable extends ConsumerWidget {
  final List<Visitor> visitors;
  final _StatusUpdater onUpdate;

  const _VisitorTable({required this.visitors, required this.onUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Row(
                children: [
                  Icon(Icons.swipe, size: 14.sp, color: const Color(0xFFA3AED0)),
                  SizedBox(width: 6.w),
                  Text(
                    'Swipe horizontally to see all columns',
                    style: TextStyle(color: const Color(0xFFA3AED0), fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F7FE)),
                      columns: const [
                        DataColumn(label: Text('Visitor Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        DataColumn(label: Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        DataColumn(label: Text('Vehicle Plate', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        DataColumn(label: Text('House No.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                      ],
                      rows: visitors.map((visitor) {
                        final statusColor = _statusColor(visitor.status);
                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF4318FF).withOpacity(0.1),
                                    child: const Icon(Icons.person, color: Color(0xFF4318FF), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(visitor.visitorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
                                ],
                              ),
                            ),
                            DataCell(Text(visitor.purpose, style: const TextStyle(color: Color(0xFFA3AED0)))),
                            DataCell(Text(visitor.vehiclePlate ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                            DataCell(Text(visitor.house?.houseNumber ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                            DataCell(Text(_visitorDate(visitor), style: const TextStyle(color: Color(0xFFA3AED0)))),
                            DataCell(_StatusBadge(status: visitor.status, color: statusColor)),
                            DataCell(
                              _VisitorActions(
                                visitor: visitor,
                                onUpdate: onUpdate,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VisitorCardList extends StatelessWidget {
  final List<Visitor> visitors;
  final _StatusUpdater onUpdate;

  const _VisitorCardList({required this.visitors, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 24.h),
      itemCount: visitors.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final visitor = visitors[index];
        final statusColor = _statusColor(visitor.status);
        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4318FF).withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF4318FF), size: 20),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      visitor.visitorName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF2B3674), fontSize: 15.sp),
                    ),
                  ),
                  _StatusBadge(status: visitor.status, color: statusColor),
                ],
              ),
              SizedBox(height: 10.h),
              _CardInfoRow(label: 'Purpose', value: visitor.purpose),
              _CardInfoRow(label: 'House No.', value: visitor.house?.houseNumber ?? '-'),
              _CardInfoRow(label: 'Plate', value: visitor.vehiclePlate ?? '-'),
              _CardInfoRow(label: 'Date', value: _visitorDate(visitor)),
              if (visitor.status == 'expected' || visitor.status == 'checked_in') ...[
                SizedBox(height: 8.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: _VisitorActions(visitor: visitor, onUpdate: onUpdate, showLabels: true),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72.w,
            child: Text(label, style: TextStyle(color: const Color(0xFFA3AED0), fontSize: 12.sp)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: const Color(0xFF2B3674), fontWeight: FontWeight.w600, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// Stateful so we can disable the button and show a spinner while the
// network call is in flight.
class _VisitorActions extends ConsumerStatefulWidget {
  final Visitor visitor;
  final _StatusUpdater onUpdate;
  final bool showLabels;

  const _VisitorActions({
    required this.visitor,
    required this.onUpdate,
    this.showLabels = false,
  });

  @override
  ConsumerState<_VisitorActions> createState() => _VisitorActionsState();
}

class _VisitorActionsState extends ConsumerState<_VisitorActions> {
  bool _busy = false;

  Future<void> _run(String status) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onUpdate(context, ref, widget.visitor.id, status);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final status = widget.visitor.status;
    if (status == 'expected') {
      return widget.showLabels
          ? ElevatedButton.icon(
              onPressed: () => _run('checked_in'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Check In'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            )
          : IconButton(
              icon: const Icon(Icons.login, color: Color(0xFF10B981)),
              onPressed: () => _run('checked_in'),
              tooltip: 'Check In',
            );
    }
    if (status == 'checked_in') {
      return widget.showLabels
          ? ElevatedButton.icon(
              onPressed: () => _run('checked_out'),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Check Out'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            )
          : IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFF59E0B)),
              onPressed: () => _run('checked_out'),
              tooltip: 'Check Out',
            );
    }
    return const SizedBox.shrink();
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFA3AED0)),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4318FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
