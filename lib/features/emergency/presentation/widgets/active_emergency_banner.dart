import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/emergency_repository.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../theme/app_colors.dart';

/// Live banner that surfaces any ACTIVE emergency on a dashboard. Shows nothing
/// when there are no active alerts. Used by residents (read-only) and by admin
/// and guard ([canResolve] true → a Resolve button per alert).
class ActiveEmergencyBanner extends ConsumerWidget {
  final bool canResolve;
  const ActiveEmergencyBanner({super.key, this.canResolve = false});

  static const _red = Color(0xFFEF4444);

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

  Future<void> _resolve(BuildContext context, WidgetRef ref, String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(emergencyRepositoryProvider).resolveEmergency(id);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts =
        ref.watch(activeEmergenciesProvider).valueOrNull ??
        const <EmergencyAlert>[];
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
                        if (canResolve) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _resolve(context, ref, a.id),
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
                                  const Icon(
                                    PhosphorIconsBold.check,
                                    color: Color(0xFFDC2626),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ref.tr('emergency.resolve'),
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
