import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
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
    if (name.isEmpty || houseNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor name and destination house number are required.')),
      );
      return;
    }
    if (_vehicleFile == null || _visitorFile == null || _licenseFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all three photos (vehicle, face, license).')),
      );
      return;
    }

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final supabase = Supabase.instance.client;
    try {
      // Resolve the destination house by its number.
      final houseRows = await supabase.from('houses').select('id').eq('house_number', houseNo).limit(1);
      if ((houseRows as List).isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text('House "$houseNo" not found.'), backgroundColor: Colors.red));
        setState(() => _submitting = false);
        return;
      }
      final houseId = houseRows[0]['id'] as String;
      final guardId = supabase.auth.currentUser!.id;

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
      // storage bucket; if missing, the visitor is still registered).
      String? photosNote;
      try {
        final storage = ref.read(storageRepositoryProvider);
        final visitorUrl = await storage.uploadGuardEvidence(_visitorFile!, visitor.id);
        final vehicleUrl = await storage.uploadGuardEvidence(_vehicleFile!, visitor.id);
        final licenseUrl = await storage.uploadGuardEvidence(_licenseFile!, visitor.id);
        await supabase.from('visitors').update({
          'visitor_photo_url': visitorUrl,
          'vehicle_photo_url': vehicleUrl,
          'license_photo_url': licenseUrl,
          'checked_in_by': guardId,
          'checked_in_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', visitor.id);
      } catch (_) {
        photosNote = ' (photos not uploaded — storage bucket missing)';
        await supabase.from('visitors').update({
          'checked_in_by': guardId,
          'checked_in_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', visitor.id);
      }

      ref.invalidate(guardVisitorsProvider);
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
      messenger.showSnackBar(SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCaptured = _vehicleFile != null && _visitorFile != null && _licenseFile != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Walk-in Registration',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2B3674)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manually register walk-in visitors by capturing required proofs.',
            style: TextStyle(color: Color(0xFFA3AED0)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
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
