import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;

/// First algorithm activates with ≥1 cycle; second with ≥2 (milestone testing).
class _StagedMinCyclesAlgorithm implements PredictionAlgorithm {
  const _StagedMinCyclesAlgorithm({
    required this.id,
    required this.minCycles,
    required this.displayName,
  });

  @override
  final AlgorithmId id;

  @override
  final int minCycles;

  @override
  final String displayName;

  @override
  AlgorithmPrediction? predict(List<PredictionCycleInput> cycles) {
    if (cycles.length < minCycles) return null;
    final anchor = utcCalendarDateOnly(cycles.last.periodStartUtc);
    return AlgorithmPrediction(
      algorithmId: id,
      predictedStartUtc: addUtcCalendarDays(anchor, 28),
      predictedDurationDays: 5,
      explanationSteps: const [],
    );
  }
}

void expectUtcMidnight(DateTime d) {
  expect(d.isUtc, isTrue);
  expect(d.hour, 0);
  expect(d.minute, 0);
  expect(d.second, 0);
  expect(d.microsecond, 0);
}

List<StoredPeriod> _threePeriods28DayCycles() {
  return [
    StoredPeriod(
      id: 1,
      span: PeriodSpan(
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 1, 5),
      ),
    ),
    StoredPeriod(
      id: 2,
      span: PeriodSpan(
        startUtc: DateTime.utc(2026, 1, 29),
        endUtc: DateTime.utc(2026, 2, 2),
      ),
    ),
    StoredPeriod(
      id: 3,
      span: PeriodSpan(
        startUtc: DateTime.utc(2026, 2, 26),
        endUtc: DateTime.utc(2026, 3, 2),
      ),
    ),
  ];
}

/// [lengths].length + 1 closed periods; consecutive starts spaced by [lengths];
/// each bleed span is 4 UTC calendar days (median duration for ensemble).
List<StoredPeriod> _storedPeriodsForCycleLengths(List<int> lengths) {
  var start = DateTime.utc(2025, 1, 1);
  final out = <StoredPeriod>[];
  for (var i = 0; i <= lengths.length; i++) {
    final end = addUtcCalendarDays(start, 3);
    out.add(
      StoredPeriod(
        id: i + 1,
        span: PeriodSpan(startUtc: start, endUtc: end),
      ),
    );
    if (i < lengths.length) {
      start = addUtcCalendarDays(start, lengths[i]);
    }
  }
  return out;
}

