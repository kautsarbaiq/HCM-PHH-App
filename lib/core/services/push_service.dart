import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global messenger so foreground pushes can show an in-app banner from
/// anywhere (system tray only shows them when the app is in background).
final GlobalKey<ScaffoldMessengerState> pushMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Firebase Cloud Messaging wiring:
///  - registers the device token in `push_tokens` for the logged-in user
///    (the `send-push` edge function looks tokens up there),
///  - keeps it fresh on token rotation, login, and app resume,
///  - shows foreground messages as an in-app banner.
///
/// Everything is best-effort: if Firebase isn't configured on this platform
/// the app simply runs without push (never crashes).
class PushService {
  PushService._();

  static bool _initialized = false;
  static bool _saved = false;
  static Timer? _retry;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Web push needs a service worker + VAPID key — mobile-only for now.
    if (kIsWeb || _initialized) return;
    _initialized = true;
    try {
      await Firebase.initializeApp();

      // Subscribe to auth changes BEFORE anything that can block.
      //
      // `requestPermission` below can sit on a system dialog for as long as the
      // user takes to tap Allow. `onAuthStateChange` is a BROADCAST stream, so
      // the `initialSession` event fired during startup is lost to whoever
      // subscribes late — which is exactly why a host who "stayed logged in"
      // ended up with no device token and received no push (boss retest 01/08).
      Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        switch (state.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
            _saveToken();
            break;
          case AuthChangeEvent.signedOut:
            _saved = false;
            break;
          default:
            break;
        }
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        _saved = false;
        _saveToken();
      });

      // Re-check whenever the app comes back to the foreground — covers the
      // case where the very first attempts all ran before the session existed.
      WidgetsBinding.instance.addObserver(_PushLifecycleObserver());

      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);

      // Try now, and keep retrying briefly in case the persisted session is
      // still being restored (uid is null for the first moments after launch).
      await _saveToken();
      _scheduleRetries();

      // Foreground: FCM deliberately does NOT raise a system notification while
      // the app is on screen, so we raise one ourselves — otherwise a host who
      // is sitting in the app sees nothing and reports "push not working"
      // (client retest 02/08). Same channel as the background notification, so
      // it looks and sounds identical either way.
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'hca_alerts',
              'Alerts',
              importance: Importance.high,
            ),
          );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title;
        final body = message.notification?.body;
        if (title == null && body == null) return;

        _localNotifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'hca_alerts',
              'Alerts',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );

        // Keep the in-app banner too — useful while the user is looking at the
        // screen the alert relates to.
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
    } catch (e) {
      // Missing google-services.json / unsupported platform — run without push.
      debugPrint('PushService disabled: $e');
    }
  }

  /// Safety net any screen can call once the user is known to be signed in.
  static Future<void> ensureToken() => _saveToken();

  /// Diagnostic for the Profile screen: is this device actually registered to
  /// receive push for the signed-in user? Testers reported "no notification"
  /// when the real cause was simply that the phone never registered a token
  /// (e.g. logged in on web, or Firebase unavailable) — this makes it visible.
  static Future<PushStatus> status() async {
    if (kIsWeb) return PushStatus(ok: false, detail: 'Not supported on web');
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return PushStatus(ok: false, detail: 'Not signed in');
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        return PushStatus(ok: false, detail: 'No device token from Firebase');
      }
      final rows = await supabase
          .from('push_tokens')
          .select('user_id')
          .eq('token', token)
          .maybeSingle();
      if (rows == null) {
        return PushStatus(ok: false, detail: 'Device not registered yet');
      }
      if (rows['user_id'] != uid) {
        return PushStatus(
          ok: false,
          detail: 'This device is registered to another account',
        );
      }
      return PushStatus(ok: true, detail: 'This device will receive alerts');
    } catch (e) {
      return PushStatus(ok: false, detail: 'Unavailable: $e');
    }
  }

  /// Retry a few times after launch: the session may still be restoring, so the
  /// first attempt can legitimately find no user.
  static void _scheduleRetries() {
    _retry?.cancel();
    var attempts = 0;
    _retry = Timer.periodic(const Duration(seconds: 3), (t) {
      attempts++;
      if (_saved || attempts > 10) {
        t.cancel();
        return;
      }
      _saveToken();
    });
  }

  static Future<void> _saveToken() async {
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return; // not signed in (yet) — a retry will catch it
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await supabase.from('push_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
      _saved = true;
      _retry?.cancel();
    } catch (e) {
      debugPrint('push token save failed: $e');
    }
  }
}

/// Result of [PushService.status] — shown on the Profile screen.
class PushStatus {
  final bool ok;
  final String detail;
  PushStatus({required this.ok, required this.detail});
}

/// Re-registers the device token when the app returns to the foreground.
class _PushLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PushService.ensureToken();
    }
  }
}
