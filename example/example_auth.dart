import 'package:zerostack/zerostack.dart';

Future<void> main() async {
  final zs = ZeroStack(
    apiUrl: 'https://zerostack.myapp.fr/api',
    wsUrl: 'https://zerostack.myapp.fr',
    apiKey: 'zs_mt_api_key'
  );

  final email = 'testuser@example.com';
  final password = 'password123';

  try {
    // Try to register (will fail if user already exists)
    print('Registering $email...');
    final registerResult = await zs.auth.register(email, password);
    zs.setToken(registerResult['accessToken'] as String);
    print('Registered! User ID: ${registerResult['user']['id']}');
  } on ZeroStackException catch (e) {
    if (e.status == 400 || e.status == 409) {
      // User exists, try login
      print('User exists, logging in...');
      final loginResult = await zs.auth.login(email, password);
      zs.setToken(loginResult['accessToken'] as String);
      print('Logged in! User ID: ${loginResult['user']['id']}');
    } else {
      rethrow;
    }
  }

  // Get current user profile
  final me = await zs.auth.me();
  print('Current user: ${me['user']['email']}');

  // Create a private note (only this user can access it)
  final note = await zs.data.create(
    'notes',
    {'title': 'My private note', 'content': 'Secret content from Dart'},
    visibility: 'private',
  );
  print('Created private note: ${note['_id']}');

  // Create a public message
  final msg = await zs.data.create('messages', {
    'text': 'Hello from authenticated Dart user!',
    'author': email,
  });
  print('Created message: ${msg['_id']}');

  // List my private notes
  final notes = await zs.data.list('notes', limit: 10);
  final notesList = notes is List ? notes : (notes['items'] as List);
  print('My notes: ${notesList.length}');

  // Update the note
  await zs.data.update('notes', note['_id'] as String, {
    'title': 'Updated private note',
    'content': 'Modified content',
  });
  print('Note updated!');

  // Share the note with another user
  await zs.data.update(
    'notes',
    note['_id'] as String,
    {'title': 'Shared note'},
    allowed: ['user_123', 'guest_abc'],
  );
  print('Note shared with user_123 and guest_abc!');

  // Clean up - delete the test data
  await zs.data.delete('notes', note['_id'] as String);
  await zs.data.delete('messages', msg['_id'] as String);
  print('Cleaned up!');

  print('\nDone!');
}
