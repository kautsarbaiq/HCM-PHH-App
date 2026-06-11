import 'package:flutter/material.dart';

class Resident {
  final String id;
  final String name;
  final String houseUnit;
  final String email;
  final String phone;
  final String status;

  Resident({
    required this.id,
    required this.name,
    required this.houseUnit,
    required this.email,
    required this.phone,
    required this.status,
  });

  Resident copyWith({
    String? id,
    String? name,
    String? houseUnit,
    String? email,
    String? phone,
    String? status,
  }) {
    return Resident(
      id: id ?? this.id,
      name: name ?? this.name,
      houseUnit: houseUnit ?? this.houseUnit,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }
}

class ResidentsAdminPage extends StatefulWidget {
  const ResidentsAdminPage({super.key});

  @override
  State<ResidentsAdminPage> createState() => _ResidentsAdminPageState();
}

class _ResidentsAdminPageState extends State<ResidentsAdminPage> {
  final List<Resident> _residents = List.generate(8, (index) {
    return Resident(
      id: '${index + 1}',
      name: 'Resident ${index + 1}',
      houseUnit: 'Block A-${100 + index}',
      email: 'resident${index + 1}@example.com',
      phone: '+60 812-3456-789$index',
      status: index % 3 == 0 ? 'Inactive' : 'Active',
    );
  });

  String _searchQuery = '';

  List<Resident> get _filteredResidents {
    if (_searchQuery.isEmpty) return _residents;
    return _residents.where((r) {
      return r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.houseUnit.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.phone.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showDetails(Resident resident) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF4318FF)),
              const SizedBox(width: 8),
              Text(
                resident.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('ID', resident.id),
              _buildDetailItem('House/Unit', resident.houseUnit),
              _buildDetailItem('Email Address', resident.email),
              _buildDetailItem('Phone Number', resident.phone),
              _buildDetailItem('Account Status', resident.status, isStatus: true),
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
                color: (value == 'Active' ? const Color(0xFF05CD99) : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value == 'Active' ? const Color(0xFF05CD99) : Colors.orange,
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

  void _showForm({Resident? resident}) {
    final isEdit = resident != null;
    final nameController = TextEditingController(text: resident?.name ?? '');
    final unitController = TextEditingController(text: resident?.houseUnit ?? '');
    final emailController = TextEditingController(text: resident?.email ?? '');
    final phoneController = TextEditingController(text: resident?.phone ?? '');
    String status = resident?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Resident' : 'Add New Resident',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameController, 'Full Name', Icons.person),
                    _buildTextField(unitController, 'House / Unit Number', Icons.house),
                    _buildTextField(emailController, 'Email Address', Icons.email),
                    _buildTextField(phoneController, 'Phone Number', Icons.phone),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Active'),
                          selected: status == 'Active',
                          selectedColor: const Color(0xFF05CD99).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF05CD99),
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Active');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Inactive'),
                          selected: status == 'Inactive',
                          selectedColor: Colors.orange.withOpacity(0.2),
                          checkmarkColor: Colors.orange,
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Inactive');
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
                    if (nameController.text.isEmpty || unitController.text.isEmpty) return;
                    setState(() {
                      if (isEdit) {
                        final idx = _residents.indexWhere((r) => r.id == resident.id);
                        if (idx != -1) {
                          _residents[idx] = resident.copyWith(
                            name: nameController.text,
                            houseUnit: unitController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                            status: status,
                          );
                        }
                      } else {
                        _residents.add(Resident(
                          id: '${_residents.length + 1}',
                          name: nameController.text,
                          houseUnit: unitController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          status: status,
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

  void _deleteResident(Resident resident) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Resident', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
          content: Text('Are you sure you want to delete ${resident.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _residents.removeWhere((r) => r.id == resident.id);
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
                    'Residents Management',
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
                  label: const Text('Add Resident'),
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
            TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search residents...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFA3AED0)),
                filled: true,
                fillColor: const Color(0xFFF4F7FE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
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
                  child: _filteredResidents.isEmpty
                      ? const Center(child: Text('No residents found', style: TextStyle(color: Color(0xFFA3AED0))))
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
                                          Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('House/Unit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)), textAlign: TextAlign.right)),
                                        ],
                                      ),
                                    ),
                                    // Scrollable list of rows stretching to 100% width
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _filteredResidents.length,
                                        itemBuilder: (context, index) {
                                          final r = _filteredResidents[index];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                            decoration: const BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Color(0xFFE0E5F2), width: 1)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(flex: 3, child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                                                Expanded(flex: 2, child: Text(r.houseUnit, style: const TextStyle(color: Color(0xFF2B3674)))),
                                                Expanded(flex: 3, child: Text(r.email, style: const TextStyle(color: Color(0xFF2B3674)))),
                                                Expanded(flex: 2, child: Text(r.phone, style: const TextStyle(color: Color(0xFF2B3674)))),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: (r.status == 'Active' ? const Color(0xFF05CD99) : Colors.orange).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        r.status,
                                                        style: TextStyle(
                                                          color: r.status == 'Active' ? const Color(0xFF05CD99) : Colors.orange,
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
                                                        onPressed: () => _showDetails(r),
                                                        tooltip: 'View Details',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                                        onPressed: () => _showForm(resident: r),
                                                        tooltip: 'Edit Resident',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                        onPressed: () => _deleteResident(r),
                                                        tooltip: 'Delete Resident',
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
