import 'package:flutter/material.dart';

class VisitorsAdminPage extends StatelessWidget {
  const VisitorsAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visitors Log',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B3674),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F7FE)),
                columns: const [
                  DataColumn(label: Text('Visitor Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                  DataColumn(label: Text('Host (Resident)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                  DataColumn(label: Text('Created By', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                  DataColumn(label: Text('Time In', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                ],
                rows: List.generate(10, (index) {
                  final createdByResident = index % 3 != 0;
                  final isCheckedIn = index % 2 == 0;
                  return DataRow(
                    cells: [
                      DataCell(Text('John Doe $index', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                      DataCell(Text('Resident ${index + 1}', style: const TextStyle(color: Color(0xFF2B3674)))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(createdByResident ? 'Resident' : 'Security Guard', style: const TextStyle(color: Color(0xFF2B3674), fontSize: 12)),
                        ),
                      ),
                      DataCell(Text('10:00 AM', style: const TextStyle(color: Color(0xFF2B3674)))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isCheckedIn ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(isCheckedIn ? 'Checked In' : 'Expected', style: TextStyle(color: isCheckedIn ? const Color(0xFF05CD99) : const Color(0xFFFFB547), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
