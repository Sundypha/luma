// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    exit(0);
  }
  final bump = _parseArgs(args);
  if (bump == null) {
    _printUsage();
    exit(1);
  }

  final repoRoot = Directory(
    Platform.script.resolve('../').toFilePath(),
  );
  final pubspecRel = 'apps${Platform.pathSeparator}ptrack${Platform.pathSeparator}pubspec.yaml';
  final changelogRel = 'CHANGELOG.md';
  final pubspecFile = File(
    '${repoRoot.path}${Platform.pathSeparator}$pubspecRel',
  );
  final changelogFile = File(
    '${repoRoot.path}${Platform.pathSeparator}$changelogRel',
  );

  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec not found: ${pubspecFile.path}');
    exit(1);
  }
  if (!changelogFile.existsSync()) {
    stderr.writeln('Error: CHANGELOG.md not found: ${changelogFile.path}');
    exit(1);
  }

  final pubspecText = pubspecFile.readAsStringSync();
  final current = _parseVersion(pubspecText);
  if (current == null) {
    stderr.writeln(
      'Error: could not parse version line (expected version: X.Y.Z+N) in ${pubspecFile.path}',
    );
    exit(1);
  }

  final next = _bumpSemver(current, bump);
  final newLine = 'version: ${next.semver}+${next.build}';
  final newPubspec = _replaceVersionLine(pubspecText, newLine);
  if (newPubspec == null) {
    stderr.writeln('Error: version line not found in ${pubspecFile.path}');
    exit(1);
  }

  final changelogText = changelogFile.readAsStringSync();
  const unreleased = '## [Unreleased]';
  final u = changelogText.indexOf(unreleased);
  if (u == -1) {
    stderr.writeln('Error: "$unreleased" not found in CHANGELOG.md');
    exit(1);
  }
  final insertAt = u + unreleased.length;
  final today = _todayUtc();
  final newSection = '''

## [${next.semver}] - $today

### Added

### Changed

### Fixed

''';
  final newChangelog = changelogText.substring(0, insertAt) +
      newSection +
      changelogText.substring(insertAt);

  final oldFull = '${current.semver}+${current.build}';
  final newFull = '${next.semver}+${next.build}';

  if (bump.dryRun) {
    print('Bumped: $oldFull → $newFull');
    print('');
    print('Updated:');
    print('  - apps/ptrack/pubspec.yaml');
    print('  - CHANGELOG.md');
    print('');
    print('(Dry-run: no files modified.)');
    print('');
    print('Next steps:');
    _printNextSteps(next.semver);
    exit(0);
  }

  pubspecFile.writeAsStringSync(newPubspec);
  changelogFile.writeAsStringSync(newChangelog);

  print('Bumped: $oldFull → $newFull');
  print('');
  print('Updated:');
  print('  - apps/ptrack/pubspec.yaml');
  print('  - CHANGELOG.md');
  print('');
  print('Next steps:');
  _printNextSteps(next.semver);

  if (bump.tag) {
    _runGit(repoRoot.path, [
      'add',
      'apps/ptrack/pubspec.yaml',
      'CHANGELOG.md',
    ]);
    _runGit(repoRoot.path, ['commit', '-m', 'release: v${next.semver}']);
    _runGit(repoRoot.path, [
      'tag',
      '-a',
      'v${next.semver}',
      '-m',
      'Release ${next.semver}',
    ]);
    print('');
    print(
      'Committed and tagged v${next.semver}. Push with: git push origin main --follow-tags',
    );
  }
}

class _Version {
  const _Version({
    required this.major,
    required this.minor,
    required this.patch,
    required this.build,
  });

  final int major;
  final int minor;
  final int patch;
  final int build;

  String get semver => '$major.$minor.$patch';
}

class _BumpArgs {
  const _BumpArgs({
    required this.level,
    required this.dryRun,
    required this.tag,
  });

  final String level;
  final bool dryRun;
  final bool tag;
}

_BumpArgs? _parseArgs(List<String> args) {
  if (args.isEmpty) return null;

  var dryRun = false;
  var tag = false;
  String? level;
  for (final a in args) {
    if (a == '--dry-run') {
      dryRun = true;
    } else if (a == '--tag') {
      tag = true;
    } else if (a.startsWith('-')) {
      stderr.writeln('Error: unknown option: $a');
      return null;
    } else {
      if (level != null) {
        stderr.writeln('Error: multiple bump levels: $level and $a');
        return null;
      }
      level = a;
    }
  }
  if (level == null) {
    return null;
  }
  final l = level.toLowerCase();
  if (l != 'major' && l != 'minor' && l != 'patch') {
    stderr.writeln('Error: bump level must be major, minor, or patch');
    return null;
  }
  if (tag && dryRun) {
    stderr.writeln('Error: --tag cannot be used with --dry-run');
    return null;
  }
  return _BumpArgs(level: l, dryRun: dryRun, tag: tag);
}

_Version? _parseVersion(String pubspecText) {
  final re = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$', multiLine: true);
  final m = re.firstMatch(pubspecText);
  if (m == null) return null;
  return _Version(
    major: int.parse(m.group(1)!),
    minor: int.parse(m.group(2)!),
    patch: int.parse(m.group(3)!),
    build: int.parse(m.group(4)!),
  );
}

_Version _bumpSemver(_Version v, _BumpArgs bump) {
  final newBuild = v.build + 1;
  switch (bump.level) {
    case 'major':
      return _Version(major: v.major + 1, minor: 0, patch: 0, build: newBuild);
    case 'minor':
      return _Version(major: v.major, minor: v.minor + 1, patch: 0, build: newBuild);
    case 'patch':
      return _Version(
        major: v.major,
        minor: v.minor,
        patch: v.patch + 1,
        build: newBuild,
      );
    default:
      throw StateError('invalid bump level');
  }
}

String? _replaceVersionLine(String pubspecText, String newVersionLine) {
  final re = RegExp(
    r'^version:\s*\d+\.\d+\.\d+\+\d+\s*$',
    multiLine: true,
  );
  if (!re.hasMatch(pubspecText)) return null;
  return pubspecText.replaceFirst(re, newVersionLine);
}

String _todayUtc() {
  final now = DateTime.now().toUtc();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

void _printNextSteps(String semver) {
  print('  1. Edit CHANGELOG.md — fill in Added/Changed/Fixed sections');
  print('  2. git add apps/ptrack/pubspec.yaml CHANGELOG.md');
  print('  3. git commit -m "release: v$semver"');
  print('  4. git tag -a v$semver -m "Release $semver"');
  print('  5. git push origin main --follow-tags');
}

void _printUsage() {
  print('Bump apps/ptrack/pubspec.yaml semver + build and prepend CHANGELOG section.');
  print('');
  print('Usage: dart run tool/bump_version.dart <major|minor|patch> [options]');
  print('');
  print('Options:');
  print('  --dry-run   Print changes without writing files or running git');
  print('  --tag       After writing, git add, commit, and create annotated tag');
  print('  --help, -h  Show this help');
  print('');
  print('Bump levels: major, minor, patch (semver bump; build number always +1).');
}

void _runGit(String workingDirectory, List<String> args) {
  final r = Process.runSync(
    'git',
    args,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  if (r.exitCode != 0) {
    stderr.writeln(r.stderr);
    stderr.writeln(r.stdout);
    exit(r.exitCode);
  }
}
