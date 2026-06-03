import 'package:flutter/material.dart';

class HousesAdminPage extends StatelessWidget {
  const HousesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Houses & Units Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add House'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF4F7FE), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F7FE)),
                        dataRowMaxHeight: 65,
                        dataRowMinHeight: 65,
                        columns: const [
                          DataColumn(label: Text('House No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        ],
                        rows: List.generate(8, (index) {
                          final isOccupied = index % 3 != 0;
                          return DataRow(
                            cells: [
                              DataCell(Text('Block A-${100 + index}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                              DataCell(Text(isOccupied ? 'Resident ${index + 1}' : '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                              DataCell(Text('Type ${index % 2 == 0 ? 'A' : 'B'}', style: const TextStyle(color: Color(0xFF2B3674)))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isOccupied ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(isOccupied ? 'Occupied' : 'Vacant', style: TextStyle(color: isOccupied ? const Color(0xFF05CD99) : const Color(0xFFFFB547), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Color(0xFF4318FF), size: 18), onPressed: () {}),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () {}),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
