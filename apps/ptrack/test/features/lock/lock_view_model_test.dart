import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/lock/lock_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

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

  void stubStorageMap() {
    final store = <String, String>{};
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      final value = invocation.namedArguments[#value] as String?;
      if (value != null) {
        store[key] = value;
      }
    });
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((invocation) async {
      final key = invocation.namedArguments[#key] as String;
      return store[key];
    });
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((invocation) async {
      store.remove(invocation.namedArguments[#key] as String);
    });
  }

  test('verifyPin with correct PIN calls onUnlocked and leaves isLoading false',
      () async {
    stubStorageMap();
    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.createPin('1234');

    final vm = LockViewModel(lockService: service);
    var unlocked = 0;
    await vm.verifyPin('1234', onUnlocked: () => unlocked++);

    expect(unlocked, 1);
    expect(vm.isLoading, isFalse);
    expect(vm.hasError, isFalse);
    expect(vm.wrongPin, isFalse);
    vm.dispose();
  });

  test('verifyPin with wrong PIN sets error and does not call onUnlocked',
      () async {
    stubStorageMap();
    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.createPin('1234');

    final vm = LockViewModel(lockService: service);
    var unlocked = 0;
    await vm.verifyPin('0000', onUnlocked: () => unlocked++);

    expect(unlocked, 0);
    expect(vm.hasError, isTrue);
    expect(vm.wrongPin, isTrue);
    expect(vm.isLoading, isFalse);
    vm.dispose();
  });

  test('authenticateBiometric success calls onUnlocked once', () async {
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
    final vm = LockViewModel(lockService: service);
    var unlocked = 0;
    await vm.authenticateBiometric(
      onUnlocked: () => unlocked++,
      localizedReason: 'test reason',
    );

    expect(unlocked, 1);
    expect(vm.isLoading, isFalse);
    expect(vm.hasError, isFalse);
    vm.dispose();
  });

  test('authenticateBiometric failure sets hasError and skips onUnlocked',
      () async {
    when(
      () => mockAuth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        biometricOnly: true,
      ),
    ).thenAnswer((_) async => false);

    final service = LockService(
      localAuth: mockAuth,
      prefs: await prefs(),
    );
    final vm = LockViewModel(lockService: service);
    var unlocked = 0;
    await vm.authenticateBiometric(
      onUnlocked: () => unlocked++,
      localizedReason: 'test reason',
    );

    expect(unlocked, 0);
    expect(vm.hasError, isTrue);
    expect(vm.wrongPin, isFalse);
    expect(vm.isLoading, isFalse);
    vm.dispose();
  });

  test('clearError resets hasError', () async {
    stubStorageMap();
    final service = LockService(
      storage: mockStorage,
      prefs: await prefs(),
    );
    await service.createPin('1234');

    final vm = LockViewModel(lockService: service);
    await vm.verifyPin('0000', onUnlocked: () {});
    expect(vm.hasError, isTrue);

    vm.clearError();
    expect(vm.hasError, isFalse);
    expect(vm.wrongPin, isFalse);
    expect(vm.isLoading, isFalse);
    vm.dispose();
  });
}
