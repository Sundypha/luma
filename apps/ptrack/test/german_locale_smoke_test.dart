import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:luma/features/lock/lock_service.dart';
import 'package:luma/features/shell/tab_shell.dart';
import 'package:luma/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class MockPeriodRepository extends Mock implements PeriodRepository {}

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  late MockPeriodRepository mockRepo;
  late MockDiaryRepository mockDiary;
  late MockFlutterSecureStorage mockStorage;
  late MockLocalAuthentication mockAuth;
  late PeriodCalendarContext calendar;

  setUp(() {
    mockRepo = MockPeriodRepository();
    mockDiary = MockDiaryRepository();
    mockStorage = MockFlutterSecureStorage();
    mockAuth = MockLocalAuthentication();
    calendar = PeriodCalendarContext.fromTimeZoneName('UTC');
    when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
    when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => false);
    SharedPreferences.setMockInitialValues({});
    when(() => mockRepo.watchPeriodsWithDays()).thenAnswer(
      (_) => Stream<List<StoredPeriodWithDays>>.value(const []),
    );
    when(() => mockDiary.watchAllEntries()).thenAnswer(
      (_) => Stream<List<StoredDiaryEntry>>.value(const []),
    );
    when(() => mockDiary.seedStarterTags()).thenAnswer((_) async {});
    when(() => mockDiary.watchEntryCount()).thenAnswer(
      (_) => Stream<int>.value(0),
    );
    when(
      () => mockDiary.getEntriesPage(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => <StoredDiaryEntry>[]);
    when(() => mockDiary.watchTags()).thenAnswer(
      (_) => Stream<List<DiaryTag>>.value(const []),
    );
    when(() => mockDiary.getEntryForDate(any())).thenAnswer((_) async => null);
  });

  Future<LockService> lockServiceForTest() async {
    final prefs = await SharedPreferences.getInstance();
    return LockService(
      prefs: prefs,
      storage: mockStorage,
      localAuth: mockAuth,
    );
  }

  testWidgets('German locale: home shell resolves AppLocalizations', (
    tester,
  ) async {
    final lockService = await lockServiceForTest();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TabShell(
          repository: mockRepo,
          calendar: calendar,
          diaryRepository: mockDiary,
          lockService: lockService,
          onReset: () {},
          onLockNow: () {},
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text(
        'Trag noch ein paar Perioden ein, um Zyklus-Einblicke zu sehen',
      ),
      findsOneWidget,
    );
  });

  testWidgets('German locale: settings screen from drawer builds', (
    tester,
  ) async {
    final lockService = await lockServiceForTest();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TabShell(
          repository: mockRepo,
          calendar: calendar,
          diaryRepository: mockDiary,
          lockService: lockService,
          onReset: () {},
          onLockNow: () {},
        ),
      ),
    );
    await tester.pump();
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einstellungen'));
    await tester.pumpAndSettle();
    expect(find.text('Einstellungen'), findsWidgets);
  });
}
