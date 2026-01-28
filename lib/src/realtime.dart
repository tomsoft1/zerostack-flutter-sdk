import 'package:socket_io_client/socket_io_client.dart' as io;
import 'zerostack_client.dart';

/// Callback for real-time events.
/// [item] is the data item, [event] is 'created', 'updated', or 'deleted'.
typedef RealtimeCallback = void Function(Map<String, dynamic> item, String event);

/// Real-time subscription module for ZeroStack using Socket.io.
class ZeroStackRealtime {
  final ZeroStack _client;
  io.Socket? _socket;
  final Map<String, RealtimeCallback> _handlers = {};

  ZeroStackRealtime(this._client);

  io.Socket _ensureSocket() {
    if (_socket != null) return _socket!;

    _socket = io.io(
      _client.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'apiKey': _client.apiKey})
          .disableAutoConnect()
          .build(),
    );

    _socket!.on('data:created', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final node = map['node'] as String;
      final item = Map<String, dynamic>.from(map['item'] as Map);
      _handlers[node]?.call(item, 'created');
    });

    _socket!.on('data:updated', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final node = map['node'] as String;
      final item = Map<String, dynamic>.from(map['item'] as Map);
      _handlers[node]?.call(item, 'updated');
    });

    _socket!.on('data:deleted', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final node = map['node'] as String;
      final item = Map<String, dynamic>.from(map['item'] as Map);
      _handlers[node]?.call(item, 'deleted');
    });

    _socket!.connect();
    return _socket!;
  }

  /// Subscribe to real-time changes on a node.
  void subscribe(String node, RealtimeCallback callback) {
    final socket = _ensureSocket();
    _handlers[node] = callback;
    socket.emit('subscribe', {'node': node});
  }

  /// Unsubscribe from a node.
  void unsubscribe(String node) {
    _handlers.remove(node);
  }

  /// Disconnect the socket and clear all handlers.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _handlers.clear();
  }

  /// Listen to raw socket events (connect, disconnect, etc.).
  void on(String event, Function(dynamic) callback) {
    final socket = _ensureSocket();
    socket.on(event, callback);
  }
}
