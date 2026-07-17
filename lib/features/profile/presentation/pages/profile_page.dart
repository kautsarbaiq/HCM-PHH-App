import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/config/brand.dart';
import '../../../main/presentation/pages/main_navigation_page.dart'
    show hideBillsForTenant;
import '../../../parking/parking_ui.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/repositories/profile_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../core/repositories/document_repository.dart';
import '../../../../core/repositories/house_repository.dart';
import 'package:file_picker/file_picker.dart';

final myResidentDocsProvider = FutureProvider<List<ResidentDocument>>((ref) {
  return ref.read(documentRepositoryProvider).getMyResidentDocuments();
});

/// The current resident's House (resolved from their houseId). Guarded so it
/// NEVER throws: returns null when there is no houseId or on any error.
final myHouseProvider = FutureProvider.autoDispose<House?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final houseId = profile?.houseId;
  if (houseId == null || houseId.isEmpty) return null;
  try {
    return await ref.read(houseRepositoryProvider).getHouseById(houseId);
  } catch (_) {
    return null;
  }
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploading = false;
  bool _isUploadingDoc = false;
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
      final profile = await ref.read(currentProfileProvider.future);
      if (profile == null) throw Exception('Profile not found');

      final storage = ref.read(storageRepositoryProvider);
      if (kIsWeb) {
        // On web XFile.path is unusable and dart:io File is unavailable, so we
        // upload the picked image's bytes instead.
        final bytes = await pickedFile.readAsBytes();
        var ext = p.extension(pickedFile.name);
        if (ext.isEmpty) ext = p.extension(pickedFile.path);
        if (ext.isEmpty) ext = '.jpg';
        await storage.uploadAvatarBytes(bytes, profile.id, ext);
      } else {
        await storage.uploadAvatar(File(pickedFile.path), profile.id);
      }

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

  Future<void> _addResidentDocument() async {
    if (_isUploadingDoc) return;

    final messenger = ScaffoldMessenger.of(context);
    // On web we must request the file bytes (path is null there).
    final picked = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (picked == null) return;
    final file = picked.files.single;

    // On web we need bytes; on mobile we need a real filesystem path.
    if (kIsWeb && file.bytes == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not read the selected file.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!kIsWeb && file.path == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not access the selected file.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    final details = await _askDocumentDetails();
    if (details == null) return; // Cancelled.

    setState(() => _isUploadingDoc = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final storage = ref.read(storageRepositoryProvider);
      final String path;
      if (kIsWeb) {
        final ext = (file.extension != null && file.extension!.isNotEmpty)
            ? '.${file.extension}'
            : p.extension(file.name);
        path = await storage.uploadResidentDocumentBytes(file.bytes!, uid, ext);
      } else {
        path = await storage.uploadResidentDocument(File(file.path!), uid);
      }
      await ref
          .read(documentRepositoryProvider)
          .addResidentDocument(
            title: details.title,
            documentType: details.type,
            referenceCode: null,
            filePath: path,
          );

      ref.invalidate(myResidentDocsProvider);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not upload document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingDoc = false);
      }
    }
  }

  /// Prompts for a required Title and an optional Document Type. Returns null
  /// if the user cancels or leaves the title blank.
  Future<({String title, String? type})?> _askDocumentDetails() {
    final titleController = TextEditingController();
    final typeController = TextEditingController();

    return showDialog<({String title, String? type})?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final title = titleController.text.trim();
            return AlertDialog(
              title: const Text('Add Document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Tenancy Agreement',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Document Type (optional)',
                      hintText: 'e.g. tenancy, pet',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: title.isEmpty
                      ? null
                      : () {
                          final type = typeController.text.trim();
                          Navigator.pop(dialogContext, (
                            title: title,
                            type: type.isEmpty ? null : type,
                          ));
                        },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
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
                    // HCA (boss 17/07): parking is its OWN section, directly
                    // under the info card and above the documents.
                    if (!Brand.isPhh) const MyParkingSection(),
                    const SizedBox(height: 32),
                    SectionHeader(
                      title: 'Resident Documents',
                      trailing: _isUploadingDoc
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brand,
                              ),
                            )
                          : GestureDetector(
                              onTap: _addResidentDocument,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      PhosphorIconsRegular.plus,
                                      size: 14,
                                      color: AppColors.brand,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildDocumentGrid(),
                    // HCA: tenants don't handle billing (point 17), so the
                    // financial section is owner-only.
                    if (!hideBillsForTenant(ref)) ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        'Financial Records',
                        onTap: () => context.go('/bills'),
                      ),
                      const SizedBox(height: 16),
                      _buildFinanceList(),
                    ],
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
    final houseAsync = ref.watch(myHouseProvider);
    final house = houseAsync.value;
    String houseAddress;
    if (house == null) {
      houseAddress = 'Not assigned';
    } else if (house.address != null && house.address!.isNotEmpty) {
      houseAddress = house.address!;
    } else {
      houseAddress = 'House ${house.houseNumber} (${house.houseType})';
    }

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            PhosphorIconsRegular.phone,
            'Phone',
            profileAsync.value?.phone ?? '-',
            AppColors.skyGradient,
            onEdit: () => _editPhone(profileAsync.value?.phone),
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
            'House Address',
            houseAddress,
            AppColors.mintGradient,
            // HCA: the house is assigned by the management office — residents
            // can't edit it themselves.
            onEdit: Brand.isPhh
                ? () => _editHouseAddress(house?.address)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Gradient gradient, {
    VoidCallback? onEdit,
  }) {
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
        if (onEdit != null)
          IconButton(
            icon: const Icon(
              PhosphorIconsRegular.pencilSimple,
              size: 18,
              color: AppColors.brand,
            ),
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          )
        else
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 16,
            color: AppColors.textSecondary,
          ),
      ],
    );
  }

  /// Edits the signed-in resident's phone (profiles.phone). An empty value
  /// clears it (stored as null).
  Future<void> _editPhone(String? currentPhone) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: currentPhone ?? '');

    final value = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Phone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone',
            hintText: 'e.g. +60 12-345 6789',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (value == null) return; // Cancelled.

    try {
      await ref.read(profileRepositoryProvider).updateMyProfile({
        'phone': value.trim().isEmpty ? null : value.trim(),
      });
      ref.invalidate(currentProfileProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Phone updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update phone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Edits the resident's house address (they are the house owner). An empty
  /// value clears it (stored as null). Shows a SnackBar if no house is assigned.
  Future<void> _editHouseAddress(String? currentAddress) async {
    final messenger = ScaffoldMessenger.of(context);
    final profile = await ref.read(currentProfileProvider.future);
    if (!mounted) return;

    final houseId = profile?.houseId;
    if (houseId == null || houseId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No house assigned')),
      );
      return;
    }

    final controller = TextEditingController(text: currentAddress ?? '');
    final value = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit House Address'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'e.g. 12 Jalan Mawar, Taman Indah',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (value == null) return; // Cancelled.

    try {
      await ref.read(houseRepositoryProvider).updateHouse(houseId, {
        'address': value.trim().isEmpty ? null : value.trim(),
      });
      ref.invalidate(myHouseProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Address updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientIconBadge(
                  icon: icon,
                  gradient: AppColors.brandGradient,
                  size: 40,
                  iconSize: 19,
                  radius: 12,
                ),
                const Spacer(),
                // Edit / Delete must NOT trigger the card's tap-to-open.
                _DocCardIconButton(
                  icon: PhosphorIconsRegular.pencilSimple,
                  tooltip: 'Edit',
                  onTap: () => _editResidentDocument(doc),
                ),
                const SizedBox(width: 2),
                _DocCardIconButton(
                  icon: PhosphorIconsRegular.trash,
                  tooltip: 'Delete',
                  color: AppColors.error,
                  onTap: () => _deleteResidentDocument(doc),
                ),
              ],
            ),
            const SizedBox(height: 12),
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

  /// Opens an edit dialog pre-filled with the doc's title + type and saves the
  /// changes via the repository, then refreshes the resident-docs list.
  Future<void> _editResidentDocument(ResidentDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final titleController = TextEditingController(text: doc.title);
    final typeController = TextEditingController(text: doc.documentType ?? '');

    final result = await showDialog<({String title, String? type})?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final title = titleController.text.trim();
            return AlertDialog(
              title: const Text('Edit Document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'e.g. Tenancy Agreement',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Document Type (optional)',
                      hintText: 'e.g. tenancy, pet',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: title.isEmpty
                      ? null
                      : () {
                          final type = typeController.text.trim();
                          Navigator.pop(dialogContext, (
                            title: title,
                            type: type.isEmpty ? null : type,
                          ));
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return; // Cancelled.

    try {
      await ref
          .read(documentRepositoryProvider)
          .updateResidentDocument(
            doc.id,
            title: result.title,
            documentType: result.type,
          );
      ref.invalidate(myResidentDocsProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Document updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Confirms then deletes a resident's own document (DB row + storage file),
  /// then refreshes the resident-docs list.
  Future<void> _deleteResidentDocument(ResidentDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(documentRepositoryProvider).deleteResidentDocument(doc.id);
      await ref
          .read(storageRepositoryProvider)
          .deleteResidentDocumentFile(doc.fileUrl ?? '');
      ref.invalidate(myResidentDocsProvider);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Document deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not delete document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openResidentDocument(ResidentDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final signed = await ref
        .read(storageRepositoryProvider)
        .signedResidentDocUrl(doc.fileUrl ?? '');

    if (signed != null && signed.isNotEmpty) {
      try {
        await launchUrl(
          Uri.parse(signed),
          mode: LaunchMode.externalApplication,
        );
        return;
      } catch (_) {
        // Fall through to the unavailable message below.
      }
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('File unavailable'),
        backgroundColor: Colors.red,
      ),
    );
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

/// A small tappable icon used on resident-document cards for Edit/Delete.
/// Uses its own gesture handling so taps don't bubble up to the card's
/// tap-to-open behaviour.
class _DocCardIconButton extends StatelessWidget {
  const _DocCardIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: color),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
