import 'package:ptrack_domain/ptrack_domain.dart';

import 'app_localizations.dart';

/// Localized labels for flow / pain / mood enum values (domain keeps English `.label` for DB/debug).
class LoggingLocalizations {
  LoggingLocalizations._();

  static String flowLabel(AppLocalizations l10n, FlowIntensity v) => switch (v) {
        FlowIntensity.light => l10n.flowValueLight,
        FlowIntensity.medium => l10n.flowValueMedium,
        FlowIntensity.heavy => l10n.flowValueHeavy,
      };

  static String painLabel(AppLocalizations l10n, PainScore v) => switch (v) {
        PainScore.none => l10n.painValueNone,
        PainScore.mild => l10n.painValueMild,
        PainScore.moderate => l10n.painValueModerate,
        PainScore.severe => l10n.painValueSevere,
        PainScore.verySevere => l10n.painValueVerySevere,
      };

  static String moodLabel(AppLocalizations l10n, Mood v) => switch (v) {
        Mood.veryBad => l10n.moodValueVeryBad,
        Mood.bad => l10n.moodValueBad,
        Mood.neutral => l10n.moodValueNeutral,
        Mood.good => l10n.moodValueGood,
        Mood.veryGood => l10n.moodValueVeryGood,
      };
}
