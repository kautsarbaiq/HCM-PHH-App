import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/storage_repository.dart';

/// Resolves (and caches) a short-lived signed URL for each stored evidence
/// reference. Because it's a `family` keyed on the stored value, each distinct
/// photo is signed only once per Riverpod cache lifetime.
final signedEvidenceUrlProvider = FutureProvider.family<String?, String>(
  (ref, stored) =>
      ref.read(storageRepositoryProvider).signedEvidenceUrl(stored),
);

/// Displays an evidence photo stored in the PRIVATE `guard_evidence` bucket by
/// first resolving a signed URL (the raw stored public URL would 403). Shows a
/// neutral placeholder while loading and a broken-image icon on error/null.
class EvidenceImage extends ConsumerWidget {
  final String storedUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const EvidenceImage({
    super.key,
    required this.storedUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = borderRadius ?? BorderRadius.circular(10);
    final signedAsync = ref.watch(signedEvidenceUrlProvider(storedUrl));

    Widget placeholderBox(Widget child) => Container(
      width: width,
      height: height,
      color: const Color(0xFFE0E5F2),
      child: Center(child: child),
    );

    final content = signedAsync.when(
      loading: () => placeholderBox(
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => placeholderBox(
        const Icon(Icons.broken_image, color: Color(0xFF8A93A8), size: 22),
      ),
      data: (signed) {
        if (signed == null || signed.isEmpty) {
          return placeholderBox(
            const Icon(Icons.broken_image, color: Color(0xFF8A93A8), size: 22),
          );
        }
        return CachedNetworkImage(
          imageUrl: signed,
          width: width,
          height: height,
          fit: fit,
          placeholder: (c, u) => placeholderBox(
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (c, u, e) => placeholderBox(
            const Icon(Icons.broken_image, color: Color(0xFF8A93A8), size: 22),
          ),
        );
      },
    );

    return ClipRRect(borderRadius: radius, child: content);
  }
}
