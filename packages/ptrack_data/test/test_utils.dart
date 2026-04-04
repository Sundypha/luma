import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Creates a temporary directory and registers recursive delete on tear down.
///
/// Returns `path/to/db.sqlite` inside that directory.
String createTempSqlitePath() {
  final dir = Directory.systemTemp.createTempSync('ptrack_data_');
  addTearDown(() {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });
  return '${dir.path}/test.sqlite';
}
