import 'package:flutter/material.dart';

class House {
  final String id;
  final String houseNo;
  final String owner;
  final String type;
  final String status;

  House({
    required this.id,
    required this.houseNo,
    required this.owner,
    required this.type,
    required this.status,
  });

  House copyWith({
    String? id,
    String? houseNo,
    String? owner,
    String? type,
    String? status,
  }) {
    return House(
      id: id ?? this.id,
      houseNo: houseNo ?? this.houseNo,
      owner: owner ?? this.owner,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}

class HousesAdminPage extends StatefulWidget {
  const HousesAdminPage({super.key});

  @override
  State<HousesAdminPage> createState() => _HousesAdminPageState();
}

class _HousesAdminPageState extends State<HousesAdminPage> {
  final List<House> _houses = List.generate(8, (index) {
    final isOccupied = index % 3 != 0;
    return House(
      id: '${index + 1}',
      houseNo: 'Block A-${100 + index}',
      owner: isOccupied ? 'Resident ${index + 1}' : '-',
      type: 'Type ${index % 2 == 0 ? 'A' : 'B'}',
      status: isOccupied ? 'Occupied' : 'Vacant',
    );
  });

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
                house.houseNo,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('ID', house.id),
              _buildDetailItem('House No / Address', house.houseNo),
              _buildDetailItem('Owner / Occupant', house.owner),
              _buildDetailItem('Unit Type', house.type),
              _buildDetailItem('Occupancy Status', house.status, isStatus: true),
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
    final houseNoController = TextEditingController(text: house?.houseNo ?? '');
    final ownerController = TextEditingController(text: house?.owner == '-' ? '' : (house?.owner ?? ''));
    final typeController = TextEditingController(text: house?.type ?? 'Type A');
    String status = house?.status ?? 'Vacant';

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
                    _buildTextField(ownerController, 'Owner (Leave empty if vacant)', Icons.person),
                    _buildTextField(typeController, 'Unit Type (e.g. Type A)', Icons.layers),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Occupied'),
                          selected: status == 'Occupied',
                          selectedColor: const Color(0xFF05CD99).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF05CD99),
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Occupied');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Vacant'),
                          selected: status == 'Vacant',
                          selectedColor: const Color(0xFFFFB547).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFFFB547),
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Vacant');
                          },
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
                  onPressed: () {
                    if (houseNoController.text.isEmpty) return;
                    setState(() {
                      final resolvedOwner = ownerController.text.trim().isEmpty ? '-' : ownerController.text.trim();
                      final resolvedStatus = ownerController.text.trim().isEmpty ? 'Vacant' : status;

                      if (isEdit) {
                        final idx = _houses.indexWhere((h) => h.id == house.id);
                        if (idx != -1) {
                          _houses[idx] = house.copyWith(
                            houseNo: houseNoController.text,
                            owner: resolvedOwner,
                            type: typeController.text,
                            status: resolvedStatus,
                          );
                        }
                      } else {
                        _houses.add(House(
                          id: '${_houses.length + 1}',
                          houseNo: houseNoController.text,
                          owner: resolvedOwner,
                          type: typeController.text,
                          status: resolvedStatus,
                        ));
                      }
                    });
                    Navigator.pop(context);
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
          content: Text('Are you sure you want to delete ${house.houseNo}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _houses.removeWhere((h) => h.id == house.id);
                });
                Navigator.pop(context);
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
                  child: _houses.isEmpty
                      ? const Center(child: Text('No houses found', style: TextStyle(color: Color(0xFFA3AED0))))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final tableWidth = constraints.maxWidth > 1000 ? constraints.maxWidth : 1000.0;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [
                                    // Full-width Table Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      color: const Color(0xFFF4F7FE),
                                      child: Row(
                                        children: const [
                                          Expanded(flex: 3, child: Text('House No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 3, child: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)), textAlign: TextAlign.right)),
                                        ],
                                      ),
                                    ),
                                    // Scrollable list of rows stretching to 100% width
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _houses.length,
                                        itemBuilder: (context, index) {
                                          final h = _houses[index];
                                          final isOccupied = h.status == 'Occupied';
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            decoration: const BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Color(0xFFE0E5F2), width: 1)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 3, child: Text(h.houseNo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                                                Expanded(flex: 3, child: Text(h.owner, style: const TextStyle(color: Color(0xFF2B3674)))),
                                                Expanded(flex: 2, child: Text(h.type, style: const TextStyle(color: Color(0xFF2B3674)))),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: (isOccupied ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        h.status,
                                                        style: TextStyle(
                                                          color: isOccupied ? const Color(0xFF05CD99) : const Color(0xFFFFB547),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
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
                                                        onPressed: () => _showDetails(h),
                                                        tooltip: 'View Details',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                                        onPressed: () => _showForm(house: h),
                                                        tooltip: 'Edit House',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                        onPressed: () => _deleteHouse(h),
                                                        tooltip: 'Delete House',
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
                          }
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
