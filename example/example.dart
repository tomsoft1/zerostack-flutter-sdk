import 'package:zerostack/zerostack.dart';

Future<void> main() async {
  final zs = ZeroStack(
    apiUrl: 'https://zerostack.example.com/api',
    wsUrl: 'https://zerostack.example.com',
    apiKey: 'zs_your_api_key',
  );

  // Register or login
  final result = await zs.auth.login('alice@example.com', 'password');
  zs.setToken(result['accessToken'] as String);

  // Create a message
  final msg = await zs.data.create('messages', {
    'text': 'Hello from Flutter!',
    'room': 'general',
  });
  print('Created: ${msg['_id']}');

  // List messages
  final items = await zs.data.list('messages', limit: 20, filter: {'room': 'general'});
  print('Messages: $items');

  // Update
  await zs.data.update('messages', msg['_id'] as String, {
    'text': 'Edited from Flutter!',
  });

  // Private item with access control
  final note = await zs.data.create(
    'notes',
    {'title': 'Secret note'},
    visibility: 'private',
    allowed: ['user_123'],
  );
  print('Private note: ${note['_id']}');

  // Real-time
  zs.realtime.subscribe('messages', (item, event) {
    print('[$event] ${item['data']}');
  });

  // Config (owner only)
  // await zs.config.setPublicNodes({'read': ['messages'], 'create': ['messages']});
  // await zs.config.setNodeTTL({'sessions': 3600});

  // Cleanup
  // zs.realtime.disconnect();
}
