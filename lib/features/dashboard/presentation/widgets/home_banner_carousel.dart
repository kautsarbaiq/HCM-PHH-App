import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/repositories/announcement_repository.dart';
import '../../../../theme/app_colors.dart';

/// Announcements shown as the dashboard slider. Each announcement is a slide
/// whose chosen banner image (announcements.image_url) is the background with
/// the title + content overlaid on it. Banner and announcement are one concept
/// now — managed together in the admin Announcements page. autoDispose so a
/// previous account's announcements aren't shown after a logout→login.
final homeAnnouncementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) {
      return ref.read(announcementRepositoryProvider).getAllAnnouncements();
    });

/// Swipeable, auto-advancing slider of announcement slides. Hidden entirely
/// when there are no announcements, so it never leaves a gap.
class HomeBannerCarousel extends ConsumerStatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  ConsumerState<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel> {
  final _controller = PageController();
  int _page = 0;
  int _count = 0;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients || _count <= 1) return;
      final next = (_page + 1) % _count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Announcement a) async {
    final link = a.linkUrl;
    if (link == null || link.trim().isEmpty) return;
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      /* ignore — a bad link should never crash the home screen */
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(homeAnnouncementsProvider).valueOrNull ??
        const <Announcement>[];

    _count = items.length;
    if (_page >= _count) _page = _count > 0 ? _count - 1 : 0;

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => _slide(items[index]),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.brand
                      : AppColors.brand.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _slide(Announcement a) {
    final hasImage = (a.imageUrl ?? '').trim().isNotEmpty;
    return GestureDetector(
      onTap: () => _open(a),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: chosen banner image, or a brand gradient fallback.
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: a.imageUrl!.trim(),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.brandGradient),
                  ),
                  errorWidget: (_, __, ___) => const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.brandGradient),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.brandGradient),
                ),

              // Dark scrim so the text is readable over any image.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(hasImage ? 0.15 : 0.0),
                      Colors.black.withOpacity(hasImage ? 0.66 : 0.28),
                    ],
                  ),
                ),
              ),

              // Title + content united on the image.
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (a.isUrgent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    Text(
                      a.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (a.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        a.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
