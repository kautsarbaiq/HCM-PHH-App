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
import '../../features/events/presentation/pages/event_invite_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/epolling/presentation/pages/epolling_page.dart';
import '../../features/directory/presentation/pages/committee_page.dart';
import '../../features/directory/presentation/pages/security_guard_page.dart';
import '../../features/directory/presentation/pages/econtact_page.dart';
import '../../features/marketplace/presentation/pages/market_square_page.dart';
import '../../features/idscan/presentation/pages/id_scan_page.dart';
import '../../features/rewards/presentation/pages/rewards_page.dart';
import '../../features/rewards/presentation/pages/voucher_redeem_page.dart';
import '../../features/auth/presentation/pages/resident_login_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

// Admin imports
import '../../features/admin/presentation/pages/admin_login_page.dart';
import '../../features/admin/presentation/widgets/admin_layout.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/residents_admin_page.dart';
import '../../features/admin/presentation/pages/alerts_admin_page.dart';
import '../../features/admin/presentation/pages/houses_admin_page.dart';
import '../../features/admin/presentation/pages/announcements_admin_page.dart';
import '../../features/admin/presentation/pages/billings_admin_page.dart';
import '../../features/admin/presentation/pages/visitors_admin_page.dart';
import '../../features/admin/presentation/pages/events_admin_page.dart';
import '../../features/admin/presentation/pages/polls_admin_page.dart';
import '../../features/admin/presentation/pages/documents_admin_page.dart';
import '../../features/admin/presentation/pages/forms_admin_page.dart';
import '../../features/admin/presentation/pages/contacts_admin_page.dart';
import '../../features/admin/presentation/pages/guards_admin_page.dart';
import '../../features/admin/presentation/pages/marketplace_admin_page.dart';
import '../../features/admin/presentation/pages/facilities_admin_page.dart';
import '../../features/admin/presentation/pages/bookings_admin_page.dart';
import '../../features/admin/presentation/pages/id_scans_admin_page.dart';
import '../../features/admin/presentation/pages/rewards_admin_page.dart';

// Super admin imports
import '../../features/superadmin/presentation/widgets/super_layout.dart';
import '../../features/superadmin/presentation/pages/companies_page.dart';
import '../../features/superadmin/presentation/pages/merchants_page.dart';

// Merchant imports
import '../../features/merchant/presentation/widgets/merchant_layout.dart';
import '../../features/merchant/presentation/pages/shop_profile_page.dart';
import '../../features/merchant/presentation/pages/merchant_offers_page.dart';
import '../../features/merchant/presentation/pages/merchant_redeem_page.dart';

