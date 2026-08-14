import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repositories/storage_repository.dart';
import '../../theme/app_colors.dart';

/// Opens a resident's Tenancy Agreement (boss batch 08/08 point 9).
///
/// The document lives in the PRIVATE `resident_documents` bucket, so the stored
/// value is an object path — it has to be signed before it can be opened. Shows
/// a muted "not uploaded" chip when the resident never attached one.
class TenancyDocButton extends ConsumerStatefulWidget {
  /// Stored object path (or legacy public URL). Null/empty = nothing uploaded.
  final String? docPath;

  /// Compact variant for dense tables/rows.
  final bool dense;

  const TenancyDocButton({super.key, required this.docPath, this.dense = false});

  @override
  ConsumerState<TenancyDocButton> createState() => _TenancyDocButtonState();
}

class _TenancyDocButtonState extends ConsumerState<TenancyDocButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await ref
          .read(storageRepositoryProvider)
          .signedResidentDocUrl(widget.docPath!);
      if (url == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not open the document — it may have been '
                'removed from storage.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open document: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final has = (widget.docPath ?? '').isNotEmpty;
    if (!has) {
      return Text(
        'No document',
        style: TextStyle(
          fontSize: widget.dense ? 11.5 : 12.5,
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary.withValues(alpha: 0.75),
        ),
      );
    }
    final icon = _busy
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.description_rounded, size: 16);
    final label = Text(
      'Tenancy Agreement',
      style: TextStyle(fontSize: widget.dense ? 11.5 : 12.5),
    );
    return widget.dense
        ? TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _busy ? null : _open,
            icon: icon,
            label: label,
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: BorderSide(color: AppColors.brand.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _busy ? null : _open,
            icon: icon,
            label: label,
          );
  }
}
