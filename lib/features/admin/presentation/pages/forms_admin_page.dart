import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/form_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

// --- Forms catalog provider ---

final adminFormsProvider =
    AsyncNotifierProvider<AdminFormsNotifier, List<AppForm>>(
      () => AdminFormsNotifier(),
    );

class AdminFormsNotifier extends AsyncNotifier<List<AppForm>> {
  @override
  Future<List<AppForm>> build() async {
    final repo = ref.read(formRepositoryProvider);
    return repo.getAllForms();
  }

  Future<void> addForm({
    required String title,
    String? description,
    String? category,
    bool isActive = true,
  }) async {
    final repo = ref.read(formRepositoryProvider);
    await repo.createForm(
      title: title,
      description: description,
      category: category,
      isActive: isActive,
    );
    ref.invalidateSelf();
  }

  Future<void> updateForm(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(formRepositoryProvider);
    await repo.updateForm(id, updates);
    ref.invalidateSelf();
  }

  Future<void> deleteForm(String id) async {
    final repo = ref.read(formRepositoryProvider);
    await repo.deleteForm(id);
    ref.invalidateSelf();
  }
}

// --- Submissions inbox provider ---

final adminFormSubmissionsProvider =
    AsyncNotifierProvider<
      AdminFormSubmissionsNotifier,
      List<FormSubmission>
    >(() => AdminFormSubmissionsNotifier());

class AdminFormSubmissionsNotifier
    extends AsyncNotifier<List<FormSubmission>> {
  @override
  Future<List<FormSubmission>> build() async {
    final repo = ref.read(formRepositoryProvider);
    return repo.getAllSubmissions();
  }

  Future<void> setStatus(String id, String status) async {
    final repo = ref.read(formRepositoryProvider);
    await repo.updateSubmissionStatus(id, status);
    ref.invalidateSelf();
  }
}

class FormsAdminPage extends ConsumerStatefulWidget {
  const FormsAdminPage({super.key});

  @override
  ConsumerState<FormsAdminPage> createState() => _FormsAdminPageState();
}

class _FormsAdminPageState extends ConsumerState<FormsAdminPage> {
  String _statusFilter = 'all';

  String _formatDate(String iso) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // --- Forms CRUD form dialog ---

