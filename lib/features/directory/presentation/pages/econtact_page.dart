import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/repositories/contact_repository.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final contactsProvider = FutureProvider<List<EmergencyContact>>((ref) {
  return ref.read(contactRepositoryProvider).getContacts();
});

IconData _contactIcon(String? category) {
  switch (category) {
    case 'management':
      return PhosphorIconsRegular.buildings;
    case 'security':
      return PhosphorIconsRegular.shieldCheck;
    case 'maintenance':
      return PhosphorIconsRegular.wrench;
    case 'utility':
      return PhosphorIconsRegular.lightning;
    default:
      return PhosphorIconsRegular.phone;
  }
}

class EContactPage extends ConsumerWidget {
  const EContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('E-Contact', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: contactsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))))),
              data: (contacts) {
                if (contacts.isEmpty) {
                  return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No contacts listed.', style: TextStyle(color: AppColors.textSecondary)))));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final c = contacts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(16)),
                            child: Icon(_contactIcon(c.category), color: AppColors.deepSlate, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(c.phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryBlue)),
                            if (c.hours != null && c.hours!.isNotEmpty) Text(c.hours!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ])),
                          GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${c.name} (${c.phone})…'), backgroundColor: AppColors.primaryBlue),
                            ),
                            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(PhosphorIconsRegular.phone, color: AppColors.primaryBlue, size: 20)),
                          ),
                        ]),
                      ),
                    );
                  }, childCount: contacts.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
