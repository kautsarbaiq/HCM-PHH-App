import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../core/repositories/document_repository.dart';

final myResidentDocsProvider = FutureProvider<List<ResidentDocument>>((ref) {
  return ref.read(documentRepositoryProvider).getMyResidentDocuments();
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploading = false;
  bool _isSigningOut = false;
  bool _avatarFailed = false;

  Future<void> _confirmSignOut() async {
    if (_isSigningOut) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSigningOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not sign out. Please try again. ($e)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile.path);
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) throw Exception('Profile not found');

      await ref.read(storageRepositoryProvider).uploadAvatar(file, profile.id);

      // Refresh profile data and re-attempt loading the (new) avatar image.
      _avatarFailed = false;
      ref.invalidate(currentProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
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
              'Profile',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(PhosphorIconsRegular.signOut),
                color: Colors.red,
                onPressed: _isSigningOut ? null : _confirmSignOut,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileHeader(ref),
                  const SizedBox(height: 32),
                  _buildInfoCard(ref),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Resident Documents'),
                  const SizedBox(height: 16),
                  _buildDocumentGrid(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Financial Records',
                    onTap: () => context.go('/bills'),
                  ),
                  const SizedBox(height: 16),
                  _buildFinanceList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : Builder(
                      builder: (context) {
                        final avatarUrl = profileAsync.whenOrNull(
                          data: (profile) => profile?.avatarUrl,
                        );
                        final hasAvatar =
                            avatarUrl != null &&
                            avatarUrl.isNotEmpty &&
                            !_avatarFailed;
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: hasAvatar
                              ? NetworkImage(avatarUrl)
                              : null,
                          onBackgroundImageError: hasAvatar
                              ? (_, __) {
                                  // Fall back to the default icon on a broken/expired URL.
                                  if (mounted && !_avatarFailed) {
                                    setState(() => _avatarFailed = true);
                                  }
                                }
                              : null,
                          child: hasAvatar
                              ? null
                              : const Icon(
                                  PhosphorIconsRegular.user,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                        );
                      },
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 8,
              child: GestureDetector(
                onTap: _uploadAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    PhosphorIconsFill.camera,
                    size: 20,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          profileAsync.value?.fullName ?? 'Resident',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Role: ${profileAsync.value?.role.toUpperCase() ?? ''}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'No email';
    final houseId = profileAsync.value?.houseId ?? 'Not Assigned';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            PhosphorIconsRegular.phone,
            'Phone',
            profileAsync.value?.phone ?? '-',
          ),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(PhosphorIconsRegular.envelopeSimple, 'Email', email),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(PhosphorIconsRegular.mapPin, 'House ID', houseId),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.deepSlate),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          PhosphorIconsRegular.caretRight,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Only show the "see more" caret when the header is actually actionable.
        if (onTap != null)
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.textSecondary,
          ),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }

  Widget _buildDocumentGrid() {
    final docsAsync = ref.watch(myResidentDocsProvider);
    return SizedBox(
      height: 140,
      child: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'No documents issued yet.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView(
            scrollDirection: Axis.horizontal,
            children: docs.map((d) => _buildDocumentCard(d)).toList(),
          );
        },
      ),
    );
  }

  IconData _docIcon(String? type) {
    switch (type) {
      case 'tenancy':
        return PhosphorIconsRegular.signature;
      case 'pet':
        return PhosphorIconsRegular.pawPrint;
      default:
        return PhosphorIconsRegular.fileText;
    }
  }

  Widget _buildDocumentCard(ResidentDocument doc) {
    final title = doc.title;
    final subtitle = doc.referenceCode ?? '';
    final icon = _docIcon(doc.documentType);
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _openResidentDocument(doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.deepSlate),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openResidentDocument(ResidentDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final hasFile = doc.fileUrl != null && doc.fileUrl!.isNotEmpty;

    if (hasFile) {
      final uri = Uri.tryParse(doc.fileUrl!);
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        } catch (_) {
          // Fall through to the detail dialog below.
        }
      }
    }

    if (!mounted) return;
    // No file (or it failed to open): show the document details instead of doing nothing.
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(doc.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doc.documentType != null && doc.documentType!.isNotEmpty)
              Text(
                'Type: ${doc.documentType}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            if (doc.referenceCode != null && doc.referenceCode!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Reference: ${doc.referenceCode}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            if (!hasFile)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No file attached to this document yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (hasFile) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open the document file.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFinanceList() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildFinanceRow(PhosphorIconsRegular.receipt, 'Monthly Statements'),
          const SizedBox(height: 8),
          _buildFinanceRow(
            PhosphorIconsRegular.shieldCheck,
            'Maintenance Receipts',
          ),
          const SizedBox(height: 8),
          _buildFinanceRow(PhosphorIconsRegular.bank, 'Billing Accounts'),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(IconData icon, String title) {
    return GestureDetector(
      onTap: () => context.go('/bills'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.deepSlate),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
