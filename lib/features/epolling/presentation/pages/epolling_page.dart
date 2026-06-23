import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
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
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  PhosphorIconsRegular.caretLeft,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'E-Polling',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              sliver: pollsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AppErrorState(
                      message: '$err',
                      onRetry: () => ref.invalidate(pollsProvider),
                    ),
                  ),
                ),
                data: (polls) {
                  if (polls.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: AppEmptyState(
                          icon: Icons.how_to_vote_rounded,
                          title: 'No active polls',
                          message:
                              'Community polls will appear here when they open for voting.',
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

                      return PremiumCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusPill(
                                  label: !poll.isActive
                                      ? 'CLOSED'
                                      : (hasVoted ? 'VOTED' : 'ACTIVE'),
                                  color: !poll.isActive
                                      ? AppColors.textSecondary
                                      : (hasVoted
                                            ? AppColors.success
                                            : AppColors.warning),
                                  dense: true,
                                ),
                                Text(
                                  _fmtDate(poll.endDate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              poll.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
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
                              final bool isLeading =
                                  totalVotes > 0 &&
                                  votes ==
                                      poll.options.fold<int>(0, (max, o) {
                                        final v = o['votes'] as int? ?? 0;
                                        return v > max ? v : max;
                                      });

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: (hasVoted || !userReady || !poll.isActive)
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
                                                    AppColors.brand,
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
                                          Expanded(
                                            child: Row(
                                              children: [
                                                if (!hasVoted && userReady) ...[
                                                  const Icon(
                                                    PhosphorIconsRegular.circle,
                                                    size: 16,
                                                    color: AppColors.brand,
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    option['label'] as String,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${(percent * 100).toInt()}%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: isLeading
                                                  ? AppColors.brand
                                                  : AppColors.textSecondary,
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: percent.clamp(
                                                0.0,
                                                1.0,
                                              ),
                                              child: Container(
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  gradient: isLeading
                                                      ? AppColors.brandGradient
                                                      : AppColors.skyGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  PhosphorIconsRegular.chartBar,
                                  size: 15,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$totalVotes total votes',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }, childCount: polls.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
