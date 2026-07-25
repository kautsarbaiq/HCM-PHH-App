import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'alarm_player_stub.dart'
    if (dart.library.js_interop) 'alarm_player_web.dart'
    if (dart.library.io) 'alarm_player_io.dart';

/// Continuous panic-alarm buzzer (boss request 19/07): while an emergency alert
/// is showing on the user's dashboard, a looping alarm tone sounds — and, on a
/// phone, a repeating heavy vibration reinforces it — until the alert is
/// cancelled (resident) or cleared (guard/admin).
///
/// A single app-wide instance so the tone never doubles up, no matter how many
/// banners are mounted. Callers just push the current state with [setActive];
/// start/stop are idempotent.
///
/// The actual sound is platform-split (see [AlarmPlayer]): a native HTML5
/// <audio> element on web (audioplayers' web backend is broken in the resolved
/// version) and audioplayers on mobile.
///
/// Web note: browsers block audio until the user has interacted with the page.
/// The resident who presses Panic has already tapped, so their buzzer sounds;
/// a guard/admin whose page loads an alert without any prior tap may only hear
/// it after their first interaction. On mobile there is no such restriction.
class EmergencyAlarm {
  EmergencyAlarm._();
  static final EmergencyAlarm instance = EmergencyAlarm._();

  final AlarmPlayer _player = AlarmPlayer();
  Timer? _hapticTimer;
  bool _active = false;

  /// Whether the guard/admin has silenced the buzzer (meeting 20/07 point 6).
  /// A ValueNotifier so the mute button can reflect state live. Muting stops
  /// the current tone and keeps future alerts silent until it's turned back on.
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  /// Drive the buzzer from the current alert state. Idempotent: repeated calls
  /// with the same value do nothing.
  void setActive(bool active) {
    if (active == _active) return;
    _active = active;
    _sync();
  }

  /// Silence / un-silence the buzzer without affecting whether an alert is
  /// active (so un-muting during a live alert resumes the tone).
  void setMuted(bool value) {
    if (value == muted.value) return;
    muted.value = value;
    _sync();
  }

  void _sync() {
    if (_active && !muted.value) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    _player.play();
    // Repeating vibration on phones — no extra package/permission needed.
    if (!kIsWeb) {
      _hapticTimer?.cancel();
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        HapticFeedback.heavyImpact();
      });
    }
  }

  void _stop() {
    _hapticTimer?.cancel();
    _hapticTimer = null;
    _player.stop();
  }
}
