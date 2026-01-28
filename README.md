# ZeroStack Flutter SDK

Flutter/Dart SDK for [ZeroStack](https://github.com/tomsoft1/zerostack) Backend-as-a-Service.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  zerostack:
    git:
      url: https://github.com/tomsoft1/zerostack-flutter-sdk.git
```

Then run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:zerostack/zerostack.dart';

final zs = ZeroStack(
  apiUrl: 'https://zerostack.example.com/api',
  wsUrl: 'https://zerostack.example.com',
  apiKey: 'zs_your_api_key',
);
```

## Authentication

```dart
// Register
final result = await zs.auth.register('user@example.com', 'password');
zs.setToken(result['accessToken']);

// Login
final result = await zs.auth.login('user@example.com', 'password');
zs.setToken(result['accessToken']);

// Get current user
final user = await zs.auth.me();

// Logout
zs.clearToken();
```

### Guest Mode

For anonymous users who need a persistent identity:

```dart
final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
zs.setGuestId(guestId);
```

## Data Operations

### List

```dart
final items = await zs.data.list('messages');

// With pagination and filter
final items = await zs.data.list('messages',
  limit: 50,
  page: 2,
  filter: {'room': 'general'},
);
```

### Create

```dart
// Public item
final item = await zs.data.create('messages', {
  'text': 'Hello world!',
  'author': 'Alice',
});

// Private item with access control
final item = await zs.data.create('notes',
  {'title': 'Secret note'},
  visibility: 'private',
  allowed: ['user_123', 'guest_abc'],
);
```

### Update

```dart
final updated = await zs.data.update('messages', itemId, {
  'text': 'Edited message',
});

// Update with access list
final updated = await zs.data.update('notes', itemId,
  {'title': 'Shared note'},
  allowed: ['user_123', 'user_456'],
);
```

### Delete

```dart
await zs.data.delete('messages', itemId);
```

### Error Handling

```dart
try {
  await zs.data.create('messages', {'text': 'hello'});
} on ZeroStackException catch (e) {
  print(e.message); // "Not authorized"
  print(e.status);  // 403
}
```

## Real-time

```dart
// Subscribe to changes
zs.realtime.subscribe('messages', (item, event) {
  switch (event) {
    case 'created':
      print('New: ${item['data']}');
      break;
    case 'updated':
      print('Updated: ${item['data']}');
      break;
    case 'deleted':
      print('Deleted: ${item['_id']}');
      break;
  }
});

// Connection events
zs.realtime.on('connect', (_) => print('Connected'));
zs.realtime.on('disconnect', (_) => print('Disconnected'));

// Unsubscribe
zs.realtime.unsubscribe('messages');

// Disconnect
zs.realtime.disconnect();
```

## App Configuration

Requires authentication as the app owner.

```dart
// Set public nodes
await zs.config.setPublicNodes({
  'read': ['messages', 'rooms'],
  'create': ['messages'],
  'update': ['messages'],
  'delete': [],
});

// Set auto-expiration TTL (in seconds)
await zs.config.setNodeTTL({
  'sessions': 3600,   // 1 hour
  'lobbies': 86400,   // 24 hours
});
```

## Complete Example

```dart
import 'package:zerostack/zerostack.dart';

Future<void> main() async {
  final zs = ZeroStack(
    apiUrl: 'https://zerostack.example.com/api',
    wsUrl: 'https://zerostack.example.com',
    apiKey: 'zs_your_api_key',
  );

  // Login
  final auth = await zs.auth.login('alice@example.com', 'password');
  zs.setToken(auth['accessToken']);

  // Create a message
  final msg = await zs.data.create('messages', {
    'text': 'Hello from Flutter!',
    'room': 'general',
  });

  // Listen for new messages
  zs.realtime.subscribe('messages', (item, event) {
    if (event == 'created') {
      print('${item['data']['author']}: ${item['data']['text']}');
    }
  });

  // List recent messages
  final recent = await zs.data.list('messages',
    limit: 20,
    filter: {'room': 'general'},
  );

  // Cleanup
  zs.realtime.disconnect();
}
```

## License

MIT
