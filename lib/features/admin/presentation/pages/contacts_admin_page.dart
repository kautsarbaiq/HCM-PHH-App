import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/contact_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

const List<String> _kContactCategories = [
  'management',
  'security',
  'maintenance',
  'utility',
  'other',
];

IconData _categoryIcon(String? category) {
  switch (category) {
    case 'management':
      return Icons.apartment_rounded;
    case 'security':
      return Icons.shield_rounded;
    case 'maintenance':
      return Icons.build_rounded;
    case 'utility':
      return Icons.bolt_rounded;
    default:
      return Icons.contact_phone_rounded;
  }
}

LinearGradient _categoryGradient(String? category) {
  switch (category) {
    case 'management':
      return AppColors.brandGradient;
    case 'security':
      return AppColors.skyGradient;
    case 'maintenance':
      return AppColors.sunsetGradient;
    case 'utility':
      return AppColors.mintGradient;
    default:
      return AppColors.brandGradient;
  }
}

class ContactsAdminPage extends ConsumerStatefulWidget {
  const ContactsAdminPage({super.key});

  @override
  ConsumerState<ContactsAdminPage> createState() => _ContactsAdminPageState();
}

class _ContactsAdminPageState extends ConsumerState<ContactsAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showForm({EmergencyContact? contact}) {
    final isEdit = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final hoursController = TextEditingController(text: contact?.hours ?? '');
    final sortController = TextEditingController(
      text: (contact?.sortOrder ?? 0).toString(),
    );
    String category =
        (contact?.category != null &&
            _kContactCategories.contains(contact!.category))
        ? contact.category!
        : 'other';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Text(
                isEdit ? 'Edit Contact' : 'Add Contact',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(nameController, 'Name', Icons.person),
                      const SizedBox(height: 4),
                      _buildTextField(phoneController, 'Phone', Icons.phone),
                      const SizedBox(height: 4),
                      _buildTextField(
                        hoursController,
                        'Hours (optional)',
                        Icons.schedule,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(
                            Icons.category,
                            color: AppColors.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E5F2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E5F2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.brand),
                          ),
                        ),
                        items: _kContactCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c[0].toUpperCase() + c.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setDialogState(
                          () => category = val ?? category,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        sortController,
                        'Sort order',
                        Icons.sort,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
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
                          if (nameController.text.isEmpty ||
                              phoneController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter both a name and phone.',
                                ),
                              ),
                            );
                            return;
                          }
                          final sortOrder =
                              int.tryParse(sortController.text) ?? 0;
                          setDialogState(() => isSaving = true);
                          try {
                            final repo = ref.read(contactRepositoryProvider);
                            if (isEdit) {
                              await repo.updateContact(contact.id, {
                                'name': nameController.text,
                                'phone': phoneController.text,
                                'hours': hoursController.text.isEmpty
                                    ? null
                                    : hoursController.text,
                                'category': category,
                                'sort_order': sortOrder,
                              });
                            } else {
                              await repo.createContact(
                                name: nameController.text,
                                phone: phoneController.text,
                                hours: hoursController.text.isEmpty
                                    ? null
                                    : hoursController.text,
                                category: category,
                                sortOrder: sortOrder,
                              );
                            }
                            ref.invalidate(adminContactsProvider);
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
                      : Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
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
        ),
      ),
    );
  }

  void _showDetails(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Icon(_categoryIcon(contact.category), color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contact.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.phone,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (contact.hours != null && contact.hours!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      contact.hours!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${contact.category ?? 'other'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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

  void _deleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: const Text(
            'Delete Contact',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text('Are you sure you want to delete "${contact.name}"?'),
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
                      .read(contactRepositoryProvider)
                      .deleteContact(contact.id);
                  ref.invalidate(adminContactsProvider);
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
    final contactsAsync = ref.watch(adminContactsProvider);

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
                  title: 'E-Contacts',
                  subtitle: 'Manage emergency and community contacts',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Contact'),
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
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminContactsProvider),
              ),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.contact_phone_rounded,
                    title: 'No contacts yet',
                    message: 'Add an emergency or community contact to begin.',
                    actionLabel: 'Add Contact',
                    onAction: () => _showForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminContactsProvider),
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final c = contacts[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GradientIconBadge(
                            icon: _categoryIcon(c.category),
                            gradient: _categoryGradient(c.category),
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: (c.category ?? 'other').toUpperCase(),
                                color: AppColors.brand,
                                dense: true,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.phone,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (c.hours != null && c.hours!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    c.hours!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: AppColors.brand,
                                ),
                                onPressed: () => _showDetails(c),
                                tooltip: 'View Contact',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.accentAmber,
                                ),
                                onPressed: () => _showForm(contact: c),
                                tooltip: 'Edit Contact',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deleteContact(c),
                                tooltip: 'Delete Contact',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
