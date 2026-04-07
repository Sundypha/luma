// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Luma';

  @override
  String get predictionDisclaimer =>
      'Dies ist nur eine kalenderbasierte Einschätzung für deine persönliche Planung und ersetzt keine medizinische Beratung.';

  @override
  String get predictionNoMethodsEnabled =>
      'Es sind keine Vorhersagemethoden aktiviert. Wähle mindestens eine unter Einstellungen → Vorhersage.';

  @override
  String predictionNOfMTotalMethods(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Vorhersagemethoden',
      one: '1 Vorhersagemethode',
    );
    return '$_temp0 von $total ist in diese Schätzung eingeflossen.';
  }

  @override
  String predictionAlgoExpectsLine(String name, String date) {
    return '$name: geht von der nächsten Periode ungefähr am $date aus.';
  }

  @override
  String get predictionAgreementClosing =>
      'An Tagen, an denen mehrere Methoden übereinstimmen, ist die Vorhersage konsistenter. Betrachte alle Termine als unsichere Schätzungen nur für die persönliche Planung.';

  @override
  String get predictionClosingInsufficientHistory =>
      'Wenn du im Laufe der Zeit mehr abgeschlossene Zyklen einträgst, wird die Schätzung klarer. Die Angaben hier sind kein Ersatz für die Betreuung durch eine qualifizierte Ärztin oder einen qualifizierten Arzt.';

  @override
  String predictionClosingRangeOnly(String start, String end) {
    return 'Für die Planung reicht ein grobes Fenster von etwa $start bis $end. Betrachte diese Termine als unsicher.';
  }

  @override
  String predictionClosingPointWithRange(
    String point,
    String bandStart,
    String bandEnd,
  ) {
    return 'Eine grobe Schätzung für den Beginn deiner nächsten Periode ist $point. Basierend auf ähnlichen Abständen in der Vergangenheit könnte ein weiteres Planungsfenster etwa von $bandStart bis $bandEnd liegen.';
  }

  @override
  String predStepCyclesConsidered(int count, String lengths) {
    return 'Basierend auf $count kürzlichen Zykluslängen aus deiner Historie ($lengths Tage).';
  }

  @override
  String predStepCycleExcluded(String reason) {
    return 'Ein eingetragener Zyklus fließt in den Durchschnitt für diese Schätzung nicht ein (Grund: $reason).';
  }

  @override
  String predStepMedianCycleLength(int median, int spread) {
    return 'Über die berücksichtigten Zyklen ist ein typischer Abstand etwa $median Tage (Streuung etwa $spread Tage).';
  }

  @override
  String predStepInsufficientHistory(int avail, int need) {
    return 'Noch reichen die abgeschlossenen Zyklen nicht aus, um den nächsten Beginn abzuschätzen. Nach Filterung stehen $avail Zyklus/Zyklen zur Verfügung; normalerweise werden mindestens $need benötigt.';
  }

  @override
  String predStepHighVariability(String start, String end) {
    return 'Weil die Schwankungen groß sind, wird ein Bereich statt eines einzelnen Tages angezeigt: ungefähr $start bis $end.';
  }

  @override
  String predStepEwma(String alpha, int days) {
    return 'Jüngeren Zyklen höheres Gewicht (EWMA, α=$alpha) spricht für etwa $days Tage.';
  }

  @override
  String predStepBayesian(String mean, int n) {
    return 'Die Schätzung durch Musterlernen (Posterior-Mittelwert) liegt bei etwa $mean Tagen aus $n Zykluslängen.';
  }

  @override
  String predStepLinearTrend(String r2, String slope, int proj) {
    return 'Trendlinie (R²=$r2, Steigung=$slope Tage pro Zyklus) legt für den nächsten Abstand etwa $proj Tage nahe.';
  }

  @override
  String predStepAlgoContrib(String name, String date) {
    return '$name liefert eine Schätzung ungefähr am $date.';
  }

  @override
  String get algoNameMedian => 'Durchschnitts-Abstand';

  @override
  String get algoNameEwma => 'Gewichtung nach Aktualität';

  @override
  String get algoNameBayesian => 'Musterlernen';

  @override
  String get algoNameLinearTrend => 'Trend';

  @override
  String predictionDayAgreement(int agreement, int active) {
    return '$agreement von $active Methoden stimmen an diesem Tag überein.';
  }

  @override
  String get ensembleMilestoneTrend =>
      'Mit genug eingetragenen Zyklen ist die Trenderkennung jetzt aktiv.';

  @override
  String get ensembleMilestoneAllCore =>
      'Drei Zyklen eingetragen — alle Kernmethoden sind jetzt aktiv.';

  @override
  String ensembleMilestoneExpanded(int cycles, int methods) {
    return 'Mit $cycles eingetragenen Zyklen nutzt deine Vorhersage jetzt $methods Methoden für mehr Genauigkeit.';
  }

  @override
  String homePeriodDay(int n) {
    return 'Periodentag $n';
  }

  @override
  String homeCycleDay(int n) {
    return 'Zyklustag $n';
  }

  @override
  String homeNextPeriodExpected(String range) {
    return 'Nächste Periode erwartet $range';
  }

  @override
  String get homeLogMorePeriods =>
      'Trag noch ein paar Perioden ein, um Zyklus-Einblicke zu sehen';

  @override
  String get homeHowCalculatedLink => 'Wie wird das berechnet?';

  @override
  String get homePredictionSheetTitle => 'So funktioniert deine Vorhersage';

  @override
  String homePredictionMethodsLine(int n) {
    return 'Aktuell werden $n Vorhersagemethoden genutzt.';
  }

  @override
  String get homeDone => 'Fertig';

  @override
  String homeCouldNotLoadPeriods(String error) {
    return 'Perioden konnten nicht geladen werden: $error';
  }

  @override
  String get homeCouldNotSaveToday =>
      'Heute konnte nicht gespeichert werden. Bitte versuch es noch einmal.';

  @override
  String get homeCouldNotOpenSymptomForm =>
      'Symptom-Formular konnte nicht geöffnet werden.';

  @override
  String get tooltipDismiss => 'Schließen';

  @override
  String get dayDetailBasedOnRecentCycles =>
      'Basierend auf deinen letzten Zyklen.';

  @override
  String get dayDetailProjectedHop =>
      'Projiziert durch Wiederholen der vorhergesagten Zykluslänge.';

  @override
  String get dayDetailPeriodExpectedTitle =>
      'Periode in etwa an diesem Tag erwartet';

  @override
  String dayDetailForecastMonthsTitle(int months) {
    return 'Vorschau etwa $months Monate voraus';
  }

  @override
  String get dayDetailDisclaimerHop1 =>
      'Grobe Schätzung, etwa 2 Monate voraus — weniger zuverlässig als die nächste Periode.';

  @override
  String get dayDetailDisclaimerHop1HighSpread =>
      'Grobe Schätzung, etwa 2 Monate voraus — weniger zuverlässig als die nächste Periode. Deine Zykluslänge schwankt ziemlich stark, dieser Termin kann sich deutlich verschieben.';

  @override
  String dayDetailDisclaimerHopN(int months) {
    return 'Sehr grobe Schätzung, etwa $months Monate voraus — nur zur allgemeinen Planung.';
  }

  @override
  String dayDetailDisclaimerHopNSpread(int months) {
    return 'Sehr grobe Schätzung, etwa $months Monate voraus — nur zur allgemeinen Planung. Deine Zykluslänge schwankt ziemlich stark, dieser Termin kann sich deutlich verschieben.';
  }

  @override
  String get dayDetailHideDetails => 'Details ausblenden';

  @override
  String get dayDetailSeeDetails => 'Details anzeigen';

  @override
  String get dayDetailEstimatesOnly =>
      'Nur Schätzungen — keine medizinische Beratung.';

  @override
  String dayDetailAlgoExpectsAround(String name, String date) {
    return '$name: erwartet ungefähr $date';
  }

  @override
  String get settingsAppLanguageSectionTitle => 'App-Sprache';

  @override
  String get appLanguageFollowDevice => 'Systemstandard (wie Gerät)';

  @override
  String get appLanguageEnglish => 'Englisch';

  @override
  String get appLanguageGerman => 'Deutsch';

  @override
  String get appLanguageRestartMessage =>
      'Starte die App neu, damit die Änderung wirkt.';
}
