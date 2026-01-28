import 'package:zerostack/zerostack.dart';

Future<void> main() async {
  final zs = ZeroStack(
    apiUrl: 'https://your-zerostack-server.com/api',
    wsUrl: 'https://your-zerostack-server.com',
    apiKey: 'zs_myapi_key'
  );

  // Option 1: Guest mode (no login required, node must be in publicNodes)
  zs.setGuestId('guest_${DateTime.now().millisecondsSinceEpoch}');

  // Option 2: Authenticated user
  // final result = await zs.auth.login('user@example.com', 'password');
  // zs.setToken(result['accessToken'] as String);

  try {
    // Create a message
    final msg = await zs.data.create('messages', {
      'text': 'Hello from Dart SDK!',
      'author': 'DartBot',
    });
    print('Created: ${msg['_id']}');

    // List messages
    final result = await zs.data.list('messages', limit: 10);
    final items = result is List ? result : (result['items'] as List);
    print('Messages count: ${items.length}');

    // Update
    await zs.data.update('messages', msg['_id'] as String, {
      'text': 'Edited from Dart SDK!',
    });
    print('Updated!');

    // Delete
    await zs.data.delete('messages', msg['_id'] as String);
    print('Deleted!');
  } on ZeroStackException catch (e) {
    print('Error: ${e.message} (${e.status})');
  }

  // Real-time subscriptions
  zs.realtime.subscribe('messages', (item, event) {
    print('[$event] ${item['data']}');
  });

  // Don't forget to disconnect when done
  // zs.realtime.disconnect();
}
