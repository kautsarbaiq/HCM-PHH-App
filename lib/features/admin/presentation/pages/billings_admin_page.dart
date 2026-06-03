import 'package:flutter/material.dart';

class BillingsAdminPage extends StatelessWidget {
  const BillingsAdminPage({super.key});

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
                    'Billings & Payments',
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
                  label: const Text('Create Billing'),
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
                          DataColumn(label: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Resident', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                        ],
                        rows: List.generate(8, (index) {
                          final isPaid = index % 2 == 0;
                          return DataRow(
                            cells: [
                              DataCell(Text('INV-2023-${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                              DataCell(Text('Resident ${index + 1}', style: const TextStyle(color: Color(0xFF2B3674)))),
                              DataCell(Text('Rp ${500000 + (index * 50000)}', style: const TextStyle(color: Color(0xFF2B3674)))),
                              DataCell(Text('Oct ${10 + index}, 2023', style: const TextStyle(color: Color(0xFF2B3674)))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isPaid ? const Color(0xFF05CD99) : Colors.red).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(isPaid ? 'Paid' : 'Unpaid', style: TextStyle(color: isPaid ? const Color(0xFF05CD99) : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.visibility, color: Color(0xFF4318FF), size: 18), onPressed: () {}),
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
