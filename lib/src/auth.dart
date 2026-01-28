import 'zerostack_client.dart';

/// Authentication module for ZeroStack.
class ZeroStackAuth {
  final ZeroStack _client;

  ZeroStackAuth(this._client);

  /// Register a new user. Returns `{ user, accessToken, refreshToken }`.
  Future<Map<String, dynamic>> register(String email, String password) async {
    final result = await _client.request('POST', '/auth/register', {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Login an existing user. Returns `{ user, accessToken, refreshToken }`.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _client.request('POST', '/auth/login', {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Refresh an expired access token.
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final result = await _client.request('POST', '/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Get the current user profile.
  Future<Map<String, dynamic>> me() async {
    final result = await _client.request('GET', '/auth/me');
    return Map<String, dynamic>.from(result as Map);
  }
}
