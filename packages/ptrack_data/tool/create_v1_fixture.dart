// Regenerates test/fixtures/ptrack_v1.sqlite — run from package root:
//   fvm dart run tool/create_v1_fixture.dart
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main() {
  final root = Directory.current;
  final out = File('${root.path}/test/fixtures/ptrack_v1.sqlite');
  out.parent.createSync(recursive: true);
  if (out.existsSync()) {
    out.deleteSync();
  }

  final db = sqlite3.open(out.path);
  try {
    db.execute('''
CREATE TABLE periods (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  start_utc INTEGER NOT NULL,
  end_utc INTEGER
);
''');

    int sec(DateTime d) => d.toUtc().millisecondsSinceEpoch ~/ 1000;

    final s1 = sec(DateTime.utc(2024, 2, 1));
    final e1 = sec(DateTime.utc(2024, 2, 5));
    final s2 = sec(DateTime.utc(2024, 3, 1));

    db.execute(
      'INSERT INTO periods (start_utc, end_utc) VALUES ($s1, $e1)',
    );
    db.execute('INSERT INTO periods (start_utc, end_utc) VALUES ($s2, NULL)');

    db.execute('PRAGMA user_version = 1');
  } finally {
    db.close();
  }

  // ignore: avoid_print
  print('Wrote ${out.path}');
}
