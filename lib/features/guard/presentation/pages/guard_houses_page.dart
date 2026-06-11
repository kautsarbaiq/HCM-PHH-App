import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/house_repository.dart';

final guardHousesProvider = FutureProvider<List<House>>((ref) async {
  final repo = ref.read(houseRepositoryProvider);
  return repo.getAllHouses();
});

class GuardHousesPage extends ConsumerWidget {
  const GuardHousesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final housesAsync = ref.watch(guardHousesProvider);

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
              child: housesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (houses) {
                  if (houses.isEmpty) {
                    return const Center(
                      child: Text('No houses found.', style: TextStyle(color: Color(0xFFA3AED0))),
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
                                DataColumn(label: Text('House No.', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                DataColumn(label: Text('Owner Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                DataColumn(label: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                              ],
                              rows: houses.map((house) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        house.houseNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                                      ),
                                    ),
                                    DataCell(Text(house.owner?.fullName ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                                    DataCell(Text(house.owner?.phone ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.phone, color: Color(0xFF4318FF)),
                                        onPressed: house.owner?.phone != null 
                                            ? () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Calling ${house.owner!.phone}...')),
                                                );
                                              }
                                            : null,
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
