import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cached role (`profiles.role`) of the currently signed-in user.
/// The router's redirect reads this to route each role to its own area, and the
/// login pages refresh it right after sign-in so routing is immediate.
final ValueNotifier<String?> appUserRoleNotifier = ValueNotifier<String?>(null);

/// Re-fetch the signed-in user's role from `profiles` and cache it.
Future<void> refreshUserRole() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    appUserRoleNotifier.value = null;
    return;
  }
  try {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    appUserRoleNotifier.value = res?['role'] as String?;
  } catch (_) {
    appUserRoleNotifier.value = null;
  }
}

/// Landing route for a given role.
String homeRouteForRole(String? role) {
  switch (role) {
    case 'admin':
      return '/admin/dashboard';
    case 'guard':
      return '/guard/visitors';
    default:
      return '/home';
  }
}
