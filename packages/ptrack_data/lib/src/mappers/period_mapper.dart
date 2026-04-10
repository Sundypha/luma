import 'package:drift/drift.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

import '../db/ptrack_database.dart';

/// Maps a Drift [Period] row to a domain [PeriodSpan].
PeriodSpan periodRowToDomain(Period row) {
  return PeriodSpan(startUtc: row.startUtc, endUtc: row.endUtc);
}

/// Builds an insert companion from [span] (new row).
PeriodsCompanion periodSpanToInsertCompanion(PeriodSpan span) {
  return PeriodsCompanion.insert(
    startUtc: span.startUtc,
    endUtc: Value(span.endUtc),
  );
}

/// Builds an update companion from [span] for an existing row.
PeriodsCompanion periodSpanToUpdateCompanion(PeriodSpan span) {
  return PeriodsCompanion(
    startUtc: Value(span.startUtc),
    endUtc: Value(span.endUtc),
  );
}
