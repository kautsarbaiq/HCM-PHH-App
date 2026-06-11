import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/main/presentation/pages/main_navigation_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/access/presentation/pages/access_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/facility/presentation/pages/facility_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/egovernance/presentation/pages/eform_page.dart';
import '../../features/egovernance/presentation/pages/edocument_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/epolling/presentation/pages/epolling_page.dart';
import '../../features/directory/presentation/pages/committee_page.dart';
import '../../features/directory/presentation/pages/security_guard_page.dart';
import '../../features/directory/presentation/pages/econtact_page.dart';
import '../../features/marketplace/presentation/pages/market_square_page.dart';
import '../../features/auth/presentation/pages/resident_login_page.dart';

// Admin imports
import '../../features/admin/presentation/pages/admin_login_page.dart';
import '../../features/admin/presentation/widgets/admin_layout.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/residents_admin_page.dart';
import '../../features/admin/presentation/pages/houses_admin_page.dart';
import '../../features/admin/presentation/pages/announcements_admin_page.dart';
import '../../features/admin/presentation/pages/banners_admin_page.dart';
import '../../features/admin/presentation/pages/billings_admin_page.dart';
import '../../features/admin/presentation/pages/visitors_admin_page.dart';

// Guard imports
import '../../features/guard/presentation/pages/guard_login_page.dart';
import '../../features/guard/presentation/widgets/guard_layout.dart';
import '../../features/guard/presentation/pages/guard_houses_page.dart';
import '../../features/guard/presentation/pages/guard_visitors_page.dart';
import '../../features/guard/presentation/pages/guard_qr_scanner_page.dart';
import '../../features/guard/presentation/pages/guard_register_visitor_page.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<NavigatorState> _adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin_shell');
final GlobalKey<NavigatorState> _guardShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'guard_shell');

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isGoingToLogin = state.matchedLocation == '/login' || 
                             state.matchedLocation == '/admin' || 
                             state.matchedLocation == '/guard';

      if (!isLoggedIn && !isGoingToLogin) {
        if (state.matchedLocation.startsWith('/admin')) {
          return '/admin';
        } else if (state.matchedLocation.startsWith('/guard')) {
          return '/guard';
        } else {
          return '/login';
        }
      }

      if (isLoggedIn && isGoingToLogin) {
        // We could decode JWT to get role, but for now we just redirect to home and let the UI handle if they are unauthorized
        if (state.matchedLocation == '/admin') return '/admin/dashboard';
        if (state.matchedLocation == '/guard') return '/guard/visitors';
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const ResidentLoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationPage(child: child);
        },
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const DashboardPage()),
          GoRoute(path: '/access', builder: (context, state) => const AccessPage()),
          GoRoute(path: '/bills', builder: (context, state) => const BillingPage()),
          GoRoute(path: '/community', builder: (context, state) => const CommunityPage()),
        ],
      ),
      // Standalone pages (no bottom nav)
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      GoRoute(path: '/facility', builder: (context, state) => const FacilityPage()),
      GoRoute(path: '/eform', builder: (context, state) => const EFormPage()),
      GoRoute(path: '/edocument', builder: (context, state) => const EDocumentPage()),
      GoRoute(path: '/events', builder: (context, state) => const EventsPage()),
      GoRoute(path: '/epolling', builder: (context, state) => const EPollingPage()),
      GoRoute(path: '/committee', builder: (context, state) => const CommitteePage()),
      GoRoute(path: '/security-guard', builder: (context, state) => const SecurityGuardPage()),
      GoRoute(path: '/econtact', builder: (context, state) => const EContactPage()),
      GoRoute(path: '/market-square', builder: (context, state) => const MarketSquarePage()),

      // Admin Routes
      GoRoute(path: '/admin', builder: (context, state) => const AdminLoginPage()),
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) {
          return AdminLayout(child: child);
        },
        routes: [
          GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardPage()),
          GoRoute(path: '/admin/residents', builder: (context, state) => const ResidentsAdminPage()),
          GoRoute(path: '/admin/houses', builder: (context, state) => const HousesAdminPage()),
          GoRoute(path: '/admin/announcements', builder: (context, state) => const AnnouncementsAdminPage()),
          GoRoute(path: '/admin/banners', builder: (context, state) => const BannersAdminPage()),
          GoRoute(path: '/admin/billings', builder: (context, state) => const BillingsAdminPage()),
          GoRoute(path: '/admin/visitors', builder: (context, state) => const VisitorsAdminPage()),
        ],
      ),

      // Guard Routes
      GoRoute(path: '/guard', builder: (context, state) => const GuardLoginPage()),
      ShellRoute(
        navigatorKey: _guardShellNavigatorKey,
        builder: (context, state, child) {
          return GuardLayout(child: child);
        },
        routes: [
          GoRoute(path: '/guard/houses', builder: (context, state) => const GuardHousesPage()),
          GoRoute(path: '/guard/visitors', builder: (context, state) => const GuardVisitorsPage()),
          GoRoute(path: '/guard/scan', builder: (context, state) => const GuardQrScannerPage()),
          GoRoute(path: '/guard/register', builder: (context, state) => const GuardRegisterVisitorPage()),
        ],
      ),
    ],
  );
}
