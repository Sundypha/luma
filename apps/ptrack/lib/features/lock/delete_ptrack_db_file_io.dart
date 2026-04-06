import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<void> deletePtrackDatabaseFileIfExists() async {
  try {
    late final String resolvedPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      resolvedPath = '${dir.path}/ptrack.sqlite';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      resolvedPath = '${dir.path}/ptrack.sqlite';
    }
    final file = File(resolvedPath);
    if (await file.exists()) {
      await file.delete();
    }
  } on Object {
    // Best-effort wipe; continue reset flow.
  }
}
