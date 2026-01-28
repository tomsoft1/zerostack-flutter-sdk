import 'package:zerostack/zerostack.dart';

/// Comprehensive test suite for ZeroStack SDK
/// Tests all features: auth, data CRUD, visibility, access control, guest mode

const apiUrl = 'https://zerostack.myapp.fr/api';
const wsUrl = 'https://zerostack.myapp.fr';
const apiKey = 'zs_1720f6260fd9449ebf15f75520cc994251ce8027b2aae7c099ee8976bdf6107d';

int passed = 0;
int failed = 0;

void test(String name, bool condition, [String? errorMsg]) {
  if (condition) {
    print('  ✓ $name');
    passed++;
  } else {
    print('  ✗ $name ${errorMsg != null ? "- $errorMsg" : ""}');
    failed++;
  }
}

Future<void> testExpectError(String name, Future<void> Function() fn, int expectedStatus) async {
  try {
    await fn();
    print('  ✗ $name - Expected error $expectedStatus but succeeded');
    failed++;
  } on ZeroStackException catch (e) {
    if (e.status == expectedStatus) {
      print('  ✓ $name (got expected $expectedStatus)');
      passed++;
    } else {
      print('  ✗ $name - Expected $expectedStatus but got ${e.status}: ${e.message}');
      failed++;
    }
  }
}

