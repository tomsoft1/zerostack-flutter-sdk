import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';
import 'data.dart';
import 'config.dart';
import 'realtime.dart';

/// Main ZeroStack client.
///
/// ```dart
/// final zs = ZeroStack(
///   apiUrl: 'https://zerostack.example.com/api',
///   wsUrl: 'https://zerostack.example.com',
///   apiKey: 'zs_your_api_key',
/// );
/// ```
class ZeroStack {
  final String apiUrl;
  final String wsUrl;
  final String apiKey;

  String? _token;
  String? _guestId;

  late final ZeroStackAuth auth;
  late final ZeroStackData data;
  late final ZeroStackConfig config;
  late final ZeroStackRealtime realtime;

  ZeroStack({
    required this.apiUrl,
    String? wsUrl,
    required this.apiKey,
  }) : wsUrl = wsUrl ?? apiUrl.replaceAll(RegExp(r'/api/?$'), '') {
    auth = ZeroStackAuth(this);
    data = ZeroStackData(this);
    config = ZeroStackConfig(this);
    realtime = ZeroStackRealtime(this);
  }

  /// Set the JWT access token for authenticated requests.
  void setToken(String token) => _token = token;

  /// Clear the JWT access token.
  void clearToken() => _token = null;

  /// Set a guest identity for anonymous users.
  void setGuestId(String guestId) => _guestId = guestId;

  /// Clear the guest identity.
  void clearGuestId() => _guestId = null;

  /// Current token (read-only).
  String? get token => _token;

  /// Current guest ID (read-only).
  String? get guestId => _guestId;

  /// Internal HTTP request helper. Returns the `data` field from the response.
  Future<dynamic> request(String method, String path, [Map<String, dynamic>? body]) async {
    final url = Uri.parse('${apiUrl.replaceAll(RegExp(r'/+$'), '')}$path');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    } else if (_guestId != null) {
      headers['x-guest-id'] = _guestId!;
    }

    http.Response response;
    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        response = await http.get(url, headers: headers);
        break;
      case 'POST':
        response = await http.post(url, headers: headers, body: encodedBody);
        break;
      case 'PUT':
        response = await http.put(url, headers: headers, body: encodedBody);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: headers, body: encodedBody);
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['success'] != true) {
      throw ZeroStackException(
        json['error'] as String? ?? 'Request failed',
        response.statusCode,
      );
    }

    return json['data'];
  }
}

/// Exception thrown by ZeroStack API calls.
class ZeroStackException implements Exception {
  final String message;
  final int status;

  ZeroStackException(this.message, this.status);

  @override
  String toString() => 'ZeroStackException($status): $message';
}
