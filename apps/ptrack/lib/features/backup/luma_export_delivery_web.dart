import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:share_plus/share_plus.dart';

Future<void> deliverLumaExport(BuildContext context, ExportResult result) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          result.bytes,
          name: result.filename,
          mimeType: 'application/octet-stream',
        ),
      ],
    ),
  );
}
