import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Application title; brand name stays Luma in all locales for Phase 10.
  ///
  /// In en, this message translates to:
  /// **'Luma'**
  String get appTitle;

  /// No description provided for @predictionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This is a calendar-based estimate for personal planning only, not medical advice.'**
  String get predictionDisclaimer;

  /// No description provided for @predictionNoMethodsEnabled.
  ///
  /// In en, this message translates to:
  /// **'No prediction methods are enabled. Choose at least one under Settings → Prediction.'**
  String get predictionNoMethodsEnabled;

  /// No description provided for @predictionNOfMTotalMethods.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{1 prediction method} other{{n} prediction methods}} of {total} contributed to this estimate.'**
  String predictionNOfMTotalMethods(int n, int total);

  /// No description provided for @predictionAlgoExpectsLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: expects next period around {date}.'**
  String predictionAlgoExpectsLine(String name, String date);

  /// No description provided for @predictionAgreementClosing.
  ///
  /// In en, this message translates to:
  /// **'On days where multiple methods agree, the prediction is more consistent. Treat all dates as uncertain estimates for personal planning only.'**
  String get predictionAgreementClosing;

  /// No description provided for @predictionClosingInsufficientHistory.
  ///
  /// In en, this message translates to:
  /// **'Add more completed cycles over time to get a clearer estimate. Numbers here are not a substitute for care from a qualified clinician.'**
  String get predictionClosingInsufficientHistory;

  /// No description provided for @predictionClosingRangeOnly.
  ///
  /// In en, this message translates to:
  /// **'For planning purposes, a broad estimate window runs from {start} through {end}. Treat these dates as uncertain.'**
  String predictionClosingRangeOnly(String start, String end);

  /// No description provided for @predictionClosingPointWithRange.
  ///
  /// In en, this message translates to:
  /// **'A rough estimate for your next period start is {point}. Based on similar past spacing, a wider planning band might be {bandStart} to {bandEnd}.'**
  String predictionClosingPointWithRange(
    String point,
    String bandStart,
    String bandEnd,
  );

  /// No description provided for @predStepCyclesConsidered.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} recent cycle lengths from your history ({lengths} days).'**
  String predStepCyclesConsidered(int count, String lengths);

  /// No description provided for @predStepCycleExcluded.
  ///
  /// In en, this message translates to:
  /// **'One logged cycle was left out of the average for this estimate (reason: {reason}).'**
  String predStepCycleExcluded(String reason);

  /// No description provided for @predStepMedianCycleLength.
  ///
  /// In en, this message translates to:
  /// **'Across included cycles, a typical spacing is about {median} days (spread about {spread} days).'**
  String predStepMedianCycleLength(int median, int spread);

  /// No description provided for @predStepInsufficientHistory.
  ///
  /// In en, this message translates to:
  /// **'{avail, plural, one{There are not enough completed cycles yet to estimate a next start. 1 cycle is available after filtering; at least {need} are typically needed.} other{There are not enough completed cycles yet to estimate a next start. {avail} cycles are available after filtering; at least {need} are typically needed.}}'**
  String predStepInsufficientHistory(int avail, int need);

  /// No description provided for @predStepHighVariability.
  ///
  /// In en, this message translates to:
  /// **'Because variability is high, a range is shown instead of a single day: approximately {start} through {end}.'**
  String predStepHighVariability(String start, String end);

  /// No description provided for @predStepEwma.
  ///
  /// In en, this message translates to:
  /// **'Recent-weighted spacing (EWMA, α={alpha}) suggests about {days} days.'**
  String predStepEwma(String alpha, int days);

  /// No description provided for @predStepBayesian.
  ///
  /// In en, this message translates to:
  /// **'Pattern-learning estimate (posterior mean) is about {mean} days from {n} cycle lengths.'**
  String predStepBayesian(String mean, int n);

  /// No description provided for @predStepLinearTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend line (R²={r2}, slope={slope} days per cycle) projects about {proj} days for the next spacing.'**
  String predStepLinearTrend(String r2, String slope, int proj);

  /// No description provided for @predStepAlgoContrib.
  ///
  /// In en, this message translates to:
  /// **'{name} contributed an estimate around {date}.'**
  String predStepAlgoContrib(String name, String date);

  /// No description provided for @algoNameMedian.
  ///
  /// In en, this message translates to:
  /// **'Average spacing'**
  String get algoNameMedian;

  /// No description provided for @algoNameEwma.
  ///
  /// In en, this message translates to:
  /// **'Recent-weighted'**
  String get algoNameEwma;

  /// No description provided for @algoNameBayesian.
  ///
  /// In en, this message translates to:
  /// **'Pattern-learning'**
  String get algoNameBayesian;

  /// No description provided for @algoNameLinearTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get algoNameLinearTrend;

  /// No description provided for @predictionDayAgreement.
  ///
  /// In en, this message translates to:
  /// **'{agreement} of {active} methods agree on this day.'**
  String predictionDayAgreement(int agreement, int active);

  /// No description provided for @ensembleMilestoneTrend.
  ///
  /// In en, this message translates to:
  /// **'With enough cycles logged, trend detection is now active.'**
  String get ensembleMilestoneTrend;

  /// No description provided for @ensembleMilestoneAllCore.
  ///
  /// In en, this message translates to:
  /// **'Three cycles logged — all core methods are now active.'**
  String get ensembleMilestoneAllCore;

  /// No description provided for @ensembleMilestoneExpanded.
  ///
  /// In en, this message translates to:
  /// **'With {cycles} cycles logged, your prediction now uses {methods, plural, one{1 method} other{{methods} methods}} for better accuracy.'**
  String ensembleMilestoneExpanded(int cycles, int methods);

  /// No description provided for @homePeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Period day {n}'**
  String homePeriodDay(int n);

  /// No description provided for @homeCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle day {n}'**
  String homeCycleDay(int n);

  /// No description provided for @homeNextPeriodExpected.
  ///
  /// In en, this message translates to:
  /// **'Next period expected {range}'**
  String homeNextPeriodExpected(String range);

  /// No description provided for @homeLogMorePeriods.
  ///
  /// In en, this message translates to:
  /// **'Log a few more periods to see cycle insights'**
  String get homeLogMorePeriods;

  /// No description provided for @homeHowCalculatedLink.
  ///
  /// In en, this message translates to:
  /// **'How is this calculated?'**
  String get homeHowCalculatedLink;

  /// No description provided for @homePredictionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'How your prediction works'**
  String get homePredictionSheetTitle;

  /// No description provided for @homePredictionMethodsLine.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{Currently using 1 prediction method.} other{Currently using {n} prediction methods.}}'**
  String homePredictionMethodsLine(int n);

  /// No description provided for @homeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get homeDone;

  /// No description provided for @homeCouldNotLoadPeriods.
  ///
  /// In en, this message translates to:
  /// **'Could not load periods: {error}'**
  String homeCouldNotLoadPeriods(String error);

  /// No description provided for @homeCouldNotSaveToday.
  ///
  /// In en, this message translates to:
  /// **'Could not save today. Please try again.'**
  String get homeCouldNotSaveToday;

  /// No description provided for @homeCouldNotOpenSymptomForm.
  ///
  /// In en, this message translates to:
  /// **'Could not open symptom form.'**
  String get homeCouldNotOpenSymptomForm;

  /// No description provided for @tooltipDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get tooltipDismiss;

  /// No description provided for @dayDetailBasedOnRecentCycles.
  ///
  /// In en, this message translates to:
  /// **'Based on your recent cycles.'**
  String get dayDetailBasedOnRecentCycles;

  /// No description provided for @dayDetailProjectedHop.
  ///
  /// In en, this message translates to:
  /// **'Projected by repeating the predicted cycle length.'**
  String get dayDetailProjectedHop;

  /// No description provided for @dayDetailPeriodExpectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Period expected around this day'**
  String get dayDetailPeriodExpectedTitle;

  /// No description provided for @dayDetailForecastMonthsTitle.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, one{Forecast ≈ 1 month out} other{Forecast ≈ {months} months out}}'**
  String dayDetailForecastMonthsTitle(int months);

  /// No description provided for @dayDetailDisclaimerHop1.
  ///
  /// In en, this message translates to:
  /// **'Rough estimate, about 2 months out — less reliable than the next period.'**
  String get dayDetailDisclaimerHop1;

  /// No description provided for @dayDetailDisclaimerHop1HighSpread.
  ///
  /// In en, this message translates to:
  /// **'Rough estimate, about 2 months out — less reliable than the next period. Your cycle length varies quite a bit, so this date may shift significantly.'**
  String get dayDetailDisclaimerHop1HighSpread;

  /// No description provided for @dayDetailDisclaimerHopN.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, one{Very rough estimate, about 1 month out — use for general planning only.} other{Very rough estimate, about {months} months out — use for general planning only.}}'**
  String dayDetailDisclaimerHopN(int months);

  /// No description provided for @dayDetailDisclaimerHopNSpread.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, one{Very rough estimate, about 1 month out — use for general planning only. Your cycle length varies quite a bit, so this date may shift significantly.} other{Very rough estimate, about {months} months out — use for general planning only. Your cycle length varies quite a bit, so this date may shift significantly.}}'**
  String dayDetailDisclaimerHopNSpread(int months);

  /// No description provided for @dayDetailHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get dayDetailHideDetails;

  /// No description provided for @dayDetailSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'See details'**
  String get dayDetailSeeDetails;

  /// No description provided for @dayDetailEstimatesOnly.
  ///
  /// In en, this message translates to:
  /// **'Estimates only — not medical advice.'**
  String get dayDetailEstimatesOnly;

  /// No description provided for @dayDetailAlgoExpectsAround.
  ///
  /// In en, this message translates to:
  /// **'{name}: expects around {date}'**
  String dayDetailAlgoExpectsAround(String name, String date);

  /// Settings section heading for UI language choice.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguageSectionTitle;

  /// Use the device locale for app strings; unsupported locales fall back to English.
  ///
  /// In en, this message translates to:
  /// **'System default (follow device)'**
  String get appLanguageFollowDevice;

  /// No description provided for @appLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get appLanguageEnglish;

  /// No description provided for @appLanguageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get appLanguageGerman;

  /// Shown after the user changes app language in Settings.
  ///
  /// In en, this message translates to:
  /// **'Restart the app to apply this change.'**
  String get appLanguageRestartMessage;

  /// No description provided for @calendarInsufficientPredictionHint.
  ///
  /// In en, this message translates to:
  /// **'No forecast yet — mark at least two separate periods so Luma can measure the gap between them.'**
  String get calendarInsufficientPredictionHint;

  /// No description provided for @calendarLegendHatching.
  ///
  /// In en, this message translates to:
  /// **'Lighter hatching = further out, less certain'**
  String get calendarLegendHatching;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
