import 'package:flutter/material.dart';

class GuardHousesPage extends StatelessWidget {
  const GuardHousesPage({super.key});

  final List<Map<String, dynamic>> _houses = const [
    {'house_no': 'A-01', 'owner': 'John Doe', 'mobile': '+1 234 567 890'},
    {'house_no': 'A-02', 'owner': 'Jane Smith', 'mobile': '+1 987 654 321'},
    {'house_no': 'B-10', 'owner': 'Michael Johnson', 'mobile': '+1 555 123 456'},
    {'house_no': 'B-11', 'owner': 'Emily Davis', 'mobile': '+1 555 987 654'},
    {'house_no': 'C-05', 'owner': 'Robert Wilson', 'mobile': '+1 444 333 222'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'House Directory',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B3674),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'List of all houses and their emergency contact persons',
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
                            DataColumn(label: Text('House No.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                            DataColumn(label: Text('Owner Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                            DataColumn(label: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                          ],
                          rows: _houses.map((house) {
                            return DataRow(
                              cells: [
                                DataCell(Text(house['house_no'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674)))),
                                DataCell(Text(house['owner'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674)))),
                                DataCell(Text(house['mobile'], style: const TextStyle(color: Color(0xFF2B3674)))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Color(0xFF10B981)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Calling ${house['owner']}...')),
                                      );
                                    },
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
