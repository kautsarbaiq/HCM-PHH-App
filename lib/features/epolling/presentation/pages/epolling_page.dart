import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

final pollsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {
        'title': 'Should we extend pool hours to 10 PM?',
        'totalVotes': 89,
        'endDate': 'Ends Nov 10, 2026',
        'options': [
          {'label': 'Yes', 'votes': 62, 'percent': 0.70},
          {'label': 'No', 'votes': 27, 'percent': 0.30},
        ],
        'hasVoted': true,
      },
      {
        'title': 'Preferred day for monthly Townhall?',
        'totalVotes': 45,
        'endDate': 'Ends Nov 20, 2026',
        'options': [
          {'label': 'Saturday', 'votes': 20, 'percent': 0.44},
          {'label': 'Sunday', 'votes': 18, 'percent': 0.40},
          {'label': 'Weekday Eve', 'votes': 7, 'percent': 0.16},
        ],
        'hasVoted': false,
      },
    ]);

class EPollingPage extends ConsumerWidget {
  const EPollingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polls = ref.watch(pollsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.backgroundGrey,
            pinned: true,
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.caretLeft),
              onPressed: () => context.pop(),
            ),
            title: const Text('E-Polling', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final poll = polls[index];
                  final bool hasVoted = poll['hasVoted'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hasVoted ? AppColors.sageGreen.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hasVoted ? 'VOTED' : 'ACTIVE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: hasVoted ? AppColors.sageGreen : AppColors.warning),
                                ),
                              ),
                              Text(poll['endDate'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(poll['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          ...List.generate(
                            (poll['options'] as List).length,
                            (i) {
                              final option = poll['options'][i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(option['label'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                        Text('${(option['percent'] * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sageGreen)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: option['percent'],
                                        minHeight: 8,
                                        backgroundColor: AppColors.backgroundGrey,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          i == 0 ? AppColors.sageGreen : AppColors.deepSlate.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text('${poll['totalVotes']} total votes', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                },
                childCount: polls.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
