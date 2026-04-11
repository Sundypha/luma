import 'package:drift/drift.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../db/ptrack_database.dart';

DateTime _calendarDateAsUtc(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day);

/// Maps a Drift [DayEntry] row to [DayEntryData].
DayEntryData dayEntryRowToDomain(DayEntry row) {
  return DayEntryData(
    dateUtc: _calendarDateAsUtc(row.dateUtc),
    flowIntensity: row.flowIntensity != null
        ? FlowIntensity.fromDbValue(row.flowIntensity!)
        : null,
    painScore:
        row.painScore != null ? PainScore.fromDbValue(row.painScore!) : null,
    mood: row.mood != null ? Mood.fromDbValue(row.mood!) : null,
    notes: row.notes,
    personalNotes: row.personalNotes,
  );
}

/// Insert companion for a new day entry under [periodId].
DayEntriesCompanion dayEntryDataToInsertCompanion(
  int periodId,
  DayEntryData data,
) {
  return DayEntriesCompanion.insert(
    periodId: periodId,
    dateUtc: _calendarDateAsUtc(data.dateUtc),
    flowIntensity: Value(data.flowIntensity?.dbValue),
    painScore: Value(data.painScore?.dbValue),
    mood: Value(data.mood?.dbValue),
    notes: Value(data.notes),
    // Omit nullable text columns when null so INSERT matches DBs that only gained
    // personal_notes via ALTER (implicit NULL) and avoids some driver edge cases.
    personalNotes: Value.absentIfNull(data.personalNotes),
  );
}

/// Update companion from [data] (typically keyed by id elsewhere).
DayEntriesCompanion dayEntryDataToUpdateCompanion(DayEntryData data) {
  return DayEntriesCompanion(
    dateUtc: Value(_calendarDateAsUtc(data.dateUtc)),
    flowIntensity: Value(data.flowIntensity?.dbValue),
    painScore: Value(data.painScore?.dbValue),
    mood: Value(data.mood?.dbValue),
    notes: Value(data.notes),
    personalNotes: Value(data.personalNotes),
  );
}
