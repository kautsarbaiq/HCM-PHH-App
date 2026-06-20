import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';

import 'package:intl/intl.dart';

import '../../../../core/repositories/poll_repository.dart';
import '../../../../core/repositories/profile_repository.dart';

final pollsProvider = AsyncNotifierProvider<PollsNotifier, List<Poll>>(
  () => PollsNotifier(),
);

String _fmtDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    return 'Ends ${DateFormat('MMM dd, yyyy').format(DateTime.parse(iso).toLocal())}';
  } catch (_) {
    return iso;
  }
}

class PollsNotifier extends AsyncNotifier<List<Poll>> {
  @override
  Future<List<Poll>> build() async {
    final repo = ref.read(pollRepositoryProvider);
    return repo.getAllPolls();
  }

  Future<void> vote(String pollId, int optionIndex) async {
    await ref.read(pollRepositoryProvider).submitVote(pollId, optionIndex);
    ref.invalidateSelf();
  }
}

class EPollingPage extends ConsumerWidget {
  const EPollingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

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
            title: const Text(
              'E-Polling',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: pollsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              data: (polls) {
                if (polls.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No active polls.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                final userId = profileAsync.value?.id ?? '';
                // Only allow voting once we actually know who the user is.
                // While the profile is loading, userId is empty and the vote
                // UI must stay disabled to avoid duplicate/erroneous votes.
                final bool userReady = userId.isNotEmpty;

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final poll = polls[index];
                    final bool hasVoted = poll.voters.contains(userId);
                    final totalVotes = poll.totalVotes;

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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasVoted
                                        ? AppColors.primaryBlue.withOpacity(
                                            0.15,
                                          )
                                        : AppColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hasVoted ? 'VOTED' : 'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: hasVoted
                                          ? AppColors.primaryBlue
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                                Text(
                                  _fmtDate(poll.endDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              poll.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(poll.options.length, (i) {
                              final option = poll.options[i];
                              final votes = option['votes'] as int? ?? 0;
                              final percent = totalVotes > 0
                                  ? (votes / totalVotes)
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: (hasVoted || !userReady)
                                      ? null
                                      : () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          try {
                                            await ref
                                                .read(pollsProvider.notifier)
                                                .vote(poll.id, i);
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Vote recorded!'),
                                                backgroundColor:
                                                    AppColors.primaryBlue,
                                              ),
                                            );
                                          } catch (e) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '$e'
                                                      .replaceAll(
                                                        'PostgrestException(message: ',
                                                        '',
                                                      )
                                                      .split(',')[0],
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                          }
                                        },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              if (!hasVoted && userReady) ...[
                                                const Icon(
                                                  PhosphorIconsRegular.circle,
                                                  size: 16,
                                                  color: AppColors.primaryBlue,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                option['label'] as String,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${(percent * 100).toInt()}%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: percent,
                                          minHeight: 8,
                                          backgroundColor:
                                              AppColors.backgroundGrey,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                i == 0
                                                    ? AppColors.primaryBlue
                                                    : AppColors.deepSlate
                                                          .withOpacity(0.4),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            Text(
                              '$totalVotes total votes',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: polls.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
