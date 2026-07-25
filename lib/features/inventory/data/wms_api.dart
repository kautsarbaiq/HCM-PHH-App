import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/purchase_order.dart';
import '../models/pick_list.dart';
import '../models/bin_location.dart';
import '../models/placement_item.dart';

/// Result of a scan/confirm action, surfaced to the UI as a snackbar.
class ScanResult {
  final bool ok;
  final String message;
  const ScanResult(this.ok, this.message);
}

/// HTTP client for the shared PHH Express API (/api/v1/wms/*).
/// This is what makes the mobile app and the web share one backend.
class WmsApi {
  final String baseUrl;
  final http.Client _client;

  /// Session cookie supplier (mobile). Null/empty on web, where the browser
  /// attaches the better-auth cookie itself.
  final String? Function()? cookie;

  WmsApi({required this.baseUrl, http.Client? client, this.cookie})
      : _client = client ?? http.Client();

  Map<String, String> get _authHeaders {
    final c = cookie?.call();
    return {if (c != null && c.isNotEmpty) 'cookie': c};
  }

  // ---- Receiving / Comparison ----
  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final list = await _getList('/wms/purchase-orders');
    return list.map((j) => PurchaseOrder.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<PurchaseOrder> getPurchaseOrder(String id) async {
    final j = await _getObject('/wms/purchase-orders/$id');
    return PurchaseOrder.fromJson(j);
  }

  Future<ScanResult> receive(String poId, String barcode) =>
      _post('/wms/purchase-orders/$poId/receive', {'barcode': barcode});

  Future<ScanResult> receiveAll(String poId, String itemId) =>
      _post('/wms/purchase-orders/$poId/items/$itemId/receive-all', const {});

  // ---- Picking ----
  Future<List<PickList>> getPickLists() async {
    final list = await _getList('/wms/pick-lists');
    return list.map((j) => PickList.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<PickList> getPickList(String id) async {
    final j = await _getObject('/wms/pick-lists/$id');
    return PickList.fromJson(j);
  }

  Future<ScanResult> pick(String listId, String barcode) =>
      _post('/wms/pick-lists/$listId/pick', {'barcode': barcode});

  Future<ScanResult> pickAll(String listId, String lineId) =>
      _post('/wms/pick-lists/$listId/lines/$lineId/pick-all', const {});

  // ---- Placement ----
  Future<List<PlacementItem>> getPlacements() async {
    final list = await _getList('/wms/placements');
    return list.map((j) => PlacementItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ScanResult> place(String itemId, String locationCode) =>
      _post('/wms/placements/$itemId/place', {'locationCode': locationCode});

  // ---- Bins ----
  Future<List<BinLocation>> getBins() async {
    final list = await _getList('/wms/bins');
    return list.map((j) => BinLocation.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ---- helpers ----
  Future<List<dynamic>> _getList(String path) async {
    final res = await _client.get(Uri.parse('$baseUrl$path'), headers: _authHeaders);
    final body = _decode(res.body);
    if (_isOk(res.statusCode) && body['success'] == true) {
      return (body['data'] as List?) ?? const [];
    }
    throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
  }

  Future<Map<String, dynamic>> _getObject(String path) async {
    final res = await _client.get(Uri.parse('$baseUrl$path'), headers: _authHeaders);
    final body = _decode(res.body);
    if (_isOk(res.statusCode) && body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['error'] ?? 'Request failed (${res.statusCode})');
  }

  Future<ScanResult> _post(String path, Map<String, dynamic> payload) async {
    final res = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json', ..._authHeaders},
      body: jsonEncode(payload),
    );
    final body = _decode(res.body);
    final ok = body['ok'] == true || (_isOk(res.statusCode) && body['success'] == true);
    return ScanResult(ok, (body['message'] ?? body['error'] ?? '').toString());
  }

  bool _isOk(int code) => code >= 200 && code < 300;

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
