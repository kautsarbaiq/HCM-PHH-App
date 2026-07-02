import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/repositories/id_scan_repository.dart';
import '../../../../core/repositories/storage_repository.dart';
import '../../../../core/repositories/visitor_repository.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../theme/app_colors.dart';
import 'guard_visitors_page.dart';

class GuardRegisterVisitorPage extends ConsumerStatefulWidget {
  const GuardRegisterVisitorPage({super.key});

  @override
  ConsumerState<GuardRegisterVisitorPage> createState() =>
      _GuardRegisterVisitorPageState();
}

class _GuardRegisterVisitorPageState
    extends ConsumerState<GuardRegisterVisitorPage> {
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _plateController = TextEditingController();
  final _idNumberController = TextEditingController();

  File? _vehicleFile;
  File? _visitorFile;
  File? _licenseFile;
  bool _submitting = false;

  // AI extraction of the captured license/ID (scan-id edge function).
  bool _scanningId = false;
  Map<String, String>? _idFields;

  @override
  void dispose() {
    _nameController.dispose();
    _houseController.dispose();
    _plateController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  /// Reads the captured license/ID photo with the scan-id function and
  /// auto-fills the form. Failure is non-fatal — the guard can always type
  /// the details manually.
  Future<void> _extractId(Uint8List bytes) async {
    setState(() {
      _scanningId = true;
      _idFields = null;
    });
    try {
      final fields = await ref
          .read(idScanRepositoryProvider)
          .extract(bytes, 'image/jpeg');
      if (!mounted) return;
      setState(() {
        _idFields = fields;
        final idNo = (fields['id_number'] ?? '').trim();
        if (idNo.isNotEmpty) _idNumberController.text = idNo;
        final name = (fields['full_name'] ?? '').trim();
        if (name.isNotEmpty && _nameController.text.trim().isEmpty) {
          _nameController.text = name;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read the ID automatically ($e). '
            'Please fill the details manually.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _scanningId = false);
    }
  }

  Future<void> _capture(String type) async {
    // CAMERA is declared in the manifest (needed by the QR scanner), so
    // image_picker's camera also requires the permission granted at runtime.
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      // When the permission is permanently denied the OS prompt no longer
      // appears, so point the guard at app settings instead of leaving them
      // stuck on a message they can't act on.
      final permanentlyDenied = status.isPermanentlyDenied;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Camera permission is required to capture photos.',
          ),
          backgroundColor: Colors.red,
          action: permanentlyDenied
              ? SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 55,
      );
      if (picked == null) return;
      final bytes = type == 'license' ? await picked.readAsBytes() : null;
      if (!mounted) return;
      setState(() {
        final file = File(picked.path);
        if (type == 'vehicle') _vehicleFile = file;
        if (type == 'visitor') _visitorFile = file;
        if (type == 'license') _licenseFile = file;
      });
      // Auto-read the ID with AI right after capture (name, IC/passport, ...).
      if (type == 'license' && bytes != null) {
        unawaited(_extractId(bytes));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera unavailable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final houseNo = _houseController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (name.isEmpty || houseNo.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Visitor name and destination house number are required.',
          ),
        ),
      );
      return;
    }
    if (_vehicleFile == null || _visitorFile == null || _licenseFile == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Please capture all three photos (vehicle, face, license).',
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final supabase = Supabase.instance.client;

    // The session may have expired between page load and submit; bail out with
    // a clear message instead of throwing a confusing null-check error.
    final guardId = supabase.auth.currentUser?.id;
    if (guardId == null) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your session expired. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      context.go('/guard');
      return;
    }

    try {
      // Resolve the destination house by its number. Use a case/space-tolerant
      // match so '10 ', ' a10' etc. still resolve to a stored 'A10'.
      final houseRows = await supabase
          .from('houses')
          .select('id')
          .ilike('house_number', houseNo)
          .limit(1);
      if ((houseRows as List).isEmpty) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('House "$houseNo" not found.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _submitting = false);
        return;
      }
      final houseId = houseRows[0]['id'] as String;

      // Create the walk-in visitor, already checked in.
      final visitor = await ref
          .read(visitorRepositoryProvider)
          .createVisitor(
            Visitor(
              id: '',
              visitorName: name,
              purpose: 'Walk-in',
              vehiclePlate: _plateController.text.trim().isEmpty
                  ? null
                  : _plateController.text.trim(),
              houseId: houseId,
              status: 'checked_in',
              registrationType: 'walk-in',
              createdBy: guardId,
            ),
          );

      // Upload the 3 evidence photos (best-effort — needs the 'guard_evidence'
      // storage bucket). If the upload fails, the visitor is still registered
      // and we surface the real error instead of always blaming the bucket.
      String? photosNote;
      try {
        final storage = ref.read(storageRepositoryProvider);
        // Upload the 3 photos in PARALLEL (was sequential — the main cause of the
        // slow save), then write all URLs in one update.
        final urls = await Future.wait([
          storage.uploadGuardEvidence(_visitorFile!, visitor.id),
          storage.uploadGuardEvidence(_vehicleFile!, visitor.id),
          storage.uploadGuardEvidence(_licenseFile!, visitor.id),
        ]);
        await supabase
            .from('visitors')
            .update({
              'visitor_photo_url': urls[0],
              'vehicle_photo_url': urls[1],
              'license_photo_url': urls[2],
              'checked_in_by': guardId,
              'checked_in_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', visitor.id);
      } catch (uploadError) {
        photosNote = ' (photos not uploaded: $uploadError)';
        await supabase
            .from('visitors')
            .update({
              'checked_in_by': guardId,
              'checked_in_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', visitor.id);
      }

      // Save the ID data read from the license (best-effort: needs the
      // id_number/id_details columns from security/09_visitor_id_ocr.sql —
      // registration still succeeds without them).
      final idNo = _idNumberController.text.trim();
      if (idNo.isNotEmpty || _idFields != null) {
        try {
          await supabase
              .from('visitors')
              .update({
                if (idNo.isNotEmpty) 'id_number': idNo,
                if (_idFields != null) 'id_details': _idFields,
              })
              .eq('id', visitor.id);
        } catch (_) {
          // Columns not added yet — ignore, the visitor itself is registered.
        }
      }

      ref.invalidate(guardVisitorsProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('$name registered & checked in${photosNote ?? ''}.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      setState(() {
        _nameController.clear();
        _houseController.clear();
        _plateController.clear();
        _idNumberController.clear();
        _vehicleFile = null;
        _visitorFile = null;
        _licenseFile = null;
        _idFields = null;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCaptured =
        _vehicleFile != null && _visitorFile != null && _licenseFile != null;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final cardPadding = isNarrow ? 16.w : 32.w;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.canvasGradient),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GradientIconBadge(
                      icon: PhosphorIconsFill.userPlus,
                      gradient: AppColors.mintGradient,
                      size: 50,
                      iconSize: 25,
                      radius: 16,
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Walk-in Registration',
                            style: TextStyle(
                              fontSize: 23.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Register walk-in visitors by capturing required proofs.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22.h),
                PremiumCard(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Visitor Details',
                        subtitle: 'Who is visiting and where',
                      ),
                      const SizedBox(height: 18),
                      _label('Visitor Name'),
                      _field(_nameController, 'e.g. John Tan'),
                      const SizedBox(height: 16),
                      _label('Destination House Number'),
                      _field(_houseController, 'e.g. 10'),
                      const SizedBox(height: 16),
                      _label('Vehicle Plate (optional)'),
                      _field(_plateController, 'e.g. WXY 1234'),
                      const SizedBox(height: 16),
                      _label('IC / Passport Number'),
                      _field(
                        _idNumberController,
                        'auto-filled from the ID scan',
                      ),
                      const SizedBox(height: 26),
                      const SectionHeader(
                        title: 'Required Captures',
                        subtitle: 'Capture all three photos to continue',
                      ),
                      const SizedBox(height: 16),
                      _buildCaptureItem(
                        'Vehicle Plate',
                        PhosphorIconsRegular.car,
                        _vehicleFile != null,
                        () => _capture('vehicle'),
                      ),
                      _buildCaptureItem(
                        'Visitor Face',
                        PhosphorIconsRegular.userFocus,
                        _visitorFile != null,
                        () => _capture('visitor'),
                      ),
                      _buildCaptureItem(
                        'Driving License / ID',
                        PhosphorIconsRegular.identificationCard,
                        _licenseFile != null,
                        () => _capture('license'),
                      ),
                      if (_scanningId) _buildScanningIndicator(),
                      if (_idFields != null) _buildIdDetailsCard(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: (allCaptured && !_submitting)
                                ? AppColors.mintGradient
                                : null,
                            color: (allCaptured && !_submitting)
                                ? null
                                : AppColors.textSecondary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (allCaptured && !_submitting)
                                ? [
                                    BoxShadow(
                                      color: AppColors.accentMint.withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: (allCaptured && !_submitting)
                                ? _submit
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Complete Registration',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Reading ID with AI…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// All fields extracted from the scanned ID, so the guard can verify them
  /// against the physical document (name & number are editable above).
  Widget _buildIdDetailsCard() {
    final fields = _idFields!;
    const labels = {
      'doc_type': 'Document',
      'full_name': 'Name',
      'id_number': 'IC / Passport',
      'nationality': 'Nationality',
      'address': 'Address',
      'validity': 'Valid Until',
      'class': 'Class',
    };
    final rows = labels.entries
        .where((e) => (fields[e.key] ?? '').trim().isNotEmpty)
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentMint.withOpacity(0.06),
        border: Border.all(
          color: AppColors.accentMint.withOpacity(0.5),
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                PhosphorIconsFill.sparkle,
                size: 16,
                color: AppColors.success,
              ),
              SizedBox(width: 6),
              Text(
                'ID read automatically',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      fields[e.key]!.trim(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      fontSize: 13.5,
    ),
  );

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.surfaceTint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureItem(
    String label,
    IconData icon,
    bool isCaptured,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCaptured
                    ? AppColors.accentMint
                    : const Color(0xFFE5E9F5),
                width: 1.8,
              ),
              borderRadius: BorderRadius.circular(16),
              color: isCaptured
                  ? AppColors.accentMint.withOpacity(0.08)
                  : AppColors.surfaceTint,
            ),
            child: Row(
              children: [
                GradientIconBadge(
                  icon: icon,
                  gradient: isCaptured
                      ? AppColors.mintGradient
                      : AppColors.brandGradient,
                  size: 42,
                  iconSize: 20,
                  radius: 13,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isCaptured ? '$label  •  captured' : label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCaptured
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isCaptured
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.camera,
                  color: isCaptured ? AppColors.success : AppColors.brand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
