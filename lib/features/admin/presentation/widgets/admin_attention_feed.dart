import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/repositories/admin_attention_repository.dart';
import '../../../../core/repositories/admin_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../theme/app_colors.dart';

/// HCA admin dashboard: pending signups (approve/reject inline) plus counts of
/// event proposals, facility bookings and form submissions awaiting review.
class AdminAttentionFeed extends ConsumerWidget {
  const AdminAttentionFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAttention = ref.watch(adminAttentionProvider);

    return asyncAttention.when(
      loading: () => const PremiumCard(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brand,
            ),
          ),
        ),
      ),
      error: (e, _) => PremiumCard(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load pending items: $e',
          style: const TextStyle(color: AppColors.error, fontSize: 13),
        ),
      ),
      data: (a) {
        if (a.isEmpty) {
          return PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const GradientIconBadge(
                  icon: Icons.check_circle_rounded,
                  gradient: AppColors.mintGradient,
                  size: 50,
                  iconSize: 24,
                  radius: 16,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'All caught up',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nothing is waiting for your approval right now.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            children: [
              for (final s in a.signups)
                _SignupRow(signup: s),
              if (a.pendingEvents > 0)
                _CountRow(
                  icon: Icons.celebration_rounded,
                  gradient: AppColors.sunsetGradient,
                  title:
                      '${a.pendingEvents} event proposal${a.pendingEvents == 1 ? '' : 's'} to review',
                  subtitle: 'Residents are waiting for approval',
                  onTap: () => context.go('/admin/events'),
                ),
              if (a.pendingBookings > 0)
                _CountRow(
                  icon: Icons.event_available_rounded,
                  gradient: AppColors.skyGradient,
                  title:
                      '${a.pendingBookings} facility booking${a.pendingBookings == 1 ? '' : 's'} to approve',
                  subtitle: 'Confirm or reject the requests',
                  onTap: () => context.go('/admin/bookings'),
                ),
              if (a.pendingForms > 0)
                _CountRow(
                  icon: Icons.description_rounded,
                  gradient: AppColors.brandGradient,
                  title:
                      '${a.pendingForms} form submission${a.pendingForms == 1 ? '' : 's'} to review',
                  subtitle: 'Applications from residents',
                  onTap: () => context.go('/admin/forms'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SignupRow extends ConsumerStatefulWidget {
  final PendingSignup signup;
  const _SignupRow({required this.signup});

  @override
  ConsumerState<_SignupRow> createState() => _SignupRowState();
}

class _SignupRowState extends ConsumerState<_SignupRow> {
  bool _busy = false;

  Future<void> _act({required bool approve}) async {
    if (_busy) return;
    if (!approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Reject this signup?'),
          content: Text(
            '${widget.signup.email} will be removed and cannot log in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(adminAttentionRepositoryProvider);
      if (approve) {
        await repo.approveSignup(widget.signup.userId);
      } else {
        await repo.rejectSignup(widget.signup.userId);
      }
      ref.invalidate(adminAttentionProvider);
      ref.invalidate(adminResidentsProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? '${widget.signup.email} approved — they can log in now.'
                : '${widget.signup.email} rejected and removed.',
          ),
          backgroundColor: approve ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.signup;
    String since = '';
    try {
      since = DateFormat('MMM d').format(DateTime.parse(s.createdAt).toLocal());
    } catch (_) {}
    return ListTile(
      leading: const GradientIconBadge(
        icon: Icons.person_add_alt_1_rounded,
        gradient: AppColors.sunsetGradient,
        size: 44,
        iconSize: 20,
        radius: 14,
      ),
      title: Text(
        s.fullName.isEmpty ? s.email : s.fullName,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        'New account waiting for approval'
        '${since.isEmpty ? '' : ' • $since'}\n${s.email}',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      isThreeLine: true,
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  tooltip: 'Approve',
                  onPressed: () => _act(approve: true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: AppColors.error),
                  tooltip: 'Reject',
                  onPressed: () => _act(approve: false),
                ),
              ],
            ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CountRow({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: GradientIconBadge(
        icon: icon,
        gradient: gradient,
        size: 44,
        iconSize: 20,
        radius: 14,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 14.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
    );
  }
}
