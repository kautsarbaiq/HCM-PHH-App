import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final contactsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {'name': 'Management Office', 'phone': '+60 3-8888 1234', 'hours': 'Mon-Fri, 9AM-6PM', 'icon': PhosphorIconsRegular.buildings},
      {'name': 'Guard House (Main)', 'phone': '+60 3-8888 5678', 'hours': '24 Hours', 'icon': PhosphorIconsRegular.shieldCheck},
      {'name': 'Maintenance Team', 'phone': '+60 12-333 4455', 'hours': 'Mon-Sat, 8AM-5PM', 'icon': PhosphorIconsRegular.wrench},
      {'name': 'TNB (Electricity)', 'phone': '15454', 'hours': '24 Hours', 'icon': PhosphorIconsRegular.lightning},
      {'name': 'Syabas (Water)', 'phone': '15300', 'hours': '24 Hours', 'icon': PhosphorIconsRegular.drop},
    ]);

class EContactPage extends ConsumerWidget {
  const EContactPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey, pinned: true,
            leading: IconButton(icon: const Icon(PhosphorIconsRegular.caretLeft), onPressed: () => context.pop()),
            title: const Text('E-Contact', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) {
              final c = contacts[index];
              return Padding(padding: const EdgeInsets.only(bottom: 16), child: GlassCard(padding: const EdgeInsets.all(20), child: Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(16)),
                  child: Icon(c['icon'], color: AppColors.deepSlate, size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(c['phone'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.sageGreen)),
                  Text(c['hours'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${c['name']}...'), backgroundColor: AppColors.sageGreen)),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.sageGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(PhosphorIconsRegular.phone, color: AppColors.sageGreen, size: 20))),
              ])));
            }, childCount: contacts.length)),
          ),
        ],
      ),
    );
  }
}
