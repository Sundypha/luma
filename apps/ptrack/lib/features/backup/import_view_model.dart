import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:ptrack_data/ptrack_data.dart';

import 'import_file_bytes.dart';

enum ImportStep {
  idle,
  pickingFile,
  passwordPrompt,
  previewing,
  chooseStrategy,
  importing,
  done,
  error,
}

/// State for the import backup flow (file → optional password → preview → apply).
final class ImportViewModel extends ChangeNotifier {
  ImportViewModel({
    required ImportService importService,
    required PtrackDatabase db,
    this.onPickerCancelled,
  })  : _importService = importService,
        _db = db;

  final ImportService _importService;
  final PtrackDatabase _db;
  final VoidCallback? onPickerCancelled;

  ImportStep _step = ImportStep.idle;
  LumaExportMeta? _meta;
  LumaExportData? _data;
  ImportPreviewResult? _preview;
  DuplicateStrategy _strategy = DuplicateStrategy.skip;
  double _progress = 0;
  String? _errorMessage;
  ImportResult? _result;
  bool _isEncrypted = false;
  Uint8List? _pendingFileBytes;
  bool _seenProgressDuringImport = false;

  ImportStep get step => _step;
  LumaExportMeta? get meta => _meta;
  LumaExportData? get data => _data;
  ImportPreviewResult? get preview => _preview;
  DuplicateStrategy get strategy => _strategy;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  ImportResult? get result => _result;
  bool get isEncrypted => _isEncrypted;
  bool get hasData => _data != null;
  bool get seenProgressDuringImport => _seenProgressDuringImport;

  Future<void> pickFile() async {
    _step = ImportStep.pickingFile;
    _errorMessage = null;
    notifyListeners();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['luma'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      _step = ImportStep.idle;
      notifyListeners();
      onPickerCancelled?.call();
      return;
    }
    final file = result.files.single;
    var bytes = file.bytes;
    bytes ??= await readPickedFileBytes(memoryBytes: file.bytes, path: file.path);
    if (bytes == null) {
      _errorMessage = 'Could not read the selected file.';
      _step = ImportStep.error;
      notifyListeners();
      return;
    }
    await handlePickedFile(bytes: bytes, fileName: file.name);
  }

  /// Parses and previews a picked file (used by [pickFile] and tests).
  Future<void> handlePickedFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lower = fileName.toLowerCase();
    if (!lower.endsWith('.luma')) {
      _errorMessage = 'Please select a .luma backup file';
      _step = ImportStep.error;
      notifyListeners();
      return;
    }
    try {
      final meta = _importService.parseFileMeta(bytes);
      _meta = meta;
      _isEncrypted = meta.encrypted;
      if (meta.encrypted) {
        _pendingFileBytes = bytes;
        _data = null;
        _preview = null;
        _step = ImportStep.passwordPrompt;
        notifyListeners();
        return;
      }
      final data = await _importService.parseFileData(bytes);
      _data = data;
      _pendingFileBytes = null;
      _preview = await ImportPreview.analyze(data, _db);
      _step = ImportStep.previewing;
      notifyListeners();
    } on LumaImportException catch (e) {
      _errorMessage = e.message;
      _step = ImportStep.error;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Could not read this backup file.';
      _step = ImportStep.error;
      notifyListeners();
    }
  }

  Future<void> submitPassword(String password) async {
    final bytes = _pendingFileBytes;
    if (bytes == null) return;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _importService.parseFileData(bytes, password: password);
      _data = data;
      _preview = await ImportPreview.analyze(data, _db);
      _step = ImportStep.previewing;
      notifyListeners();
    } on LumaDecryptionException catch (_) {
      _errorMessage = 'Incorrect password. Please try again.';
      notifyListeners();
    } on LumaImportException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Could not decrypt this backup.';
      notifyListeners();
    }
  }

  void selectStrategy(DuplicateStrategy strategy) {
    _strategy = strategy;
    notifyListeners();
  }

  void proceedToImport() {
    _step = ImportStep.chooseStrategy;
    notifyListeners();
  }

  Future<void> applyImport() async {
    final data = _data;
    if (data == null) return;
    _step = ImportStep.importing;
    _progress = 0;
    _seenProgressDuringImport = false;
    _errorMessage = null;
    _result = null;
    notifyListeners();
    try {
      _result = await _importService.applyImport(
        data: data,
        strategy: _strategy,
        onProgress: (current, total) {
          _seenProgressDuringImport = true;
          _progress = total > 0 ? current / total : 0;
          notifyListeners();
        },
      );
      _progress = 1;
      _step = ImportStep.done;
    } on LumaImportException catch (e) {
      _errorMessage = e.message;
      _step = ImportStep.error;
    } catch (_) {
      _errorMessage = 'Could not import this backup. Please try again.';
      _step = ImportStep.error;
    }
    notifyListeners();
  }

  void reset() {
    _step = ImportStep.idle;
    _meta = null;
    _data = null;
    _preview = null;
    _strategy = DuplicateStrategy.skip;
    _progress = 0;
    _errorMessage = null;
    _result = null;
    _isEncrypted = false;
    _pendingFileBytes = null;
    _seenProgressDuringImport = false;
    notifyListeners();
  }
}
