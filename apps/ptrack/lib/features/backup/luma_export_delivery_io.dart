import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:share_plus/share_plus.dart';

Future<void> deliverLumaExport(BuildContext context, ExportResult result) async {
  if (Platform.isLinux) {
    final path = await FilePicker.saveFile(
      fileName: result.filename,
      bytes: result.bytes,
    );
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup saved')),
      );
    }
    return;
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${result.filename}');
  try {
    await file.writeAsBytes(result.bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  } finally {
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }
}
