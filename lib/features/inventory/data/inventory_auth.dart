import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'inventory_client_io.dart'
    if (dart.library.js_interop) 'inventory_client_web.dart';

/// Sign-in against the PHH-Inventory server's better-auth endpoints. The WMS
/// API routes all require a session, so the inventory hub shows a login card
/// until [signedIn] is true.
///
/// Web: the browser stores the session cookie (withCredentials). Mobile: we
/// capture the `set-cookie` header ourselves and replay it on every call.
class InventoryAuth extends ChangeNotifier {
  /// Server root, e.g. http://localhost:3001 (no /api/v1 suffix).
  final String serverRoot;
  final http.Client client = createHttpClient();

  InventoryAuth(this.serverRoot) {
    // An earlier browser session may still be valid — check silently.
    _checkExistingSession();
  }

  bool signedIn = false;
  bool busy = false;
  String? error;
  String? _cookie;

  /// Cookie header for IO platforms; null on web (browser handles it).
  String? get cookieHeader => browserManagesCookies ? null : _cookie;

  Future<void> _checkExistingSession() async {
    try {
      final res = await client.get(
        Uri.parse('$serverRoot/api/auth/get-session'),
        headers: _headers(),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final body = jsonDecode(res.body);
        if (body is Map && body['session'] != null) {
          signedIn = true;
          notifyListeners();
        }
      }
    } catch (_) {/* server down — the store will surface that */}
  }

  Future<bool> signIn(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await client.post(
        Uri.parse('$serverRoot/api/auth/sign-in/email'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!browserManagesCookies) {
          final setCookie = res.headers['set-cookie'] ?? '';
          final m = RegExp(
            r'([^,;\s=]+\.session_token)=([^;]+)',
          ).firstMatch(setCookie);
          if (m != null) _cookie = '${m.group(1)}=${m.group(2)}';
        }
        signedIn = true;
        busy = false;
        notifyListeners();
        return true;
      }
      String msg = 'Sign-in failed (${res.statusCode}).';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] != null) {
          msg = body['message'].toString();
        }
      } catch (_) {}
      error = msg;
    } catch (e) {
      error = e.toString().contains('SocketException') ||
              e.toString().contains('Failed to fetch')
          ? 'Cannot reach the inventory server at $serverRoot.'
          : e.toString();
    }
    busy = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    try {
      await client.post(
        Uri.parse('$serverRoot/api/auth/sign-out'),
        headers: _headers(json: true),
        body: '{}',
      );
    } catch (_) {}
    _cookie = null;
    signedIn = false;
    notifyListeners();
  }

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'content-type': 'application/json',
        if (cookieHeader != null) 'cookie': cookieHeader!,
      };
}
