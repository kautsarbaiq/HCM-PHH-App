import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/repositories/poll_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

final adminPollsProvider = AsyncNotifierProvider<AdminPollsNotifier, List<Poll>>(
  () => AdminPollsNotifier(),
);

class AdminPollsNotifier extends AsyncNotifier<List<Poll>> {
  @override
  Future<List<Poll>> build() async {
    final repo = ref.read(pollRepositoryProvider);
    return repo.getAllPolls();
  }

  Future<void> addPoll({
    required String question,
    String? description,
    required List<String> optionLabels,
    DateTime? expiresAt,
  }) async {
    final repo = ref.read(pollRepositoryProvider);
    await repo.createPoll(
      question: question,
      description: description,
      optionLabels: optionLabels,
      expiresAt: expiresAt,
    );
    ref.invalidateSelf();
  }

  Future<void> updatePoll(String id, Map<String, dynamic> updates) async {
    final repo = ref.read(pollRepositoryProvider);
    await repo.updatePoll(id, updates);
    ref.invalidateSelf();
  }

  Future<void> closePoll(String id) async {
    final repo = ref.read(pollRepositoryProvider);
    await repo.closePoll(id);
    ref.invalidateSelf();
  }

  Future<void> deletePoll(String id) async {
    final repo = ref.read(pollRepositoryProvider);
    await repo.deletePoll(id);
    ref.invalidateSelf();
  }
}

class PollsAdminPage extends ConsumerStatefulWidget {
  const PollsAdminPage({super.key});

  @override
  ConsumerState<PollsAdminPage> createState() => _PollsAdminPageState();
}

class _PollsAdminPageState extends ConsumerState<PollsAdminPage> {
  String _formatDate(String iso) {
    if (iso.isEmpty) return 'No end date';
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

  void _showResults(Poll poll) {
    final total = poll.totalVotes;
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
              const Icon(Icons.bar_chart_rounded, color: AppColors.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.title,
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
                  Row(
                    children: [
                      StatusPill(
                        label: poll.isActive ? 'ACTIVE' : 'CLOSED',
                        color: poll.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                        dense: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ends ${_formatDate(poll.endDate)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (poll.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      poll.description,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...List.generate(poll.options.length, (i) {
                    final option = poll.options[i];
                    final label = (option['label'] ?? '').toString();
                    final votes = option['votes'] as int? ?? 0;
                    final percent = total > 0 ? (votes / total) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$votes votes  •  ${(percent * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percent.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.brandGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.how_to_vote_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$total total votes',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

  void _showForm() {
    final questionController = TextEditingController();
    final descriptionController = TextEditingController();
    final optionControllers = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];
    DateTime? expiresAt;
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
                'Create Poll',
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
                      _buildTextField(
                        questionController,
                        'Question',
                        Icons.help_outline,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        descriptionController,
                        'Description (optional)',
                        Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expiresAt ?? now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setDialogState(() => expiresAt = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End date (optional)',
                            prefixIcon: const Icon(
                              Icons.event,
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
                              borderSide: const BorderSide(
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                expiresAt == null
                                    ? 'No end date'
                                    : DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(expiresAt!),
                                style: TextStyle(
                                  color: expiresAt == null
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (expiresAt != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () =>
                                      setDialogState(() => expiresAt = null),
                                  tooltip: 'Clear end date',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(optionControllers.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  optionControllers[i],
                                  'Option ${i + 1}',
                                  Icons.radio_button_unchecked,
                                ),
                              ),
                              if (optionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => setDialogState(() {
                                    optionControllers.removeAt(i).dispose();
                                  }),
                                  tooltip: 'Remove option',
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => setDialogState(() {
                          optionControllers.add(TextEditingController());
                        }),
                        icon: const Icon(Icons.add, color: AppColors.brand),
                        label: const Text(
                          'Add option',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                          if (questionController.text.trim().isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a question.'),
                              ),
                            );
                            return;
                          }
                          final labels = optionControllers
                              .map((c) => c.text.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          if (labels.length < 2) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please provide at least 2 non-empty options.',
                                ),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSaving = true);
                          try {
                            await ref
                                .read(adminPollsProvider.notifier)
                                .addPoll(
                                  question: questionController.text.trim(),
                                  description:
                                      descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  optionLabels: labels,
                                  expiresAt: expiresAt,
                                );
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
                      : const Text('Create'),
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

  void _closePoll(Poll poll) {
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
            'Close Poll',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Close "${poll.title}"? Residents will no longer be able to vote.',
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
                      .read(adminPollsProvider.notifier)
                      .closePoll(poll.id);
                  navigator.pop();
                } catch (e) {
                  _showError(e);
                }
              },
              child: const Text(
                'Close Poll',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deletePoll(Poll poll) {
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
            'Delete Poll',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text('Are you sure you want to delete "${poll.title}"?'),
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
                      .read(adminPollsProvider.notifier)
                      .deletePoll(poll.id);
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
    final pollsAsync = ref.watch(adminPollsProvider);

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
                  title: 'Polling',
                  subtitle: 'Create and manage community polls',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create Poll'),
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
            child: pollsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminPollsProvider),
              ),
              data: (polls) {
                if (polls.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.how_to_vote_rounded,
                    title: 'No polls created yet',
                    message: 'Open your first community poll for voting.',
                    actionLabel: 'Create Poll',
                    onAction: () => _showForm(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminPollsProvider),
                  child: ListView.builder(
                    itemCount: polls.length,
                    itemBuilder: (context, index) {
                      final p = polls[index];
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GradientIconBadge(
                            icon: Icons.how_to_vote_rounded,
                            gradient: p.isActive
                                ? AppColors.brandGradient
                                : AppColors.skyGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: p.isActive ? 'ACTIVE' : 'CLOSED',
                                color: p.isActive
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
                                Text(
                                  'Ends ${_formatDate(p.endDate)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.totalVotes} total votes  •  ${p.options.length} options',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: AppColors.brand,
                                ),
                                onPressed: () => _showResults(p),
                                tooltip: 'View Results',
                              ),
                              if (p.isActive)
                                IconButton(
                                  icon: const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.accentAmber,
                                  ),
                                  onPressed: () => _closePoll(p),
                                  tooltip: 'Close Poll',
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.error,
                                ),
                                onPressed: () => _deletePoll(p),
                                tooltip: 'Delete Poll',
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
