import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:luma/features/lock/lock_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

/// In-memory store helper to simulate FlutterSecureStorage.
void stubSecureStore(MockFlutterSecureStorage mock, Map<String, String> store) {
  when(() => mock.write(key: any(named: 'key'), value: any(named: 'value')))
      .thenAnswer((inv) async {
    final key = inv.namedArguments[#key] as String;
    final value = inv.namedArguments[#value] as String?;
    if (value != null) store[key] = value;
  });
  when(() => mock.read(key: any(named: 'key'))).thenAnswer((inv) async {
    return store[inv.namedArguments[#key] as String];
  });
  when(() => mock.delete(key: any(named: 'key'))).thenAnswer((inv) async {
    store.remove(inv.namedArguments[#key] as String);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockAuth;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockLocalAuthentication();
    SharedPreferences.setMockInitialValues({});
  });

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  test('isEnabled is false by default', () async {
    final service = LockService(prefs: await prefs());
    expect(service.isEnabled, isFalse);
  });

  test('createPin writes hash and salt to secure storage', () async {
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.createPin('1234');

    verify(
      () => mockStorage.write(
        key: 'lock_pin_salt',
        value: any(named: 'value'),
      ),
    ).called(1);
    verify(
      () => mockStorage.write(
        key: 'lock_pin_hash',
        value: any(named: 'value'),
      ),
    ).called(1);
  });

  test('verifyPin returns true for the same PIN used in createPin', () async {
    final store = <String, String>{};
    stubSecureStore(mockStorage, store);

    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.createPin('424242');
    expect(await service.verifyPin('424242'), isTrue);
  });

  test('verifyPin returns false for a wrong PIN', () async {
    final store = <String, String>{};
    stubSecureStore(mockStorage, store);

    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.createPin('111111');
    expect(await service.verifyPin('222222'), isFalse);
  });

  test('verifyPin returns false if no hash stored', () async {
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    expect(await service.verifyPin('1234'), isFalse);
  });

  test('enableLock sets lock_enabled in SharedPreferences', () async {
    final service = LockService(prefs: await prefs());
    await service.enableLock();
    expect((await prefs()).getBool('lock_enabled'), isTrue);
    expect(service.isEnabled, isTrue);
  });

  test('disableLock clears enabled flag and deletes hash and salt', () async {
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    final p = await prefs();
    await p.setBool('lock_enabled', true);
    final service = LockService(
      storage: mockStorage,
      prefs: p,
    );
    await service.disableLock();

    expect(service.isEnabled, isFalse);
    verify(() => mockStorage.delete(key: 'lock_pin_hash')).called(1);
    verify(() => mockStorage.delete(key: 'lock_pin_salt')).called(1);
  });

  test('authenticateWithBiometrics returns true when authenticate succeeds', () async {
    when(
      () => mockAuth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        biometricOnly: true,
      ),
    ).thenAnswer((_) async => true);

    final service = LockService(
      localAuth: mockAuth,
      prefs: await prefs(),
    );
    expect(await service.authenticateWithBiometrics('Unlock'), isTrue);
  });

  test('authenticateWithBiometrics returns false on LocalAuthException', () async {
    when(
      () => mockAuth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        biometricOnly: true,
      ),
    ).thenThrow(
      const LocalAuthException(
        code: LocalAuthExceptionCode.systemCanceled,
        description: 'failed',
      ),
    );

    final service = LockService(
      localAuth: mockAuth,
      prefs: await prefs(),
    );
    expect(await service.authenticateWithBiometrics('Unlock'), isFalse);
  });

  test('canUseBiometrics returns true when canCheckBiometrics is true', () async {
    when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);

    final service = LockService(
      localAuth: mockAuth,
      prefs: await prefs(),
    );
    expect(await service.canUseBiometrics(), isTrue);
  });

  test('deletePinData deletes hash, salt, and lockout keys', () async {
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.deletePinData();

    verify(() => mockStorage.delete(key: 'lock_pin_hash')).called(1);
    verify(() => mockStorage.delete(key: 'lock_pin_salt')).called(1);
    verify(() => mockStorage.delete(key: 'lock_failed_attempts')).called(1);
    verify(() => mockStorage.delete(key: 'lock_lockout_until')).called(1);
  });

  group('lockout', () {
    late Map<String, String> store;
    late DateTime fakeNow;

    setUp(() {
      store = <String, String>{};
      stubSecureStore(mockStorage, store);
      fakeNow = DateTime.utc(2026, 4, 10, 12);
    });

    LockService serviceWithClock() => LockService(
          storage: mockStorage,
          prefs: null,
          clock: () => fakeNow,
        );

    test('recordFailedAttempt increments counter in storage', () async {
      final service = serviceWithClock();
      await service.recordFailedAttempt();
      expect(store['lock_failed_attempts'], '1');
      await service.recordFailedAttempt();
      expect(store['lock_failed_attempts'], '2');
    });

    test('isLockedOut returns false before threshold', () async {
      final service = serviceWithClock();
      await service.recordFailedAttempt();
      await service.recordFailedAttempt();
      expect(await service.isLockedOut(), isFalse);
    });

    test('isLockedOut returns true after 3 attempts', () async {
      final service = serviceWithClock();
      for (var i = 0; i < 3; i++) {
        await service.recordFailedAttempt();
      }
      expect(await service.isLockedOut(), isTrue);
      final remaining = await service.lockoutRemaining();
      expect(remaining.inSeconds, 30);
    });

    test('isLockedOut returns false after lockout expires', () async {
      final service = serviceWithClock();
      for (var i = 0; i < 3; i++) {
        await service.recordFailedAttempt();
      }
      expect(await service.isLockedOut(), isTrue);

      fakeNow = fakeNow.add(const Duration(seconds: 31));
      expect(await service.isLockedOut(), isFalse);
      expect((await service.lockoutRemaining()), Duration.zero);
    });

    test('lockout escalates: 5 attempts → 60s', () async {
      final service = serviceWithClock();
      for (var i = 0; i < 5; i++) {
        await service.recordFailedAttempt();
      }
      final remaining = await service.lockoutRemaining();
      expect(remaining.inSeconds, 60);
    });

    test('lockout escalates: 7 attempts → 300s', () async {
      final service = serviceWithClock();
      for (var i = 0; i < 7; i++) {
        await service.recordFailedAttempt();
      }
      final remaining = await service.lockoutRemaining();
      expect(remaining.inSeconds, 300);
    });

    test('lockout escalates: 10 attempts → 900s', () async {
      final service = serviceWithClock();
      for (var i = 0; i < 10; i++) {
        await service.recordFailedAttempt();
      }
      final remaining = await service.lockoutRemaining();
      expect(remaining.inSeconds, 900);
    });

    test('resetLockoutState clears counter and lockout', () async {
      final service = serviceWithClock();
      for (var i = 0; i < 3; i++) {
        await service.recordFailedAttempt();
      }
      expect(await service.isLockedOut(), isTrue);

      await service.resetLockoutState();
      expect(await service.isLockedOut(), isFalse);
      expect(store.containsKey('lock_failed_attempts'), isFalse);
      expect(store.containsKey('lock_lockout_until'), isFalse);
    });

    test('verifyPin success resets lockout state', () async {
      final service = LockService(
        storage: mockStorage,
        prefs: null,
        clock: () => fakeNow,
      );
      await service.createPin('123456');
      for (var i = 0; i < 3; i++) {
        await service.recordFailedAttempt();
      }
      expect(await service.isLockedOut(), isTrue);

      final ok = await service.verifyPin('123456');
      expect(ok, isTrue);
      expect(await service.isLockedOut(), isFalse);
      expect(store.containsKey('lock_failed_attempts'), isFalse);
    });
  });
}
