import 'package:meta/meta.dart';

/// Discrete flow levels stored 1-indexed in SQLite (0 reserved for null).
enum FlowIntensity {
  light,
  medium,
  heavy;

  String get label => switch (this) {
        FlowIntensity.light => 'Light',
        FlowIntensity.medium => 'Medium',
        FlowIntensity.heavy => 'Heavy',
      };

  /// 1-based index for persistence; 0 means null in the DB.
  int get dbValue => index + 1;

  static FlowIntensity fromDbValue(int v) => values[v - 1];
}

/// Pain scale stored 1-indexed in SQLite (0 reserved for null).
enum PainScore {
  none,
  mild,
  moderate,
  severe,
  verySevere;

  String get label => switch (this) {
        PainScore.none => 'None',
        PainScore.mild => 'Mild',
        PainScore.moderate => 'Moderate',
        PainScore.severe => 'Severe',
        PainScore.verySevere => 'Very Severe',
      };

  /// Short labels for tight UI (e.g. [SegmentedButton]); [label] stays full text elsewhere.
  String get compactLabel => switch (this) {
        PainScore.none => 'None',
        PainScore.mild => 'Mild',
        PainScore.moderate => 'Mod.',
        PainScore.severe => 'Severe',
        PainScore.verySevere => 'V. sev.',
      };

  int get dbValue => index + 1;

  static PainScore fromDbValue(int v) => values[v - 1];
}

/// Mood scale stored 1-indexed in SQLite (0 reserved for null).
enum Mood {
  veryBad,
  bad,
  neutral,
  good,
  veryGood;

  String get label => switch (this) {
        Mood.veryBad => 'Very Bad',
        Mood.bad => 'Bad',
        Mood.neutral => 'Neutral',
        Mood.good => 'Good',
        Mood.veryGood => 'Very Good',
      };

  String get emoji => switch (this) {
        Mood.veryBad => '😢',
        Mood.bad => '😟',
        Mood.neutral => '😐',
        Mood.good => '🙂',
        Mood.veryGood => '😄',
      };

  int get dbValue => index + 1;

  static Mood fromDbValue(int v) => values[v - 1];
}

/// Per-day logging payload for a period (symptoms optional).
@immutable
class DayEntryData {
  const DayEntryData({
    required this.dateUtc,
    this.flowIntensity,
    this.painScore,
    this.mood,
    this.notes,
  });

  final DateTime dateUtc;
  final FlowIntensity? flowIntensity;
  final PainScore? painScore;
  final Mood? mood;
  final String? notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayEntryData &&
        other.dateUtc == dateUtc &&
        other.flowIntensity == flowIntensity &&
        other.painScore == painScore &&
        other.mood == mood &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        dateUtc,
        flowIntensity,
        painScore,
        mood,
        notes,
      );

  @override
  String toString() {
    return 'DayEntryData(dateUtc: $dateUtc, flowIntensity: $flowIntensity, '
        'painScore: $painScore, mood: $mood, notes: $notes)';
  }
}
