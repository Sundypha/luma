import 'dart:convert';
import 'dart:io';

/// Fails if `app_de.arb` is missing any message key present in `app_en.arb`.
///
/// Run from repository root: `dart run tool/arb_de_key_parity.dart`
/// or `melos run ci:arb`.
void main() {
  final root = _repoRoot();
  final enFile = File('$root/apps/ptrack/lib/l10n/app_en.arb');
  final deFile = File('$root/apps/ptrack/lib/l10n/app_de.arb');

  if (!enFile.existsSync()) {
    stderr.writeln('Missing ${enFile.path}');
    exitCode = 2;
    return;
  }
  if (!deFile.existsSync()) {
    stderr.writeln('Missing ${deFile.path}');
    exitCode = 2;
    return;
  }

  final en = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final de = json.decode(deFile.readAsStringSync()) as Map<String, dynamic>;

  final enKeys = _messageKeys(en);
  final deKeys = _messageKeys(de);
  final missing = enKeys.difference(deKeys);

  if (missing.isEmpty) {
    stdout.writeln(
      'ARB parity OK: ${deKeys.length} DE keys cover all ${enKeys.length} EN message keys.',
    );
    return;
  }

  final sorted = missing.toList()..sort();
  stderr.writeln(
    'app_de.arb is missing ${sorted.length} key(s) required by app_en.arb:',
  );
  for (final k in sorted) {
    stderr.writeln('  - $k');
  }
  exitCode = 1;
}

String _repoRoot() {
  final scriptPath = Platform.script.toFilePath();
  final toolDir = File(scriptPath).parent.path;
  return Directory(toolDir).parent.path;
}

/// User-visible message keys: same rule as Flutter gen-l10n (exclude @metadata).
Set<String> _messageKeys(Map<String, dynamic> arb) {
  final out = <String>{};
  for (final e in arb.entries) {
    if (e.key.startsWith('@')) continue;
    out.add(e.key);
  }
  return out;
}
