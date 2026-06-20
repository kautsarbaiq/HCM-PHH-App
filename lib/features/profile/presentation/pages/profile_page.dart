import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
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
                'Profile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
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
                            color: AppColors.error,
                          ),
                        )
                      : const Icon(PhosphorIconsRegular.signOut),
                  color: AppColors.error,
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
                    const SectionHeader(title: 'Resident Documents'),
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
                gradient: AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.30),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: _isUploading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
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
                    color: AppColors.brand,
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
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            (profileAsync.value?.role.toUpperCase() ?? 'RESIDENT'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
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

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            PhosphorIconsRegular.phone,
            'Phone',
            profileAsync.value?.phone ?? '-',
            AppColors.skyGradient,
          ),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(
            PhosphorIconsRegular.envelopeSimple,
            'Email',
            email,
            AppColors.brandGradient,
          ),
          const Divider(height: 32, thickness: 0.5),
          _buildInfoRow(
            PhosphorIconsRegular.mapPin,
            'House ID',
            houseId,
            AppColors.mintGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Gradient gradient,
  ) {
    return Row(
      children: [
        GradientIconBadge(
          icon: icon,
          gradient: gradient,
          size: 44,
          iconSize: 20,
          radius: 13,
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
                  fontWeight: FontWeight.w700,
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
    final header = SectionHeader(
      title: title,
      // Only show the "see more" caret when the header is actually actionable.
      trailing: onTap != null
          ? const Icon(
              PhosphorIconsRegular.caretRight,
              size: 18,
              color: AppColors.textSecondary,
            )
          : null,
    );
    if (onTap == null) return header;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: header,
    );
  }

  Widget _buildDocumentGrid() {
    final docsAsync = ref.watch(myResidentDocsProvider);
    return SizedBox(
      height: 150,
      child: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PremiumCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                PhosphorIconsRegular.warningCircle,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not load documents: $e',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        data: (docs) {
          if (docs.isEmpty) {
            return PremiumCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: const [
                  GradientIconBadge(
                    icon: PhosphorIconsRegular.fileText,
                    gradient: AppColors.skyGradient,
                    size: 44,
                    iconSize: 20,
                    radius: 13,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No documents issued yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _openResidentDocument(doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GradientIconBadge(
              icon: icon,
              gradient: AppColors.brandGradient,
              size: 40,
              iconSize: 19,
              radius: 12,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.5,
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
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildFinanceRow(
            PhosphorIconsRegular.receipt,
            'Monthly Statements',
            AppColors.brandGradient,
          ),
          const SizedBox(height: 8),
          _buildFinanceRow(
            PhosphorIconsRegular.shieldCheck,
            'Maintenance Receipts',
            AppColors.mintGradient,
          ),
          const SizedBox(height: 8),
          _buildFinanceRow(
            PhosphorIconsRegular.bank,
            'Billing Accounts',
            AppColors.sunsetGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(IconData icon, String title, Gradient gradient) {
    return GestureDetector(
      onTap: () => context.go('/bills'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            GradientIconBadge(
              icon: icon,
              gradient: gradient,
              size: 40,
              iconSize: 19,
              radius: 12,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
