import 'package:flutter/material.dart';

class Visitor {
  final String id;
  final String visitorName;
  final String hostResident;
  final String createdBy;
  final String timeIn;
  final String status;

  Visitor({
    required this.id,
    required this.visitorName,
    required this.hostResident,
    required this.createdBy,
    required this.timeIn,
    required this.status,
  });

  Visitor copyWith({
    String? id,
    String? visitorName,
    String? hostResident,
    String? createdBy,
    String? timeIn,
    String? status,
  }) {
    return Visitor(
      id: id ?? this.id,
      visitorName: visitorName ?? this.visitorName,
      hostResident: hostResident ?? this.hostResident,
      createdBy: createdBy ?? this.createdBy,
      timeIn: timeIn ?? this.timeIn,
      status: status ?? this.status,
    );
  }
}

class VisitorsAdminPage extends StatefulWidget {
  const VisitorsAdminPage({super.key});

  @override
  State<VisitorsAdminPage> createState() => _VisitorsAdminPageState();
}

class _VisitorsAdminPageState extends State<VisitorsAdminPage> {
  final List<Visitor> _visitors = List.generate(8, (index) {
    final createdByResident = index % 3 != 0;
    final isCheckedIn = index % 2 == 0;
    return Visitor(
      id: '${index + 1}',
      visitorName: 'Visitor Name ${index + 1}',
      hostResident: 'Resident ${index + 1}',
      createdBy: createdByResident ? 'Resident' : 'Security Guard',
      timeIn: '10:00 AM',
      status: isCheckedIn ? 'Checked In' : 'Expected',
    );
  });

  void _showDetails(Visitor visitor) {
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
              Text(
                visitor.visitorName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('ID', visitor.id),
              _buildDetailItem('Visitor Name', visitor.visitorName),
              _buildDetailItem('Host Resident', visitor.hostResident),
              _buildDetailItem('Log Created By', visitor.createdBy),
              _buildDetailItem('Expected Arrival / Time In', visitor.timeIn),
              _buildDetailItem('Log Status', visitor.status, isStatus: true),
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
                color: (value == 'Checked In' ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value == 'Checked In' ? const Color(0xFF05CD99) : const Color(0xFFFFB547),
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

  void _showForm({Visitor? visitor}) {
    final isEdit = visitor != null;
    final visitorController = TextEditingController(text: visitor?.visitorName ?? '');
    final hostController = TextEditingController(text: visitor?.hostResident ?? '');
    final timeController = TextEditingController(text: visitor?.timeIn ?? '10:00 AM');
    String createdBy = visitor?.createdBy ?? 'Security Guard';
    String status = visitor?.status ?? 'Expected';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Visitor Log' : 'Add Visitor Log',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(visitorController, 'Visitor Name', Icons.person),
                    _buildTextField(hostController, 'Host (Resident)', Icons.home),
                    _buildTextField(timeController, 'Time In / Arrival Time', Icons.access_time),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Created By: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Security'),
                          selected: createdBy == 'Security Guard',
                          selectedColor: const Color(0xFF4318FF).withOpacity(0.15),
                          checkmarkColor: const Color(0xFF4318FF),
                          onSelected: (val) {
                            if (val) setDialogState(() => createdBy = 'Security Guard');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Resident'),
                          selected: createdBy == 'Resident',
                          selectedColor: const Color(0xFF4318FF).withOpacity(0.15),
                          checkmarkColor: const Color(0xFF4318FF),
                          onSelected: (val) {
                            if (val) setDialogState(() => createdBy = 'Resident');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 32),
                        ChoiceChip(
                          label: const Text('Checked In'),
                          selected: status == 'Checked In',
                          selectedColor: const Color(0xFF05CD99).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF05CD99),
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Checked In');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Expected'),
                          selected: status == 'Expected',
                          selectedColor: const Color(0xFFFFB547).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFFFB547),
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Expected');
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
                    if (visitorController.text.isEmpty || hostController.text.isEmpty) return;
                    setState(() {
                      if (isEdit) {
                        final idx = _visitors.indexWhere((v) => v.id == visitor.id);
                        if (idx != -1) {
                          _visitors[idx] = visitor.copyWith(
                            visitorName: visitorController.text,
                            hostResident: hostController.text,
                            createdBy: createdBy,
                            timeIn: timeController.text,
                            status: status,
                          );
                        }
                      } else {
                        _visitors.add(Visitor(
                          id: '${_visitors.length + 1}',
                          visitorName: visitorController.text,
                          hostResident: hostController.text,
                          createdBy: createdBy,
                          timeIn: timeController.text,
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
              onPressed: () {
                setState(() {
                  _visitors.removeWhere((v) => v.id == visitor.id);
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
                    'Visitors Log',
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
                  label: const Text('Create Visitor Log'),
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
                  child: _visitors.isEmpty
                      ? const Center(child: Text('No visitors logged today', style: TextStyle(color: Color(0xFFA3AED0))))
                      : Column(
                          children: [
                            // Full-width Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              color: const Color(0xFFF4F7FE),
                              child: Row(
                                children: const [
                                  Expanded(flex: 3, child: Text('Visitor Name', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 3, child: Text('Host (Resident)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Created By', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Time In', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)), textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            // Scrollable list of rows stretching to 100% width
                            Expanded(
                              child: ListView.builder(
                                itemCount: _visitors.length,
                                itemBuilder: (context, index) {
                                  final v = _visitors[index];
                                  final isCheckedIn = v.status == 'Checked In';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFE0E5F2), width: 1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(v.visitorName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                                        Expanded(flex: 3, child: Text(v.hostResident, style: const TextStyle(color: Color(0xFF2B3674)))),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF4F7FE),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(v.createdBy, style: const TextStyle(color: Color(0xFF2B3674), fontSize: 12)),
                                            ),
                                          ),
                                        ),
                                        Expanded(flex: 2, child: Text(v.timeIn, style: const TextStyle(color: Color(0xFF2B3674)))),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: (isCheckedIn ? const Color(0xFF05CD99) : const Color(0xFFFFB547)).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                v.status,
                                                style: TextStyle(
                                                  color: isCheckedIn ? const Color(0xFF05CD99) : const Color(0xFFFFB547),
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
                                                onPressed: () => _showDetails(v),
                                                tooltip: 'View Details',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                                onPressed: () => _showForm(visitor: v),
                                                tooltip: 'Edit Visitor',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
