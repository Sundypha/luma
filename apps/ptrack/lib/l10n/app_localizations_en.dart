// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Luma';

  @override
  String get predictionDisclaimer =>
      'This is a calendar-based estimate for personal planning only, not medical advice.';

  @override
  String get predictionNoMethodsEnabled =>
      'No prediction methods are enabled. Choose at least one under Settings → Prediction.';

  @override
  String predictionNOfMTotalMethods(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n prediction methods',
      one: '1 prediction method',
    );
    return '$_temp0 of $total contributed to this estimate.';
  }

  @override
  String predictionAlgoExpectsLine(String name, String date) {
    return '$name: expects next period around $date.';
  }

  @override
  String get predictionAgreementClosing =>
      'On days where multiple methods agree, the prediction is more consistent. Treat all dates as uncertain estimates for personal planning only.';

  @override
  String get predictionClosingInsufficientHistory =>
      'Add more completed cycles over time to get a clearer estimate. Numbers here are not a substitute for care from a qualified clinician.';

  @override
  String predictionClosingRangeOnly(String start, String end) {
    return 'For planning purposes, a broad estimate window runs from $start through $end. Treat these dates as uncertain.';
  }

  @override
  String predictionClosingPointWithRange(
    String point,
    String bandStart,
    String bandEnd,
  ) {
    return 'A rough estimate for your next period start is $point. Based on similar past spacing, a wider planning band might be $bandStart to $bandEnd.';
  }

  @override
  String predStepCyclesConsidered(int count, String lengths) {
    return 'Based on $count recent cycle lengths from your history ($lengths days).';
  }

  @override
  String predStepCycleExcluded(String reason) {
    return 'One logged cycle was left out of the average for this estimate (reason: $reason).';
  }

  @override
  String predStepMedianCycleLength(int median, int spread) {
    return 'Across included cycles, a typical spacing is about $median days (spread about $spread days).';
  }

  @override
  String predStepInsufficientHistory(int avail, int need) {
    return 'There are not enough completed cycles yet to estimate a next start. $avail cycle(s) are available after filtering; at least $need are typically needed.';
  }

  @override
  String predStepHighVariability(String start, String end) {
    return 'Because variability is high, a range is shown instead of a single day: approximately $start through $end.';
  }

  @override
  String predStepEwma(String alpha, int days) {
    return 'Recent-weighted spacing (EWMA, α=$alpha) suggests about $days days.';
  }

  @override
  String predStepBayesian(String mean, int n) {
    return 'Pattern-learning estimate (posterior mean) is about $mean days from $n cycle lengths.';
  }

  @override
  String predStepLinearTrend(String r2, String slope, int proj) {
    return 'Trend line (R²=$r2, slope=$slope days per cycle) projects about $proj days for the next spacing.';
  }

  @override
  String predStepAlgoContrib(String name, String date) {
    return '$name contributed an estimate around $date.';
  }

  @override
  String get algoNameMedian => 'Average spacing';

  @override
  String get algoNameEwma => 'Recent-weighted';

  @override
  String get algoNameBayesian => 'Pattern-learning';

  @override
  String get algoNameLinearTrend => 'Trend';

  @override
  String predictionDayAgreement(int agreement, int active) {
    return '$agreement of $active methods agree on this day.';
  }

  @override
  String get ensembleMilestoneTrend =>
      'With enough cycles logged, trend detection is now active.';

  @override
  String get ensembleMilestoneAllCore =>
      'Three cycles logged — all core methods are now active.';

  @override
  String ensembleMilestoneExpanded(int cycles, int methods) {
    return 'With $cycles cycles logged, your prediction now uses $methods methods for better accuracy.';
  }

  @override
  String homePeriodDay(int n) {
    return 'Period day $n';
  }

  @override
  String homeCycleDay(int n) {
    return 'Cycle day $n';
  }

  @override
  String homeNextPeriodExpected(String range) {
    return 'Next period expected $range';
  }

  @override
  String get homeLogMorePeriods =>
      'Log a few more periods to see cycle insights';

  @override
  String get homeHowCalculatedLink => 'How is this calculated?';

  @override
  String get homePredictionSheetTitle => 'How your prediction works';

  @override
  String homePredictionMethodsLine(int n) {
    return 'Currently using $n prediction methods.';
  }

  @override
  String get homeDone => 'Done';

  @override
  String homeCouldNotLoadPeriods(String error) {
    return 'Could not load periods: $error';
  }

  @override
  String get homeCouldNotSaveToday => 'Could not save today. Please try again.';

  @override
  String get homeCouldNotOpenSymptomForm => 'Could not open symptom form.';

  @override
  String get tooltipDismiss => 'Dismiss';

  @override
  String get dayDetailBasedOnRecentCycles => 'Based on your recent cycles.';

  @override
  String get dayDetailProjectedHop =>
      'Projected by repeating the predicted cycle length.';

  @override
  String get dayDetailPeriodExpectedTitle => 'Period expected around this day';

  @override
  String dayDetailForecastMonthsTitle(int months) {
    return 'Forecast ≈ $months months out';
  }

  @override
  String get dayDetailDisclaimerHop1 =>
      'Rough estimate, about 2 months out — less reliable than the next period.';

  @override
  String get dayDetailDisclaimerHop1HighSpread =>
      'Rough estimate, about 2 months out — less reliable than the next period. Your cycle length varies quite a bit, so this date may shift significantly.';

  @override
  String dayDetailDisclaimerHopN(int months) {
    return 'Very rough estimate, about $months months out — use for general planning only.';
  }

  @override
  String dayDetailDisclaimerHopNSpread(int months) {
    return 'Very rough estimate, about $months months out — use for general planning only. Your cycle length varies quite a bit, so this date may shift significantly.';
  }

  @override
  String get dayDetailHideDetails => 'Hide details';

  @override
  String get dayDetailSeeDetails => 'See details';

  @override
  String get dayDetailEstimatesOnly => 'Estimates only — not medical advice.';

  @override
  String dayDetailAlgoExpectsAround(String name, String date) {
    return '$name: expects around $date';
  }
}
