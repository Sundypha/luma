import 'package:drift/drift.dart';

/// Persisted period rows: UTC instants only (see [ptrack_domain.PeriodSpan]).
class Periods extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get startUtc => dateTime()();

  DateTimeColumn get endUtc => dateTime().nullable()();
}

/// Per-day symptom log rows for a period (all symptom columns optional).
class DayEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get periodId => integer().references(Periods, #id)();

  DateTimeColumn get dateUtc => dateTime()();

  IntColumn get flowIntensity => integer().nullable()();

  IntColumn get painScore => integer().nullable()();

  IntColumn get mood => integer().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{periodId, dateUtc}];
}

/// Standalone personal diary entries keyed by calendar date (no period FK).
@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get dateUtc => dateTime()();

  IntColumn get mood => integer().nullable()();

  TextColumn get notes => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [{dateUtc}];
}

/// Tag definitions for diary entries (flat, no hierarchy).
@DataClassName('DiaryTagRow')
class DiaryTags extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  @override
  List<Set<Column>> get uniqueKeys => [{name}];
}

/// Many-to-many join between diary entries and tags.
class DiaryEntryTagJoin extends Table {
  IntColumn get diaryEntryId =>
      integer().references(DiaryEntries, #id)();

  IntColumn get tagId => integer().references(DiaryTags, #id)();

  @override
  Set<Column> get primaryKey => {diaryEntryId, tagId};
}
