import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/main/presentation/pages/main_navigation_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

import '../../features/access/presentation/pages/access_page.dart';

class BillsPage extends StatelessWidget {
  const BillsPage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Bills Page'));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile Page'));
}

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
            builder: (context, state) => const BillsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
}
