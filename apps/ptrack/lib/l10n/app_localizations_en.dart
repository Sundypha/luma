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
    String _temp0 = intl.Intl.pluralLogic(
      avail,
      locale: localeName,
      other:
          'There are not enough completed cycles yet to estimate a next start. $avail cycles are available after filtering; at least $need are typically needed.',
      one:
          'There are not enough completed cycles yet to estimate a next start. 1 cycle is available after filtering; at least $need are typically needed.',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      methods,
      locale: localeName,
      other: '$methods methods',
      one: '1 method',
    );
    return 'With $cycles cycles logged, your prediction now uses $_temp0 for better accuracy.';
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Currently using $n prediction methods.',
      one: 'Currently using 1 prediction method.',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'Forecast ≈ $months months out',
      one: 'Forecast ≈ 1 month out',
    );
    return '$_temp0';
  }

  @override
  String get dayDetailDisclaimerHop1 =>
      'Rough estimate, about 2 months out — less reliable than the next period.';

  @override
  String get dayDetailDisclaimerHop1HighSpread =>
      'Rough estimate, about 2 months out — less reliable than the next period. Your cycle length varies quite a bit, so this date may shift significantly.';

  @override
  String dayDetailDisclaimerHopN(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other:
          'Very rough estimate, about $months months out — use for general planning only.',
      one:
          'Very rough estimate, about 1 month out — use for general planning only.',
    );
    return '$_temp0';
  }

  @override
  String dayDetailDisclaimerHopNSpread(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other:
          'Very rough estimate, about $months months out — use for general planning only. Your cycle length varies quite a bit, so this date may shift significantly.',
      one:
          'Very rough estimate, about 1 month out — use for general planning only. Your cycle length varies quite a bit, so this date may shift significantly.',
    );
    return '$_temp0';
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

  @override
  String get settingsAppLanguageSectionTitle => 'App language';

  @override
  String get appLanguageFollowDevice => 'System default (follow device)';

  @override
  String get appLanguageEnglish => 'English';

  @override
  String get appLanguageGerman => 'German';

  @override
  String get appLanguageRestartMessage =>
      'Restart the app to apply this change.';

  @override
  String get settingsMenuLanguageTitle => 'Language';

  @override
  String get settingsMenuLanguageSubtitle =>
      'System default, English, or German';

  @override
  String get settingsMenuPeriodPredictionTitle => 'Period prediction';

  @override
  String get settingsMenuFertilityTitle => 'Fertility prediction';

  @override
  String get settingsMenuPrivacySubtitle => 'App lock, backup, and export';

  @override
  String get settingsMenuDataBackupSubtitle =>
      'Export, import, and automatic local backups';

  @override
  String get calendarInsufficientPredictionHint =>
      'No forecast yet — mark at least two separate periods so Luma can measure the gap between them.';

  @override
  String get calendarLegendHatching =>
      'Lighter hatching = further out, less certain';

  @override
  String get calendarLegendDiaryEntry => 'Diary entry';

  @override
  String get calendarToday => 'Today';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get drawerSettingsLabel => 'Settings';

  @override
  String get drawerDataLabel => 'Data';

  @override
  String get drawerAboutLabel => 'About';

  @override
  String get todaySectionTitle => 'Today';

  @override
  String get homeDiaryNewEntry => 'Write diary entry';

  @override
  String get homeDiaryEditEntry => 'Edit today\'s diary entry';

  @override
  String get todayUnmarkedBody => 'You have not marked today as a period day.';

  @override
  String get todayMarkPeriodCta => 'I had my period today';

  @override
  String get todayAddSymptomsCta => 'Add symptoms for today';

  @override
  String get todayLogTitle => 'Today\'s log';

  @override
  String todayFlowLine(String label) {
    return 'Flow: $label';
  }

  @override
  String todayPainLine(String label) {
    return 'Pain: $label';
  }

  @override
  String todayMoodLine(String emoji, String label) {
    return 'Mood: $emoji $label';
  }

  @override
  String get todayEditLogCta => 'Edit today\'s log';

  @override
  String get lockUseBiometrics => 'Use biometrics';

  @override
  String get lockForgotPin => 'Forgot PIN?';

  @override
  String get lockIncorrectPin => 'Incorrect PIN';

  @override
  String get lockBiometricUnlockReason => 'Authenticate to unlock Luma';

  @override
  String get lockBiometricSettingsReason =>
      'Authenticate to change lock settings';

  @override
  String get lockSettingsAppBar => 'App lock';

  @override
  String get lockSettingsSwitchTitle => 'App lock';

  @override
  String get lockSettingsSwitchSubtitle =>
      'Lock with PIN or biometrics when returning from background.';

  @override
  String get lockSettingsChangePin => 'Change PIN';

  @override
  String get lockSettingsUseBiometrics => 'Use biometrics';

  @override
  String get lockSettingsLockNow => 'Lock now';

  @override
  String get lockSettingsLockNowTooltip => 'Lock now';

  @override
  String get lockPrivacySecurityTile => 'Privacy & Security';

  @override
  String get lockPrivacySecurityOnSubtitle => 'App lock is on';

  @override
  String get lockPrivacySecurityOffSubtitle =>
      'Lock with PIN or biometrics when returning from background';

  @override
  String get lockReauthTitle => 'Confirm it is you';

  @override
  String get lockReauthBody => 'Enter your PIN to continue.';

  @override
  String get forgotPinTitle => 'Forgot your PIN?';

  @override
  String get forgotPinBody =>
      'There is no way to recover a forgotten PIN without erasing your data.\n\nBefore resetting, export your data from Data settings so you can restore it afterwards.\n\nResetting will erase all period and symptom history from this device.';

  @override
  String get forgotPinEraseCta => 'Erase all data and reset';

  @override
  String get pinSetupTitle => 'Set up app lock';

  @override
  String get pinSetupAckBody =>
      'App lock encrypts access with a PIN. If you forget your PIN, the only recovery option is a data reset — your period data will be erased. Export your data regularly to avoid data loss.';

  @override
  String get pinSetupAckContinue => 'I understand, continue';

  @override
  String get pinSetupCreateTitle => 'Create a PIN';

  @override
  String get pinSetupCreateHint =>
      'Choose a PIN of at least 6 digits. Press ✓ when done.';

  @override
  String get pinSetupConfirmTitle => 'Confirm your PIN';

  @override
  String get pinSetupMismatch => 'PINs do not match';

  @override
  String get pinSetupBioTitle => 'Enable biometrics for faster unlock?';

  @override
  String get pinSetupEnableBio => 'Enable biometrics';

  @override
  String get pinSetupSkip => 'Skip';

  @override
  String get onbPrivacyTitle => 'Your data stays here';

  @override
  String get onbPrivacyBody =>
      'Everything you log stays on this device. There\'s no account to create, no cloud sync, and no sign-up — just your phone and your entries.';

  @override
  String get onbEstimatesTitle => 'Estimates, not medical advice';

  @override
  String get onbEstimatesBody =>
      'Forecasts are based on the history you add here. They\'re personal estimates to help you notice patterns — not a diagnosis, treatment, or substitute for care from a qualified health professional.';

  @override
  String get onbReadyTitle => 'Ready to start';

  @override
  String get onbReadyBody =>
      'Log when your period starts to get going. The more you add over time, the more helpful your estimates can be — and you can always skip for now.';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbGetStarted => 'Get Started';

  @override
  String get onbSkip => 'Skip';

  @override
  String onbStepSemantics(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get aboutAppBarTitle => 'About Luma';

  @override
  String get aboutSectionHeading => 'Your privacy & how estimates work';

  @override
  String get dataSettingsTitle => 'Data';

  @override
  String get dataExportTitle => 'Export Backup';

  @override
  String get dataExportSubtitle => 'Save your data as a .luma file';

  @override
  String get dataImportTitle => 'Import Backup';

  @override
  String get dataImportSubtitle => 'Restore data from a .luma file';

  @override
  String get dataAutoBackupsTitle => 'Auto-backups';

  @override
  String get dataAutoBackupsSubtitle => 'Snapshots created before each import';

  @override
  String get exportLeaveTitle => 'Leave export?';

  @override
  String get exportLeaveBody =>
      'Your current progress in this wizard will be lost.';

  @override
  String get exportStay => 'Stay';

  @override
  String get exportLeave => 'Leave';

  @override
  String get exportPasswordsMismatch => 'Passwords do not match';

  @override
  String get exportAppBar => 'Export Backup';

  @override
  String get exportBackTooltip => 'Back';

  @override
  String get exportWhatToInclude => 'What to include';

  @override
  String get exportChipEverything => 'Everything';

  @override
  String get exportChipPeriodsOnly => 'Periods only';

  @override
  String get exportTogglePeriods => 'Periods';

  @override
  String get exportToggleSymptoms => 'Symptoms & flow';

  @override
  String get exportToggleSymptomsSubtitle => 'Flow, pain, mood';

  @override
  String get exportToggleNotes => 'Notes';

  @override
  String get exportToggleDiary => 'Diary';

  @override
  String get exportNext => 'Next';

  @override
  String get exportPasswordIntro =>
      'Optionally protect this backup with a password.';

  @override
  String get exportPasswordLabel => 'Password';

  @override
  String get exportConfirmPasswordLabel => 'Confirm password';

  @override
  String get exportClearPasswordTooltip => 'Clear password';

  @override
  String get exportSkip => 'Skip';

  @override
  String get exportCreating => 'Creating backup…';

  @override
  String get exportReadyTitle => 'Export ready';

  @override
  String get exportMetaExported => 'Exported';

  @override
  String get exportMetaContent => 'Content';

  @override
  String get exportMetaEncrypted => 'Encrypted';

  @override
  String get exportShare => 'Share';

  @override
  String get exportDone => 'Done';

  @override
  String get exportFailedTitle => 'Export failed';

  @override
  String get exportFailedBody => 'Could not complete export. Please try again.';

  @override
  String get exportUnknownError => 'Unknown error';

  @override
  String get exportTryAgain => 'Try Again';

  @override
  String get exportClose => 'Close';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonNotAvailable => '—';

  @override
  String get importInProgressSnack => 'Import in progress. Please wait.';

  @override
  String get importAppBar => 'Import Backup';

  @override
  String get importSelectingFile => 'Selecting file…';

  @override
  String get importPasswordProtectedTitle =>
      'This backup is password-protected';

  @override
  String importExportedLine(String when) {
    return 'Exported: $when';
  }

  @override
  String importIncludesLine(String types) {
    return 'Includes: $types';
  }

  @override
  String get importDecrypt => 'Decrypt';

  @override
  String get importCancel => 'Cancel';

  @override
  String get importBackupSummary => 'Backup summary';

  @override
  String importPreviewCounts(int periods, int entries) {
    return 'Found $periods period(s) and $entries day entries.';
  }

  @override
  String importDupWarning(int count) {
    return '$count entries match dates you already logged on this device.';
  }

  @override
  String get importNoDupMessage =>
      'No duplicates found — all entries are new for your existing dates.';

  @override
  String get importStrategyTitle => 'How should duplicates be handled?';

  @override
  String importStrategyExplainer(int count) {
    return 'Duplicate means the same calendar day already has a log entry on this device. $count entries are affected.';
  }

  @override
  String get importSegmentKeep => 'Keep existing';

  @override
  String get importSegmentUseImported => 'Use imported';

  @override
  String get importTooltipKeep =>
      'Entries already on your device stay unchanged. Only new dates are imported.';

  @override
  String get importTooltipReplace =>
      'Entries from the backup replace your current data for matching dates.';

  @override
  String get importStrategyHintKeep =>
      'Entries already on your device stay unchanged. Only new dates are imported.';

  @override
  String get importStrategyHintReplace =>
      'Entries from the backup replace your current data for matching dates.';

  @override
  String get importImportCta => 'Import';

  @override
  String get importCreatingSafetyBackup => 'Creating safety backup…';

  @override
  String get importImportingEntries => 'Importing entries…';

  @override
  String importResultSummary(
    int periods,
    int entries,
    int skipped,
    int replaced,
  ) {
    return '$periods period(s) imported, $entries new entries, $skipped skipped, $replaced replaced.';
  }

  @override
  String get importErrorGeneric => 'Something went wrong.';

  @override
  String get importErrorReadSelected => 'Could not read the selected file.';

  @override
  String get importErrorWrongExtension => 'Please select a .luma backup file';

  @override
  String get importErrorReadBackup => 'Could not read this backup file.';

  @override
  String get importErrorWrongPassword =>
      'Incorrect password. Please try again.';

  @override
  String get importErrorDecrypt => 'Could not decrypt this backup.';

  @override
  String get importErrorApply =>
      'Could not import this backup. Please try again.';

  @override
  String importErrorParser(String message) {
    return '$message';
  }

  @override
  String get importTryAgain => 'Try again';

  @override
  String get importClose => 'Close';

  @override
  String get commonBackspace => 'Backspace';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get dataContentTypesFallback => 'Periods and entries';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get diaryNotesLabel => 'Personal notes';

  @override
  String get diaryMoodLabel => 'Mood';

  @override
  String get diaryTagsLabel => 'Tags';

  @override
  String get diaryAddTagLabel => 'Add tag…';

  @override
  String get diaryFormTitleNew => 'New diary entry';

  @override
  String get diaryFormTitleEdit => 'Edit diary entry';

  @override
  String get diaryDeleteEntryTitle => 'Delete diary entry?';

  @override
  String diaryDeleteEntryBody(String date) {
    return 'This will permanently delete the diary entry for $date.';
  }

  @override
  String get symptomFormTitleAdd => 'Add symptoms';

  @override
  String get symptomFormTitleEdit => 'Edit symptoms';

  @override
  String get symptomSectionFlow => 'Flow';

  @override
  String get symptomSectionPain => 'Pain';

  @override
  String get symptomSectionMood => 'Mood';

  @override
  String get symptomNotesLabel => 'Notes';

  @override
  String get symptomNotesHelper => 'Included in PDF export.';

  @override
  String get symptomNotSet => 'Not set';

  @override
  String get symptomClearSymptoms => 'Clear symptoms';

  @override
  String get dayDetailMarkFailed =>
      'Could not mark this day. Please try again.';

  @override
  String get dayDetailDeletePeriodTitle => 'Delete entire period?';

  @override
  String dayDetailDeletePeriodOngoingBody(String start) {
    return 'Remove the ongoing period starting $start and all of its day logs.';
  }

  @override
  String dayDetailDeletePeriodClosedBody(String start, String end) {
    return 'Remove the period $start–$end and all of its day logs. This cannot be undone.';
  }

  @override
  String get dayDetailPeriodOngoing => 'ongoing';

  @override
  String get dayDetailDeletePeriodFailed => 'Could not delete period.';

  @override
  String get dayDetailRemoveDayTitle => 'Remove this day?';

  @override
  String dayDetailRemoveDayBody(String date) {
    return 'Unmark $date as a period day. Logged symptoms for this day will be removed.';
  }

  @override
  String get dayDetailRemoveDayFailed =>
      'Could not remove this day. Please try again.';

  @override
  String get dayDetailClearSymptomsFailed => 'Could not clear symptoms.';

  @override
  String get dayDetailLogWhenArrives =>
      'You can log this once the day arrives.';

  @override
  String get dayDetailHadPeriod => 'I had my period';

  @override
  String get dayDetailFuturePlaceholder =>
      'Future dates — check back when this day arrives.';

  @override
  String get dayDetailNoSymptoms => 'No symptoms or notes logged for this day.';

  @override
  String get dayDetailAddSymptoms => 'Add symptoms';

  @override
  String get dayDetailRemoveThisDay => 'Remove this day';

  @override
  String get dayDetailDeleteEntirePeriod => 'Delete entire period';

  @override
  String get dayDetailEdit => 'Edit';

  @override
  String get dayDetailClearSymptoms => 'Clear symptoms';

  @override
  String get firstLogAppBarTitle => 'Log your first period';

  @override
  String get firstLogStartQuestion =>
      'When did your current or most recent period start?';

  @override
  String get firstLogChangeDate => 'Change date';

  @override
  String get firstLogPeriodEndedTitle => 'This period has already ended';

  @override
  String get firstLogPeriodEndedSubtitle =>
      'Optional — add a last period day if it is not ongoing.';

  @override
  String get firstLogChangeEndDate => 'Change end date';

  @override
  String get firstLogSaveContinue => 'Save & Continue';

  @override
  String get firstLogSaveFailed =>
      'Could not save your period. Please try again.';

  @override
  String get firstLogSuccessSnack => 'Period logged — you\'re all set!';

  @override
  String get predSettingsTileTitle => 'Predictions';

  @override
  String get predSettingsTileSubtitle =>
      'Forecast display, horizon, and methods';

  @override
  String get predSettingsAppBarTitle => 'Predictions';

  @override
  String get predSettingsSectionHowManyDays => 'How many days to show';

  @override
  String get predSettingsModeConsensusTitle => 'Only strong predictions';

  @override
  String get predSettingsModeConsensusSubtitle =>
      'Days where multiple methods agree';

  @override
  String get predSettingsModeAllTitle => 'All predictions';

  @override
  String get predSettingsModeAllSubtitle =>
      'Every predicted day, even less certain ones';

  @override
  String get predSettingsModeAllNotesTitle => 'All predictions + labels';

  @override
  String get predSettingsModeAllNotesSubtitle =>
      'Same as above, with a note on less certain days';

  @override
  String get predSettingsSectionHorizon => 'How far ahead to forecast';

  @override
  String get predSettingsHorizonCaption =>
      'Farther forecasts are less reliable, especially with irregular cycles. Hatch density shows how much prediction methods agree.';

  @override
  String get predSettingsHorizonNextOnly => 'Next period only';

  @override
  String get predSettingsHorizon3Title => '3 months ahead';

  @override
  String get predSettingsHorizon3Subtitle => 'Good for travel planning';

  @override
  String get predSettingsHorizon6Title => '6 months ahead';

  @override
  String get predSettingsHorizon6Subtitle =>
      'Rough planning only — uncertainty grows significantly';

  @override
  String get predSettingsSectionMethods => 'Prediction methods';

  @override
  String get predSettingsMethodsCaption =>
      'More methods = stronger predictions when they agree. Turn off any you don\'t want.';

  @override
  String get predSettingsLinearTrendTitle => 'Trend detection';

  @override
  String get predSettingsHintMedian =>
      'Uses the middle value of your last few cycles';

  @override
  String get predSettingsHintEwma =>
      'Gives more weight to your most recent cycles';

  @override
  String get predSettingsHintBayesian =>
      'Learns your pattern over time, works from 1 cycle';

  @override
  String get predSettingsHintLinearTrend =>
      'Detects if cycles are getting longer or shorter (5+ cycles)';

  @override
  String get fertilitySettingsTitle => 'Fertile window estimate';

  @override
  String get fertilitySettingsSubtitle =>
      'Show estimated fertile days on calendar and home';

  @override
  String get fertilityDisclaimerTitle => 'Before you begin';

  @override
  String get fertilityDisclaimerBody =>
      'This feature shows an estimated fertile window based on your cycle history. It is an educational guide only — not medical or contraceptive advice. Talk to a healthcare provider for personal guidance.';

  @override
  String get fertilityDisclaimerAccept => 'I understand';

  @override
  String get fertilityInputTitle => 'Fertile window setup';

  @override
  String get fertilityInputCycleLengthLabel => 'Average cycle length';

  @override
  String fertilityInputCycleLengthAutoHint(int count) {
    return 'Computed from your $count logged cycles';
  }

  @override
  String get fertilityInputCycleLengthManualHint =>
      'Adjust if your typical cycle differs';

  @override
  String get fertilityInputLutealPhaseLabel => 'Luteal phase length';

  @override
  String get fertilityInputLutealPhaseExplanation =>
      'Most have around 14 days. Adjust if you know yours.';

  @override
  String fertilityInputLutealPhaseDaysUnit(int days) {
    return '$days days';
  }

  @override
  String get fertilityInputSave => 'Save';

  @override
  String get fertilitySettingsSavedSnackbar => 'Fertility settings saved';

  @override
  String get fertilityInputNotEnoughData =>
      'Log at least 2 complete cycles to auto-fill';

  @override
  String get fertilityCalendarLegendLabel => 'Fertile (est.)';

  @override
  String get fertilityCalendarDayLabel => 'Estimated fertile day';

  @override
  String get fertilityCalendarDayDetail =>
      'Estimated fertile day — based on your cycle history';

  @override
  String get fertilityHomeCardTitle => 'Fertile window';

  @override
  String fertilityHomeCardRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get fertilityHomeCardFooter => 'Estimate only';

  @override
  String fertilityHomeCardExplanation(int days) {
    return 'Based on your average cycle of $days days';
  }

  @override
  String get fertilitySuggestionTitle => 'Fertile window estimate';

  @override
  String get fertilitySuggestionBody =>
      'Get an estimated fertile window on your calendar based on your cycle history.';

  @override
  String get fertilitySuggestionEnable => 'Enable';

  @override
  String get fertilitySuggestionNotEnoughData =>
      'Log more periods to unlock this feature';

  @override
  String get fertilityDisabled => 'Disabled';

  @override
  String get flowValueLight => 'Light';

  @override
  String get flowValueMedium => 'Medium';

  @override
  String get flowValueHeavy => 'Heavy';

  @override
  String get painValueNone => 'None';

  @override
  String get painValueMild => 'Mild';

  @override
  String get painValueModerate => 'Moderate';

  @override
  String get painValueSevere => 'Severe';

  @override
  String get painValueVerySevere => 'Very severe';

  @override
  String get moodValueVeryBad => 'Very bad';

  @override
  String get moodValueBad => 'Bad';

  @override
  String get moodValueNeutral => 'Neutral';

  @override
  String get moodValueGood => 'Good';

  @override
  String get moodValueVeryGood => 'Very good';

  @override
  String get pdfReportTitle => 'Luma — Period Report';

  @override
  String get pdfDisclaimer =>
      'This report is an informational export generated from self-reported data. It is not a diagnostic tool. Accuracy depends on the completeness and consistency of user entries. Consult a qualified healthcare professional for medical decisions.';

  @override
  String pdfGeneratedOn(String date) {
    return 'Generated on $date';
  }

  @override
  String pdfDateRange(String start, String end) {
    return 'Data from $start to $end';
  }

  @override
  String get pdfOverviewHeading => 'Overview';

  @override
  String get pdfCycleHistoryHeading => 'Cycle History';

  @override
  String get pdfCycleChartHeading => 'Cycle Length Over Time';

  @override
  String get pdfDaySummaryHeading => 'Daily Log Summary';

  @override
  String get pdfNotesHeading => 'Notes';

  @override
  String get pdfTotalCycles => 'Completed cycles';

  @override
  String get pdfAvgCycleLength => 'Average cycle length';

  @override
  String get pdfAvgPeriodDuration => 'Average period duration';

  @override
  String get pdfShortestCycle => 'Shortest cycle';

  @override
  String get pdfLongestCycle => 'Longest cycle';

  @override
  String pdfNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get pdfFlowDistribution => 'Flow intensity';

  @override
  String get pdfPainDistribution => 'Pain levels';

  @override
  String get pdfMoodDistribution => 'Mood';

  @override
  String get pdfDateColumn => 'Date';

  @override
  String get pdfFlowColumn => 'Flow';

  @override
  String get pdfPainColumn => 'Pain';

  @override
  String get pdfMoodColumn => 'Mood';

  @override
  String get pdfCycleStartColumn => 'Cycle start';

  @override
  String get pdfCycleLengthColumn => 'Length (days)';

  @override
  String get pdfNoDataForRange =>
      'No data available for the selected date range.';

  @override
  String get pdfNoDayData => 'No day-level data for the selected range.';

  @override
  String get pdfNoNotes => 'No notes for the selected range.';

  @override
  String get pdfMetadataOnlyNote =>
      'This report contains metadata only. Enable data sections for cycle details.';

  @override
  String get pdfFooterGenerated => 'Generated by Luma';

  @override
  String get pdfFlowLight => 'Light';

  @override
  String get pdfFlowMedium => 'Medium';

  @override
  String get pdfFlowHeavy => 'Heavy';

  @override
  String get pdfPainNone => 'None';

  @override
  String get pdfPainMild => 'Mild';

  @override
  String get pdfPainModerate => 'Moderate';

  @override
  String get pdfPainSevere => 'Severe';

  @override
  String get pdfPainVerySevere => 'Very severe';

  @override
  String get pdfMoodVeryBad => 'Very bad';

  @override
  String get pdfMoodBad => 'Bad';

  @override
  String get pdfMoodNeutral => 'Neutral';

  @override
  String get pdfMoodGood => 'Good';

  @override
  String get pdfMoodVeryGood => 'Very good';

  @override
  String get pdfExportTitle => 'PDF Report';

  @override
  String get pdfExportSubtitle => 'Generate a report for your physician';

  @override
  String get pdfExportScreenTitle => 'Export PDF Report';

  @override
  String get pdfPresetSummary => 'Summary';

  @override
  String get pdfPresetStandard => 'Standard';

  @override
  String get pdfPresetFull => 'Full';

  @override
  String get pdfSectionsHeading => 'Sections';

  @override
  String get pdfSectionOverview => 'Overview statistics';

  @override
  String get pdfSectionCycleHistory => 'Cycle history';

  @override
  String get pdfSectionChart => 'Cycle length chart';

  @override
  String get pdfSectionDaySummary => 'Daily log summary';

  @override
  String get pdfSectionNotes => 'Notes';

  @override
  String get pdfDateFrom => 'From';

  @override
  String get pdfDateTo => 'To';

  @override
  String get pdfGeneratePreview => 'Generate Preview';

  @override
  String get pdfGenerating => 'Generating report…';

  @override
  String get pdfPreviewTitle => 'Preview';

  @override
  String get pdfShareAction => 'Share';

  @override
  String get pdfExportError => 'Failed to generate report. Please try again.';

  @override
  String get pdfSaved => 'Report saved';

  @override
  String get pdfLinuxPreviewBody =>
      'Preview is not available on this platform. Save the PDF to open it elsewhere.';

  @override
  String get pdfSavePdf => 'Save PDF';
}
