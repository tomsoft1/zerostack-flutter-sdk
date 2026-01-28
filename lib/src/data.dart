import 'dart:convert';
import 'zerostack_client.dart';

/// Data CRUD module for ZeroStack.
class ZeroStackData {
  final ZeroStack _client;

  ZeroStackData(this._client);

  /// List items in a node.
  ///
  /// [node] — collection name.
  /// [limit] — max items per page (default 50).
  /// [page] — page number.
  /// [filter] — filter on data fields, e.g. `{'room': 'general'}`.
  Future<dynamic> list(
    String node, {
    int limit = 50,
    int? page,
    Map<String, dynamic>? filter,
  }) {
    var path = '/data/$node?limit=$limit';
    if (page != null) path += '&page=$page';
    if (filter != null) {
      path += '&filter=${Uri.encodeComponent(jsonEncode(filter))}';
    }
    return _client.request('GET', path);
  }

  /// Create a new item in a node.
  ///
  /// [node] — collection name.
  /// [data] — the data object to store.
  /// [visibility] — `'public'` (default) or `'private'`.
  /// [allowed] — list of identity strings that can access this item.
  Future<Map<String, dynamic>> create(
    String node,
    Map<String, dynamic> data, {
    String visibility = 'public',
    List<String>? allowed,
  }) async {
    final body = <String, dynamic>{
      'data': data,
      'visibility': visibility,
    };
    if (allowed != null) body['allowed'] = allowed;
    if (_client.guestId != null && _client.token == null) {
      body['guestId'] = _client.guestId;
    }

    final result = await _client.request('POST', '/data/$node', body);
    return Map<String, dynamic>.from(result as Map);
  }

  /// Update an existing item.
  ///
  /// [node] — collection name.
  /// [id] — item ID.
  /// [data] — new data fields.
  /// [allowed] — optional updated access list.
  Future<Map<String, dynamic>> update(
    String node,
    String id,
    Map<String, dynamic> data, {
    List<String>? allowed,
  }) async {
    final body = <String, dynamic>{'data': data};
    if (allowed != null) body['allowed'] = allowed;
    if (_client.guestId != null && _client.token == null) {
      body['guestId'] = _client.guestId;
    }

    final result = await _client.request('PUT', '/data/$node/$id', body);
    return Map<String, dynamic>.from(result as Map);
  }

  /// Delete an item.
  Future<void> delete(String node, String id) async {
    Map<String, dynamic>? body;
    if (_client.guestId != null && _client.token == null) {
      body = {'guestId': _client.guestId};
    }
    await _client.request('DELETE', '/data/$node/$id', body);
  }
}
