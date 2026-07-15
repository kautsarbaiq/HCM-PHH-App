import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Repositories
import '../repositories/contact_repository.dart' show adminContactsProvider;
import '../repositories/profile_repository.dart' show currentProfileProvider;
import '../repositories/admin_repository.dart'
    show adminResidentsProvider, adminGuardsProvider;
import '../repositories/id_scan_repository.dart'
    show myIdScansProvider, adminIdScansProvider;

// Resident-facing providers
import '../../features/dashboard/presentation/widgets/home_banner_carousel.dart'
    show homeAnnouncementsProvider;
import '../../features/dashboard/presentation/pages/dashboard_page.dart'
    show dashboardOutstandingProvider, dashboardBookingsProvider;
import '../../features/billing/presentation/pages/billing_page.dart'
    show myBillingsProvider;
import '../../features/facility/presentation/pages/facility_page.dart'
    show facilitiesProvider, myBookingsProvider;
import '../../features/access/presentation/pages/access_page.dart'
    show myVisitorsProvider;
import '../../features/community/presentation/pages/community_page.dart'
    show noticesProvider, myTicketsProvider;
import '../../features/events/presentation/pages/events_page.dart'
    show eventsProvider;
import '../../features/epolling/presentation/pages/epolling_page.dart'
    show pollsProvider;
import '../../features/egovernance/presentation/pages/eform_page.dart'
    show eFormsProvider, mySubmittedFormsProvider;
import '../../features/egovernance/presentation/pages/edocument_page.dart'
    show eDocumentsProvider;
import '../../features/marketplace/presentation/pages/market_square_page.dart'
    show servicesProvider;
import '../../features/directory/presentation/pages/econtact_page.dart'
    show contactsProvider;
import '../../features/directory/presentation/pages/committee_page.dart'
    show committeeProvider;
import '../../features/directory/presentation/pages/security_guard_page.dart'
    show guardsProvider;
import '../../features/profile/presentation/pages/profile_page.dart'
    show myResidentDocsProvider, myHouseProvider;
import '../../features/guard/presentation/pages/guard_visitors_page.dart'
    show guardVisitorsProvider;
import '../../features/guard/presentation/pages/guard_houses_page.dart'
    show guardHousesProvider;

// Admin providers
import '../../features/admin/presentation/pages/announcements_admin_page.dart'
    show adminAnnouncementsProvider;
import '../../features/admin/presentation/pages/billings_admin_page.dart'
    show adminBillingsProvider;
import '../../features/admin/presentation/pages/bookings_admin_page.dart'
    show adminBookingsProvider;
import '../../features/admin/presentation/pages/documents_admin_page.dart'
    show adminDocumentsProvider;
import '../../features/admin/presentation/pages/facilities_admin_page.dart'
    show adminFacilitiesProvider;
import '../../features/admin/presentation/pages/forms_admin_page.dart'
    show adminFormsProvider, adminFormSubmissionsProvider;
import '../../features/admin/presentation/pages/events_admin_page.dart'
    show adminEventsProvider;
import '../../features/admin/presentation/pages/polls_admin_page.dart'
    show adminPollsProvider;
import '../../features/admin/presentation/pages/houses_admin_page.dart'
    show adminHousesProvider;
import '../../features/admin/presentation/pages/visitors_admin_page.dart'
    show adminVisitorsProvider;
import '../../features/admin/presentation/pages/marketplace_admin_page.dart'
    show adminMarketplaceProvider;
import '../../features/admin/presentation/pages/communities_admin_page.dart'
    show adminCommunitiesProvider;
import '../../features/admin/presentation/pages/admin_dashboard_page.dart'
    show adminDashboardStatsProvider;

