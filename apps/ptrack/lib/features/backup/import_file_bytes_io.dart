import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readPickedFileBytes({
  Uint8List? memoryBytes,
  String? path,
}) async {
  if (memoryBytes != null) return memoryBytes;
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
