import 'package:flutter/material.dart';

class GuardVisitorsPage extends StatelessWidget {
  const GuardVisitorsPage({super.key});

  final List<Map<String, dynamic>> _visitors = const [
    {'name': 'Mark Courier', 'type': 'Delivery', 'plate': 'B 1234 CD', 'house_no': 'A-01', 'date': 'Oct 25, 2026', 'status': 'Pre-registered'},
    {'name': 'Sarah Plumber', 'type': 'Service', 'plate': 'D 5678 EF', 'house_no': 'B-10', 'date': 'Oct 25, 2026', 'status': 'Scanned'},
    {'name': 'Unknown Guest', 'type': 'Visitor', 'plate': 'F 9101 GH', 'house_no': 'C-05', 'date': 'Oct 25, 2026', 'status': 'Walk-in'},
  ];

  @override
  Widget build(BuildContext context) {
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
              child: LayoutBuilder(
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
                          ],
                          rows: _visitors.map((visitor) {
                            Color statusColor;
                            switch (visitor['status']) {
                              case 'Pre-registered':
                                statusColor = const Color(0xFFF59E0B);
                                break;
                              case 'Scanned':
                                statusColor = const Color(0xFF10B981);
                                break;
                              default:
                                statusColor = const Color(0xFF3B82F6);
                            }

                            return DataRow(
                              cells: [
                                DataCell(Text(visitor['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674)))),
                                DataCell(Text(visitor['type'], style: const TextStyle(color: Color(0xFF2B3674)))),
                                DataCell(Text(visitor['plate'], style: const TextStyle(color: Color(0xFF2B3674)))),
                                DataCell(Text(visitor['house_no'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674)))),
                                DataCell(Text(visitor['date'], style: const TextStyle(color: Color(0xFF2B3674)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      visitor['status'],
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
