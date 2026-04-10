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
