import 'package:afochatapplication/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock flutter_secure_storage plugin calls with an in-memory map
  const MethodChannel storageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> fakeStorage = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(storageChannel, (MethodCall method) async {
    final args = method.arguments as Map?;
    switch (method.method) {
      case 'write':
        final key = args?['key'] as String?;
        final value = args?['value'] as String?;
        if (key != null && value != null) fakeStorage[key] = value;
        return null;
      case 'read':
        final key = args?['key'] as String?;
        return key != null ? fakeStorage[key] : null;
      case 'delete':
        final key = args?['key'] as String?;
        if (key != null) fakeStorage.remove(key);
        return null;
      case 'readAll':
        return fakeStorage;
      case 'deleteAll':
        fakeStorage.clear();
        return null;
      default:
        return null;
    }
  });

  test('AuthService mock login stores tokens and user', () async {
    final auth = AuthService();
    await auth.login(email: 'tester@example.com', password: 'secret123');

    expect(auth.accessToken, isNotNull);
    expect(auth.user, isNotNull);
    expect(auth.user!['email'], equals('tester@example.com'));
  });
}
