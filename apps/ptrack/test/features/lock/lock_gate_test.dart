import 'package:flutter/material.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:luma/features/lock/lock_gate.dart';
import 'package:luma/features/lock/lock_screen.dart';
import 'package:luma/features/lock/lock_service.dart';
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
    when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
    when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);
  });

  Future<LockService> buildService({required Map<String, Object> prefsValues}) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return LockService(
      prefs: prefs,
      storage: mockStorage,
      localAuth: mockAuth,
    );
  }

  testWidgets('LockGate shows child when lock is disabled', (tester) async {
    final lockService = await buildService(prefsValues: {});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LockGate(
          lockService: lockService,
          onReset: () {},
          child: const Text('inside_tab_shell'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('inside_tab_shell'), findsOneWidget);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('LockGate shows LockScreen when lock is enabled', (tester) async {
    final lockService = await buildService(prefsValues: {'lock_enabled': true});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LockGate(
          lockService: lockService,
          onReset: () {},
          child: const Text('inside_tab_shell'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('inside_tab_shell'), findsNothing);
  });

  testWidgets(
    'Lock now pops pushed route so LockScreen is on top when lock enabled',
    (tester) async {
      final lockService = await buildService(prefsValues: {'lock_enabled': true});
      final navKey = GlobalKey<NavigatorState>();
      final signal = ValueNotifier<int>(0);
      addTearDown(signal.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: navKey,
          home: LockGate(
            lockService: lockService,
            onReset: () {},
            onBeforeLock: () =>
                navKey.currentState?.popUntil((route) => route.isFirst),
            lockNowSignal: signal,
            child: const Text('inside_tab_shell'),
          ),
        ),
      );
      await tester.pump();

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('dummy_overlay_route')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('dummy_overlay_route'), findsOneWidget);

      signal.value++;
      await tester.pumpAndSettle();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('dummy_overlay_route'), findsNothing);
    },
  );

  testWidgets(
    'Lock now signal does not pop routes when lock is disabled',
    (tester) async {
      final lockService = await buildService(prefsValues: {});
      final navKey = GlobalKey<NavigatorState>();
      final signal = ValueNotifier<int>(0);
      addTearDown(signal.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: navKey,
          home: LockGate(
            lockService: lockService,
            onReset: () {},
            onBeforeLock: () =>
                navKey.currentState?.popUntil((route) => route.isFirst),
            lockNowSignal: signal,
            child: const Text('inside_tab_shell'),
          ),
        ),
      );
      await tester.pump();

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('dummy_overlay_route')),
        ),
      );
      await tester.pumpAndSettle();

      signal.value++;
      await tester.pumpAndSettle();

      expect(find.byType(LockScreen), findsNothing);
      expect(find.text('dummy_overlay_route'), findsOneWidget);
    },
  );
}
