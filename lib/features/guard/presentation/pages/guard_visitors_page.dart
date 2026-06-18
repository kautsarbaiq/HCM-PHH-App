import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class GuardVisitorsPage extends ConsumerWidget {
  const GuardVisitorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitorsAsync = ref.watch(guardVisitorsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visitor Logs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Today's active and completed visitor registrations",
            style: TextStyle(color: Color(0xFFA3AED0)),
          ),
          const SizedBox(height: 24),
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
              child: visitorsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (visitors) {
                  if (visitors.isEmpty) {
                    return const Center(
                      child: Text('No visitors found.', style: TextStyle(color: Color(0xFFA3AED0))),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
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
                                Color statusColor;
                                switch (visitor.status.toLowerCase()) {
                                  case 'expected':
                                    statusColor = const Color(0xFFF59E0B);
                                    break;
                                  case 'checked_in':
                                    statusColor = const Color(0xFF10B981);
                                    break;
                                  case 'checked_out':
                                    statusColor = const Color(0xFF6B7280);
                                    break;
                                  default:
                                    statusColor = const Color(0xFF3B82F6);
                                }

                                final dateStr = visitor.expectedAt != null 
                                    ? DateFormat('MMM d, yyyy HH:mm').format(DateTime.parse(visitor.expectedAt!).toLocal())
                                    : '-';

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
                                    DataCell(Text(dateStr, style: const TextStyle(color: Color(0xFFA3AED0)))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          visitor.status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (visitor.status == 'expected')
                                            IconButton(
                                              icon: const Icon(Icons.login, color: Color(0xFF10B981)),
                                              onPressed: () {
                                                ref.read(guardVisitorsProvider.notifier).updateStatus(visitor.id, 'checked_in');
                                              },
                                              tooltip: 'Check In',
                                            ),
                                          if (visitor.status == 'checked_in')
                                            IconButton(
                                              icon: const Icon(Icons.logout, color: Color(0xFFF59E0B)),
                                              onPressed: () {
                                                ref.read(guardVisitorsProvider.notifier).updateStatus(visitor.id, 'checked_out');
                                              },
                                              tooltip: 'Check Out',
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
