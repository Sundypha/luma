import 'package:meta/meta.dart';

import 'logging_types.dart';

/// Domain value object for a single diary entry (no period FK).
@immutable
class DiaryEntryData {
  const DiaryEntryData({
    required this.dateUtc,
    this.mood,
    this.notes,
  });

  final DateTime dateUtc;
  final Mood? mood;
  final String? notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntryData &&
        other.dateUtc == dateUtc &&
        other.mood == mood &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(dateUtc, mood, notes);

  @override
  String toString() =>
      'DiaryEntryData(dateUtc: $dateUtc, mood: $mood, notes: $notes)';
}

/// A diary tag definition (flat, no hierarchy).
@immutable
class DiaryTag {
  const DiaryTag({required this.id, required this.name});

  final int id;
  final String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryTag && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'DiaryTag(id: $id, name: $name)';
}