// Guard imports
import '../../features/guard/presentation/pages/guard_login_page.dart';
import '../../features/guard/presentation/widgets/guard_layout.dart';
import '../../features/guard/presentation/pages/guard_houses_page.dart';
import '../../features/guard/presentation/pages/guard_events_page.dart';
import '../../features/guard/presentation/pages/guard_visitors_page.dart';
import '../../features/guard/presentation/pages/guard_qr_scanner_page.dart';
import '../../features/guard/presentation/pages/guard_register_visitor_page.dart';

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_role.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);
final GlobalKey<NavigatorState> _adminShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'admin_shell');
final GlobalKey<NavigatorState> _guardShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'guard_shell');

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Load the role for an already-restored session, then mark auth as resolved
    // and notify the router (this lifts the splash gate on cold start).
    refreshUserRole().then((_) {
      appAuthReadyNotifier.value = true;
      notifyListeners();
    });
    _subscription = stream.asBroadcastStream().listen((dynamic _) async {
      // Re-fetch the role on every auth change (login/logout) BEFORE routing,
      // so the redirect can route by role correctly.
      await refreshUserRole();
      appAuthReadyNotifier.value = true;
      notifyListeners();
    });
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
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final ready = appAuthReadyNotifier.value;
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final role = appUserRoleNotifier.value;
      final loc = state.matchedLocation;
      const loginPages = {'/login', '/admin', '/guard'};

      // PUBLIC event-invitation page (HCA): outside guests open a shared link
      // without any account — never bounce them to splash/login/home.
      if (loc.startsWith('/event-invite')) return null;

      // PUBLIC voucher redemption page: a shop scans the owner's QR and opens
      // this with no account (boss 28/07).
      if (loc.startsWith('/redeem')) return null;

      // Cold start: hold on the splash until the first auth + role resolution
      // completes, so we never flash the resident home or bounce through a
      // login screen before landing on the correct destination. Unlike a
      // `role == null` gate, this can't get stuck forever if the role read
      // fails — `ready` flips true once the first resolution returns.
      if (!ready) {
        return loc == '/splash' ? null : '/splash';
      }

      // Not signed in → always send to the unified login page. The old
      // role-specific /admin and /guard login screens are deprecated, so
      // logging out from any area lands on the single initial login.
      if (!isLoggedIn) {
        return loc == '/login' ? null : '/login';
      }

      // Signed in + resolved. The splash and login pages are "gates" that must
      // bounce into the role's real home (role == null → resident default).
      final atGate = loc == '/splash' || loginPages.contains(loc);
      // Super admin owns the estate: their own portal plus every company's
      // admin area (they manage all of them).
      if (role == 'super_admin') {
        return (atGate ||
                !(loc.startsWith('/super') || loc.startsWith('/admin')))
            ? '/super/companies'
            : null;
      }
      if (role == 'admin') {
        return (atGate || !loc.startsWith('/admin'))
            ? '/admin/dashboard'
            : null;
      }
      if (role == 'guard') {
        return (atGate || !loc.startsWith('/guard')) ? '/guard/visitors' : null;
      }
      if (role == 'merchant') {
        return (atGate || !loc.startsWith('/merchant'))
            ? '/merchant/shop'
            : null;
      }
      // resident (default): block staff areas, splash and login pages.
      if (atGate ||
          loc.startsWith('/admin') ||
          loc.startsWith('/guard') ||
          loc.startsWith('/super') ||
          loc.startsWith('/merchant')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/login',
        builder: (context, state) => const ResidentLoginPage(),
      ),
      // Public event invitation for outside guests (no login required).
      GoRoute(
        path: '/event-invite/:id',
        builder: (context, state) => EventInvitePage(
          eventId: state.pathParameters['id'] ?? '',
          passToken: state.uri.queryParameters['pass'],
          guestName: state.uri.queryParameters['n'],
          inviterId: state.uri.queryParameters['inv'],
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationPage(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/access',
            builder: (context, state) => const AccessPage(),
          ),
          GoRoute(
            path: '/bills',
            builder: (context, state) => const BillingPage(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityPage(),
          ),
        ],
      ),
      // Standalone pages (no bottom nav)
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/facility',
        builder: (context, state) => const FacilityPage(),
      ),
      GoRoute(path: '/eform', builder: (context, state) => const EFormPage()),
      GoRoute(
        path: '/edocument',
        builder: (context, state) => const EDocumentPage(),
      ),
      GoRoute(path: '/events', builder: (context, state) => const EventsPage()),
      GoRoute(
        path: '/epolling',
        builder: (context, state) => const EPollingPage(),
      ),
      GoRoute(
        path: '/committee',
        builder: (context, state) => const CommitteePage(),
      ),
      GoRoute(
        path: '/security-guard',
        builder: (context, state) => const SecurityGuardPage(),
      ),
      GoRoute(
        path: '/econtact',
        builder: (context, state) => const EContactPage(),
      ),
      GoRoute(
        path: '/market-square',
        builder: (context, state) => const MarketSquarePage(),
      ),
      GoRoute(
        path: '/scan-id',
        builder: (context, state) => const IdScanPage(),
      ),
      // Rewards program for house owners (meeting 20/07 point 9).
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsPage(),
      ),
      // Public voucher redemption for shops (boss 28/07 — no login).
      GoRoute(
        path: '/redeem/:token',
        builder: (context, state) =>
            VoucherRedeemPage(token: state.pathParameters['token'] ?? ''),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminLoginPage(),
      ),
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) {
          return AdminLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/residents',
            builder: (context, state) => const ResidentsAdminPage(),
          ),
          GoRoute(
            path: '/admin/houses',
            builder: (context, state) => const HousesAdminPage(),
          ),
          GoRoute(
            path: '/admin/alerts',
            builder: (context, state) => const AlertsAdminPage(),
          ),
          GoRoute(
            path: '/admin/announcements',
            builder: (context, state) => const AnnouncementsAdminPage(),
          ),
          GoRoute(
            path: '/admin/billings',
            builder: (context, state) => const BillingsAdminPage(),
          ),
          GoRoute(
            path: '/admin/visitors',
            builder: (context, state) => const VisitorsAdminPage(),
          ),
          GoRoute(
            path: '/admin/events',
            builder: (context, state) => const EventsAdminPage(),
          ),
          GoRoute(
            path: '/admin/polls',
            builder: (context, state) => const PollsAdminPage(),
          ),
          GoRoute(
            path: '/admin/documents',
            builder: (context, state) => const DocumentsAdminPage(),
          ),
          GoRoute(
            path: '/admin/forms',
            builder: (context, state) => const FormsAdminPage(),
          ),
          GoRoute(
            path: '/admin/contacts',
            builder: (context, state) => const ContactsAdminPage(),
          ),
          GoRoute(
            path: '/admin/guards',
            builder: (context, state) => const GuardsAdminPage(),
          ),
          GoRoute(
            path: '/admin/marketplace',
            builder: (context, state) => const MarketplaceAdminPage(),
          ),
          GoRoute(
            path: '/admin/facilities',
            builder: (context, state) => const FacilitiesAdminPage(),
          ),
          GoRoute(
            path: '/admin/bookings',
            builder: (context, state) => const BookingsAdminPage(),
          ),
          GoRoute(
            path: '/admin/id-scans',
            builder: (context, state) => const IdScansAdminPage(),
          ),
          GoRoute(
            path: '/admin/rewards',
            builder: (context, state) => const RewardsAdminPage(),
          ),
        ],
      ),

      // Super Admin Routes (boss batch 08/08 point 1)
      ShellRoute(
        builder: (context, state, child) => SuperLayout(child: child),
        routes: [
          GoRoute(
            path: '/super/companies',
            builder: (context, state) => const CompaniesPage(),
          ),
          GoRoute(
            path: '/super/merchants',
            builder: (context, state) => const SuperMerchantsPage(),
          ),
        ],
      ),

      // Merchant Routes (boss batch 08/08 point 2)
      ShellRoute(
        builder: (context, state, child) => MerchantLayout(child: child),
        routes: [
          GoRoute(
            path: '/merchant/shop',
            builder: (context, state) => const ShopProfilePage(),
          ),
          GoRoute(
            path: '/merchant/offers',
            builder: (context, state) => const MerchantOffersPage(),
          ),
          GoRoute(
            path: '/merchant/redeem',
            builder: (context, state) => const MerchantRedeemPage(),
          ),
        ],
      ),

      // Guard Routes
      GoRoute(
        path: '/guard',
        builder: (context, state) => const GuardLoginPage(),
      ),
      ShellRoute(
        navigatorKey: _guardShellNavigatorKey,
        builder: (context, state, child) {
          return GuardLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/guard/houses',
            builder: (context, state) => const GuardHousesPage(),
          ),
          // Guards need to see what events are happening in the area (boss 01/08).
          GoRoute(
            path: '/guard/events',
            builder: (context, state) => const GuardEventsPage(),
          ),
          GoRoute(
            path: '/guard/visitors',
            builder: (context, state) => const GuardVisitorsPage(),
          ),
          GoRoute(
            path: '/guard/scan',
            builder: (context, state) => const GuardQrScannerPage(),
          ),
          GoRoute(
            path: '/guard/register',
            builder: (context, state) => const GuardRegisterVisitorPage(),
          ),
        ],
      ),
    ],
  );
}
