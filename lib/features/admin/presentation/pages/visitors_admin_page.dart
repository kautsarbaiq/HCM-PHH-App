import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/visitor_repository.dart';

final adminVisitorsProvider =
    AsyncNotifierProvider<AdminVisitorsNotifier, List<Visitor>>(
        () => AdminVisitorsNotifier());

class AdminVisitorsNotifier extends AsyncNotifier<List<Visitor>> {
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

  Future<void> deleteVisitor(String id) async {
    final repo = ref.read(visitorRepositoryProvider);
    await repo.deleteVisitor(id);
    ref.invalidateSelf();
  }
}

({String label, Color color}) _statusStyle(String status) {
  switch (status) {
    case 'checked_in':
      return (label: 'Checked In', color: const Color(0xFF05CD99));
    case 'checked_out':
      return (label: 'Checked Out', color: const Color(0xFFA3AED0));
    case 'cancelled':
      return (label: 'Cancelled', color: const Color(0xFFEE5D50));
    case 'expected':
    default:
      return (label: 'Expected', color: const Color(0xFFFFB547));
  }
}

String _formatTime(String? iso) {
  if (iso == null) return '-';
  try {
    return DateFormat('MMM dd, HH:mm').format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

String _nameOrDash(String? name) => (name != null && name.isNotEmpty) ? name : '-';

class VisitorsAdminPage extends ConsumerStatefulWidget {
  const VisitorsAdminPage({super.key});

  @override
  ConsumerState<VisitorsAdminPage> createState() => _VisitorsAdminPageState();
}

class _VisitorsAdminPageState extends ConsumerState<VisitorsAdminPage> {
  String _searchQuery = '';

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  List<Visitor> _filter(List<Visitor> visitors) {
    if (_searchQuery.isEmpty) return visitors;
    final q = _searchQuery.toLowerCase();
    return visitors.where((v) {
      return v.visitorName.toLowerCase().contains(q) ||
          (v.house?.houseNumber.toLowerCase().contains(q) ?? false) ||
          (v.creator?.fullName.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _showDetails(Visitor visitor) {
    final status = _statusStyle(visitor.status);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.badge, color: Color(0xFF4318FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  visitor.visitorName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Purpose', visitor.purpose),
                _buildDetailItem('Vehicle Plate', visitor.vehiclePlate?.isNotEmpty == true ? visitor.vehiclePlate! : '-'),
                _buildDetailItem('House', visitor.house?.houseNumber ?? '-'),
                _buildDetailItem('Registration', visitor.registrationType),
                _buildDetailItem('Logged By', _nameOrDash(visitor.creator?.fullName)),
                _buildDetailItem('Expected At', _formatTime(visitor.expectedAt)),
                _buildDetailItem('Checked In', _formatTime(visitor.checkedInAt)),
                _buildDetailItem('Checked Out', _formatTime(visitor.checkedOutAt)),
                _buildDetailItem('Status', status.label, statusColor: status.color),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF4318FF))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
          const SizedBox(height: 4),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674), fontSize: 16),
            ),
        ],
      ),
    );
  }

  void _deleteVisitor(Visitor visitor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Visitor Log', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
          content: Text('Are you sure you want to delete visitor ${visitor.visitorName}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref.read(adminVisitorsProvider.notifier).deleteVisitor(visitor.id);
                  navigator.pop();
                } catch (e) {
                  _showError(e);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitorsAsync = ref.watch(adminVisitorsProvider);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Visitors Log',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(adminVisitorsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4318FF),
                    side: const BorderSide(color: Color(0xFF4318FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by visitor, house, or who logged it...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA3AED0)),
                filled: true,
                fillColor: const Color(0xFFF4F7FE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: visitorsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Color(0xFFA3AED0)))),
                data: (allVisitors) {
                  final visitors = _filter(allVisitors);
                  if (visitors.isEmpty) {
                    return const Center(child: Text('No visitors logged', style: TextStyle(color: Color(0xFFA3AED0))));
                  }
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF4F7FE), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000.0;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: tableWidth,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    color: const Color(0xFFF4F7FE),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 3, child: Text('Visitor Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        Expanded(flex: 2, child: Text('House', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        Expanded(flex: 3, child: Text('Logged By', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        Expanded(flex: 2, child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                        Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)), textAlign: TextAlign.right)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: visitors.length,
                                      itemBuilder: (context, index) {
                                        final v = visitors[index];
                                        final status = _statusStyle(v.status);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          decoration: const BoxDecoration(
                                            border: Border(bottom: BorderSide(color: Color(0xFFE0E5F2), width: 1)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(flex: 3, child: Text(v.visitorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                                              Expanded(flex: 2, child: Text(v.house?.houseNumber ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                                              Expanded(
                                                flex: 3,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF4F7FE),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(_nameOrDash(v.creator?.fullName), style: const TextStyle(color: Color(0xFF2B3674), fontSize: 12)),
                                                  ),
                                                ),
                                              ),
                                              Expanded(flex: 2, child: Text(_formatTime(v.checkedInAt ?? v.expectedAt), style: const TextStyle(color: Color(0xFF2B3674), fontSize: 13))),
                                              Expanded(
                                                flex: 2,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: status.color.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      status.label,
                                                      style: TextStyle(color: status.color, fontWeight: FontWeight.bold, fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.visibility, color: Color(0xFF4318FF), size: 18),
                                                      onPressed: () => _showDetails(v),
                                                      tooltip: 'View Details',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                      onPressed: () => _deleteVisitor(v),
                                                      tooltip: 'Delete Visitor',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