  void _showFormDialog({AppForm? form}) {
    final isEdit = form != null;
    final titleController = TextEditingController(text: form?.title ?? '');
    final descriptionController = TextEditingController(
      text: form?.description ?? '',
    );
    final categoryController = TextEditingController(text: form?.category ?? '');
    bool isActive = form?.isActive ?? true;
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
                isEdit ? 'Edit Form' : 'Create Form',
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
                      _buildTextField(
                        titleController,
                        'Title',
                        Icons.title,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        descriptionController,
                        'Description (optional)',
                        Icons.description,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        categoryController,
                        'Category (optional)',
                        Icons.category,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.success,
                        title: const Text(
                          'Active',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Only active forms are shown to residents',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: isActive,
                        onChanged: (val) =>
                            setDialogState(() => isActive = val),
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
                          if (titleController.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a form title.'),
                              ),
                            );
                            return;
                          }
                          final description =
                              descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text;
                          final category = categoryController.text.isEmpty
                              ? null
                              : categoryController.text;
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await ref
                                  .read(adminFormsProvider.notifier)
                                  .updateForm(form.id, {
                                    'title': titleController.text,
                                    'description': description,
                                    'category': category,
                                    'is_active': isActive,
                                  });
                            } else {
                              await ref
                                  .read(adminFormsProvider.notifier)
                                  .addForm(
                                    title: titleController.text,
                                    description: description,
                                    category: category,
                                    isActive: isActive,
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
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.textSecondary)
              : null,
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

  void _deleteForm(AppForm form) {
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
            'Delete Form',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text('Are you sure you want to delete "${form.title}"?'),
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
                      .read(adminFormsProvider.notifier)
                      .deleteForm(form.id);
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

  // --- Submission status dialog ---

  void _showSubmissionDialog(FormSubmission submission) {
    String selectedStatus = submission.status.isEmpty
        ? 'pending'
        : submission.status;
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
              title: const Text(
                'Review Submission',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.formTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Submitted by ${submission.residentName}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(submission.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Set status',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['approved', 'rejected'].map((status) {
                          final selected = selectedStatus == status;
                          final color = _statusColor(status);
                          return ChoiceChip(
                            label: Text(_statusLabel(status)),
                            selected: selected,
                            onSelected: (_) => setDialogState(
                              () => selectedStatus = status,
                            ),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : color,
                              fontWeight: FontWeight.w700,
                            ),
                            selectedColor: color,
                            backgroundColor: color.withOpacity(0.12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(color: color.withOpacity(0.4)),
                            ),
                          );
                        }).toList(),
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
                          final navigator = Navigator.of(context);
                          setDialogState(() => isSaving = true);
                          try {
                            await ref
                                .read(adminFormSubmissionsProvider.notifier)
                                .setStatus(submission.id, selectedStatus);
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
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Tab bodies ---

  Widget _buildFormsTab() {
    final formsAsync = ref.watch(adminFormsProvider);
    return formsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppErrorState(
        message: '$error',
        onRetry: () => ref.invalidate(adminFormsProvider),
      ),
      data: (forms) {
        if (forms.isEmpty) {
          return AppEmptyState(
            icon: Icons.description_rounded,
            title: 'No forms created yet',
            message: 'Create your first form for residents to submit.',
            actionLabel: 'Create Form',
            onAction: () => _showFormDialog(),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminFormsProvider),
          child: ListView.builder(
            itemCount: forms.length,
            itemBuilder: (context, index) {
              final f = forms[index];
              return PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const GradientIconBadge(
                    icon: Icons.description_rounded,
                    gradient: AppColors.brandGradient,
                    size: 46,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          f.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(
                        label: f.isActive ? 'ACTIVE' : 'INACTIVE',
                        color: f.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                        dense: true,
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (f.description != null &&
                            f.description!.isNotEmpty)
                          Text(
                            f.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (f.category != null && f.category!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            f.category!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
                          Icons.edit,
                          color: AppColors.accentAmber,
                        ),
                        onPressed: () => _showFormDialog(form: f),
                        tooltip: 'Edit Form',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: AppColors.error,
                        ),
                        onPressed: () => _deleteForm(f),
                        tooltip: 'Delete Form',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmissionsTab() {
    final submissionsAsync = ref.watch(adminFormSubmissionsProvider);
    return submissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppErrorState(
        message: '$error',
        onRetry: () => ref.invalidate(adminFormSubmissionsProvider),
      ),
      data: (submissions) {
        final filtered = _statusFilter == 'all'
            ? submissions
            : submissions
                  .where(
                    (s) =>
                        (s.status.isEmpty ? 'pending' : s.status)
                            .toLowerCase() ==
                        _statusFilter,
                  )
                  .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterChips(),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No submissions',
                      message:
                          'Resident form submissions will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(adminFormSubmissionsProvider),
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          final status = s.status.isEmpty
                              ? 'pending'
                              : s.status;
                          return PremiumCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            radius: 18,
                            padding: const EdgeInsets.all(16),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () => _showSubmissionDialog(s),
                              leading: const GradientIconBadge(
                                icon: Icons.assignment_turned_in_rounded,
                                gradient: AppColors.skyGradient,
                                size: 46,
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      s.formTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusPill(
                                    label: _statusLabel(status),
                                    color: _statusColor(status),
                                    dense: true,
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.residentName,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDate(s.createdAt),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.rule_rounded,
                                  color: AppColors.brand,
                                ),
                                onPressed: () => _showSubmissionDialog(s),
                                tooltip: 'Review Submission',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    const filters = {
      'all': 'All',
      'pending': 'Pending',
      'approved': 'Approved',
      'rejected': 'Rejected',
    };
    return Wrap(
      spacing: 8,
      children: filters.entries.map((entry) {
        final selected = _statusFilter == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => setState(() => _statusFilter = entry.key),
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          selectedColor: AppColors.brand,
          backgroundColor: AppColors.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: PremiumCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: SectionHeader(
                    title: 'E-Forms',
                    subtitle: 'Manage forms and review resident submissions',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Form'),
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
            const SizedBox(height: 16),
            const TabBar(
              isScrollable: true,
              labelColor: AppColors.brand,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.brand,
              labelStyle: TextStyle(fontWeight: FontWeight.w800),
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Forms'),
                Tab(text: 'Submissions'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFormsTab(),
                  _buildSubmissionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
