import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';

class GuardsAdminPage extends ConsumerStatefulWidget {
  const GuardsAdminPage({super.key});

  @override
  ConsumerState<GuardsAdminPage> createState() => _GuardsAdminPageState();
}

class _GuardsAdminPageState extends ConsumerState<GuardsAdminPage> {
  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red),
    );
  }

  void _showForm(Profile guard) {
    final shiftController = TextEditingController(text: guard.shift ?? '');
    final postController = TextEditingController(text: guard.post ?? '');
    bool onDuty = guard.onDuty;
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
                'Manage ${guard.fullName}',
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.success,
                        title: const Text(
                          'On Duty',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'On-duty guards are highlighted in the directory',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        value: onDuty,
                        onChanged: (val) =>
                            setDialogState(() => onDuty = val),
                      ),
                      _buildTextField(
                        shiftController,
                        'Shift (e.g. 8AM - 4PM)',
                        Icons.schedule,
                      ),
                      const SizedBox(height: 4),
                      _buildTextField(
                        postController,
                        'Post (e.g. Main Gate)',
                        Icons.location_on,
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
                                .read(adminRepositoryProvider)
                                .updateGuardDuty(
                                  guard.id,
                                  shift: shiftController.text.isEmpty
                                      ? null
                                      : shiftController.text,
                                  post: postController.text.isEmpty
                                      ? null
                                      : postController.text,
                                  onDuty: onDuty,
                                );
                            ref.invalidate(adminGuardsProvider);
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
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

  @override
  Widget build(BuildContext context) {
    final guardsAsync = ref.watch(adminGuardsProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Security Guards',
                  subtitle: 'Manage guard duty status, shift and post',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: guardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorState(
                message: '$error',
                onRetry: () => ref.invalidate(adminGuardsProvider),
              ),
              data: (guards) {
                if (guards.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.shield_rounded,
                    title: 'No guards found',
                    message:
                        'Guard accounts (role = guard) will appear here once created.',
                    gradient: AppColors.skyGradient,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminGuardsProvider),
                  child: ListView.builder(
                    itemCount: guards.length,
                    itemBuilder: (context, index) {
                      final g = guards[index];
                      final detail = [
                        g.post,
                        g.shift,
                      ].where((e) => e != null && e.isNotEmpty).join(' — ');
                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        radius: 18,
                        padding: const EdgeInsets.all(16),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: GradientIconBadge(
                            icon: Icons.shield_rounded,
                            gradient: g.onDuty
                                ? AppColors.skyGradient
                                : AppColors.brandGradient,
                            size: 46,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  g.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(
                                label: g.onDuty ? 'ON DUTY' : 'OFF DUTY',
                                color: g.onDuty
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                dense: true,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              detail.isEmpty ? 'Security Guard' : detail,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.accentAmber,
                            ),
                            onPressed: () => _showForm(g),
                            tooltip: 'Edit Duty',
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