List<StoredPeriod> _sixPeriodsLinearLengths() {
  // Same spacing as LinearTrendAlgorithm test [26,27,28,29,30] → R² = 1, projection ~31.
  return _storedPeriodsForCycleLengths([26, 27, 28, 29, 30]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  late PeriodCalendarContext utcCtx;

  setUp(() {
    utcCtx = PeriodCalendarContext.fromTimeZoneName('UTC');
  });

  group('EnsembleCoordinator', () {
    test('0 cycles → no active algorithms, empty dayConfidenceMap', () {
      final coord = EnsembleCoordinator();
      final out = coord.predictNext(
        storedPeriods: const [],
        calendar: utcCtx,
      );
      expect(out.activeAlgorithmCount, 0);
      expect(out.dayConfidenceMap, isEmpty);
      expect(out.algorithmOutputs, isEmpty);
      expect(out.consensusPrediction, isA<PredictionInsufficientHistory>());
    });

    test('2 cycle inputs → 3 core algorithms, linear null, map non-empty', () {
      final coord = EnsembleCoordinator();
      final stored = _threePeriods28DayCycles();
      final out = coord.predictNext(
        storedPeriods: stored,
        calendar: utcCtx,
      );
      expect(out.activeAlgorithmCount, 3);
      expect(out.totalAlgorithmCount, 4);
      expect(out.algorithmOutputs.map((e) => e.algorithmId).toSet(), {
        AlgorithmId.median,
        AlgorithmId.ewma,
        AlgorithmId.bayesian,
      });
      expect(out.dayConfidenceMap, isNotEmpty);
    });

    test('5+ cycles with strong trend → 4 algorithms, agreement 1–4 possible', () {
      final coord = EnsembleCoordinator();
      final out = coord.predictNext(
        storedPeriods: _sixPeriodsLinearLengths(),
        calendar: utcCtx,
      );
      expect(out.activeAlgorithmCount, 4);
      final counts = out.dayConfidenceMap.values.toSet()..remove(0);
      expect(counts.isNotEmpty, isTrue);
      expect(out.dayConfidenceMap.values.any((c) => c >= 1), isTrue);
    });

    test('milestone when crossing 1 → 2 active algorithms', () {
      final coord = EnsembleCoordinator(
        algorithms: const [
          _StagedMinCyclesAlgorithm(
            id: AlgorithmId.median,
            minCycles: 1,
            displayName: 'Early',
          ),
          _StagedMinCyclesAlgorithm(
            id: AlgorithmId.ewma,
            minCycles: 2,
            displayName: 'Late',
          ),
        ],
      );

      final twoPeriods = _threePeriods28DayCycles().sublist(0, 2);
      final oneCycleOut = coord.predictNext(
        storedPeriods: twoPeriods,
        calendar: utcCtx,
      );
      expect(oneCycleOut.activeAlgorithmCount, 1);

      final threePeriods = _threePeriods28DayCycles();
      final twoCycleOut = coord.predictNext(
        storedPeriods: threePeriods,
        calendar: utcCtx,
        previousActiveCount: 1,
      );
      expect(twoCycleOut.activeAlgorithmCount, 2);
      expect(twoCycleOut.milestoneMessage, isNotNull);
      expect(
        twoCycleOut.milestoneMessage,
        contains('2 methods for better accuracy'),
      );
    });

    test('consensusPrediction matches PredictionCoordinator result', () {
      final stored = _threePeriods28DayCycles();
      final ensemble = EnsembleCoordinator().predictNext(
        storedPeriods: stored,
        calendar: utcCtx,
      );
      final direct = PredictionCoordinator().predictNext(
        storedPeriods: stored,
        calendar: utcCtx,
      );
      expect(ensemble.consensusPrediction, direct.result);
    });

    test('dayConfidenceMap keys are UTC midnight', () {
      final out = EnsembleCoordinator().predictNext(
        storedPeriods: _threePeriods28DayCycles(),
        calendar: utcCtx,
      );
      for (final k in out.dayConfidenceMap.keys) {
        expectUtcMidnight(k);
      }
    });

    test('shared duration: 4-day bleeding spans → predictedDurationDays 4', () {
      final stored = [
        StoredPeriod(
          id: 1,
          span: PeriodSpan(
            startUtc: DateTime.utc(2026, 1, 1),
            endUtc: DateTime.utc(2026, 1, 4),
          ),
        ),
        StoredPeriod(
          id: 2,
          span: PeriodSpan(
            startUtc: DateTime.utc(2026, 1, 29),
            endUtc: DateTime.utc(2026, 2, 1),
          ),
        ),
        StoredPeriod(
          id: 3,
          span: PeriodSpan(
            startUtc: DateTime.utc(2026, 2, 26),
            endUtc: DateTime.utc(2026, 3, 1),
          ),
        ),
      ];
      expect(EnsembleCoordinator.medianBleedingDurationDays(stored), 4);
      final out = EnsembleCoordinator().predictNext(
        storedPeriods: stored,
        calendar: utcCtx,
      );
      for (final o in out.algorithmOutputs) {
        expect(o.predictedDurationDays, 4);
      }
    });

    test('ensemble explanation omits forbidden phrases', () {
      final out = EnsembleCoordinator().predictNext(
        storedPeriods: _threePeriods28DayCycles(),
        calendar: utcCtx,
      );
      final lower = out.explanationText.toLowerCase();
      for (final phrase in predictionCopyForbiddenPhrasesLowercase) {
        expect(lower, isNot(contains(phrase)));
      }
    });
  });
}
