import '../db/ptrack_database.dart';
import 'export_schema.dart';

DateTime _utcCalendarMidnight(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day);

bool _periodRangesOverlap(
  DateTime aStart,
  DateTime? aEnd,
  DateTime bStart,
  DateTime? bEnd,
) {
  final aEndEff = aEnd ?? DateTime.utc(9999, 12, 31, 23, 59, 59);
  final bEndEff = bEnd ?? DateTime.utc(9999, 12, 31, 23, 59, 59);
  return !aStart.isAfter(aEndEff) && !bStart.isAfter(bEndEff);
}

/// Counts produced by [ImportPreview.analyze].
final class ImportPreviewResult {
  const ImportPreviewResult({
    required this.newPeriods,
    required this.existingPeriodOverlaps,
    required this.newEntries,
    required this.duplicateEntries,
    required this.totalPeriods,
    required this.totalEntries,
  });

  final int newPeriods;
  final int existingPeriodOverlaps;
  final int newEntries;
  final int duplicateEntries;
  final int totalPeriods;
  final int totalEntries;
}

/// Compares an export payload to the current database for duplicate preview.
final class ImportPreview {
  ImportPreview._();

  static Future<ImportPreviewResult> analyze(
    LumaExportData data,
    PtrackDatabase db,
  ) async {
    final existingDayRows = await db.select(db.dayEntries).get();
    final existingDates = <DateTime>{
      for (final row in existingDayRows) _utcCalendarMidnight(row.dateUtc),
    };

    final importedEntries = data.dayEntries ?? const <ExportedDayEntry>[];
    var newEntries = 0;
    var duplicateEntries = 0;
    for (final e in importedEntries) {
      final d = _utcCalendarMidnight(DateTime.parse(e.dateUtc).toUtc());
      if (existingDates.contains(d)) {
        duplicateEntries++;
      } else {
        newEntries++;
      }
    }

    final existingPeriods = await db.select(db.periods).get();
    final importedPeriods = data.periods ?? const <ExportedPeriod>[];
    var existingPeriodOverlaps = 0;
    for (final ip in importedPeriods) {
      final iStart = DateTime.parse(ip.startUtc).toUtc();
      final iEnd =
          ip.endUtc != null ? DateTime.parse(ip.endUtc!).toUtc() : null;
      var overlaps = false;
      for (final ep in existingPeriods) {
        if (_periodRangesOverlap(
          iStart,
          iEnd,
          ep.startUtc.toUtc(),
          ep.endUtc?.toUtc(),
        )) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) {
        existingPeriodOverlaps++;
      }
    }

    final totalPeriods = importedPeriods.length;
    final newPeriods = totalPeriods - existingPeriodOverlaps;

    return ImportPreviewResult(
      newPeriods: newPeriods,
      existingPeriodOverlaps: existingPeriodOverlaps,
      newEntries: newEntries,
      duplicateEntries: duplicateEntries,
      totalPeriods: totalPeriods,
      totalEntries: importedEntries.length,
    );
  }
}
