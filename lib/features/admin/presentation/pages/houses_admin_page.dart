import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/house_repository.dart';

final adminHousesProvider = AsyncNotifierProvider<AdminHousesNotifier, List<House>>(() => AdminHousesNotifier());

class AdminHousesNotifier extends AsyncNotifier<List<House>> {
  @override
  Future<List<House>> build() async {
    final repo = ref.read(houseRepositoryProvider);
    return repo.getAllHouses();
  }

  Future<void> addHouse(House house) async {
    final repo = ref.read(houseRepositoryProvider);
    await repo.createHouse(house);
    ref.invalidateSelf();
  }

  Future<void> updateHouse(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(houseRepositoryProvider);
    await repo.updateHouse(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteHouse(String id) async {
    final repo = ref.read(houseRepositoryProvider);
    await repo.deleteHouse(id);
    ref.invalidateSelf();
  }
}

class HousesAdminPage extends ConsumerStatefulWidget {
  const HousesAdminPage({super.key});

  @override
  ConsumerState<HousesAdminPage> createState() => _HousesAdminPageState();
}

class _HousesAdminPageState extends ConsumerState<HousesAdminPage> {
  String _searchQuery = '';

  List<House> _filterHouses(List<House> houses) {
    if (_searchQuery.isEmpty) return houses;
    return houses.where((house) {
      final matchesNo = house.houseNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesOwner = house.owner?.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return matchesNo || matchesOwner;
    }).toList();
  }

  void _showDetails(House house) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.house, color: Color(0xFF4318FF)),
              const SizedBox(width: 8),
              Text(
                house.houseNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('ID', house.id),
              _buildDetailItem('House No / Address', house.houseNumber),
              _buildDetailItem('Owner / Occupant', house.owner?.fullName ?? '-'),
              _buildDetailItem('Unit Type', house.houseType),
              _buildDetailItem('Occupancy Status', house.status == 'occupied' ? 'Occupied' : 'Vacant', isStatus: true),
            ],
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

  Widget _buildDetailItem(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
          const SizedBox(height: 4),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (value == 'Occupied' ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value == 'Occupied' ? const Color(0xFF05CD99) : const Color(0xFFFFB547),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
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

  void _showForm({House? house}) {
    final isEdit = house != null;
    final houseNoController = TextEditingController(text: house?.houseNumber ?? '');
    final typeController = TextEditingController(text: house?.houseType ?? 'Type A');
    String status = house?.status ?? 'vacant';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit House' : 'Add New House',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(houseNoController, 'House Number / Block', Icons.house),
                    _buildTextField(typeController, 'Unit Type (e.g. Type A)', Icons.layers),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Status: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('Occupied'),
                                selected: status == 'occupied',
                                selectedColor: const Color(0xFF05CD99).withOpacity(0.2),
                                checkmarkColor: const Color(0xFF05CD99),
                                onSelected: (val) {
                                  if (val) setDialogState(() => status = 'occupied');
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Vacant'),
                                selected: status == 'vacant',
                                selectedColor: const Color(0xFFFFB547).withOpacity(0.2),
                                checkmarkColor: const Color(0xFFFFB547),
                                onSelected: (val) {
                                  if (val) setDialogState(() => status = 'vacant');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (houseNoController.text.isEmpty) return;
                    
                    if (isEdit) {
                      await ref.read(adminHousesProvider.notifier).updateHouse(house.id, {
                        'house_number': houseNoController.text,
                        'house_type': typeController.text,
                        'status': status,
                      });
                    } else {
                      await ref.read(adminHousesProvider.notifier).addHouse(House(
                        id: '',
                        houseNumber: houseNoController.text,
                        houseType: typeController.text,
                        status: status,
                      ));
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFA3AED0)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4318FF)),
          ),
        ),
      ),
    );
  }

  void _deleteHouse(House house) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete House', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
          content: Text('Are you sure you want to delete ${house.houseNumber}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(adminHousesProvider.notifier).deleteHouse(house.id);
                if (mounted) Navigator.pop(context);
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
    final housesAsync = ref.watch(adminHousesProvider);

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
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add House'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by house number or owner...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA3AED0)),
                filled: true,
                fillColor: const Color(0xFFF4F7FE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: housesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (houses) {
                  final filteredHouses = _filterHouses(houses);
                  
                  if (filteredHouses.isEmpty) {
                    return const Center(
                      child: Text('No houses found.', style: TextStyle(color: Color(0xFFA3AED0))),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E5F2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F7FE)),
                          columns: const [
                            DataColumn(label: Text('House No.', style: TextStyle(color: Color(0xFFA3AED0), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Type', style: TextStyle(color: Color(0xFFA3AED0), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Owner', style: TextStyle(color: Color(0xFFA3AED0), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFFA3AED0), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(color: Color(0xFFA3AED0), fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredHouses.map((house) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    house.houseNumber,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
                                  ),
                                ),
                                DataCell(Text(house.houseType, style: const TextStyle(color: Color(0xFF2B3674)))),
                                DataCell(Text(house.owner?.fullName ?? '-', style: const TextStyle(color: Color(0xFF2B3674)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (house.status == 'occupied' ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      house.status == 'occupied' ? 'Occupied' : 'Vacant',
                                      style: TextStyle(
                                        color: house.status == 'occupied' ? const Color(0xFF05CD99) : const Color(0xFFFFB547),
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
                                      IconButton(
                                        icon: const Icon(Icons.visibility, color: Color(0xFFA3AED0)),
                                        onPressed: () => _showDetails(house),
                                        tooltip: 'View Details',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Color(0xFF4318FF)),
                                        onPressed: () => _showForm(house: house),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteHouse(house),
                                        tooltip: 'Delete',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
