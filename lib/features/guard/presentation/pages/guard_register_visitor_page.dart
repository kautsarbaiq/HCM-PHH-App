import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/repositories/storage_repository.dart';
import '../../../../core/repositories/visitor_repository.dart';
import 'guard_visitors_page.dart';

class GuardRegisterVisitorPage extends ConsumerStatefulWidget {
  const GuardRegisterVisitorPage({super.key});

  @override
  ConsumerState<GuardRegisterVisitorPage> createState() => _GuardRegisterVisitorPageState();
}

class _GuardRegisterVisitorPageState extends ConsumerState<GuardRegisterVisitorPage> {
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _plateController = TextEditingController();

  File? _vehicleFile;
  File? _visitorFile;
  File? _licenseFile;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _houseController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _capture(String type) async {
    // CAMERA is declared in the manifest (needed by the QR scanner), so
    // image_picker's camera also requires the permission granted at runtime.
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to capture photos.'), backgroundColor: Colors.red),
        );
      }
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
      setState(() {
        final file = File(picked.path);
        if (type == 'vehicle') _vehicleFile = file;
        if (type == 'visitor') _visitorFile = file;
        if (type == 'license') _licenseFile = file;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera unavailable: $e'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('Visitor name and destination house number are required.')),
      );
      return;
    }
    if (_vehicleFile == null || _visitorFile == null || _licenseFile == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please capture all three photos (vehicle, face, license).')),
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
        const SnackBar(content: Text('Your session expired. Please log in again.'), backgroundColor: Colors.red),
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
        messenger.showSnackBar(SnackBar(content: Text('House "$houseNo" not found.'), backgroundColor: Colors.red));
        setState(() => _submitting = false);
        return;
      }
      final houseId = houseRows[0]['id'] as String;

      // Create the walk-in visitor, already checked in.
      final visitor = await ref.read(visitorRepositoryProvider).createVisitor(Visitor(
            id: '',
            visitorName: name,
            purpose: 'Walk-in',
            vehiclePlate: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
            houseId: houseId,
            status: 'checked_in',
            registrationType: 'walk-in',
            createdBy: guardId,
          ));

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
        await supabase.from('visitors').update({
          'visitor_photo_url': urls[0],
          'vehicle_photo_url': urls[1],
          'license_photo_url': urls[2],
          'checked_in_by': guardId,
          'checked_in_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', visitor.id);
      } catch (uploadError) {
        photosNote = ' (photos not uploaded: $uploadError)';
        await supabase.from('visitors').update({
          'checked_in_by': guardId,
          'checked_in_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', visitor.id);
      }

      ref.invalidate(guardVisitorsProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$name registered & checked in${photosNote ?? ''}.'), backgroundColor: const Color(0xFF10B981)),
      );
      setState(() {
        _nameController.clear();
        _houseController.clear();
        _plateController.clear();
        _vehicleFile = null;
        _visitorFile = null;
        _licenseFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCaptured = _vehicleFile != null && _visitorFile != null && _licenseFile != null;
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final cardPadding = isNarrow ? 16.w : 32.w;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Walk-in Registration',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2B3674)),
              ),
              SizedBox(height: 8.h),
              Text(
                'Manually register walk-in visitors by capturing required proofs.',
                style: TextStyle(color: const Color(0xFFA3AED0), fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Visitor Name'),
                    _field(_nameController, 'e.g. John Tan'),
                    const SizedBox(height: 16),
                    _label('Destination House Number'),
                    _field(_houseController, 'e.g. 10'),
                    const SizedBox(height: 16),
                    _label('Vehicle Plate (optional)'),
                    _field(_plateController, 'e.g. WXY 1234'),
                    const SizedBox(height: 24),
                    _label('Required Captures'),
                    const SizedBox(height: 16),
                    _buildCaptureItem('Vehicle Plate', PhosphorIconsRegular.car, _vehicleFile != null, () => _capture('vehicle')),
                    _buildCaptureItem('Visitor Face', PhosphorIconsRegular.userFocus, _visitorFile != null, () => _capture('visitor')),
                    _buildCaptureItem('Driving License / ID', PhosphorIconsRegular.identificationCard, _licenseFile != null, () => _capture('license')),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (allCaptured && !_submitting) ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: const Color(0xFFE0E5F2),
                        ),
                        child: _submitting
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Complete Registration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B3674)));

  Widget _field(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFA3AED0)),
          filled: true,
          fillColor: const Color(0xFFF4F7FE),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCaptureItem(String label, IconData icon, bool isCaptured, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isCaptured ? const Color(0xFF10B981) : const Color(0xFFE0E5F2), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isCaptured ? const Color(0xFF10B981).withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isCaptured ? const Color(0xFF10B981) : const Color(0xFFA3AED0)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                isCaptured ? '$label ✓ captured' : label,
                style: TextStyle(fontWeight: FontWeight.w600, color: isCaptured ? const Color(0xFF10B981) : const Color(0xFF2B3674)),
              ),
            ),
            Icon(
              isCaptured ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.camera,
              color: isCaptured ? const Color(0xFF10B981) : const Color(0xFF4318FF),
            ),
          ],
        ),
      ),
    );
  }
}
