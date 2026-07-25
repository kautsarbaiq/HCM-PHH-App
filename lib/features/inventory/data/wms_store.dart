import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/purchase_order.dart';
import '../models/pick_list.dart';
import '../models/bin_location.dart';
import '../models/placement_item.dart';
import 'inventory_auth.dart';
import 'wms_api.dart';

export 'wms_api.dart' show ScanResult;

/// App-wide store backed by the shared PHH Express API (WmsApi).
/// Holds the loaded data + loading/error flags; mutations call the API and
/// refresh the affected slice so the UI stays in sync with the backend.
class WmsStore extends ChangeNotifier {
  final WmsApi _api;
  WmsStore(this._api);

  List<PurchaseOrder> _orders = [];
  List<PickList> _pickLists = [];
  List<BinLocation> _bins = [];
  List<PlacementItem> _placements = [];

  bool loading = false;
  String? error;

  // ---- reads ----
  List<PurchaseOrder> get orders => List.unmodifiable(_orders);
  List<PickList> get pickLists => List.unmodifiable(_pickLists);
  List<BinLocation> get bins => List.unmodifiable(_bins);
  List<PlacementItem> get placements => List.unmodifiable(_placements);

  PurchaseOrder? orderById(String id) => _orders.where((o) => o.id == id).firstOrNull;
  PickList? pickListById(String id) => _pickLists.where((p) => p.id == id).firstOrNull;

  List<ComparisonRow> comparisonRows(String poId) =>
      orderById(poId)?.items.map(ComparisonRow.fromItem).toList() ?? const [];

  int get pendingReceivingCount =>
      _orders.where((o) => o.status != ReceiveStatus.received).length;
  int get openPickCount =>
      _pickLists.where((p) => p.status != PickStatus.picked).length;
  int get awaitingPlacementCount =>
      _placements.where((p) => p.status == PlacementStatus.awaiting).length;
  int get varianceCount => _orders
      .where((o) => o.status != ReceiveStatus.pending)
      .expand((o) => o.items)
      .where((i) => i.receivedQty != i.expectedQty)
      .length;

  // ---- loading ----
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getPurchaseOrders(),
        _api.getPickLists(),
        _api.getPlacements(),
        _api.getBins(),
      ]);
      _orders = results[0] as List<PurchaseOrder>;
      _pickLists = results[1] as List<PickList>;
      _placements = results[2] as List<PlacementItem>;
      _bins = results[3] as List<BinLocation>;
    } catch (e) {
      error = _friendly(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshOrder(String poId) async {
    try {
      final fresh = await _api.getPurchaseOrder(poId);
      final i = _orders.indexWhere((o) => o.id == poId);
      if (i >= 0) _orders[i] = fresh;
      // Receiving can create placement items — refresh that slice too.
      _placements = await _api.getPlacements();
      notifyListeners();
    } catch (_) {/* keep last good state */}
  }

  Future<void> _refreshPickList(String listId) async {
    try {
      final fresh = await _api.getPickList(listId);
      final i = _pickLists.indexWhere((p) => p.id == listId);
      if (i >= 0) _pickLists[i] = fresh;
      notifyListeners();
    } catch (_) {}
  }

  // ---- receiving ----
  Future<ScanResult> receiveByBarcode(String poId, String code) async {
    final r = await _api.receive(poId, code);
    if (r.ok) await _refreshOrder(poId);
    return r;
  }

  Future<ScanResult> receiveLineFully(String poId, String itemId) async {
    final r = await _api.receiveAll(poId, itemId);
    if (r.ok) await _refreshOrder(poId);
    return r;
  }

  // ---- picking ----
  Future<ScanResult> pickByBarcode(String listId, String code) async {
    final r = await _api.pick(listId, code);
    if (r.ok) await _refreshPickList(listId);
    return r;
  }

  Future<ScanResult> pickLineFully(String listId, String lineId) async {
    final r = await _api.pickAll(listId, lineId);
    if (r.ok) await _refreshPickList(listId);
    return r;
  }

  // ---- placement ----
  Future<ScanResult> placeByBarcodes(String itemId, String locationCode) async {
    final r = await _api.place(itemId, locationCode);
    if (r.ok) {
      _placements = await _api.getPlacements();
      notifyListeners();
    }
    return r;
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('Connection')) {
      return 'Cannot reach the PHH server. Is it running on ${_api.baseUrl}?';
    }
    return s.replaceFirst('Exception: ', '');
  }
}

/// Base URL of the shared PHH-Inventory ("canvas") Express API. Resolution
/// order: --dart-define=INVENTORY_API_URL → INVENTORY_API_URL in the brand
/// .env file → local dev server.
String inventoryApiBase() {
  const defined = String.fromEnvironment('INVENTORY_API_URL');
  if (defined.isNotEmpty) return defined;
  try {
    final v = dotenv.maybeGet('INVENTORY_API_URL');
    if (v != null && v.isNotEmpty) return v;
  } catch (_) {/* dotenv not loaded — use default */}
  return 'http://localhost:3001/api/v1';
}

/// Session with the inventory server (better-auth). Shared by the API client.
final inventoryAuthProvider = ChangeNotifierProvider<InventoryAuth>((ref) {
  final root = inventoryApiBase().replaceFirst(RegExp(r'/api/v1/?$'), '');
  return InventoryAuth(root);
});

final wmsApiProvider = Provider<WmsApi>((ref) {
  final auth = ref.watch(inventoryAuthProvider);
  return WmsApi(
    baseUrl: inventoryApiBase(),
    client: auth.client,
    cookie: () => auth.cookieHeader,
  );
});

final wmsStoreProvider = ChangeNotifierProvider<WmsStore>((ref) {
  // watch: signing in rebuilds the API (session cookie) and reloads the data.
  return WmsStore(ref.watch(wmsApiProvider))..load();
});