Future<void> main() async {
  print('═══════════════════════════════════════════════════════════');
  print('           ZeroStack SDK Test Suite');
  print('═══════════════════════════════════════════════════════════\n');

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final testEmail1 = 'test_user1_$timestamp@test.com';
  final testEmail2 = 'test_user2_$timestamp@test.com';
  final testPassword = 'testpass123';
  final guestId1 = 'guest_test1_$timestamp';
  final guestId2 = 'guest_test2_$timestamp';

  // Create multiple client instances for different users
  final zsUser1 = ZeroStack(apiUrl: apiUrl, wsUrl: wsUrl, apiKey: apiKey);
  final zsUser2 = ZeroStack(apiUrl: apiUrl, wsUrl: wsUrl, apiKey: apiKey);
  final zsGuest1 = ZeroStack(apiUrl: apiUrl, wsUrl: wsUrl, apiKey: apiKey);
  final zsGuest2 = ZeroStack(apiUrl: apiUrl, wsUrl: wsUrl, apiKey: apiKey);
  final zsAnon = ZeroStack(apiUrl: apiUrl, wsUrl: wsUrl, apiKey: apiKey);

  String? user1Id;
  String? user2Id;
  String? user1Token;
  String? user2Token;

  // ═══════════════════════════════════════════════════════════
  // AUTHENTICATION TESTS
  // ═══════════════════════════════════════════════════════════
  print('▶ AUTHENTICATION\n');

  // Register User 1
  try {
    print('  Registering $testEmail1...');
    final result = await zsUser1.auth.register(testEmail1, testPassword);
    user1Token = result['accessToken'] as String;
    user1Id = result['user']['id'] as String;
    zsUser1.setToken(user1Token!);

    test('Register user 1', user1Token.isNotEmpty);
    test('Register returns user ID', user1Id != null && user1Id.isNotEmpty);
    test('Register returns refresh token', result['refreshToken'] != null);
  } catch (e) {
    print('  ✗ Register user 1 failed: $e');
    failed++;
  }

  // Register User 2
  try {
    print('  Registering $testEmail2...');
    final result = await zsUser2.auth.register(testEmail2, testPassword);
    user2Token = result['accessToken'] as String;
    user2Id = result['user']['id'] as String;
    zsUser2.setToken(user2Token!);

    test('Register user 2', user2Token.isNotEmpty);
  } catch (e) {
    print('  ✗ Register user 2 failed: $e');
    failed++;
  }

  // Login test
  try {
    final loginResult = await zsUser1.auth.login(testEmail1, testPassword);
    test('Login returns access token', loginResult['accessToken'] != null);
    test('Login returns user email', loginResult['user']['email'] == testEmail1);
  } catch (e) {
    print('  ✗ Login failed: $e');
    failed++;
  }

  // Login with wrong password
  await testExpectError('Login with wrong password', () async {
    await zsAnon.auth.login(testEmail1, 'wrongpassword');
  }, 401);

  // Get profile (me)
  try {
    final me = await zsUser1.auth.me();
    test('Get profile returns email', me['user']['email'] == testEmail1);
  } catch (e) {
    print('  ✗ Get profile failed: $e');
    failed++;
  }

  // Get profile without token
  await testExpectError('Get profile without token', () async {
    await zsAnon.auth.me();
  }, 401);

  // Setup guests
  zsGuest1.setGuestId(guestId1);
  zsGuest2.setGuestId(guestId2);
  test('Set guest ID 1', zsGuest1.guestId == guestId1);
  test('Set guest ID 2', zsGuest2.guestId == guestId2);

  print('');

  // ═══════════════════════════════════════════════════════════
  // DATA CRUD - PUBLIC ITEMS
  // ═══════════════════════════════════════════════════════════
  print('▶ DATA CRUD - PUBLIC ITEMS\n');

  String? publicMsgId;

  // Create public item as authenticated user
  try {
    final msg = await zsUser1.data.create('test_messages', {
      'text': 'Public message from user 1',
      'author': testEmail1,
    }, visibility: 'public');
    publicMsgId = msg['_id'] as String;

    test('Create public item', publicMsgId.isNotEmpty);
    test('Item has correct visibility', msg['visibility'] == 'public');
  } catch (e) {
    print('  ✗ Create public item failed: $e');
    failed++;
  }

  // Read public item as different user
  try {
    final result = await zsUser2.data.list('test_messages', limit: 10);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == publicMsgId);
    test('User 2 can read public item', found);
  } catch (e) {
    print('  ✗ User 2 read public item failed: $e');
    failed++;
  }

  // Read public item as guest
  try {
    final result = await zsGuest1.data.list('test_messages', limit: 10);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == publicMsgId);
    test('Guest can read public item', found);
  } catch (e) {
    print('  ✗ Guest read public item failed: $e');
    failed++;
  }

  // Update public item by creator
  try {
    final updated = await zsUser1.data.update('test_messages', publicMsgId!, {
      'text': 'Updated public message',
    });
    test('Creator can update public item', updated['data']['text'] == 'Updated public message');
  } catch (e) {
    print('  ✗ Update public item failed: $e');
    failed++;
  }

  print('');

  // ═══════════════════════════════════════════════════════════
  // DATA CRUD - PRIVATE ITEMS
  // ═══════════════════════════════════════════════════════════
  print('▶ DATA CRUD - PRIVATE ITEMS\n');

  String? privateNoteId;

  // Create private item
  try {
    final note = await zsUser1.data.create('test_notes', {
      'title': 'Private note from user 1',
      'secret': 'confidential data',
    }, visibility: 'private');
    privateNoteId = note['_id'] as String;

    test('Create private item', privateNoteId.isNotEmpty);
    test('Private item has correct visibility', note['visibility'] == 'private');
  } catch (e) {
    print('  ✗ Create private item failed: $e');
    failed++;
  }

  // Creator can read private item
  try {
    final result = await zsUser1.data.list('test_notes', limit: 10);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == privateNoteId);
    test('Creator can read own private item', found);
  } catch (e) {
    print('  ✗ Creator read private item failed: $e');
    failed++;
  }

  // Other user cannot see private item in list
  try {
    final result = await zsUser2.data.list('test_notes', limit: 100);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == privateNoteId);
    test('Other user cannot see private item in list', !found);
  } catch (e) {
    print('  ✗ Other user list check failed: $e');
    failed++;
  }

  // Guest cannot see private item in list
  try {
    final result = await zsGuest1.data.list('test_notes', limit: 100);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == privateNoteId);
    test('Guest cannot see private item in list', !found);
  } catch (e) {
    print('  ✗ Guest list check failed: $e');
    failed++;
  }

  // Other user cannot update private item
  await testExpectError('Other user cannot update private item', () async {
    await zsUser2.data.update('test_notes', privateNoteId!, {'title': 'Hacked!'});
  }, 403);

  // Guest cannot update private item
  await testExpectError('Guest cannot update private item', () async {
    await zsGuest1.data.update('test_notes', privateNoteId!, {'title': 'Hacked!'});
  }, 403);

  // Other user cannot delete private item
  await testExpectError('Other user cannot delete private item', () async {
    await zsUser2.data.delete('test_notes', privateNoteId!);
  }, 403);

  print('');

  // ═══════════════════════════════════════════════════════════
  // ACCESS CONTROL - allowed[]
  // ═══════════════════════════════════════════════════════════
  print('▶ ACCESS CONTROL - allowed[]\n');

  String? sharedNoteId;

  // Create private item shared with user 2
  try {
    final note = await zsUser1.data.create('test_shared', {
      'title': 'Shared with user 2',
      'content': 'User 2 can see this',
    }, visibility: 'private', allowed: [user2Id!]);
    sharedNoteId = note['_id'] as String;

    test('Create item with allowed[]', sharedNoteId.isNotEmpty);
    test('Item has allowed array', (note['allowed'] as List).contains(user2Id));
  } catch (e) {
    print('  ✗ Create shared item failed: $e');
    failed++;
  }

  // User 2 can read shared item
  try {
    final result = await zsUser2.data.list('test_shared', limit: 10);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == sharedNoteId);
    test('User in allowed[] can see private item', found);
  } catch (e) {
    print('  ✗ User 2 read shared item failed: $e');
    failed++;
  }

  // User 2 can update shared item
  try {
    final updated = await zsUser2.data.update('test_shared', sharedNoteId!, {
      'title': 'Updated by user 2',
    });
    test('User in allowed[] can update item', updated['data']['title'] == 'Updated by user 2');
  } catch (e) {
    print('  ✗ User 2 update shared item failed: $e');
    failed++;
  }

  // Guest 1 cannot see item (not in allowed[])
  try {
    final result = await zsGuest1.data.list('test_shared', limit: 100);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == sharedNoteId);
    test('User not in allowed[] cannot see item', !found);
  } catch (e) {
    print('  ✗ Guest 1 list check failed: $e');
    failed++;
  }

  // User 2 adds guest 1 to allowed[]
  try {
    await zsUser2.data.update('test_shared', sharedNoteId!, {
      'title': 'Now shared with guest too',
    }, allowed: [user1Id!, user2Id!, guestId1]);
    test('User in allowed[] can modify allowed list', true);
  } catch (e) {
    print('  ✗ User 2 modify allowed[] failed: $e');
    failed++;
  }

  // Now guest 1 can see the item
  try {
    final result = await zsGuest1.data.list('test_shared', limit: 100);
    final items = result is List ? result : (result['items'] as List);
    final found = items.any((i) => i['_id'] == sharedNoteId);
    test('Guest added to allowed[] can now see item', found);
  } catch (e) {
    print('  ✗ Guest 1 read after allowed failed: $e');
    failed++;
  }

  // Guest 1 can update item
  try {
    final updated = await zsGuest1.data.update('test_shared', sharedNoteId!, {
      'title': 'Updated by guest 1',
    });
    test('Guest in allowed[] can update item', updated['data']['title'] == 'Updated by guest 1');
  } catch (e) {
    print('  ✗ Guest 1 update failed: $e');
    failed++;
  }

  // Guest 2 still cannot access
  await testExpectError('Guest not in allowed[] cannot update', () async {
    await zsGuest2.data.update('test_shared', sharedNoteId!, {'title': 'Hacked!'});
  }, 403);

  print('');

  // ═══════════════════════════════════════════════════════════
  // GUEST MODE CRUD
  // ═══════════════════════════════════════════════════════════
  print('▶ GUEST MODE CRUD\n');

  String? guestItemId;

  // Guest creates public item
  try {
    final item = await zsGuest1.data.create('test_guest_items', {
      'text': 'Created by guest 1',
    }, visibility: 'public');
    guestItemId = item['_id'] as String;

    test('Guest can create public item', guestItemId.isNotEmpty);
    test('Guest is in allowed[] of own item', (item['allowed'] as List).contains(guestId1));
  } catch (e) {
    print('  ✗ Guest create item failed: $e');
    failed++;
  }

  // Guest can update own item
  try {
    final updated = await zsGuest1.data.update('test_guest_items', guestItemId!, {
      'text': 'Updated by guest 1',
    });
    test('Guest can update own item', updated['data']['text'] == 'Updated by guest 1');
  } catch (e) {
    print('  ✗ Guest update own item failed: $e');
    failed++;
  }

  // Other guest cannot update
  await testExpectError('Other guest cannot update item', () async {
    await zsGuest2.data.update('test_guest_items', guestItemId!, {'text': 'Hacked!'});
  }, 403);

  // Guest can delete own item
  try {
    await zsGuest1.data.delete('test_guest_items', guestItemId!);
    test('Guest can delete own item', true);
  } catch (e) {
    print('  ✗ Guest delete own item failed: $e');
    failed++;
  }

  print('');

  // ═══════════════════════════════════════════════════════════
  // FILTERS AND PAGINATION
  // ═══════════════════════════════════════════════════════════
  print('▶ FILTERS AND PAGINATION\n');

  // Create test items for filtering
  try {
    await zsUser1.data.create('test_filter', {'category': 'A', 'value': 1}, visibility: 'public');
    await zsUser1.data.create('test_filter', {'category': 'A', 'value': 2}, visibility: 'public');
    await zsUser1.data.create('test_filter', {'category': 'B', 'value': 3}, visibility: 'public');
    await zsUser1.data.create('test_filter', {'category': 'B', 'value': 4}, visibility: 'public');
    await zsUser1.data.create('test_filter', {'category': 'B', 'value': 5}, visibility: 'public');

    // Filter by category
    final resultA = await zsUser1.data.list('test_filter', filter: {'category': 'A'});
    final itemsA = resultA is List ? resultA : (resultA['items'] as List);
    test('Filter by category A returns 2 items', itemsA.length == 2);

    final resultB = await zsUser1.data.list('test_filter', filter: {'category': 'B'});
    final itemsB = resultB is List ? resultB : (resultB['items'] as List);
    test('Filter by category B returns 3 items', itemsB.length == 3);

    // Pagination
    final page1 = await zsUser1.data.list('test_filter', limit: 2, page: 1);
    final items1 = page1 is List ? page1 : (page1['items'] as List);
    test('Pagination limit 2 returns 2 items', items1.length == 2);

  } catch (e) {
    print('  ✗ Filter/pagination test failed: $e');
    failed++;
  }

  print('');

  // ═══════════════════════════════════════════════════════════
  // ERROR CASES
  // ═══════════════════════════════════════════════════════════
  print('▶ ERROR CASES\n');

  // Invalid API key
  final zsBadKey = ZeroStack(apiUrl: apiUrl, wsUrl: wsUrl, apiKey: 'zs_invalid_key');
  await testExpectError('Invalid API key rejected', () async {
    await zsBadKey.data.list('test_messages');
  }, 401);

  // Register with existing email
  await testExpectError('Register with existing email fails', () async {
    await zsAnon.auth.register(testEmail1, testPassword);
  }, 400);

  // Access non-existent item
  await testExpectError('Access non-existent item returns 404', () async {
    await zsUser1.data.update('test_messages', '000000000000000000000000', {'text': 'test'});
  }, 404);

  print('');

  // ═══════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════
  print('▶ CLEANUP\n');

  try {
    // Delete test data
    if (publicMsgId != null) {
      await zsUser1.data.delete('test_messages', publicMsgId);
      print('  Deleted test_messages');
    }
    if (privateNoteId != null) {
      await zsUser1.data.delete('test_notes', privateNoteId);
      print('  Deleted test_notes');
    }
    if (sharedNoteId != null) {
      await zsUser1.data.delete('test_shared', sharedNoteId);
      print('  Deleted test_shared');
    }

    // Clean up filter test items
    final filterItems = await zsUser1.data.list('test_filter', limit: 100);
    final items = filterItems is List ? filterItems : (filterItems['items'] as List);
    for (final item in items) {
      await zsUser1.data.delete('test_filter', item['_id'] as String);
    }
    print('  Deleted test_filter items');

  } catch (e) {
    print('  Warning: Cleanup failed: $e');
  }

  print('');

  // ═══════════════════════════════════════════════════════════
  // RESULTS
  // ═══════════════════════════════════════════════════════════
  print('═══════════════════════════════════════════════════════════');
  print('                    TEST RESULTS');
  print('═══════════════════════════════════════════════════════════');
  print('');
  print('  Passed: $passed');
  print('  Failed: $failed');
  print('  Total:  ${passed + failed}');
  print('');

  if (failed == 0) {
    print('  ✓ ALL TESTS PASSED!');
  } else {
    print('  ✗ SOME TESTS FAILED');
  }
  print('');
}
