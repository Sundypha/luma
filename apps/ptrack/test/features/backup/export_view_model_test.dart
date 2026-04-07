import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/backup/export_view_model.dart';
import 'package:ptrack_data/ptrack_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportViewModel', () {
    test('preset everything sets all toggles true', () {
      final vm = ExportViewModel()
        ..applyPreset(ExportPreset.periodsOnly)
        ..applyPreset(ExportPreset.everything);
      expect(vm.includePeriods, isTrue);
      expect(vm.includeSymptoms, isTrue);
      expect(vm.includeNotes, isTrue);
    });

    test('preset periodsOnly sets only periods true', () {
      final vm = ExportViewModel()
        ..applyPreset(ExportPreset.everything)
        ..applyPreset(ExportPreset.periodsOnly);
      expect(vm.includePeriods, isTrue);
      expect(vm.includeSymptoms, isFalse);
      expect(vm.includeNotes, isFalse);
    });

    test('toggleSymptoms flips the value and notifies', () {
      final vm = ExportViewModel();
      var n = 0;
      vm.addListener(() => n++);
      expect(vm.includeSymptoms, isTrue);
      vm.toggleSymptoms();
      expect(vm.includeSymptoms, isFalse);
      expect(n, 1);
    });

    test('startExport transitions to done with result', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final vm = ExportViewModel();
      final service = ExportService(db);
      await vm.startExport(service);
      expect(vm.step, ExportStep.done);
      expect(vm.result, isNotNull);
      expect(vm.result!.meta.encrypted, isFalse);
    });

    test('runExport when export throws transitions to error', () async {
      final vm = ExportViewModel();
      await vm.runExport(
        ({required options, onProgress}) async {
          throw StateError('export failed');
        },
      );
      expect(vm.step, ExportStep.error);
      expect(
        vm.errorMessage,
        'Could not complete export. Please try again.',
      );
    });

    test('password is passed through to export (encrypted meta)', () async {
      final db = PtrackDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final vm = ExportViewModel()..setPassword('secret');
      await vm.startExport(ExportService(db));
      expect(vm.step, ExportStep.done);
      expect(vm.result!.meta.encrypted, isTrue);
    });

    test('cannot nextStep from selectContent when all toggles are false', () {
      final vm = ExportViewModel()
        ..togglePeriods()
        ..toggleSymptoms()
        ..toggleNotes();
      expect(vm.hasContentSelection, isFalse);
      vm.nextStep();
      expect(vm.step, ExportStep.selectContent);
    });
  });
}
