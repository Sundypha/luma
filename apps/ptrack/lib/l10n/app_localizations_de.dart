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
    String _temp0 = intl.Intl.pluralLogic(
      avail,
      locale: localeName,
      other:
          'Noch reichen die abgeschlossenen Zyklen nicht aus, um den nächsten Beginn abzuschätzen. Nach Filterung stehen $avail Zyklen zur Verfügung; normalerweise werden mindestens $need benötigt.',
      one:
          'Noch reichen die abgeschlossenen Zyklen nicht aus, um den nächsten Beginn abzuschätzen. Nach Filterung steht 1 Zyklus zur Verfügung; normalerweise werden mindestens $need benötigt.',
    );
    return '$_temp0';
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
    return 'Die Schätzung durch Mustererkennung (Posterior-Mittelwert) liegt bei etwa $mean Tagen aus $n Zykluslängen.';
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
  String get algoNameBayesian => 'Mustererkennung';

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
    String _temp0 = intl.Intl.pluralLogic(
      methods,
      locale: localeName,
      other: '$methods Methoden',
      one: '1 Methode',
    );
    return 'Mit $cycles eingetragenen Zyklen nutzt deine Vorhersage jetzt $_temp0 für mehr Genauigkeit.';
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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Aktuell werden $n Vorhersagemethoden genutzt.',
      one: 'Aktuell wird 1 Vorhersagemethode genutzt.',
    );
    return '$_temp0';
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
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'Vorschau etwa $months Monate voraus',
      one: 'Vorschau etwa 1 Monat voraus',
    );
    return '$_temp0';
  }

  @override
  String get dayDetailDisclaimerHop1 =>
      'Grobe Schätzung, etwa 2 Monate voraus — weniger zuverlässig als die nächste Periode.';

  @override
  String get dayDetailDisclaimerHop1HighSpread =>
      'Grobe Schätzung, etwa 2 Monate voraus — weniger zuverlässig als die nächste Periode. Deine Zykluslänge schwankt ziemlich stark, dieser Termin kann sich deutlich verschieben.';

  @override
  String dayDetailDisclaimerHopN(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other:
          'Sehr grobe Schätzung, etwa $months Monate voraus — nur zur allgemeinen Planung.',
      one:
          'Sehr grobe Schätzung, etwa 1 Monat voraus — nur zur allgemeinen Planung.',
    );
    return '$_temp0';
  }

  @override
  String dayDetailDisclaimerHopNSpread(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other:
          'Sehr grobe Schätzung, etwa $months Monate voraus — nur zur allgemeinen Planung. Deine Zykluslänge schwankt ziemlich stark, dieser Termin kann sich deutlich verschieben.',
      one:
          'Sehr grobe Schätzung, etwa 1 Monat voraus — nur zur allgemeinen Planung. Deine Zykluslänge schwankt ziemlich stark, dieser Termin kann sich deutlich verschieben.',
    );
    return '$_temp0';
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

  @override
  String get calendarInsufficientPredictionHint =>
      'Noch keine Vorhersage — markier mindestens zwei getrennte Perioden, damit Luma den Abstand dazwischen messen kann.';

  @override
  String get calendarLegendHatching =>
      'Hellere Schraffur = weiter weg, unsicherer';

  @override
  String get calendarToday => 'Heute';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get navHome => 'Start';

  @override
  String get navCalendar => 'Kalender';

  @override
  String get drawerSettingsLabel => 'Einstellungen';

  @override
  String get drawerDataLabel => 'Daten';

  @override
  String get drawerAboutLabel => 'Über die App';

  @override
  String get todaySectionTitle => 'Heute';

  @override
  String get todayUnmarkedBody =>
      'Du hast heute noch keinen Periodentag markiert.';

  @override
  String get todayMarkPeriodCta => 'Ich hatte heute meine Periode';

  @override
  String get todayAddSymptomsCta => 'Symptome für heute eintragen';

  @override
  String get todayLogTitle => 'Heutiger Eintrag';

  @override
  String todayFlowLine(String label) {
    return 'Fluss: $label';
  }

  @override
  String todayPainLine(String label) {
    return 'Schmerzen: $label';
  }

  @override
  String todayMoodLine(String emoji, String label) {
    return 'Stimmung: $emoji $label';
  }

  @override
  String get todayEditLogCta => 'Heutigen Eintrag bearbeiten';

  @override
  String get lockUseBiometrics => 'Biometrie nutzen';

  @override
  String get lockForgotPin => 'PIN vergessen?';

  @override
  String get lockIncorrectPin => 'Falsche PIN';

  @override
  String get lockBiometricUnlockReason => 'Entsperren, um Luma zu öffnen';

  @override
  String get lockBiometricSettingsReason =>
      'Entsperren, um die Sperre zu ändern';

  @override
  String get lockSettingsAppBar => 'App-Sperre';

  @override
  String get lockSettingsSwitchTitle => 'App-Sperre';

  @override
  String get lockSettingsSwitchSubtitle =>
      'Sperre mit PIN oder Biometrie, wenn du zur App zurückkehrst.';

  @override
  String get lockSettingsChangePin => 'PIN ändern';

  @override
  String get lockSettingsUseBiometrics => 'Biometrie nutzen';

  @override
  String get lockSettingsLockNow => 'Jetzt sperren';

  @override
  String get lockSettingsLockNowTooltip => 'Jetzt sperren';

  @override
  String get lockPrivacySecurityTile => 'Datenschutz & Sicherheit';

  @override
  String get lockPrivacySecurityOnSubtitle => 'App-Sperre ist aktiv';

  @override
  String get lockPrivacySecurityOffSubtitle =>
      'Sperre mit PIN oder Biometrie, wenn du zur App zurückkehrst';

  @override
  String get lockReauthTitle => 'Bestätige, dass du es bist';

  @override
  String get lockReauthBody => 'Gib deine PIN ein, um fortzufahren.';

  @override
  String get forgotPinTitle => 'PIN vergessen?';

  @override
  String get forgotPinBody =>
      'Eine vergessene PIN kannst du nicht wiederherstellen, ohne deine Daten zu löschen.\n\nBevor du zurücksetzt, exportier deine Daten unter Daten, damit du sie danach wieder einspielen kannst.\n\nZurücksetzen löscht alle Perioden- und Symptomdaten auf diesem Gerät.';

  @override
  String get forgotPinEraseCta => 'Alle Daten löschen und zurücksetzen';

  @override
  String get pinSetupTitle => 'App-Sperre einrichten';

  @override
  String get pinSetupAckBody =>
      'Die App-Sperre schützt den Zugang mit einer PIN. Wenn du die PIN vergisst, bleibt nur ein Daten-Reset — deine Periodendaten gehen dabei verloren. Exportier deine Daten regelmäßig, um nichts zu verlieren.';

  @override
  String get pinSetupAckContinue => 'Verstanden, weiter';

  @override
  String get pinSetupCreateTitle => 'PIN festlegen';

  @override
  String get pinSetupCreateHint =>
      'Wähle eine PIN mit mindestens 4 Ziffern. Tippe auf ✓, wenn du fertig bist.';

  @override
  String get pinSetupConfirmTitle => 'PIN bestätigen';

  @override
  String get pinSetupMismatch => 'PINs stimmen nicht überein';

  @override
  String get pinSetupBioTitle =>
      'Biometrie für schnelleres Entsperren aktivieren?';

  @override
  String get pinSetupEnableBio => 'Biometrie aktivieren';

  @override
  String get pinSetupSkip => 'Überspringen';

  @override
  String get onbPrivacyTitle => 'Deine Daten bleiben hier';

  @override
  String get onbPrivacyBody =>
      'Alles, was du einträgst, bleibt auf diesem Gerät. Es gibt kein Konto, keinen Cloud-Sync und keine Anmeldung — nur dein Handy und deine Einträge.';

  @override
  String get onbEstimatesTitle => 'Schätzungen, keine medizinische Beratung';

  @override
  String get onbEstimatesBody =>
      'Vorhersagen basieren auf deiner Geschichte hier. Sie sind persönliche Schätzungen, um Muster zu erkennen — keine Diagnose, keine Behandlung und kein Ersatz für die Betreuung durch Fachpersonen.';

  @override
  String get onbReadyTitle => 'Bereit zum Start';

  @override
  String get onbReadyBody =>
      'Trag ein, wann deine Periode beginnt, um loszulegen. Je mehr du über die Zeit einträgst, desto hilfreicher können die Schätzungen werden — und du kannst auch vorerst überspringen.';

  @override
  String get onbContinue => 'Weiter';

  @override
  String get onbGetStarted => 'Los geht\'s';

  @override
  String get onbSkip => 'Überspringen';

  @override
  String onbStepSemantics(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get aboutAppBarTitle => 'Über Luma';

  @override
  String get aboutSectionHeading =>
      'Dein Datenschutz & wie Schätzungen funktionieren';

  @override
  String get dataSettingsTitle => 'Daten';

  @override
  String get dataExportTitle => 'Backup exportieren';

  @override
  String get dataExportSubtitle => 'Daten als .luma-Datei speichern';

  @override
  String get dataImportTitle => 'Backup importieren';

  @override
  String get dataImportSubtitle =>
      'Daten aus einer .luma-Datei wiederherstellen';

  @override
  String get dataAutoBackupsTitle => 'Auto-Backups';

  @override
  String get dataAutoBackupsSubtitle => 'Schnappschüsse vor jedem Import';

  @override
  String get exportLeaveTitle => 'Export verlassen?';

  @override
  String get exportLeaveBody =>
      'Dein aktueller Fortschritt in diesem Assistenten geht verloren.';

  @override
  String get exportStay => 'Bleiben';

  @override
  String get exportLeave => 'Verlassen';

  @override
  String get exportPasswordsMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get exportAppBar => 'Backup exportieren';

  @override
  String get exportBackTooltip => 'Zurück';

  @override
  String get exportWhatToInclude => 'Was einbeziehen';

  @override
  String get exportChipEverything => 'Alles';

  @override
  String get exportChipPeriodsOnly => 'Nur Perioden';

  @override
  String get exportTogglePeriods => 'Perioden';

  @override
  String get exportToggleSymptoms => 'Symptome & Fluss';

  @override
  String get exportToggleSymptomsSubtitle => 'Fluss, Schmerz, Stimmung';

  @override
  String get exportToggleNotes => 'Notizen';

  @override
  String get exportNext => 'Weiter';

  @override
  String get exportPasswordIntro =>
      'Optional: Dieses Backup mit einem Passwort schützen.';

  @override
  String get exportPasswordLabel => 'Passwort';

  @override
  String get exportConfirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get exportClearPasswordTooltip => 'Passwort löschen';

  @override
  String get exportSkip => 'Überspringen';

  @override
  String get exportCreating => 'Backup wird erstellt …';

  @override
  String get exportReadyTitle => 'Export fertig';

  @override
  String get exportMetaExported => 'Exportiert';

  @override
  String get exportMetaContent => 'Inhalt';

  @override
  String get exportMetaEncrypted => 'Verschlüsselt';

  @override
  String get exportShare => 'Teilen';

  @override
  String get exportDone => 'Fertig';

  @override
  String get exportFailedTitle => 'Export fehlgeschlagen';

  @override
  String get exportFailedBody =>
      'Export konnte nicht abgeschlossen werden. Bitte versuch es noch einmal.';

  @override
  String get exportUnknownError => 'Unbekannter Fehler';

  @override
  String get exportTryAgain => 'Erneut versuchen';

  @override
  String get exportClose => 'Schließen';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get commonNotAvailable => '—';

  @override
  String get importInProgressSnack => 'Import läuft. Bitte warten.';

  @override
  String get importAppBar => 'Backup importieren';

  @override
  String get importSelectingFile => 'Datei wird ausgewählt …';

  @override
  String get importPasswordProtectedTitle =>
      'Dieses Backup ist passwortgeschützt';

  @override
  String importExportedLine(String when) {
    return 'Exportiert: $when';
  }

  @override
  String importIncludesLine(String types) {
    return 'Enthält: $types';
  }

  @override
  String get importDecrypt => 'Entschlüsseln';

  @override
  String get importCancel => 'Abbrechen';

  @override
  String get importBackupSummary => 'Backup-Übersicht';

  @override
  String importPreviewCounts(int periods, int entries) {
    return '$periods Periode(n) und $entries Tageseinträge gefunden.';
  }

  @override
  String importDupWarning(int count) {
    return '$count Einträge treffen auf Tage, die du auf diesem Gerät schon geloggt hast.';
  }

  @override
  String get importNoDupMessage =>
      'Keine Duplikate — alle Einträge sind für deine bestehenden Tage neu.';

  @override
  String get importStrategyTitle => 'Wie sollen Duplikate behandelt werden?';

  @override
  String importStrategyExplainer(int count) {
    return 'Duplikat heißt: derselbe Kalendertag hat schon einen Eintrag auf diesem Gerät. $count Einträge sind betroffen.';
  }

  @override
  String get importSegmentKeep => 'Bestehende behalten';

  @override
  String get importSegmentUseImported => 'Import nutzen';

  @override
  String get importTooltipKeep =>
      'Einträge auf deinem Gerät bleiben. Nur neue Tage werden importiert.';

  @override
  String get importTooltipReplace =>
      'Einträge aus dem Backup ersetzen deine aktuellen Daten für passende Tage.';

  @override
  String get importStrategyHintKeep =>
      'Einträge auf deinem Gerät bleiben. Nur neue Tage werden importiert.';

  @override
  String get importStrategyHintReplace =>
      'Einträge aus dem Backup ersetzen deine aktuellen Daten für passende Tage.';

  @override
  String get importImportCta => 'Importieren';

  @override
  String get importCreatingSafetyBackup => 'Sicherheits-Backup wird erstellt …';

  @override
  String get importImportingEntries => 'Einträge werden importiert …';

  @override
  String importResultSummary(
    int periods,
    int entries,
    int skipped,
    int replaced,
  ) {
    return '$periods Periode(n) importiert, $entries neue Einträge, $skipped übersprungen, $replaced ersetzt.';
  }

  @override
  String get importErrorGeneric => 'Etwas ist schiefgelaufen.';

  @override
  String get importErrorReadSelected =>
      'Die ausgewählte Datei konnte nicht gelesen werden.';

  @override
  String get importErrorWrongExtension => 'Bitte wähle eine .luma-Backup-Datei';

  @override
  String get importErrorReadBackup =>
      'Diese Backup-Datei konnte nicht gelesen werden.';

  @override
  String get importErrorWrongPassword =>
      'Falsches Passwort. Bitte versuch es noch einmal.';

  @override
  String get importErrorDecrypt => 'Backup konnte nicht entschlüsselt werden.';

  @override
  String get importErrorApply =>
      'Backup konnte nicht importiert werden. Bitte versuch es noch einmal.';

  @override
  String importErrorParser(String message) {
    return '$message';
  }

  @override
  String get importTryAgain => 'Erneut versuchen';

  @override
  String get importClose => 'Schließen';

  @override
  String get commonBackspace => 'Rücktaste';

  @override
  String get commonSubmit => 'Senden';

  @override
  String get dataContentTypesFallback => 'Perioden und Einträge';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get symptomFormTitleAdd => 'Symptome hinzufügen';

  @override
  String get symptomFormTitleEdit => 'Symptome bearbeiten';

  @override
  String get symptomSectionFlow => 'Fluss';

  @override
  String get symptomSectionPain => 'Schmerz';

  @override
  String get symptomSectionMood => 'Stimmung';

  @override
  String get symptomNotesLabel => 'Notizen';

  @override
  String get symptomNotSet => 'Nicht gesetzt';

  @override
  String get symptomClearSymptoms => 'Symptome löschen';

  @override
  String get dayDetailMarkFailed =>
      'Dieser Tag konnte nicht markiert werden. Bitte versuch es noch einmal.';

  @override
  String get dayDetailDeletePeriodTitle => 'Ganze Periode löschen?';

  @override
  String dayDetailDeletePeriodOngoingBody(String start) {
    return 'Die laufende Periode ab $start und alle zugehörigen Tageseinträge entfernen.';
  }

  @override
  String dayDetailDeletePeriodClosedBody(String start, String end) {
    return 'Die Periode $start–$end und alle zugehörigen Tageseinträge entfernen. Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get dayDetailPeriodOngoing => 'läuft noch';

  @override
  String get dayDetailDeletePeriodFailed =>
      'Periode konnte nicht gelöscht werden.';

  @override
  String get dayDetailRemoveDayTitle => 'Diesen Tag entfernen?';

  @override
  String dayDetailRemoveDayBody(String date) {
    return '$date als Periodentag abwählen. Getragene Symptome für diesen Tag werden gelöscht.';
  }

  @override
  String get dayDetailRemoveDayFailed =>
      'Dieser Tag konnte nicht entfernt werden. Bitte versuch es noch einmal.';

  @override
  String get dayDetailClearSymptomsFailed =>
      'Symptome konnten nicht gelöscht werden.';

  @override
  String get dayDetailLogWhenArrives =>
      'Du kannst eintragen, sobald der Tag da ist.';

  @override
  String get dayDetailHadPeriod => 'Ich hatte meine Periode';

  @override
  String get dayDetailFuturePlaceholder =>
      'Zukünftige Tage — schau wieder vorbei, wenn der Tag da ist.';

  @override
  String get dayDetailNoSymptoms =>
      'Für diesen Tag sind keine Symptome oder Notizen eingetragen.';

  @override
  String get dayDetailAddSymptoms => 'Symptome hinzufügen';

  @override
  String get dayDetailRemoveThisDay => 'Diesen Tag entfernen';

  @override
  String get dayDetailDeleteEntirePeriod => 'Ganze Periode löschen';

  @override
  String get dayDetailEdit => 'Bearbeiten';

  @override
  String get dayDetailClearSymptoms => 'Symptome löschen';

  @override
  String get firstLogAppBarTitle => 'Erste Periode eintragen';

  @override
  String get firstLogStartQuestion =>
      'Wann hat deine aktuelle oder letzte Periode begonnen?';

  @override
  String get firstLogChangeDate => 'Datum ändern';

  @override
  String get firstLogPeriodEndedTitle => 'Diese Periode ist schon zu Ende';

  @override
  String get firstLogPeriodEndedSubtitle =>
      'Optional — setz den letzten Periodentag, wenn sie nicht mehr läuft.';

  @override
  String get firstLogChangeEndDate => 'Enddatum ändern';

  @override
  String get firstLogSaveContinue => 'Speichern & weiter';

  @override
  String get firstLogSaveFailed =>
      'Periode konnte nicht gespeichert werden. Bitte versuch es noch einmal.';

  @override
  String get firstLogSuccessSnack => 'Periode gespeichert — du bist startklar!';

  @override
  String get moodSettingsLoadingTitle => 'Stimmungsanzeige';

  @override
  String get moodSettingsWordLabelsTitle => 'Wörter statt Emoji für Stimmung';

  @override
  String get moodSettingsWordLabelsSubtitle =>
      'Textbezeichnungen statt Emoji-Gesichter anzeigen';

  @override
  String get predSettingsTileTitle => 'Vorhersagen';

  @override
  String get predSettingsTileSubtitle => 'Anzeige, Zeithorizont und Methoden';

  @override
  String get predSettingsAppBarTitle => 'Vorhersagen';

  @override
  String get predSettingsSectionHowManyDays => 'Wie viele Tage anzeigen';

  @override
  String get predSettingsModeConsensusTitle =>
      'Nur übereinstimmende Vorhersagen';

  @override
  String get predSettingsModeConsensusSubtitle =>
      'Tage, an denen mehrere Methoden übereinstimmen';

  @override
  String get predSettingsModeAllTitle => 'Alle Vorhersagen';

  @override
  String get predSettingsModeAllSubtitle =>
      'Jeden vorhergesagten Tag, auch weniger sichere';

  @override
  String get predSettingsModeAllNotesTitle => 'Alle Vorhersagen + Hinweise';

  @override
  String get predSettingsModeAllNotesSubtitle =>
      'Wie oben, mit Hinweis an unsicheren Tagen';

  @override
  String get predSettingsSectionHorizon => 'Wie weit voraus planen';

  @override
  String get predSettingsHorizonCaption =>
      'Weiter entfernte Vorhersagen sind weniger zuverlässig, besonders bei unregelmäßigen Zyklen. Die Schraffurdichte zeigt, wie stark die Vorhersagemethoden übereinstimmen.';

  @override
  String get predSettingsHorizonNextOnly => 'Nur nächste Periode';

  @override
  String get predSettingsHorizon3Title => '3 Monate voraus';

  @override
  String get predSettingsHorizon3Subtitle => 'Gut für Reiseplanung';

  @override
  String get predSettingsHorizon6Title => '6 Monate voraus';

  @override
  String get predSettingsHorizon6Subtitle =>
      'Nur grobe Planung — Unsicherheit steigt deutlich';

  @override
  String get predSettingsSectionMethods => 'Vorhersagemethoden';

  @override
  String get predSettingsMethodsCaption =>
      'Mehr Methoden = stärkere Vorhersagen, wenn sie übereinstimmen. Schalt aus, was du nicht willst.';

  @override
  String get predSettingsLinearTrendTitle => 'Trendererkennung';

  @override
  String get predSettingsHintMedian =>
      'Nutzt den Mittelwert deiner letzten Zyklen';

  @override
  String get predSettingsHintEwma => 'Gewichtet neuere Zyklen stärker';

  @override
  String get predSettingsHintBayesian =>
      'Erlernt dein Muster über Zeit, ab 1 Zyklus';

  @override
  String get predSettingsHintLinearTrend =>
      'Erkennt, ob Zyklen länger oder kürzer werden (5+ Zyklen)';

  @override
  String get fertilitySettingsTitle => 'Fruchtbarkeitsfenster (Schätzung)';

  @override
  String get fertilitySettingsSubtitle =>
      'Geschätzte fruchtbare Tage im Kalender und auf der Startseite anzeigen';

  @override
  String get fertilityDisclaimerTitle => 'Bevor du startest';

  @override
  String get fertilityDisclaimerBody =>
      'Diese Funktion zeigt ein geschätztes Fruchtbarkeitsfenster anhand deiner Zyklushistorie. Sie ist nur eine Bildungshilfe — keine medizinische oder empfängnisverhütende Beratung. Wende dich bei persönlichen Fragen an medizinisches Fachpersonal.';

  @override
  String get fertilityDisclaimerAccept => 'Ich verstehe';

  @override
  String get fertilityInputTitle => 'Fruchtbarkeitsfenster einrichten';

  @override
  String get fertilityInputCycleLengthLabel => 'Durchschnittliche Zykluslänge';

  @override
  String fertilityInputCycleLengthAutoHint(int count) {
    return 'Berechnet aus deinen $count erfassten Zyklen';
  }

  @override
  String get fertilityInputCycleLengthManualHint =>
      'Passe an, wenn dein typischer Zyklus anders ist';

  @override
  String get fertilityInputLutealPhaseLabel => 'Lutealphase (Tage)';

  @override
  String get fertilityInputLutealPhaseExplanation =>
      'Bei den meisten sind es etwa 14 Tage. Passe an, wenn du deine Länge kennst.';

  @override
  String fertilityInputLutealPhaseDaysUnit(int days) {
    return '$days Tage';
  }

  @override
  String get fertilityInputSave => 'Speichern';

  @override
  String get fertilityInputNotEnoughData =>
      'Erfasse mindestens 2 vollständige Zyklen für die automatische Berechnung';

  @override
  String get fertilityCalendarLegendLabel => 'Fruchtbar (geschätzt)';

  @override
  String get fertilityCalendarDayLabel => 'Geschätzter fruchtbarer Tag';

  @override
  String get fertilityCalendarDayDetail =>
      'Geschätzter fruchtbarer Tag — basierend auf deiner Zyklushistorie';

  @override
  String get fertilityHomeCardTitle => 'Fruchtbarkeitsfenster';

  @override
  String fertilityHomeCardRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get fertilityHomeCardFooter => 'Nur Schätzung';

  @override
  String fertilityHomeCardExplanation(int days) {
    return 'Basierend auf deinem durchschnittlichen Zyklus von $days Tagen';
  }

  @override
  String get fertilitySuggestionTitle => 'Fruchtbarkeitsfenster (Schätzung)';

  @override
  String get fertilitySuggestionBody =>
      'Sieh ein geschätztes Fruchtbarkeitsfenster im Kalender — basierend auf deiner Zyklushistorie.';

  @override
  String get fertilitySuggestionEnable => 'Aktivieren';

  @override
  String get fertilitySuggestionNotEnoughData =>
      'Erfasse mehr Perioden, um diese Funktion freizuschalten';

  @override
  String get fertilityDisabled => 'Aus';

  @override
  String get flowValueLight => 'Leicht';

  @override
  String get flowValueMedium => 'Mittel';

  @override
  String get flowValueHeavy => 'Stark';

  @override
  String get painValueNone => 'Keine';

  @override
  String get painValueMild => 'Leicht';

  @override
  String get painValueModerate => 'Mittel';

  @override
  String get painValueSevere => 'Stark';

  @override
  String get painValueVerySevere => 'Sehr stark';

  @override
  String get moodValueVeryBad => 'Sehr schlecht';

  @override
  String get moodValueBad => 'Schlecht';

  @override
  String get moodValueNeutral => 'Neutral';

  @override
  String get moodValueGood => 'Gut';

  @override
  String get moodValueVeryGood => 'Sehr gut';

  @override
  String get pdfReportTitle => 'Luma — Periodenbericht';

  @override
  String get pdfDisclaimer =>
      'Dieser Bericht ist ein informativer Export aus selbst erfassten Daten. Er ist kein Diagnoseinstrument. Die Genauigkeit hängt von der Vollständigkeit und Konsistenz der Einträge ab. Wenden Sie sich für medizinische Entscheidungen an eine qualifizierte Fachperson.';

  @override
  String pdfGeneratedOn(String date) {
    return 'Erstellt am $date';
  }

  @override
  String pdfDateRange(String start, String end) {
    return 'Daten von $start bis $end';
  }

  @override
  String get pdfOverviewHeading => 'Überblick';

  @override
  String get pdfCycleHistoryHeading => 'Zyklusverlauf';

  @override
  String get pdfCycleChartHeading => 'Zykluslänge im Zeitverlauf';

  @override
  String get pdfDaySummaryHeading => 'Tägliche Übersicht';

  @override
  String get pdfNotesHeading => 'Notizen';

  @override
  String get pdfTotalCycles => 'Abgeschlossene Zyklen';

  @override
  String get pdfAvgCycleLength => 'Durchschnittliche Zykluslänge';

  @override
  String get pdfAvgPeriodDuration => 'Durchschnittliche Periodendauer';

  @override
  String get pdfShortestCycle => 'Kürzester Zyklus';

  @override
  String get pdfLongestCycle => 'Längster Zyklus';

  @override
  String pdfNDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get pdfFlowDistribution => 'Flussintensität';

  @override
  String get pdfPainDistribution => 'Schmerzlevel';

  @override
  String get pdfMoodDistribution => 'Stimmung';

  @override
  String get pdfDateColumn => 'Datum';

  @override
  String get pdfFlowColumn => 'Fluss';

  @override
  String get pdfPainColumn => 'Schmerz';

  @override
  String get pdfMoodColumn => 'Stimmung';

  @override
  String get pdfCycleStartColumn => 'Zyklusbeginn';

  @override
  String get pdfCycleLengthColumn => 'Länge (Tage)';

  @override
  String get pdfNoDataForRange =>
      'Für den gewählten Zeitraum liegen keine Daten vor.';

  @override
  String get pdfNoDayData => 'Keine Tagesdaten für den gewählten Zeitraum.';

  @override
  String get pdfNoNotes => 'Keine Notizen für den gewählten Zeitraum.';

  @override
  String get pdfMetadataOnlyNote =>
      'Dieser Bericht enthält nur Metadaten. Aktiviere Datenbereiche für Zyklusdetails.';

  @override
  String get pdfFooterGenerated => 'Erstellt mit Luma';

  @override
  String get pdfFlowLight => 'Leicht';

  @override
  String get pdfFlowMedium => 'Mittel';

  @override
  String get pdfFlowHeavy => 'Stark';

  @override
  String get pdfPainNone => 'Keine';

  @override
  String get pdfPainMild => 'Leicht';

  @override
  String get pdfPainModerate => 'Mittel';

  @override
  String get pdfPainSevere => 'Stark';

  @override
  String get pdfPainVerySevere => 'Sehr stark';

  @override
  String get pdfMoodVeryBad => 'Sehr schlecht';

  @override
  String get pdfMoodBad => 'Schlecht';

  @override
  String get pdfMoodNeutral => 'Neutral';

  @override
  String get pdfMoodGood => 'Gut';

  @override
  String get pdfMoodVeryGood => 'Sehr gut';

  @override
  String get pdfExportTitle => 'PDF-Bericht';

  @override
  String get pdfExportSubtitle =>
      'Bericht für Ihre Ärztin oder Ihren Arzt erstellen';

  @override
  String get pdfExportScreenTitle => 'PDF-Bericht exportieren';

  @override
  String get pdfPresetSummary => 'Zusammenfassung';

  @override
  String get pdfPresetStandard => 'Standard';

  @override
  String get pdfPresetFull => 'Vollständig';

  @override
  String get pdfSectionsHeading => 'Abschnitte';

  @override
  String get pdfSectionOverview => 'Überblick';

  @override
  String get pdfSectionCycleHistory => 'Zyklusverlauf';

  @override
  String get pdfSectionChart => 'Zykluslängen-Diagramm';

  @override
  String get pdfSectionDaySummary => 'Tägliche Übersicht';

  @override
  String get pdfSectionNotes => 'Notizen';

  @override
  String get pdfDateFrom => 'Von';

  @override
  String get pdfDateTo => 'Bis';

  @override
  String get pdfGeneratePreview => 'Vorschau erstellen';

  @override
  String get pdfGenerating => 'Bericht wird erstellt…';

  @override
  String get pdfPreviewTitle => 'Vorschau';

  @override
  String get pdfShareAction => 'Teilen';

  @override
  String get pdfExportError =>
      'Bericht konnte nicht erstellt werden. Bitte versuchen Sie es erneut.';

  @override
  String get pdfSaved => 'Bericht gespeichert';

  @override
  String get pdfLinuxPreviewBody =>
      'Vorschau ist auf dieser Plattform nicht verfügbar. Speichern Sie die PDF-Datei, um sie woanders zu öffnen.';

  @override
  String get pdfSavePdf => 'PDF speichern';
}
