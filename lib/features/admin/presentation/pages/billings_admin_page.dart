import 'package:flutter/material.dart';

class Billing {
  final String id;
  final String invoiceNo;
  final String resident;
  final int amount;
  final String dueDate;
  final String status;

  Billing({
    required this.id,
    required this.invoiceNo,
    required this.resident,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  Billing copyWith({
    String? id,
    String? invoiceNo,
    String? resident,
    int? amount,
    String? dueDate,
    String? status,
  }) {
    return Billing(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      resident: resident ?? this.resident,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
}

class BillingsAdminPage extends StatefulWidget {
  const BillingsAdminPage({super.key});

  @override
  State<BillingsAdminPage> createState() => _BillingsAdminPageState();
}

class _BillingsAdminPageState extends State<BillingsAdminPage> {
  final List<Billing> _billings = List.generate(8, (index) {
    final isPaid = index % 2 == 0;
    return Billing(
      id: '${index + 1}',
      invoiceNo: 'INV-2023-${1000 + index}',
      resident: 'Resident ${index + 1}',
      amount: 500000 + (index * 50000),
      dueDate: 'Oct ${10 + index}, 2023',
      status: isPaid ? 'Paid' : 'Unpaid',
    );
  });

  void _showDetails(Billing billing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF4318FF)),
              const SizedBox(width: 8),
              Text(
                billing.invoiceNo,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Invoice ID', billing.id),
              _buildDetailItem('Resident Name', billing.resident),
              _buildDetailItem('Billing Amount', 'Rp ${billing.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'),
              _buildDetailItem('Due Date', billing.dueDate),
              _buildDetailItem('Payment Status', billing.status, isStatus: true),
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
                color: (value == 'Paid' ? const Color(0xFF05CD99) : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value == 'Paid' ? const Color(0xFF05CD99) : Colors.red,
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

  void _showForm({Billing? billing}) {
    final isEdit = billing != null;
    final invoiceController = TextEditingController(text: billing?.invoiceNo ?? 'INV-2023-${1000 + _billings.length}');
    final residentController = TextEditingController(text: billing?.resident ?? '');
    final amountController = TextEditingController(text: billing?.amount.toString() ?? '');
    final dateController = TextEditingController(text: billing?.dueDate ?? 'Oct 15, 2023');
    String status = billing?.status ?? 'Unpaid';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEdit ? 'Edit Billing Invoice' : 'Create Billing Invoice',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(invoiceController, 'Invoice Number', Icons.bookmark_outline),
                    _buildTextField(residentController, 'Resident Name', Icons.person),
                    _buildTextField(amountController, 'Amount (in Rupiah, numbers only)', Icons.attach_money, isNumeric: true),
                    _buildTextField(dateController, 'Due Date', Icons.calendar_today),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(color: Color(0xFF2B3674), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('Paid'),
                          selected: status == 'Paid',
                          selectedColor: const Color(0xFF05CD99).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF05CD99),
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Paid');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Unpaid'),
                          selected: status == 'Unpaid',
                          selectedColor: Colors.red.withOpacity(0.2),
                          checkmarkColor: Colors.red,
                          onSelected: (val) {
                            if (val) setDialogState(() => status = 'Unpaid');
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
                    if (residentController.text.isEmpty || amountController.text.isEmpty) return;
                    setState(() {
                      final amountVal = int.tryParse(amountController.text) ?? 0;

                      if (isEdit) {
                        final idx = _billings.indexWhere((b) => b.id == billing.id);
                        if (idx != -1) {
                          _billings[idx] = billing.copyWith(
                            invoiceNo: invoiceController.text,
                            resident: residentController.text,
                            amount: amountVal,
                            dueDate: dateController.text,
                            status: status,
                          );
                        }
                      } else {
                        _billings.add(Billing(
                          id: '${_billings.length + 1}',
                          invoiceNo: invoiceController.text,
                          resident: residentController.text,
                          amount: amountVal,
                          dueDate: dateController.text,
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
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

  void _deleteBilling(Billing billing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674))),
          content: Text('Are you sure you want to delete ${billing.invoiceNo}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _billings.removeWhere((b) => b.id == billing.id);
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
                    'Billings & Payments',
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
                  child: _billings.isEmpty
                      ? const Center(child: Text('No invoices found', style: TextStyle(color: Color(0xFFA3AED0))))
                      : Column(
                          children: [
                            // Full-width Table Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              color: const Color(0xFFF4F7FE),
                              child: Row(
                                children: const [
                                  Expanded(flex: 3, child: Text('Invoice No', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 3, child: Text('Resident', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)))),
                                  Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFA3AED0)), textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            // Scrollable list of rows stretching to 100% width
                            Expanded(
                              child: ListView.builder(
                                itemCount: _billings.length,
                                itemBuilder: (context, index) {
                                  final b = _billings[index];
                                  final isPaid = b.status == 'Paid';
                                  final formattedAmount = 'Rp ${b.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFE0E5F2), width: 1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(b.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B3674)))),
                                        Expanded(flex: 3, child: Text(b.resident, style: const TextStyle(color: Color(0xFF2B3674)))),
                                        Expanded(flex: 2, child: Text(formattedAmount, style: const TextStyle(color: Color(0xFF2B3674)))),
                                        Expanded(flex: 2, child: Text(b.dueDate, style: const TextStyle(color: Color(0xFF2B3674)))),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: (isPaid ? const Color(0xFF05CD99) : Colors.red).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                b.status,
                                                style: TextStyle(
                                                  color: isPaid ? const Color(0xFF05CD99) : Colors.red,
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
                                                onPressed: () => _showDetails(b),
                                                tooltip: 'View Invoice Details',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                                onPressed: () => _showForm(billing: b),
                                                tooltip: 'Edit Invoice',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                                onPressed: () => _deleteBilling(b),
                                                tooltip: 'Delete Invoice',
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
