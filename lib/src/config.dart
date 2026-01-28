import 'zerostack_client.dart';

/// App configuration module for ZeroStack (owner only).
class ZeroStackConfig {
  final ZeroStack _client;

  ZeroStackConfig(this._client);

  /// Set public node permissions.
  ///
  /// ```dart
  /// await zs.config.setPublicNodes({
  ///   'read': ['messages', 'rooms'],
  ///   'create': ['messages'],
  ///   'update': ['messages'],
  ///   'delete': [],
  /// });
  /// ```
  Future<dynamic> setPublicNodes(Map<String, dynamic> publicNodes) {
    return _client.request('PUT', '/data/_config', {'publicNodes': publicNodes});
  }

  /// Set TTL per node in seconds.
  ///
  /// ```dart
  /// await zs.config.setNodeTTL({'sessions': 3600, 'lobbies': 86400});
  /// ```
  Future<dynamic> setNodeTTL(Map<String, int> nodeTTL) {
    return _client.request('PUT', '/data/_config', {'nodeTTL': nodeTTL});
  }
}
