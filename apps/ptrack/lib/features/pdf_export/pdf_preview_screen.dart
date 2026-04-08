import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Scrollable in-app PDF preview with share (or save on Linux).
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.filename,
  });

  final Uint8List pdfBytes;
  final String filename;

  Future<void> _shareOrSave(BuildContext context) async {
    if (Platform.isLinux) {
      final path = await FilePicker.saveFile(
        fileName: filename,
        bytes: pdfBytes,
      );
      if (!context.mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report saved')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    try {
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _shareOrSave(context),
          ),
        ],
      ),
      body: Platform.isLinux
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Preview is not available on this platform. '
                      'Use Share to save the PDF.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _shareOrSave(context),
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Save PDF'),
                    ),
                  ],
                ),
              ),
            )
          : PdfPreview(
              build: (format) async => pdfBytes,
              canChangePageFormat: false,
              canDebug: false,
            ),
    );
  }
}
