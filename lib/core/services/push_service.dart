import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global messenger so foreground pushes can show an in-app banner from
/// anywhere (system tray only shows them when the app is in background).
final GlobalKey<ScaffoldMessengerState> pushMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Firebase Cloud Messaging wiring:
///  - registers the device token in `push_tokens` for the logged-in user
///    (the `send-push` edge function looks tokens up there),
///  - keeps it fresh on token rotation and on login/logout,
///  - shows foreground messages as an in-app banner.
///
/// Everything is best-effort: if Firebase isn't configured on this platform
/// the app simply runs without push (never crashes).
class PushService {
  PushService._();

  static bool _initialized = false;

  static Future<void> init() async {
    // Web push needs a service worker + VAPID key — mobile-only for now.
    if (kIsWeb || _initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Save the token now (if already logged in) and on every change.
      await _saveToken();
      messaging.onTokenRefresh.listen((_) => _saveToken());
      Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn) {
          _saveToken();
        }
      });

      // Foreground: FCM does not show a system notification — surface it as
      // an in-app banner instead (the screen itself already updates live).
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title;
        final body = message.notification?.body;
        if (title == null && body == null) return;
        pushMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              [title, body].whereType<String>().join(' — '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      });

      _initialized = true;
    } catch (e) {
      // Missing google-services.json / unsupported platform — run without push.
      debugPrint('PushService disabled: $e');
    }
  }

  static Future<void> _saveToken() async {
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await supabase.from('push_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      debugPrint('push token save failed: $e');
    }
  }
}
