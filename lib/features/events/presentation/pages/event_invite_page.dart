import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../theme/app_colors.dart';

/// PUBLIC page (no login) — an outside guest opens the link the event host
/// shared on WhatsApp, registers with name/contact/vehicle, and instantly
/// gets a QR gate pass (boss voice note 16/07). Opening the link with
/// `?pass=<token>` re-displays a previously issued pass.
class EventInvitePage extends StatefulWidget {
  final String eventId;
  final String? passToken;
  final String? guestName;

  /// Resident who shared this link. The gate pass is issued against THEIR
  /// house, so invites work for community events created by management too.
  final String? inviterId;

  const EventInvitePage({
    super.key,
    required this.eventId,
    this.passToken,
    this.guestName,
    this.inviterId,
  });

  @override
  State<EventInvitePage> createState() => _EventInvitePageState();
}

class _EventInvitePageState extends State<EventInvitePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  Map<String, dynamic>? _event; // from event_invite_info
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  // Set once registration succeeds (or when opened with ?pass=).
  String? _qrToken;
  String? _passName;
  bool _alreadyRegistered = false;

  @override
  void initState() {
    super.initState();
    if (widget.passToken != null && widget.passToken!.isNotEmpty) {
      _qrToken = widget.passToken;
      _passName = widget.guestName;
    }
    _loadEvent();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    try {
      final rows = await Supabase.instance.client.rpc(
        'event_invite_info',
        params: {'p_event_id': widget.eventId},
      );
      final list = rows as List;
      setState(() {
        _event = list.isEmpty ? null : list.first as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _event = null;
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (phone.isEmpty && email.isEmpty) {
      setState(
        () => _error = 'Please leave a WhatsApp number or e-mail address.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'event-guest-register',
        body: {
          'event_id': widget.eventId,
          'name': name,
          'phone': phone,
          'email': email,
          'vehicle_plate': _plateCtrl.text.trim(),
          'inviter_id': widget.inviterId,
        },
      );
      final data = res.data;
      if (data is Map && data['qr_token'] != null) {
        setState(() {
          _qrToken = data['qr_token'] as String;
          _passName = data['visitor_name'] as String? ?? name;
          _alreadyRegistered = data['already_registered'] == true;
          _submitting = false;
        });
      } else {
        setState(() {
          _error = (data is Map ? data['error'] : null)?.toString() ??
              'Registration failed — please try again.';
          _submitting = false;
        });
      }
    } on FunctionException catch (e) {
      final details = e.details;
      setState(() {
        _error = (details is Map ? details['error'] : null)?.toString() ??
            'Registration failed (${e.status}).';
        _submitting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
        _submitting = false;
      });
    }
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat(
        'EEE, MMM d, yyyy • HH:mm',
      ).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors.brand),
                    )
                  : _qrToken != null
                      ? _passView()
                      : _event == null
                          ? _notFound()
                          : _formView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A7BA8).withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      );

  Widget _notFound() => _card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.event_busy_rounded,
                size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'This invitation is not available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'The event may have ended or is awaiting approval.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _eventHeader() {
    final e = _event;
    return Column(
      children: [
        const Icon(Icons.celebration_rounded, size: 40, color: AppColors.brand),
        const SizedBox(height: 10),
        Text(
          e?['title']?.toString() ?? 'Community event',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if ((e?['event_date'] ?? '').toString().isNotEmpty)
          Text(
            _fmtDate(e!['event_date'].toString()),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
        if ((e?['location'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              e!['location'].toString(),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        if ((e?['host_name'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Hosted by ${e!['host_name']}'
              '${(e['community_name'] ?? '').toString().isNotEmpty ? ' • ${e['community_name']}' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ),
      ],
    );
  }

  Widget _formView() {
    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: const Color(0xFFF4F6FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        );

    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _eventHeader(),
          const SizedBox(height: 18),
          const Text(
            "You're invited! Register below to receive your gate pass.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: deco('Full name', Icons.person_outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: deco('WhatsApp number', Icons.phone_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: deco('E-mail (optional)', Icons.email_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plateCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration:
                deco('Vehicle plate (optional)', Icons.directions_car_outlined),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _submitting ? null : _register,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Register & get my pass',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _passView() {
    return _card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _eventHeader(),
          const SizedBox(height: 14),
          if (_alreadyRegistered)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'You were already registered — here is your pass again.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
          Text(
            _passName == null ? 'Your gate pass' : 'Gate pass — $_passName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0E5F2)),
            ),
            child: QrImageView(
              data: _qrToken!,
              version: QrVersions.auto,
              size: 220,
              foregroundColor: AppColors.deepSlate,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Show this QR code at the main gate on the event day.\n'
            'Take a screenshot so you have it ready.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
