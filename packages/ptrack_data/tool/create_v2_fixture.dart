// Regenerates test/fixtures/ptrack_v2.sqlite — run from package root:
//   fvm dart run tool/create_v2_fixture.dart
//
// Uses raw SQL (no Flutter imports) so the script runs on the Dart VM.
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main() {
  final root = Directory.current;
  final out = File('${root.path}/test/fixtures/ptrack_v2.sqlite');
  out.parent.createSync(recursive: true);
  if (out.existsSync()) {
    out.deleteSync();
  }

  int sec(DateTime d) => d.toUtc().millisecondsSinceEpoch ~/ 1000;

  final db = sqlite3.open(out.path);
  try {
    db.execute('''
CREATE TABLE periods (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  start_utc INTEGER NOT NULL,
  end_utc INTEGER
);
''');

    db.execute('''
CREATE TABLE day_entries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  period_id INTEGER NOT NULL REFERENCES periods (id),
  date_utc INTEGER NOT NULL,
  flow_intensity INTEGER,
  pain_score INTEGER,
  mood INTEGER,
  notes TEXT,
  UNIQUE (period_id, date_utc)
);
''');

    final s1 = sec(DateTime.utc(2024, 2, 1));
    final e1 = sec(DateTime.utc(2024, 2, 5));
    final s2 = sec(DateTime.utc(2024, 3, 1));
    final dayUtc = sec(DateTime.utc(2024, 2, 2));

    db.execute(
      'INSERT INTO periods (start_utc, end_utc) VALUES ($s1, $e1)',
    );
    db.execute('INSERT INTO periods (start_utc, end_utc) VALUES ($s2, NULL)');

    // FlowIntensity.medium=2, PainScore.mild=2, Mood.good=4
    db.execute('''
INSERT INTO day_entries (period_id, date_utc, flow_intensity, pain_score, mood, notes)
VALUES (1, $dayUtc, 2, 2, 4, 'fixture v2');
''');

    db.execute('PRAGMA user_version = 2');
  } finally {
    db.close();
  }

  // ignore: avoid_print
  print('Wrote ${out.path}');
}