/// Which providers to refresh when a given table changes. Invalidating a
/// provider that isn't currently in use is a safe no-op, so this can list every
/// consumer of a table across resident / guard / admin without harm.
final Map<String, List<ProviderOrFamily>> _providersByTable = {
  'announcements': [
    homeAnnouncementsProvider,
    adminAnnouncementsProvider,
    noticesProvider,
  ],
  'billings': [
    dashboardOutstandingProvider,
    myBillingsProvider,
    adminBillingsProvider,
    adminDashboardStatsProvider,
  ],
  'bookings': [
    dashboardBookingsProvider,
    myBookingsProvider,
    adminBookingsProvider,
  ],
  'events': [eventsProvider, adminEventsProvider],
  'polls': [pollsProvider, adminPollsProvider],
  'visitors': [
    myVisitorsProvider,
    guardVisitorsProvider,
    adminVisitorsProvider,
    adminDashboardStatsProvider,
  ],
  'documents': [eDocumentsProvider, adminDocumentsProvider],
  'forms': [eFormsProvider, adminFormsProvider],
  'form_submissions': [mySubmittedFormsProvider, adminFormSubmissionsProvider],
  'marketplace_services': [servicesProvider, adminMarketplaceProvider],
  'emergency_contacts': [contactsProvider, adminContactsProvider],
  'facilities': [facilitiesProvider, adminFacilitiesProvider],
  'houses': [
    myHouseProvider,
    guardHousesProvider,
    adminHousesProvider,
    adminDashboardStatsProvider,
    // These embed houses(*) in their select:
    guardVisitorsProvider,
    adminVisitorsProvider,
  ],
  'profiles': [
    currentProfileProvider,
    committeeProvider,
    guardsProvider,
    adminResidentsProvider,
    adminGuardsProvider,
    adminDashboardStatsProvider,
    // These embed profiles(*) in their select, so a profile edit must
    // refresh the names/phones they display:
    guardHousesProvider,
    adminHousesProvider,
    adminBillingsProvider,
    guardVisitorsProvider,
    adminVisitorsProvider,
    adminFormSubmissionsProvider,
    adminIdScansProvider,
  ],
  'communities': [adminCommunitiesProvider],
  'resident_documents': [myResidentDocsProvider],
  'resident_id_scans': [myIdScansProvider, adminIdScansProvider],
  'tickets': [myTicketsProvider],
};

/// Wraps the app and keeps every screen live: it opens ONE Supabase Realtime
/// channel listening to all app tables, and whenever a row changes anywhere
/// (from web OR mobile), it invalidates the affected providers so the open
/// screen re-fetches and updates instantly — no refresh, no app restart.
///
/// Realtime delivery is RLS-filtered per subscriber, and the claims are fixed
/// at SUBSCRIBE time. A channel joined before login is an `anon` subscriber and
/// never receives events for private tables (billings, visitors, ...), so this
/// widget re-subscribes whenever auth changes (login / logout / session restore
/// / token refresh). It also re-subscribes with a backoff when the socket
/// drops, and refreshes everything when the app returns from the background —
/// either way no screen is left showing stale data.
class RealtimeSync extends ConsumerStatefulWidget {
  final Widget child;
  const RealtimeSync({super.key, required this.child});

  @override
  ConsumerState<RealtimeSync> createState() => _RealtimeSyncState();
}

class _RealtimeSyncState extends ConsumerState<RealtimeSync>
    with WidgetsBindingObserver {
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;
  Timer? _retryTimer;
  int _retryAttempt = 0;
  int _channelSeq = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
    // onAuthStateChange also emits the current state as its first event.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.tokenRefreshed:
          _resubscribe();
        default:
          break;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS may have dropped the socket while backgrounded; rejoin and
    // refetch so the user never returns to stale screens.
    if (state == AppLifecycleState.resumed) {
      _resubscribe();
    }
  }

  void _resubscribe() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _teardownChannel();
    _subscribe();
    _invalidateAll(); // catch up on anything missed while unsubscribed
  }

  void _subscribe() {
    final client = Supabase.instance.client;
    // Unique topic per join so a stale server-side subscription can never be
    // confused with the new one.
    final channel = client.channel('app_realtime_sync_${++_channelSeq}');
    for (final table in _providersByTable.keys) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) {
          if (!mounted) return;
          for (final provider in _providersByTable[table]!) {
            ref.invalidate(provider);
          }
        },
      );
    }
    _channel = channel;
    channel.subscribe((status, [error]) {
      // Statuses from a channel we already replaced are ignored.
      if (!mounted || !identical(channel, _channel)) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        _retryAttempt = 0;
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut ||
          status == RealtimeSubscribeStatus.closed) {
        _scheduleRetry();
      }
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final seconds = math.min(30, 2 << math.min(_retryAttempt, 4)); // 2..30s
    _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (mounted) _resubscribe();
    });
  }

  void _teardownChannel() {
    final ch = _channel;
    _channel = null; // makes the old channel's subscribe-callback a no-op
    if (ch != null) {
      Supabase.instance.client.removeChannel(ch);
    }
  }

  void _invalidateAll() {
    for (final providers in _providersByTable.values) {
      for (final provider in providers) {
        ref.invalidate(provider);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _authSub?.cancel();
    _teardownChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
