import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../theme/app_colors.dart';

/// One residential community (condo/apartment complex). Residents join it at
/// signup by entering [code].
class Community {
  final String id;
  final String code;
  final String name;
  final String? address;

  Community({
    required this.id,
    required this.code,
    required this.name,
    this.address,
  });

  factory Community.fromJson(Map<String, dynamic> json) => Community(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,
  );
}

final adminCommunitiesProvider =
    AsyncNotifierProvider<AdminCommunitiesNotifier, List<Community>>(
      () => AdminCommunitiesNotifier(),
    );

class AdminCommunitiesNotifier extends AsyncNotifier<List<Community>> {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Community>> build() async {
    final rows = await _db.from('communities').select().order('code');
    return (rows as List).map((j) => Community.fromJson(j)).toList();
  }

  Future<void> save({
    String? id,
    required String code,
    required String name,
    String? address,
  }) async {
    final data = {
      'code': code,
      'name': name,
      'address': (address?.trim().isEmpty ?? true) ? null : address!.trim(),
    };
    if (id == null) {
      await _db.from('communities').insert(data);
    } else {
      await _db.from('communities').update(data).eq('id', id);
    }
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await _db.from('communities').delete().eq('id', id);
    ref.invalidateSelf();
  }
}

/// Admin: list of residence communities (code + name), with add/edit/delete —
/// the codes residents enter when signing up on the mobile app.
class CommunitiesAdminPage extends ConsumerStatefulWidget {
  const CommunitiesAdminPage({super.key});

  @override
  ConsumerState<CommunitiesAdminPage> createState() =>
      _CommunitiesAdminPageState();
}

class _CommunitiesAdminPageState extends ConsumerState<CommunitiesAdminPage> {
  void _showEditor({Community? existing}) {
    final codeController = TextEditingController(text: existing?.code ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final addressController = TextEditingController(
      text: existing?.address ?? '',
    );
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            existing == null ? 'Add Community' : 'Edit Community',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Community code (3-6 digit, e.g. 001)',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Community name (e.g. Sunway Apartments)',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address — optional',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
              onPressed: saving
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      final name = nameController.text.trim();
                      if (!RegExp(r'^\d{3,6}$').hasMatch(code)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code must be 3-6 digits.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Community name is required.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await ref
                            .read(adminCommunitiesProvider.notifier)
                            .save(
                              id: existing?.id,
                              code: code,
                              name: name,
                              address: addressController.text,
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$e'.contains('duplicate')
                                    ? 'That code is already used.'
                                    : 'Failed: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Community c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Community',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Delete "${c.code} – ${c.name}"? Residents already linked to it '
          'keep working, but new signups with this code will be rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(adminCommunitiesProvider.notifier)
                    .delete(c.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communitiesAsync = ref.watch(adminCommunitiesProvider);

    return PremiumCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Communities',
                  subtitle:
                      'Residence community codes used at mobile-app signup',
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                ),
                onPressed: () => _showEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Community'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: communitiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorState(
                message: 'Could not load communities: $e',
                onRetry: () => ref.invalidate(adminCommunitiesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.apartment_rounded,
                    title: 'No communities yet',
                    message:
                        'Add a community code so residents can sign up with it.',
                    gradient: AppColors.skyGradient,
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = items[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            c.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: (c.address?.isNotEmpty ?? false)
                          ? Text(
                              c.address!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.brand,
                              size: 20,
                            ),
                            tooltip: 'Edit',
                            onPressed: () => _showEditor(existing: c),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(c),
                          ),
                        ],
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
}
