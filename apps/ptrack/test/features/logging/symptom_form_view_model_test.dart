import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ptrack/features/logging/symptom_form_view_model.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

class MockPeriodRepository extends Mock implements PeriodRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPeriodRepository mockRepo;
  final day = DateTime.utc(2025, 6, 10);
  const periodId = 7;

  setUp(() {
    mockRepo = MockPeriodRepository();
    registerFallbackValue(
      DayEntryData(dateUtc: DateTime.utc(2020, 1, 1)),
    );
  });

  test('initial state uses defaults when no existing entry', () {
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
    );
    expect(vm.flowIntensity, isNull);
    expect(vm.painScore, isNull);
    expect(vm.mood, isNull);
    expect(vm.notes, '');
    expect(vm.isEditing, isFalse);
    expect(vm.isSaving, isFalse);
    vm.dispose();
  });

  test('initial state reflects existing entry', () {
    final existing = StoredDayEntry(
      id: 42,
      periodId: periodId,
      data: DayEntryData(
        dateUtc: day,
        flowIntensity: FlowIntensity.medium,
        painScore: PainScore.mild,
        mood: Mood.good,
        notes: 'hello',
      ),
    );
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
      existing: existing,
    );
    expect(vm.flowIntensity, FlowIntensity.medium);
    expect(vm.painScore, PainScore.mild);
    expect(vm.mood, Mood.good);
    expect(vm.notes, 'hello');
    expect(vm.isEditing, isTrue);
    vm.dispose();
  });

  test('setters update state and notify listeners', () {
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
    );
    var count = 0;
    vm.addListener(() => count++);
    vm.setFlow(FlowIntensity.light);
    expect(vm.flowIntensity, FlowIntensity.light);
    vm.setPain(PainScore.severe);
    expect(vm.painScore, PainScore.severe);
    vm.setMood(Mood.neutral);
    expect(vm.mood, Mood.neutral);
    vm.setNotes('n');
    expect(vm.notes, 'n');
    expect(count, 4);
    vm.dispose();
  });

  test('save() create calls upsertDayEntryForPeriod with built data', () async {
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any()))
        .thenAnswer((_) async => 99);
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
    );
    vm.setFlow(FlowIntensity.heavy);
    vm.setPain(PainScore.none);
    vm.setMood(Mood.bad);
    vm.setNotes('  x  ');
    final ok = await vm.save();
    expect(ok, isTrue);
    final captured = verify(
      () => mockRepo.upsertDayEntryForPeriod(periodId, captureAny()),
    ).captured.single as DayEntryData;
    expect(captured.dateUtc, DateTime.utc(2025, 6, 10));
    expect(captured.flowIntensity, FlowIntensity.heavy);
    expect(captured.painScore, PainScore.none);
    expect(captured.mood, Mood.bad);
    expect(captured.notes, 'x');
    verifyNever(() => mockRepo.updateDayEntry(any(), any()));
    vm.dispose();
  });

  test('save() edit calls updateDayEntry with existing id', () async {
    final existing = StoredDayEntry(
      id: 42,
      periodId: periodId,
      data: DayEntryData(dateUtc: day, notes: 'old'),
    );
    when(() => mockRepo.updateDayEntry(any(), any())).thenAnswer((_) async => true);
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
      existing: existing,
    );
    vm.setNotes('');
    final ok = await vm.save();
    expect(ok, isTrue);
    verifyNever(() => mockRepo.upsertDayEntryForPeriod(any(), any()));
    final captured = verify(() => mockRepo.updateDayEntry(42, captureAny()))
        .captured
        .single as DayEntryData;
    expect(captured.notes, isNull);
    vm.dispose();
  });

  test('save() sets isSaving during async operation', () async {
    final completer = Completer<int>();
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any()))
        .thenAnswer((_) => completer.future);
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
    );
    final future = vm.save();
    await Future<void>.delayed(Duration.zero);
    expect(vm.isSaving, isTrue);
    completer.complete(1);
    await future;
    expect(vm.isSaving, isFalse);
    vm.dispose();
  });

  test('save() records error and returns false on failure', () async {
    when(() => mockRepo.upsertDayEntryForPeriod(any(), any()))
        .thenThrow(StateError('bad'));
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
    );
    final ok = await vm.save();
    expect(ok, isFalse);
    expect(vm.isSaving, isFalse);
    expect(vm.errorText, contains('bad'));
    vm.dispose();
  });

  test('clearSymptoms calls deleteDayEntry when editing', () async {
    final existing = StoredDayEntry(
      id: 42,
      periodId: periodId,
      data: DayEntryData(dateUtc: day),
    );
    when(() => mockRepo.deleteDayEntry(42)).thenAnswer((_) async => true);
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
      existing: existing,
    );
    final ok = await vm.clearSymptoms();
    expect(ok, isTrue);
    verify(() => mockRepo.deleteDayEntry(42)).called(1);
    vm.dispose();
  });

  test('clearSymptoms returns false when not editing', () async {
    final vm = SymptomFormViewModel(
      repository: mockRepo,
      day: day,
      periodId: periodId,
    );
    final ok = await vm.clearSymptoms();
    expect(ok, isFalse);
    verifyNever(() => mockRepo.deleteDayEntry(any()));
    vm.dispose();
  });
}
