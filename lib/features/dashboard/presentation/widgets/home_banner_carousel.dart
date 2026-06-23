import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/repositories/announcement_repository.dart';
import '../../../../core/repositories/banner_repository.dart';
import '../../../../theme/app_colors.dart';

/// Active promotional banners shown to residents (managed in the admin Banners
/// page). Hidden entirely when there are none, so it never leaves a gap.
final homeBannersProvider = FutureProvider.autoDispose<List<BannerItem>>((
  ref,
) async {
  final all = await ref.read(bannerRepositoryProvider).getAllBanners();
  return all.where((b) => b.isActive && b.imageUrl.isNotEmpty).toList();
});

/// Announcements shown as a moving ticker over the banner slider. autoDispose so
/// a previous account's announcements aren't shown after a logout→login.
final homeAnnouncementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) {
      return ref.read(announcementRepositoryProvider).getAllAnnouncements();
    });

/// Wallpaper banner SLIDER: swipeable left/right, auto-advances every few
/// seconds, with ALL announcements scrolling as a marquee overlaid on top.
/// When there are no announcements the ticker is hidden; when there are no
/// banners but there are announcements, the ticker rides on a brand backdrop.
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

  Future<void> _open(BannerItem b) async {
    final link = b.linkUrl;
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
    final banners =
        ref.watch(homeBannersProvider).valueOrNull ?? const <BannerItem>[];
    final announcements =
        ref.watch(homeAnnouncementsProvider).valueOrNull ??
        const <Announcement>[];

    _count = banners.length;
    if (_page >= _count) _page = _count > 0 ? _count - 1 : 0;

    final messages = announcements
        .map((a) => a.title.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Nothing at all to show → take up no space.
    if (banners.isEmpty && messages.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          height: 158,
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
                // ---- Background: banner slider, or a brand backdrop ----
                if (banners.isNotEmpty)
                  PageView.builder(
                    controller: _controller,
                    itemCount: banners.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final b = banners[index];
                      return GestureDetector(
                        onTap: () => _open(b),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: b.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                ),
                              ),
                              errorWidget: (_, __, ___) => const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white70,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                            if (b.title.trim().isNotEmpty)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    24,
                                    16,
                                    14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.55),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    b.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.brandGradient),
                  ),

                // ---- Announcement marquee overlaid on top ----
                if (messages.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _AnnouncementTicker(messages: messages),
                  ),
              ],
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) {
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
}

/// A horizontally scrolling "news ribbon" of announcement titles. The content
/// is duplicated so the scroll loops seamlessly with no visible jump.
class _AnnouncementTicker extends StatefulWidget {
  final List<String> messages;
  const _AnnouncementTicker({required this.messages});

  @override
  State<_AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<_AnnouncementTicker> {
  final _scroll = ScrollController();
  Timer? _timer;
  double _textWidth = 0;

  static const _style = TextStyle(
    color: Colors.white,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );
  static const _gap = 48.0;

  String get _text => widget.messages.join('      •      ');

  @override
  void initState() {
    super.initState();
    _measure();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      // Only scrolls when the text overflows (then a horizontal scroll view
      // exists and has clients). Short text fits statically → no clients → skip,
      // so the ribbon never judders for a single short announcement.
      if (!_scroll.hasClients) return;
      final oneCopy = _textWidth + _gap;
      if (oneCopy <= 0) return;
      var next = _scroll.offset + 1.1;
      // Rewind by exactly one copy width — the next copy is identical, so the
      // seam is invisible (seamless loop).
      if (next >= oneCopy) next -= oneCopy;
      _scroll.jumpTo(next);
    });
  }

  @override
  void didUpdateWidget(_AnnouncementTicker old) {
    super.didUpdateWidget(old);
    if (old.messages.join('|') != widget.messages.join('|')) {
      setState(_measure);
    }
  }

  void _measure() {
    final tp = TextPainter(
      text: TextSpan(text: _text, style: _style),
      textDirection: TextDirection.ltr,
    )..layout();
    _textWidth = tp.width;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsFill.megaphone,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final overflow = _textWidth > c.maxWidth;
                if (!overflow) {
                  // Fits on one line → static single copy (no scroll, no dupe).
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style,
                    ),
                  );
                }
                // Overflows → scroll two identical copies for a seamless loop.
                return SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      Text(_text, style: _style),
                      const SizedBox(width: _gap),
                      Text(_text, style: _style),
                      const SizedBox(width: _gap),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
