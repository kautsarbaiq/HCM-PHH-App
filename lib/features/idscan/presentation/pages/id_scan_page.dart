import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/repositories/id_scan_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../theme/app_colors.dart';

/// Resident feature: photograph an ID / driving license / passport and let the
/// AI auto-fill the fields (name, IC/passport number, etc.). Saved scans are
/// visible to the admin in the admin panel.
class IdScanPage extends ConsumerStatefulWidget {
  const IdScanPage({super.key});

  @override
  ConsumerState<IdScanPage> createState() => _IdScanPageState();
}

class _IdScanPageState extends ConsumerState<IdScanPage> {
  bool _busy = false;

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Scan ID',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsFill.camera, color: AppColors.brand),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsFill.image, color: AppColors.brand),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _scan(source);
  }

  Future<void> _scan(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 88,
      );
      if (x == null) return;
      setState(() => _busy = true);
      final bytes = await x.readAsBytes();
      final name = x.name;
      final ext = name.contains('.')
          ? name.substring(name.lastIndexOf('.'))
          : '.jpg';
      final mediaType =
          x.mimeType ??
          (ext.toLowerCase() == '.png' ? 'image/png' : 'image/jpeg');

      // Store the image (best-effort) so the admin can view it later.
      String? imageUrl;
      try {
        imageUrl = await ref
            .read(storageRepositoryProvider)
            .uploadCommunityDocumentBytes(bytes, 'id-$name', ext);
      } catch (_) {
        /* upload failure shouldn't block the scan */
      }

      final fields = await ref
          .read(idScanRepositoryProvider)
          .extract(bytes, mediaType);
      if (!mounted) return;
      setState(() => _busy = false);
      _review(fields, imageUrl);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _review(Map<String, String> fields, String? imageUrl) {
    final ctl = <String, TextEditingController>{
      for (final k in [
        'doc_type',
        'full_name',
        'id_number',
        'nationality',
        'address',
        'validity',
        'class',
      ])
        k: TextEditingController(text: fields[k] ?? ''),
    };
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Review scanned details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(ctl['full_name']!, 'Full name'),
                  _field(ctl['id_number']!, 'IC / Passport / License No.'),
                  _field(ctl['doc_type']!, 'Document type'),
                  _field(ctl['nationality']!, 'Nationality'),
                  _field(ctl['address']!, 'Address', lines: 2),
                  _field(ctl['validity']!, 'Validity'),
                  _field(ctl['class']!, 'Class'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      setD(() => saving = true);
                      try {
                        await ref.read(idScanRepositoryProvider).create(
                          {for (final e in ctl.entries) e.key: e.value.text.trim()},
                          imageUrl,
                        );
                        ref.invalidate(myIdScansProvider);
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('ID saved'),
                            backgroundColor: AppColors.brand,
                          ),
                        );
                      } catch (e) {
                        setD(() => saving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('$e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E5F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.brand),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scans = ref.watch(myIdScansProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        PhosphorIconsRegular.caretLeft,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'Scan ID',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(PhosphorIconsFill.identificationCard),
                    label: Text(_busy ? 'Scanning…' : 'Scan an ID / License'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: scans.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorState(
                    message: '$e',
                    onRetry: () => ref.invalidate(myIdScansProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.badge_rounded,
                        title: 'No scanned IDs yet',
                        message:
                            'Tap "Scan an ID / License" to photograph your ID and auto-fill the details.',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(myIdScansProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _card(items[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(IdScan s) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 14),
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: s.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName.isEmpty ? '(no name)' : s.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.idNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (s.docType.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.docType,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(idScanRepositoryProvider).delete(s.id);
                ref.invalidate(myIdScansProvider);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('$e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback() => Container(
    color: AppColors.surfaceTint,
    child: const Icon(Icons.badge_rounded, color: AppColors.brand),
  );
}
