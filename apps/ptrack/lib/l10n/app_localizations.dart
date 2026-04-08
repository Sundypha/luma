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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @drawerSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettingsLabel;

  /// No description provided for @drawerDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get drawerDataLabel;

  /// No description provided for @drawerAboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAboutLabel;

  /// No description provided for @fabTooltipMarkToday.
  ///
  /// In en, this message translates to:
  /// **'Mark today'**
  String get fabTooltipMarkToday;

  /// No description provided for @fabTooltipAddSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Add symptoms'**
  String get fabTooltipAddSymptoms;

  /// No description provided for @todaySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todaySectionTitle;

  /// No description provided for @todayUnmarkedBody.
  ///
  /// In en, this message translates to:
  /// **'You have not marked today as a period day.'**
  String get todayUnmarkedBody;

  /// No description provided for @todayMarkPeriodCta.
  ///
  /// In en, this message translates to:
  /// **'I had my period today'**
  String get todayMarkPeriodCta;

  /// No description provided for @todayAddSymptomsCta.
  ///
  /// In en, this message translates to:
  /// **'Add symptoms for today'**
  String get todayAddSymptomsCta;

  /// No description provided for @todayLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s log'**
  String get todayLogTitle;

  /// No description provided for @todayFlowLine.
  ///
  /// In en, this message translates to:
  /// **'Flow: {label}'**
  String todayFlowLine(String label);

  /// No description provided for @todayPainLine.
  ///
  /// In en, this message translates to:
  /// **'Pain: {label}'**
  String todayPainLine(String label);

  /// No description provided for @todayMoodLine.
  ///
  /// In en, this message translates to:
  /// **'Mood: {emoji} {label}'**
  String todayMoodLine(String emoji, String label);

  /// No description provided for @todayEditLogCta.
  ///
  /// In en, this message translates to:
  /// **'Edit today\'s log'**
  String get todayEditLogCta;

  /// No description provided for @lockUseBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get lockUseBiometrics;

  /// No description provided for @lockForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get lockForgotPin;

  /// No description provided for @lockIncorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get lockIncorrectPin;

  /// No description provided for @lockBiometricUnlockReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to unlock Luma'**
  String get lockBiometricUnlockReason;

  /// No description provided for @lockBiometricSettingsReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to change lock settings'**
  String get lockBiometricSettingsReason;

  /// No description provided for @lockSettingsAppBar.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get lockSettingsAppBar;

  /// No description provided for @lockSettingsSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get lockSettingsSwitchTitle;

  /// No description provided for @lockSettingsSwitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN or biometrics when returning from background.'**
  String get lockSettingsSwitchSubtitle;

  /// No description provided for @lockSettingsChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get lockSettingsChangePin;

  /// No description provided for @lockSettingsUseBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get lockSettingsUseBiometrics;

  /// No description provided for @lockSettingsLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockSettingsLockNow;

  /// No description provided for @lockSettingsLockNowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockSettingsLockNowTooltip;

  /// No description provided for @lockPrivacySecurityTile.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get lockPrivacySecurityTile;

  /// No description provided for @lockPrivacySecurityOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App lock is on'**
  String get lockPrivacySecurityOnSubtitle;

  /// No description provided for @lockPrivacySecurityOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN or biometrics when returning from background'**
  String get lockPrivacySecurityOffSubtitle;

  /// No description provided for @lockReauthTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it is you'**
  String get lockReauthTitle;

  /// No description provided for @lockReauthBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue.'**
  String get lockReauthBody;

  /// No description provided for @forgotPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN?'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinBody.
  ///
  /// In en, this message translates to:
  /// **'There is no way to recover a forgotten PIN without erasing your data.\n\nBefore resetting, export your data from Data settings so you can restore it afterwards.\n\nResetting will erase all period and symptom history from this device.'**
  String get forgotPinBody;

  /// No description provided for @forgotPinEraseCta.
  ///
  /// In en, this message translates to:
  /// **'Erase all data and reset'**
  String get forgotPinEraseCta;

  /// No description provided for @pinSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up app lock'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupAckBody.
  ///
  /// In en, this message translates to:
  /// **'App lock encrypts access with a PIN. If you forget your PIN, the only recovery option is a data reset — your period data will be erased. Export your data regularly to avoid data loss.'**
  String get pinSetupAckBody;

  /// No description provided for @pinSetupAckContinue.
  ///
  /// In en, this message translates to:
  /// **'I understand, continue'**
  String get pinSetupAckContinue;

  /// No description provided for @pinSetupCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN'**
  String get pinSetupCreateTitle;

  /// No description provided for @pinSetupCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN of at least 4 digits. Press ✓ when done.'**
  String get pinSetupCreateHint;

  /// No description provided for @pinSetupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get pinSetupConfirmTitle;

  /// No description provided for @pinSetupMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get pinSetupMismatch;

  /// No description provided for @pinSetupBioTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable biometrics for faster unlock?'**
  String get pinSetupBioTitle;

  /// No description provided for @pinSetupEnableBio.
  ///
  /// In en, this message translates to:
  /// **'Enable biometrics'**
  String get pinSetupEnableBio;

  /// No description provided for @pinSetupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get pinSetupSkip;

  /// No description provided for @onbPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data stays here'**
  String get onbPrivacyTitle;

  /// No description provided for @onbPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you log stays on this device. There\'s no account to create, no cloud sync, and no sign-up — just your phone and your entries.'**
  String get onbPrivacyBody;

  /// No description provided for @onbEstimatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimates, not medical advice'**
  String get onbEstimatesTitle;

  /// No description provided for @onbEstimatesBody.
  ///
  /// In en, this message translates to:
  /// **'Forecasts are based on the history you add here. They\'re personal estimates to help you notice patterns — not a diagnosis, treatment, or substitute for care from a qualified health professional.'**
  String get onbEstimatesBody;

  /// No description provided for @onbReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to start'**
  String get onbReadyTitle;

  /// No description provided for @onbReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Log when your period starts to get going. The more you add over time, the more helpful your estimates can be — and you can always skip for now.'**
  String get onbReadyBody;

  /// No description provided for @onbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbContinue;

  /// No description provided for @onbGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onbGetStarted;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onbSkip;

  /// No description provided for @onbStepSemantics.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onbStepSemantics(int current, int total);

  /// No description provided for @aboutAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'About Luma'**
  String get aboutAppBarTitle;

  /// No description provided for @aboutSectionHeading.
  ///
  /// In en, this message translates to:
  /// **'Your privacy & how estimates work'**
  String get aboutSectionHeading;

  /// No description provided for @dataSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSettingsTitle;

  /// No description provided for @dataExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get dataExportTitle;

  /// No description provided for @dataExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your data as a .luma file'**
  String get dataExportSubtitle;

  /// No description provided for @dataImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get dataImportTitle;

  /// No description provided for @dataImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a .luma file'**
  String get dataImportSubtitle;

  /// No description provided for @dataAutoBackupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-backups'**
  String get dataAutoBackupsTitle;

  /// No description provided for @dataAutoBackupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snapshots created before each import'**
  String get dataAutoBackupsSubtitle;

  /// No description provided for @exportLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave export?'**
  String get exportLeaveTitle;

  /// No description provided for @exportLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Your current progress in this wizard will be lost.'**
  String get exportLeaveBody;

  /// No description provided for @exportStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get exportStay;

  /// No description provided for @exportLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get exportLeave;

  /// No description provided for @exportPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get exportPasswordsMismatch;

  /// No description provided for @exportAppBar.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportAppBar;

  /// No description provided for @exportBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get exportBackTooltip;

  /// No description provided for @exportWhatToInclude.
  ///
  /// In en, this message translates to:
  /// **'What to include'**
  String get exportWhatToInclude;

  /// No description provided for @exportChipEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get exportChipEverything;

  /// No description provided for @exportChipPeriodsOnly.
  ///
  /// In en, this message translates to:
  /// **'Periods only'**
  String get exportChipPeriodsOnly;

  /// No description provided for @exportTogglePeriods.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get exportTogglePeriods;

  /// No description provided for @exportToggleSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Symptoms & flow'**
  String get exportToggleSymptoms;

  /// No description provided for @exportToggleSymptomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flow, pain, mood'**
  String get exportToggleSymptomsSubtitle;

  /// No description provided for @exportToggleNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get exportToggleNotes;

  /// No description provided for @exportNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get exportNext;

  /// No description provided for @exportPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Optionally protect this backup with a password.'**
  String get exportPasswordIntro;

  /// No description provided for @exportPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get exportPasswordLabel;

  /// No description provided for @exportConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get exportConfirmPasswordLabel;

  /// No description provided for @exportClearPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear password'**
  String get exportClearPasswordTooltip;

  /// No description provided for @exportSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get exportSkip;

  /// No description provided for @exportCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating backup…'**
  String get exportCreating;

  /// No description provided for @exportReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get exportReadyTitle;

  /// No description provided for @exportMetaExported.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportMetaExported;

  /// No description provided for @exportMetaContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get exportMetaContent;

  /// No description provided for @exportMetaEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get exportMetaEncrypted;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportShare;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get exportDone;

  /// No description provided for @exportFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailedTitle;

  /// No description provided for @exportFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Could not complete export. Please try again.'**
  String get exportFailedBody;

  /// No description provided for @exportUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get exportUnknownError;

  /// No description provided for @exportTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get exportTryAgain;

  /// No description provided for @exportClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get exportClose;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get commonNotAvailable;

  /// No description provided for @importInProgressSnack.
  ///
  /// In en, this message translates to:
  /// **'Import in progress. Please wait.'**
  String get importInProgressSnack;

  /// No description provided for @importAppBar.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importAppBar;

  /// No description provided for @importSelectingFile.
  ///
  /// In en, this message translates to:
  /// **'Selecting file…'**
  String get importSelectingFile;

  /// No description provided for @importPasswordProtectedTitle.
  ///
  /// In en, this message translates to:
  /// **'This backup is password-protected'**
  String get importPasswordProtectedTitle;

  /// No description provided for @importExportedLine.
  ///
  /// In en, this message translates to:
  /// **'Exported: {when}'**
  String importExportedLine(String when);

  /// No description provided for @importIncludesLine.
  ///
  /// In en, this message translates to:
  /// **'Includes: {types}'**
  String importIncludesLine(String types);

  /// No description provided for @importDecrypt.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get importDecrypt;

  /// No description provided for @importCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get importCancel;

  /// No description provided for @importBackupSummary.
  ///
  /// In en, this message translates to:
  /// **'Backup summary'**
  String get importBackupSummary;

  /// No description provided for @importPreviewCounts.
  ///
  /// In en, this message translates to:
  /// **'Found {periods} period(s) and {entries} day entries.'**
  String importPreviewCounts(int periods, int entries);

  /// No description provided for @importDupWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} entries match dates you already logged on this device.'**
  String importDupWarning(int count);

  /// No description provided for @importNoDupMessage.
  ///
  /// In en, this message translates to:
  /// **'No duplicates found — all entries are new for your existing dates.'**
  String get importNoDupMessage;

  /// No description provided for @importStrategyTitle.
  ///
  /// In en, this message translates to:
  /// **'How should duplicates be handled?'**
  String get importStrategyTitle;

  /// No description provided for @importStrategyExplainer.
  ///
  /// In en, this message translates to:
  /// **'Duplicate means the same calendar day already has a log entry on this device. {count} entries are affected.'**
  String importStrategyExplainer(int count);

  /// No description provided for @importSegmentKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep existing'**
  String get importSegmentKeep;

  /// No description provided for @importSegmentUseImported.
  ///
  /// In en, this message translates to:
  /// **'Use imported'**
  String get importSegmentUseImported;

  /// No description provided for @importTooltipKeep.
  ///
  /// In en, this message translates to:
  /// **'Entries already on your device stay unchanged. Only new dates are imported.'**
  String get importTooltipKeep;

  /// No description provided for @importTooltipReplace.
  ///
  /// In en, this message translates to:
  /// **'Entries from the backup replace your current data for matching dates.'**
  String get importTooltipReplace;

  /// No description provided for @importStrategyHintKeep.
  ///
  /// In en, this message translates to:
  /// **'Entries already on your device stay unchanged. Only new dates are imported.'**
  String get importStrategyHintKeep;

  /// No description provided for @importStrategyHintReplace.
  ///
  /// In en, this message translates to:
  /// **'Entries from the backup replace your current data for matching dates.'**
  String get importStrategyHintReplace;

  /// No description provided for @importImportCta.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importImportCta;

  /// No description provided for @importCreatingSafetyBackup.
  ///
  /// In en, this message translates to:
  /// **'Creating safety backup…'**
  String get importCreatingSafetyBackup;

  /// No description provided for @importImportingEntries.
  ///
  /// In en, this message translates to:
  /// **'Importing entries…'**
  String get importImportingEntries;

  /// No description provided for @importResultSummary.
  ///
  /// In en, this message translates to:
  /// **'{periods} period(s) imported, {entries} new entries, {skipped} skipped, {replaced} replaced.'**
  String importResultSummary(
    int periods,
    int entries,
    int skipped,
    int replaced,
  );

  /// No description provided for @importErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get importErrorGeneric;

  /// No description provided for @importErrorReadSelected.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file.'**
  String get importErrorReadSelected;

  /// No description provided for @importErrorWrongExtension.
  ///
  /// In en, this message translates to:
  /// **'Please select a .luma backup file'**
  String get importErrorWrongExtension;

  /// No description provided for @importErrorReadBackup.
  ///
  /// In en, this message translates to:
  /// **'Could not read this backup file.'**
  String get importErrorReadBackup;

  /// No description provided for @importErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get importErrorWrongPassword;

  /// No description provided for @importErrorDecrypt.
  ///
  /// In en, this message translates to:
  /// **'Could not decrypt this backup.'**
  String get importErrorDecrypt;

  /// No description provided for @importErrorApply.
  ///
  /// In en, this message translates to:
  /// **'Could not import this backup. Please try again.'**
  String get importErrorApply;

  /// No description provided for @importErrorParser.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String importErrorParser(String message);

  /// No description provided for @importTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get importTryAgain;

  /// No description provided for @importClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get importClose;

  /// No description provided for @commonBackspace.
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get commonBackspace;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @dataContentTypesFallback.
  ///
  /// In en, this message translates to:
  /// **'Periods and entries'**
  String get dataContentTypesFallback;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @symptomFormTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add symptoms'**
  String get symptomFormTitleAdd;

  /// No description provided for @symptomFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit symptoms'**
  String get symptomFormTitleEdit;

  /// No description provided for @symptomSectionFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get symptomSectionFlow;

  /// No description provided for @symptomSectionPain.
  ///
  /// In en, this message translates to:
  /// **'Pain'**
  String get symptomSectionPain;

  /// No description provided for @symptomSectionMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get symptomSectionMood;

  /// No description provided for @symptomNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get symptomNotesLabel;

  /// No description provided for @symptomNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get symptomNotSet;

  /// No description provided for @symptomClearSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Clear symptoms'**
  String get symptomClearSymptoms;

  /// No description provided for @dayDetailMarkFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not mark this day. Please try again.'**
  String get dayDetailMarkFailed;

  /// No description provided for @dayDetailDeletePeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entire period?'**
  String get dayDetailDeletePeriodTitle;

  /// No description provided for @dayDetailDeletePeriodOngoingBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the ongoing period starting {start} and all of its day logs.'**
  String dayDetailDeletePeriodOngoingBody(String start);

  /// No description provided for @dayDetailDeletePeriodClosedBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the period {start}–{end} and all of its day logs. This cannot be undone.'**
  String dayDetailDeletePeriodClosedBody(String start, String end);

  /// No description provided for @dayDetailPeriodOngoing.
  ///
  /// In en, this message translates to:
  /// **'ongoing'**
  String get dayDetailPeriodOngoing;

  /// No description provided for @dayDetailDeletePeriodFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete period.'**
  String get dayDetailDeletePeriodFailed;

  /// No description provided for @dayDetailRemoveDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this day?'**
  String get dayDetailRemoveDayTitle;

  /// No description provided for @dayDetailRemoveDayBody.
  ///
  /// In en, this message translates to:
  /// **'Unmark {date} as a period day. Logged symptoms for this day will be removed.'**
  String dayDetailRemoveDayBody(String date);

  /// No description provided for @dayDetailRemoveDayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove this day. Please try again.'**
  String get dayDetailRemoveDayFailed;

  /// No description provided for @dayDetailClearSymptomsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear symptoms.'**
  String get dayDetailClearSymptomsFailed;

  /// No description provided for @dayDetailLogWhenArrives.
  ///
  /// In en, this message translates to:
  /// **'You can log this once the day arrives.'**
  String get dayDetailLogWhenArrives;

  /// No description provided for @dayDetailHadPeriod.
  ///
  /// In en, this message translates to:
  /// **'I had my period'**
  String get dayDetailHadPeriod;

  /// No description provided for @dayDetailFuturePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Future dates — check back when this day arrives.'**
  String get dayDetailFuturePlaceholder;

  /// No description provided for @dayDetailNoSymptoms.
  ///
  /// In en, this message translates to:
  /// **'No symptoms or notes logged for this day.'**
  String get dayDetailNoSymptoms;

  /// No description provided for @dayDetailAddSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Add symptoms'**
  String get dayDetailAddSymptoms;

  /// No description provided for @dayDetailRemoveThisDay.
  ///
  /// In en, this message translates to:
  /// **'Remove this day'**
  String get dayDetailRemoveThisDay;

  /// No description provided for @dayDetailDeleteEntirePeriod.
  ///
  /// In en, this message translates to:
  /// **'Delete entire period'**
  String get dayDetailDeleteEntirePeriod;

  /// No description provided for @dayDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dayDetailEdit;

  /// No description provided for @dayDetailClearSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Clear symptoms'**
  String get dayDetailClearSymptoms;

  /// No description provided for @firstLogAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Log your first period'**
  String get firstLogAppBarTitle;

  /// No description provided for @firstLogStartQuestion.
  ///
  /// In en, this message translates to:
  /// **'When did your current or most recent period start?'**
  String get firstLogStartQuestion;

  /// No description provided for @firstLogChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get firstLogChangeDate;

  /// No description provided for @firstLogPeriodEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'This period has already ended'**
  String get firstLogPeriodEndedTitle;

  /// No description provided for @firstLogPeriodEndedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — add a last period day if it is not ongoing.'**
  String get firstLogPeriodEndedSubtitle;

  /// No description provided for @firstLogChangeEndDate.
  ///
  /// In en, this message translates to:
  /// **'Change end date'**
  String get firstLogChangeEndDate;

  /// No description provided for @firstLogSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get firstLogSaveContinue;

  /// No description provided for @firstLogSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your period. Please try again.'**
  String get firstLogSaveFailed;

  /// No description provided for @firstLogSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Period logged — you\'re all set!'**
  String get firstLogSuccessSnack;

  /// No description provided for @moodSettingsLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood display'**
  String get moodSettingsLoadingTitle;

  /// No description provided for @moodSettingsWordLabelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use word labels for mood'**
  String get moodSettingsWordLabelsTitle;

  /// No description provided for @moodSettingsWordLabelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show text labels instead of emoji faces'**
  String get moodSettingsWordLabelsSubtitle;

  /// No description provided for @predSettingsTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predSettingsTileTitle;

  /// No description provided for @predSettingsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Forecast display, horizon, and methods'**
  String get predSettingsTileSubtitle;

  /// No description provided for @predSettingsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predSettingsAppBarTitle;

  /// No description provided for @predSettingsSectionHowManyDays.
  ///
  /// In en, this message translates to:
  /// **'How many days to show'**
  String get predSettingsSectionHowManyDays;

  /// No description provided for @predSettingsModeConsensusTitle.
  ///
  /// In en, this message translates to:
  /// **'Only strong predictions'**
  String get predSettingsModeConsensusTitle;

  /// No description provided for @predSettingsModeConsensusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Days where multiple methods agree'**
  String get predSettingsModeConsensusSubtitle;

  /// No description provided for @predSettingsModeAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All predictions'**
  String get predSettingsModeAllTitle;

  /// No description provided for @predSettingsModeAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every predicted day, even less certain ones'**
  String get predSettingsModeAllSubtitle;

  /// No description provided for @predSettingsModeAllNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'All predictions + labels'**
  String get predSettingsModeAllNotesTitle;

  /// No description provided for @predSettingsModeAllNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same as above, with a note on less certain days'**
  String get predSettingsModeAllNotesSubtitle;

  /// No description provided for @predSettingsSectionHorizon.
  ///
  /// In en, this message translates to:
  /// **'How far ahead to forecast'**
  String get predSettingsSectionHorizon;

  /// No description provided for @predSettingsHorizonCaption.
  ///
  /// In en, this message translates to:
  /// **'Farther forecasts are less reliable, especially with irregular cycles. They fade out to show this.'**
  String get predSettingsHorizonCaption;

  /// No description provided for @predSettingsHorizonNextOnly.
  ///
  /// In en, this message translates to:
  /// **'Next period only'**
  String get predSettingsHorizonNextOnly;

  /// No description provided for @predSettingsHorizon3Title.
  ///
  /// In en, this message translates to:
  /// **'3 months ahead'**
  String get predSettingsHorizon3Title;

  /// No description provided for @predSettingsHorizon3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Good for travel planning'**
  String get predSettingsHorizon3Subtitle;

  /// No description provided for @predSettingsHorizon6Title.
  ///
  /// In en, this message translates to:
  /// **'6 months ahead'**
  String get predSettingsHorizon6Title;

  /// No description provided for @predSettingsHorizon6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Rough planning only — uncertainty grows significantly'**
  String get predSettingsHorizon6Subtitle;

  /// No description provided for @predSettingsSectionMethods.
  ///
  /// In en, this message translates to:
  /// **'Prediction methods'**
  String get predSettingsSectionMethods;

  /// No description provided for @predSettingsMethodsCaption.
  ///
  /// In en, this message translates to:
  /// **'More methods = stronger predictions when they agree. Turn off any you don\'t want.'**
  String get predSettingsMethodsCaption;

  /// No description provided for @predSettingsLinearTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Trend detection'**
  String get predSettingsLinearTrendTitle;

  /// No description provided for @predSettingsHintMedian.
  ///
  /// In en, this message translates to:
  /// **'Uses the middle value of your last few cycles'**
  String get predSettingsHintMedian;

  /// No description provided for @predSettingsHintEwma.
  ///
  /// In en, this message translates to:
  /// **'Gives more weight to your most recent cycles'**
  String get predSettingsHintEwma;

  /// No description provided for @predSettingsHintBayesian.
  ///
  /// In en, this message translates to:
  /// **'Learns your pattern over time, works from 1 cycle'**
  String get predSettingsHintBayesian;

  /// No description provided for @predSettingsHintLinearTrend.
  ///
  /// In en, this message translates to:
  /// **'Detects if cycles are getting longer or shorter (5+ cycles)'**
  String get predSettingsHintLinearTrend;

  /// No description provided for @fertilitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertile window estimate'**
  String get fertilitySettingsTitle;

  /// No description provided for @fertilitySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show estimated fertile days on calendar and home'**
  String get fertilitySettingsSubtitle;

  /// No description provided for @fertilityDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you begin'**
  String get fertilityDisclaimerTitle;

  /// No description provided for @fertilityDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'This feature shows an estimated fertile window based on your cycle history. It is an educational guide only — not medical or contraceptive advice. Talk to a healthcare provider for personal guidance.'**
  String get fertilityDisclaimerBody;

  /// No description provided for @fertilityDisclaimerAccept.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get fertilityDisclaimerAccept;

  /// No description provided for @fertilityInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertile window setup'**
  String get fertilityInputTitle;

  /// No description provided for @fertilityInputCycleLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Average cycle length'**
  String get fertilityInputCycleLengthLabel;

  /// No description provided for @fertilityInputCycleLengthAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Computed from your {count} logged cycles'**
  String fertilityInputCycleLengthAutoHint(int count);

  /// No description provided for @fertilityInputCycleLengthManualHint.
  ///
  /// In en, this message translates to:
  /// **'Adjust if your typical cycle differs'**
  String get fertilityInputCycleLengthManualHint;

  /// No description provided for @fertilityInputLutealPhaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Luteal phase length'**
  String get fertilityInputLutealPhaseLabel;

  /// No description provided for @fertilityInputLutealPhaseExplanation.
  ///
  /// In en, this message translates to:
  /// **'Most people have around 14 days. Adjust if you know yours.'**
  String get fertilityInputLutealPhaseExplanation;

  /// No description provided for @fertilityInputLutealPhaseDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String fertilityInputLutealPhaseDaysUnit(int days);

  /// No description provided for @fertilityInputSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fertilityInputSave;

  /// No description provided for @fertilityInputNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Log at least 2 complete cycles to auto-fill'**
  String get fertilityInputNotEnoughData;

  /// No description provided for @fertilityCalendarLegendLabel.
  ///
  /// In en, this message translates to:
  /// **'Fertile (est.)'**
  String get fertilityCalendarLegendLabel;

  /// No description provided for @fertilityCalendarDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated fertile day'**
  String get fertilityCalendarDayLabel;

  /// No description provided for @fertilityCalendarDayDetail.
  ///
  /// In en, this message translates to:
  /// **'Estimated fertile day — based on your cycle history'**
  String get fertilityCalendarDayDetail;

  /// No description provided for @fertilityHomeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertile window'**
  String get fertilityHomeCardTitle;

  /// No description provided for @fertilityHomeCardRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String fertilityHomeCardRange(String start, String end);

  /// No description provided for @fertilityHomeCardFooter.
  ///
  /// In en, this message translates to:
  /// **'Estimate only'**
  String get fertilityHomeCardFooter;

  /// No description provided for @fertilityHomeCardExplanation.
  ///
  /// In en, this message translates to:
  /// **'Based on your average cycle of {days} days'**
  String fertilityHomeCardExplanation(int days);

  /// No description provided for @fertilitySuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertile window estimate'**
  String get fertilitySuggestionTitle;

  /// No description provided for @fertilitySuggestionBody.
  ///
  /// In en, this message translates to:
  /// **'Get an estimated fertile window on your calendar based on your cycle history.'**
  String get fertilitySuggestionBody;

  /// No description provided for @fertilitySuggestionEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get fertilitySuggestionEnable;

  /// No description provided for @fertilitySuggestionNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Log more periods to unlock this feature'**
  String get fertilitySuggestionNotEnoughData;

  /// No description provided for @fertilityDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get fertilityDisabled;

  /// No description provided for @flowValueLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get flowValueLight;

  /// No description provided for @flowValueMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get flowValueMedium;

  /// No description provided for @flowValueHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get flowValueHeavy;

  /// No description provided for @painValueNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get painValueNone;

  /// No description provided for @painValueMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get painValueMild;

  /// No description provided for @painValueModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get painValueModerate;

  /// No description provided for @painValueSevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get painValueSevere;

  /// No description provided for @painValueVerySevere.
  ///
  /// In en, this message translates to:
  /// **'Very severe'**
  String get painValueVerySevere;

  /// No description provided for @moodValueVeryBad.
  ///
  /// In en, this message translates to:
  /// **'Very bad'**
  String get moodValueVeryBad;

  /// No description provided for @moodValueBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodValueBad;

  /// No description provided for @moodValueNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodValueNeutral;

  /// No description provided for @moodValueGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodValueGood;

  /// No description provided for @moodValueVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get moodValueVeryGood;
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
