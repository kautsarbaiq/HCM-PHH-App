import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/repositories/emergency_repository.dart';
import '../../../../core/services/emergency_alarm.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';

/// Live banner that surfaces any ACTIVE emergency on a dashboard. Shows nothing
/// when there are no active alerts. Used by residents (read-only) and by admin
/// and guard ([canResolve] true → a Resolve button per alert).
///
/// While at least one alert is showing it also drives a continuous buzzer
/// ([EmergencyAlarm]) that stops the moment the alert is cancelled/cleared.
class ActiveEmergencyBanner extends ConsumerStatefulWidget {
  final bool canResolve;
  const ActiveEmergencyBanner({super.key, this.canResolve = false});

  @override
  ConsumerState<ActiveEmergencyBanner> createState() =>
      _ActiveEmergencyBannerState();
}

class _ActiveEmergencyBannerState extends ConsumerState<ActiveEmergencyBanner> {
  static const _red = Color(0xFFEF4444);

  bool get canResolve => widget.canResolve;

  @override
  void dispose() {
    // Leaving the screen (logout, navigation) must silence the buzzer.
    EmergencyAlarm.instance.setActive(false);
    super.dispose();
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'panic':
        return 'PANIC';
      case 'community':
        return 'COMMUNITY';
      case 'rollcall':
        return 'ROLL CALL';
      case 'contact':
        return 'CONTACTS';
      case 'broadcast':
        return 'BROADCAST';
      default:
        return type.toUpperCase();
    }
  }

  String _relative(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _resolve(BuildContext context, String id) async {
    final messenger = ScaffoldMessenger.of(context);

    String? remarks;
    String? clearType;
    if (canResolve) {
      // Meeting 20/07 point 7: the guard picks a resolution first.
      //   • False alarm  → cleared immediately, no remarks.
      //   • Attended     → remarks required (what happened / action taken).
      // Either way the community is told the STATUS only (send-push), never
      // the remarks.
      final choice = await showDialog<String>(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Resolve Alert',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'How was this alert resolved?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dctx, 'false_alarm'),
              child: const Text('False alarm'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dctx, 'attended'),
              child: const Text('Attended'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      clearType = choice;

      if (choice == 'attended') {
        final controller = TextEditingController();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Attended — remarks',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            content: TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'What happened / action taken',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(dctx, true);
                },
                child: const Text('Clear Alert'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        remarks = controller.text.trim();
      }
    } else if (!canResolve) {
      remarks = 'Cancelled by the resident who raised it';
    }

    try {
      await ref
          .read(emergencyRepositoryProvider)
          .resolveEmergency(id, remarks: remarks, clearType: clearType);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ref.tr('emergency.resolved')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: _red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final all =
        ref.watch(activeEmergenciesProvider).valueOrNull ??
        const <EmergencyAlert>[];

    // Staff (admin/guard) see every active alert. A resident only sees
    // broadcasts addressed to everyone + the alerts they raised themselves —
    // so the banner never piles up with other residents' panic alerts.
    final alerts = canResolve
        ? all
        : all
              .where((a) => a.type == 'broadcast' || a.triggeredBy == myId)
              .toList();

    // Buzzer follows the visible alerts: sound while any are showing, silence
    // the instant the last one is cancelled/cleared. Scheduled post-frame so
    // we never touch the player mid-build.
    final hasAlerts = alerts.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) EmergencyAlarm.instance.setActive(hasAlerts);
    });
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          for (final a in alerts)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _red.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsFill.siren,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn()
                      .scaleXY(begin: 0.9, end: 1.08, duration: 700.ms),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _typeLabel(a.type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _relative(a.createdAt),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Point 6 (20/07): silence the buzzer. Shown on the
                            // first card only (the alarm is app-wide, one tone).
                            if (a == alerts.first) _MuteToggle(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (a.subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            a.subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (canResolve || a.triggeredBy == myId) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _resolve(context, a.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    canResolve
                                        ? PhosphorIconsBold.check
                                        : PhosphorIconsBold.x,
                                    color: const Color(0xFFDC2626),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    canResolve
                                        ? ref.tr('emergency.resolve')
                                        : ref.tr('emergency.cancel'),
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Small speaker button on the alert banner that mutes/unmutes the app-wide
/// panic buzzer (meeting 20/07 point 6). Reflects the live mute state.
class _MuteToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: EmergencyAlarm.instance.muted,
      builder: (context, muted, _) {
        return GestureDetector(
          onTap: () => EmergencyAlarm.instance.setMuted(!muted),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  muted
                      ? PhosphorIconsFill.speakerSimpleX
                      : PhosphorIconsFill.speakerSimpleHigh,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  muted ? 'Muted' : 'Silence',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
