import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/billing_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminBillingsProvider =
    AsyncNotifierProvider<AdminBillingsNotifier, List<Billing>>(
      () => AdminBillingsNotifier(),
    );

class AdminBillingsNotifier extends AsyncNotifier<List<Billing>> {
  @override
  Future<List<Billing>> build() async {
    final repo = ref.read(billingRepositoryProvider);
    return repo.getAllBillings();
  }

  Future<void> addBilling(Billing billing) async {
    final repo = ref.read(billingRepositoryProvider);
    await repo.createBilling(billing);
    ref.invalidateSelf();
  }

  Future<void> updateBilling(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(billingRepositoryProvider);
    await repo.updateBilling(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteBilling(String id) async {
    final repo = ref.read(billingRepositoryProvider);
    await repo.deleteBilling(id);
    ref.invalidateSelf();
  }
}

final _currencyFormat = NumberFormat('#,##0.00');
String _formatAmount(double amount) => 'RM ${_currencyFormat.format(amount)}';

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

({String label, Color color}) _statusStyle(String status) {
  switch (status) {
    case 'paid':
      return (label: 'Paid', color: AppColors.success);
    case 'overdue':
      return (label: 'Overdue', color: AppColors.warning);
    case 'unpaid':
    default:
      return (label: 'Unpaid', color: AppColors.error);
  }
}

class BillingsAdminPage extends ConsumerStatefulWidget {
  const BillingsAdminPage({super.key});

  @override
  ConsumerState<BillingsAdminPage> createState() => _BillingsAdminPageState();
}

class _BillingsAdminPageState extends ConsumerState<BillingsAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showDetails(Billing billing) {
    final status = _statusStyle(billing.status);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  billing.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Title', billing.title),
                _buildDetailItem('Resident', billing.resident?.fullName ?? '-'),
                _buildDetailItem('Amount', _formatAmount(billing.amount)),
                _buildDetailItem(
                  'Period',
                  billing.period?.isNotEmpty == true ? billing.period! : '-',
                ),
                _buildDetailItem('Due Date', _formatDate(billing.dueDate)),
                _buildDetailItem(
                  'Status',
                  status.label,
                  statusColor: status.color,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.brand),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          if (statusColor != null)
            StatusPill(label: value, color: statusColor)
          else
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  void _showForm({Billing? billing}) {
    final isEdit = billing != null;
    final residentsAsync = ref.read(adminResidentsProvider);

    // If the residents list is still loading, don't misreport "none assigned".
    if (residentsAsync.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading residents… please try again in a moment.'),
        ),
      );
      return;
    }

    final residents = (residentsAsync.valueOrNull ?? [])
        .where((r) => r.houseId != null && r.houseId!.isNotEmpty)
        .toList();

    if (residents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No residents with an assigned house. Assign a house to a resident first.',
          ),
        ),
      );
      return;
    }

    final defaultInvoice =
        'INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
    final invoiceController = TextEditingController(
      text: billing?.invoiceNumber ?? defaultInvoice,
    );
    final titleController = TextEditingController(
      text: billing?.title ?? 'Monthly Maintenance',
    );
    final amountController = TextEditingController(
      // Preserve the real amount when editing — show cents if present, drop a
      // trailing ".0" for whole numbers. (toStringAsFixed(0) would round and
      // silently discard the cents on save.)
      text: billing != null
          ? (billing.amount == billing.amount.truncateToDouble()
                ? billing.amount.toStringAsFixed(0)
                : billing.amount.toString())
          : '',
    );
    final periodController = TextEditingController(text: billing?.period ?? '');

    String? selectedResidentId =
        (billing != null && residents.any((r) => r.id == billing.residentId))
        ? billing.residentId
        : null;
    String status = billing?.status ?? 'unpaid';
    bool isSaving = false;
    DateTime dueDate = () {
      if (billing?.dueDate != null) {
        try {
          return DateTime.parse(billing!.dueDate!);
        } catch (_) {}
      }
      return DateTime.now().add(const Duration(days: 14));
    }();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isEdit ? 'Edit Billing Invoice' : 'Create Billing Invoice',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      invoiceController,
                      'Invoice Number',
                      Icons.bookmark_outline,
                    ),
                    _buildTextField(
                      titleController,
                      'Title (e.g. Monthly Maintenance)',
                      Icons.title,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedResidentId,
                      isExpanded: true,
                      decoration: _inputDecoration('Resident', Icons.person),
                      items: residents
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                r.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedResidentId = val),
                    ),
                    _buildTextField(
                      amountController,
                      'Amount (numbers only)',
                      Icons.attach_money,
                      isNumeric: true,
                    ),
                    _buildTextField(
                      periodController,
                      'Period (e.g. June 2026) — optional',
                      Icons.event_note,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          'Due Date',
                          Icons.calendar_today,
                        ),
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(dueDate),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              _statusChip(
                                'Unpaid',
                                'unpaid',
                                status,
                                AppColors.error,
                                (v) => setDialogState(() => status = v),
                              ),
                              _statusChip(
                                'Paid',
                                'paid',
                                status,
                                AppColors.success,
                                (v) => setDialogState(() => status = v),
                              ),
                              _statusChip(
                                'Overdue',
                                'overdue',
                                status,
                                AppColors.warning,
                                (v) => setDialogState(() => status = v),
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
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final amountVal = double.tryParse(
                            amountController.text,
                          );
                          if (invoiceController.text.isEmpty ||
                              titleController.text.isEmpty ||
                              selectedResidentId == null ||
                              amountVal == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill invoice, title, resident, and a valid amount.',
                                ),
                              ),
                            );
                            return;
                          }
                          final resident = residents.firstWhere(
                            (r) => r.id == selectedResidentId,
                          );
                          final dueIso = DateFormat(
                            'yyyy-MM-dd',
                          ).format(dueDate);
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminBillingsProvider.notifier)
                                  .updateBilling(billing.id, {
                                    'invoice_number': invoiceController.text,
                                    'title': titleController.text,
                                    'resident_id': resident.id,
                                    'house_id': resident.houseId,
                                    'amount': amountVal,
                                    'due_date': dueIso,
                                    'period': periodController.text.isEmpty
                                        ? null
                                        : periodController.text,
                                    'status': status,
                                  });
                            } else {
                              await ref
                                  .read(adminBillingsProvider.notifier)
                                  .addBilling(
                                    Billing(
                                      id: '',
                                      invoiceNumber: invoiceController.text,
                                      title: titleController.text,
                                      amount: amountVal,
                                      dueDate: dueIso,
                                      status: status,
                                      period: periodController.text.isEmpty
                                          ? null
                                          : periodController.text,
                                      residentId: resident.id,
                                      houseId: resident.houseId!,
                                    ),
                                  );
                            }
                            navigator.pop();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showError(e);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statusChip(
    String label,
    String value,
    String selected,
    Color color,
    ValueChanged<String> onSelect,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      onSelected: (val) {
        if (val) onSelect(value);
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
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
        borderSide: const BorderSide(color: AppColors.brand),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: _inputDecoration(label, icon),
      ),
    );
  }

  void _deleteBilling(Billing billing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Invoice',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${billing.invoiceNumber}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref
                      .read(adminBillingsProvider.notifier)
                      .deleteBilling(billing.id);
                  navigator.pop();
                } catch (e) {
                  _showError(e);
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingsAsync = ref.watch(adminBillingsProvider);
    // Warm the residents list so the create/edit form has data ready.
    ref.watch(adminResidentsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Billings & Payments',
                  subtitle: 'Manage invoices and resident payments',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Billing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: billingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminBillingsProvider),
              ),
              data: (billings) {
                if (billings.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No invoices found',
                    message:
                        'Create your first billing invoice to get started.',
                    actionLabel: 'Create Billing',
                    onAction: () => _showForm(),
                    gradient: AppColors.mintGradient,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // On narrow phones, render a vertical card list instead of a wide table.
                    if (constraints.maxWidth < 600) {
                      return ListView.separated(
                        itemCount: billings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildBillingCard(billings[index]),
                      );
                    }
                    final tableWidth = constraints.maxWidth > 760
                        ? constraints.maxWidth
                        : 760.0;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.surfaceTint,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  color: AppColors.surfaceTint,
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Invoice No',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Resident',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Amount',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Due Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Actions',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: billings.length,
                                    itemBuilder: (context, index) {
                                      final b = billings[index];
                                      final status = _statusStyle(b.status);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFE0E5F2),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                b.invoiceNumber,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                b.resident?.fullName ?? '-',
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatAmount(b.amount),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                _formatDate(b.dueDate),
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: StatusPill(
                                                  label: status.label,
                                                  color: status.color,
                                                  dense: true,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.visibility,
                                                      color: AppColors.brand,
                                                      size: 18,
                                                    ),
                                                    onPressed: () =>
                                                        _showDetails(b),
                                                    tooltip:
                                                        'View Invoice Details',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color:
                                                          AppColors.accentAmber,
                                                      size: 18,
                                                    ),
                                                    onPressed: () =>
                                                        _showForm(billing: b),
                                                    tooltip: 'Edit Invoice',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: AppColors.error,
                                                      size: 18,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteBilling(b),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Compact card used for the narrow-phone billings layout.
  Widget _buildBillingCard(Billing b) {
    final status = _statusStyle(b.status);
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBadge(
                icon: Icons.receipt_long_rounded,
                gradient: AppColors.brandGradient,
                size: 42,
                iconSize: 20,
                radius: 13,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  b.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: status.label, color: status.color, dense: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Resident: ${b.resident?.fullName ?? '-'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            'Amount: ${_formatAmount(b.amount)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Due: ${_formatDate(b.dueDate)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.visibility,
                  color: AppColors.brand,
                  size: 20,
                ),
                onPressed: () => _showDetails(b),
                tooltip: 'View Invoice Details',
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.accentAmber,
                  size: 20,
                ),
                onPressed: () => _showForm(billing: b),
                tooltip: 'Edit Invoice',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _deleteBilling(b),
                tooltip: 'Delete Invoice',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
