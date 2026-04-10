import 'dart:typed_data';

import 'import_file_bytes_io.dart'
    if (dart.library.html) 'import_file_bytes_web.dart' as impl;

Future<Uint8List?> readPickedFileBytes({
  Uint8List? memoryBytes,
  String? path,
}) =>
    impl.readPickedFileBytes(memoryBytes: memoryBytes, path: path);
