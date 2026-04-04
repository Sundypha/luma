import 'package:drift/drift.dart';

/// Persisted period rows: UTC instants only (see [ptrack_domain.PeriodSpan]).
class Periods extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get startUtc => dateTime()();

  DateTimeColumn get endUtc => dateTime().nullable()();
}
