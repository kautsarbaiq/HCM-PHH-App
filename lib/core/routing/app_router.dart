import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/main/presentation/pages/main_navigation_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/access/presentation/pages/access_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/facility/presentation/pages/facility_page.dart';
import '../../features/community/presentation/pages/community_page.dart';
import '../../features/egovernance/presentation/pages/eform_page.dart';
import '../../features/egovernance/presentation/pages/edocument_page.dart';
import '../../features/events/presentation/pages/events_page.dart';
import '../../features/epolling/presentation/pages/epolling_page.dart';
import '../../features/directory/presentation/pages/committee_page.dart';
import '../../features/directory/presentation/pages/security_guard_page.dart';
import '../../features/directory/presentation/pages/econtact_page.dart';
import '../../features/marketplace/presentation/pages/market_square_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
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
      GoRoute(path: '/facility', builder: (context, state) => const FacilityPage()),
      GoRoute(path: '/eform', builder: (context, state) => const EFormPage()),
      GoRoute(path: '/edocument', builder: (context, state) => const EDocumentPage()),
      GoRoute(path: '/events', builder: (context, state) => const EventsPage()),
      GoRoute(path: '/epolling', builder: (context, state) => const EPollingPage()),
      GoRoute(path: '/committee', builder: (context, state) => const CommitteePage()),
      GoRoute(path: '/security-guard', builder: (context, state) => const SecurityGuardPage()),
      GoRoute(path: '/econtact', builder: (context, state) => const EContactPage()),
      GoRoute(path: '/market-square', builder: (context, state) => const MarketSquarePage()),
    ],
  );
}
