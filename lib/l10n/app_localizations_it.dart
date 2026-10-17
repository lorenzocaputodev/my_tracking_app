// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get loading => 'Caricamento...';

  @override
  String get bootstrapErrorTitle => 'Avvio non completato';

  @override
  String get bootstrapErrorBody =>
      'Si è verificato un problema durante il caricamento iniziale. Puoi riprovare senza chiudere l\'app.';

  @override
  String get retry => 'Riprova';

  @override
  String get backupErrorEmpty => 'Backup CSV vuoto.';

  @override
  String get backupErrorUnknownFormat => 'Formato backup CSV non riconosciuto.';

  @override
  String get backupErrorMissingVersion => 'Versione backup mancante.';

  @override
  String backupErrorInvalidSection(int line) {
    return 'Sezione backup non valida alla riga $line.';
  }

  @override
  String backupErrorMissingHeader(String section) {
    return 'Header mancante per la sezione \"$section\".';
  }

  @override
  String backupErrorMissingProduct(String id) {
    return 'La cronologia fa riferimento a un prodotto mancante: $id.';
  }

  @override
  String get backupErrorMissingMeta => 'Sezione meta mancante nel backup.';

  @override
  String get backupErrorInvalidMetaHeader => 'Header meta non valido.';

  @override
  String get backupErrorMissingProducts =>
      'Sezione prodotti mancante nel backup.';

  @override
  String get backupErrorNoActiveProduct =>
      'Il backup non contiene prodotti attivi.';

  @override
  String get backupErrorIncompleteProduct => 'Riga prodotti incompleta.';

  @override
  String get backupErrorMissingHistory =>
      'Sezione cronologia mancante nel backup.';

  @override
  String get backupErrorIncompleteEntry => 'Riga cronologia incompleta.';

  @override
  String get backupErrorIncompleteAchievement => 'Riga achievement incompleta.';

  @override
  String get backupErrorIncompletePlan => 'Riga piano di riduzione incompleta.';

  @override
  String backupErrorInvalidValue(String value) {
    return 'Valore non valido nel backup: \"$value\".';
  }

  @override
  String backupErrorInvalidHeader(String section) {
    return 'Header $section non valido.';
  }

  @override
  String get backupSectionProducts => 'prodotti';

  @override
  String get backupSectionHistory => 'cronologia';

  @override
  String get backupSectionAchievements => 'achievement';

  @override
  String get backupSectionPlan => 'piano di riduzione';

  @override
  String get backupSectionReminder => 'promemoria globale';

  @override
  String backupErrorEntriesNotSaved(int stored, int total) {
    return 'Salvate $stored registrazioni su $total. I dati non sono stati ripristinati: riprova.';
  }

  @override
  String backupErrorProductsNotSaved(int stored, int total) {
    return 'Salvati $stored prodotti su $total. I dati non sono stati ripristinati: riprova.';
  }

  @override
  String get errorProductNotFound => 'Prodotto non trovato.';

  @override
  String get errorStockCorrectionUnavailable =>
      'La correzione della scorta non è disponibile.';

  @override
  String get achFirstEntryTitle => 'Prima tracciata';

  @override
  String get achFirstEntryDesc => 'Hai registrato la prima unità.';

  @override
  String get achTracked7Title => '7 giorni di dati';

  @override
  String get achTracked7Desc => 'Attività registrata per 7 giorni distinti.';

  @override
  String get achTracked30Title => '30 giorni di dati';

  @override
  String get achTracked30Desc => 'Attività registrata per 30 giorni distinti.';

  @override
  String get achStreak3Title => '3 giorni di fila';

  @override
  String get achStreak3Desc => 'Attivo 3 giorni consecutivi.';

  @override
  String get achStreak7Title => 'Settimana intera';

  @override
  String get achStreak7Desc => 'Attivo 7 giorni consecutivi.';

  @override
  String get achStreak14Title => 'Due settimane';

  @override
  String get achStreak14Desc => 'Attivo 14 giorni consecutivi.';

  @override
  String get achStreak30Title => 'Un mese intero';

  @override
  String get achStreak30Desc => 'Attivo 30 giorni consecutivi.';

  @override
  String get achUnderLimit1Title => 'Primo giorno ok';

  @override
  String get achUnderLimit1Desc => '1 giorno sotto il limite giornaliero.';

  @override
  String get achUnderLimit3Title => 'Tre giorni ok';

  @override
  String get achUnderLimit3Desc => '3 giorni consecutivi sotto il limite.';

  @override
  String get achUnderLimit7Title => 'Settimana ok';

  @override
  String get achUnderLimit7Desc => '7 giorni consecutivi sotto il limite.';

  @override
  String get achUnderLimit30Title => 'Mese sotto controllo';

  @override
  String get achUnderLimit30Desc => '30 giorni consecutivi sotto il limite.';

  @override
  String get achReduction10Title => '-10% media';

  @override
  String get achReduction10Desc =>
      'Media ridotta del 10% rispetto all\'inizio del piano.';

  @override
  String get achReduction25Title => '-25% media';

  @override
  String get achReduction25Desc =>
      'Media ridotta del 25% rispetto all\'inizio del piano.';

  @override
  String get achReduction50Title => '-50% media';

  @override
  String get achReduction50Desc => 'Hai dimezzato la tua media. Eccezionale!';

  @override
  String get reminderChannelName => 'Promemoria registrazione';

  @override
  String get reminderChannelDescription =>
      'Promemoria generali per ricordare di registrare i prodotti tracciati.';

  @override
  String get reminderNotificationTitle => 'Promemoria';

  @override
  String get reminderNotificationBody =>
      'Ricordati di registrare i prodotti tracciati.';

  @override
  String productAddedInUse(String name) {
    return '$name aggiunto e in uso';
  }

  @override
  String get backupFilesUnsupported =>
      'Import/export file disponibile solo su Android e Windows.';

  @override
  String get fileSaveUnsupported =>
      'Salvataggio file non supportato su questa piattaforma.';

  @override
  String get backupSaved => 'Backup CSV salvato';

  @override
  String get backupExportFailed => 'Esportazione CSV non riuscita.';

  @override
  String get browserOpenFailed => 'Non riesco ad aprire il browser.';

  @override
  String get clearHistoryTitle => 'Cancella tutto?';

  @override
  String get clearHistoryBody =>
      'Questa azione elimina permanentemente tutta la cronologia registrata finora.';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String stockCount(int remaining, int total) {
    return '$remaining/$total in scorta';
  }

  @override
  String get noStock => 'Senza scorta';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsSectionProducts => 'PRODOTTI';

  @override
  String get addProduct => 'Aggiungi prodotto';

  @override
  String archivedCount(int count) {
    return 'Archiviati ($count)  ›';
  }

  @override
  String get settingsSectionAppearance => 'ASPETTO';

  @override
  String get settingsSectionLanguageCurrency => 'LINGUA E VALUTA';

  @override
  String get settingsSectionReminders => 'PROMEMORIA';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get system => 'Sistema';

  @override
  String get language => 'Lingua';

  @override
  String get widgetTheme => 'Tema del widget';

  @override
  String get currency => 'Valuta';

  @override
  String get settingsSectionData => 'DATI';

  @override
  String get exportBackup => 'Esporta backup';

  @override
  String lastBackupOn(String date) {
    return 'Ultimo backup: $date';
  }

  @override
  String get noBackupYet =>
      'Nessun backup ancora: salva un file CSV con tutti i dati';

  @override
  String get importBackup => 'Importa backup';

  @override
  String get importBackupSubtitle => 'Sostituisce i dati attuali';

  @override
  String get settingsSectionAbout => 'INFORMAZIONI';

  @override
  String get checkForUpdates => 'Controlla aggiornamenti';

  @override
  String installedVersion(String version) {
    return 'Versione installata $version · apre GitHub';
  }

  @override
  String get opensReleasesPage => 'Apre la pagina delle versioni su GitHub';

  @override
  String get clearHistory => 'Cancella cronologia';

  @override
  String get widgetHint =>
      'Tieni premuto sulla schermata Home del telefono per aggiungere il widget.';

  @override
  String get inUseBadge => 'IN USO';

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '1 ora',
    );
    return '$_temp0';
  }

  @override
  String get notificationPermissionDenied => 'Permesso notifiche non concesso.';

  @override
  String get remindMeEvery => 'Ricordamelo ogni';

  @override
  String get reminders => 'Promemoria';

  @override
  String get remindersSubtitle => 'Ti ricorda di registrare';

  @override
  String get androidOnly => 'Disponibile solo su Android';

  @override
  String get frequency => 'Frequenza';

  @override
  String every(String interval) {
    return 'Ogni $interval';
  }

  @override
  String get fileImportUnsupported =>
      'Importazione file non supportata su questa piattaforma.';

  @override
  String restoreCompleted(String summary) {
    return 'Ripristino completato: $summary.';
  }

  @override
  String restoreCompletedRemindersOff(String summary) {
    return 'Ripristino completato: $summary. Promemoria disattivati: permesso notifiche non concesso.';
  }

  @override
  String get backupInvalid => 'Backup CSV non valido';

  @override
  String get backupImportFailed => 'Importazione CSV non riuscita.';

  @override
  String get emptyBackupTitle => 'Backup senza cronologia';

  @override
  String get emptyBackupBody =>
      'Questo file non contiene nessuna registrazione. Importarlo sostituisce i dati attuali e la cronologia resta vuota.';

  @override
  String get importAnyway => 'Importa comunque';

  @override
  String restoreSummary(String entries, String products) {
    return '$entries e $products';
  }

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrazioni',
      one: '1 registrazione',
    );
    return '$_temp0';
  }

  @override
  String productsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prodotti',
      one: '1 prodotto',
    );
    return '$_temp0';
  }

  @override
  String productRestored(String name) {
    return '$name ripristinato';
  }

  @override
  String get deletePermanentlyTitle => 'Eliminare definitivamente?';

  @override
  String deletePermanentlyBody(String name) {
    return 'Questa azione rimuove $name e tutta la cronologia collegata.';
  }

  @override
  String productDeleted(String name) {
    return '$name eliminato definitivamente';
  }

  @override
  String get archivedTitle => 'Archiviati';

  @override
  String get archivedIntro =>
      'I prodotti archiviati non compaiono in home, ma la loro cronologia resta. Ripristinandoli tornano come prima.';

  @override
  String get noArchivedProducts => 'Nessun prodotto archiviato';

  @override
  String get historyKept => 'Storico conservato';

  @override
  String get restore => 'Ripristina';

  @override
  String get deletePermanently => 'Elimina definitivamente';

  @override
  String get newProduct => 'Nuovo prodotto';

  @override
  String get setupTitle => 'Configura il tuo prodotto';

  @override
  String get startTracking => 'Inizia a tracciare';

  @override
  String get haveBackup => 'Ho già un backup';

  @override
  String get haveBackupSubtitle => 'Ripristina i tuoi dati da un file CSV';

  @override
  String get setupQuestion => 'Cosa vuoi tracciare?';

  @override
  String get setupSubtitle =>
      'Puoi modificare tutto nelle impostazioni in qualsiasi momento.';

  @override
  String get remindersSection => 'PROMEMORIA';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto su\nMy Tracking App';

  @override
  String get onboardingWelcomeBody =>
      'Tieni d\'occhio quanto usi, quanto spendi e come cambiano le tue abitudini. Tutti i dati restano sul tuo telefono.';

  @override
  String get onboardingTrackTitle => 'Tieni traccia\ndi tutto';

  @override
  String get onboardingTrackBody =>
      'Puoi seguire più prodotti insieme. Ognuno ha la sua cronologia, i suoi costi e il suo obiettivo.';

  @override
  String get onboardingCustomizeTitle => 'Personalizza\nil tuo prodotto';

  @override
  String get onboardingCustomizeBody =>
      'Indica nome, costo e confezione, e se vuoi un limite giornaliero: il costo di ogni utilizzo lo calcola l\'app.';

  @override
  String get onboardingTimeTitle => 'Quanto tempo\nti costa?';

  @override
  String get onboardingTimeBody =>
      'Puoi aggiungere una stima dei minuti di vita persi per ogni utilizzo: è un valore simbolico, non il tempo per consumarlo. Se non ti serve, scegli «Nessuna stima».';

  @override
  String get onboardingTapTitle => 'Un tocco\nper registrare';

  @override
  String get onboardingTapBody =>
      'Premi HO USATO ogni volta, oppure registra tutto a fine giornata. Se tocchi per sbaglio puoi annullare subito, e su Android c\'è anche il widget.';

  @override
  String get onboardingProgressTitle => 'Osserva\ni tuoi progressi';

  @override
  String get onboardingProgressBody =>
      'Cronologia per giorni, settimane e mesi, obiettivi e un piano di riduzione. Con il backup non perdi nulla.';

  @override
  String get skip => 'Salta';

  @override
  String get start => 'Inizia';

  @override
  String get next => 'Avanti';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get achievementsTooltip => 'Obiettivi e badge';

  @override
  String get today => 'Oggi';

  @override
  String get lifeLostToday => 'Vita persa oggi';

  @override
  String get totalSpent => 'Totale speso';

  @override
  String lastEntry(String time) {
    return 'ULTIMA: $time';
  }

  @override
  String get logButton => 'HO USATO';

  @override
  String loggedToday(int count) {
    return 'Registrato · $count oggi';
  }

  @override
  String get undo => 'Annulla';

  @override
  String get creatorMessage =>
      'Applicazione creata da Lorenzo Caputo, with love <3';

  @override
  String stockFinished(String name) {
    return '📦 $name terminato!';
  }

  @override
  String overLimit(int count, int limit) {
    return 'Sopra il limite impostato ($count/$limit)';
  }

  @override
  String dailyLimitReached(int count, int limit) {
    return 'Limite giornaliero raggiunto ($count/$limit)';
  }

  @override
  String get newStockButton => 'NUOVA\nSCORTA';

  @override
  String get productInUse => 'Prodotto in uso';

  @override
  String get todayCaps => 'OGGI';

  @override
  String get unitCost => 'Costo unitario';

  @override
  String get costPerUse => 'Costo per utilizzo';

  @override
  String labelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get never => 'Mai';

  @override
  String get justNow => 'Adesso';

  @override
  String daysAgo(int count) {
    return '${count}g fa';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h fa';
  }

  @override
  String hoursMinutesAgo(int hours, int minutes) {
    return '${hours}h ${minutes}m fa';
  }

  @override
  String minutesAgo(int count) {
    return '${count}m fa';
  }

  @override
  String get insightPlanAhead => 'Piano: avanti';

  @override
  String get insightPlanOnTrack => 'Piano: in linea';

  @override
  String get insightPlanBehind => 'Piano: in ritardo';

  @override
  String insightLimitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mancano $count unità al limite',
      one: 'Manca 1 unità al limite',
    );
    return '$_temp0';
  }

  @override
  String insightComparedToYesterday(String delta) {
    return '$delta rispetto a ieri';
  }

  @override
  String get changesSaved => 'Modifiche salvate';

  @override
  String get discardChangesTitle => 'Scartare le modifiche?';

  @override
  String get discardChangesBody => 'Le modifiche non salvate andranno perse.';

  @override
  String get discard => 'Scarta';

  @override
  String productInUseFeedback(String name) {
    return '$name in uso';
  }

  @override
  String get keepOneActiveProduct => 'Devi mantenere almeno un prodotto attivo';

  @override
  String productArchived(String name) {
    return '$name archiviato';
  }

  @override
  String get moreActions => 'Altre azioni';

  @override
  String get useThisProduct => 'Usa questo prodotto';

  @override
  String get useThisProductSubtitle => 'Diventa quello registrato in home';

  @override
  String get archive => 'Archivia';

  @override
  String get archiveSubtitle => 'Sparisce dalla home, la cronologia resta';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get save => 'Salva';

  @override
  String get newPackTitle => 'Nuova confezione?';

  @override
  String newPackBody(String name, int pieces) {
    return 'La scorta di $name torna a $pieces/$pieces.';
  }

  @override
  String get restock => 'Reintegra';

  @override
  String get stockRestocked => 'Scorta reintegrata';

  @override
  String get correctStockTitle => 'Correggi scorta';

  @override
  String get correctStockBody =>
      'Inserisci il numero reale di unità rimaste per allineare la scorta attuale.';

  @override
  String get unitsLeft => 'Unità rimaste';

  @override
  String get enterWholeNumber => 'Inserisci un numero intero.';

  @override
  String get enterValidWholeNumber => 'Inserisci un numero intero valido.';

  @override
  String get valueNotNegative => 'Il valore non può essere negativo.';

  @override
  String valueAtMost(int max) {
    return 'Il valore non può superare $max.';
  }

  @override
  String get confirm => 'Conferma';

  @override
  String get correctStockFailed => 'Correzione scorta non riuscita.';

  @override
  String get stock => 'Scorta';

  @override
  String get correct => 'Correggi';

  @override
  String get productNameLabel => 'NOME PRODOTTO';

  @override
  String get productNameHint => 'Es. Sigarette';

  @override
  String get enterName => 'Inserisci un nome';

  @override
  String get productModeLabel => 'MODALITÀ PRODOTTO';

  @override
  String get packCostLabel => 'COSTO CONFEZIONE';

  @override
  String get packCostHint => 'Es. 6,00';

  @override
  String get enterAmount => 'Inserisci un importo';

  @override
  String get invalidAmount => 'Importo non valido';

  @override
  String get unitsPerPackLabel => 'UNITÀ / USI STIMATI PER CONFEZIONE';

  @override
  String get unitsPerPackHint => 'Es. 20';

  @override
  String get enterNumber => 'Inserisci un numero';

  @override
  String get invalidNumber => 'Numero non valido';

  @override
  String get unitsPerPackHelp =>
      'Puoi inserire anche il numero medio di usi ottenibili da una confezione.';

  @override
  String get costPerUseLabel => 'COSTO PER UTILIZZO';

  @override
  String get costPerUseHint => 'Facoltativo, es. 0,10';

  @override
  String get costPerUseHelp =>
      'Lascia vuoto se vuoi registrare solo gli utilizzi, senza calcolare costi.';

  @override
  String get minutesLostLabel => 'MINUTI DI VITA PERSI PER UTILIZZO';

  @override
  String get enterValue => 'Inserisci un valore';

  @override
  String get dailyGoalLabel => 'OBIETTIVO GIORNALIERO';

  @override
  String get noDailyLimit => 'Nessun limite giornaliero';

  @override
  String dailyGoalText(int count) {
    return 'Voglio stare sotto $count al giorno';
  }

  @override
  String get noLimit => 'Nessun limite';

  @override
  String get zeroNoLimit => '0 = nessun limite impostato';

  @override
  String get withStock => 'Con scorta';

  @override
  String get withStockHelp =>
      'Il prodotto usa una scorta residua e può essere reintegrato quando termina.';

  @override
  String get noStockHelp =>
      'Il prodotto registra solo gli utilizzi, senza gestire confezioni o residuo.';

  @override
  String get minutesLostSheetTitle => 'Minuti di vita persi';

  @override
  String get noEstimate => 'Nessuna stima';

  @override
  String get noEstimateSubtitle => 'Non conta la vita persa';

  @override
  String minutesEstimate(int count) {
    return '$count min (stima)';
  }

  @override
  String minutesPresetLabel(String name, String estimate) {
    return '$name — $estimate';
  }

  @override
  String get presetCigarette => 'Sigaretta';

  @override
  String get presetEcigarette => 'Sigaretta elettronica';

  @override
  String get presetHeatedTobacco => 'Riscaldatore di tabacco';

  @override
  String get presetCigar => 'Sigaro';

  @override
  String get presetHookah => 'Narghilè (sessione)';

  @override
  String get custom => 'Personalizzato…';

  @override
  String get minutesPerUse => 'Minuti per utilizzo';

  @override
  String get last7Days => 'ULTIMI 7 GIORNI';

  @override
  String averagePerDay(String value) {
    return 'media $value/giorno';
  }

  @override
  String get weekdaysShort => 'LUN,MAR,MER,GIO,VEN,SAB,DOM';

  @override
  String get openCsv => 'Apri CSV';

  @override
  String get saveCsv => 'Salva CSV';

  @override
  String get unreadableBackupFile =>
      'File non leggibile: usa il backup CSV esportato dall\'app, senza modificarlo.';

  @override
  String get last7DaysTitle => 'Ultimi 7 giorni';

  @override
  String get last30DaysTitle => 'Ultimi 30 giorni';

  @override
  String get entireHistory => 'Tutta la cronologia';

  @override
  String get customPeriod => 'Periodo personalizzato';

  @override
  String get selectRange => 'Seleziona intervallo';

  @override
  String get noDataLogged => 'Nessun dato registrato';

  @override
  String get noDataLoggedBody =>
      'La cronologia apparirà qui dopo i primi utilizzi.';

  @override
  String get noFilterResults => 'Nessun risultato nel filtro selezionato';

  @override
  String get noFilterResultsBody =>
      'Prova un altro prodotto o un intervallo di date più ampio.';

  @override
  String get filters => 'FILTRI';

  @override
  String get product => 'Prodotto';

  @override
  String get allProducts => 'Tutti i prodotti';

  @override
  String get statistics => 'STATISTICHE';

  @override
  String get periodOverview => 'Panoramica periodo';

  @override
  String get periodOverviewSubtitle =>
      'Medie e riepilogo del filtro selezionato';

  @override
  String get periodTotal => 'Totale periodo';

  @override
  String get mixedProductsNote =>
      'Prodotti diversi non si sommano: scegli un prodotto per vedere medie e andamento.';

  @override
  String get periodAveragePerDay => 'Media periodo/g';

  @override
  String get trend7Days => 'Trend 7g';

  @override
  String get average30Days => 'Media 30 giorni';

  @override
  String unitsCount(int count) {
    return '$count unità';
  }

  @override
  String get costsAndProjections => 'Costi e proiezioni';

  @override
  String get costsAndProjectionsSubtitle => 'Spesa attuale e stime future';

  @override
  String get periodCost => 'Costo periodo';

  @override
  String get monthlyProjection => 'Proiezione mese';

  @override
  String get annualEstimate => 'Stima annua';

  @override
  String get monthlyEstimate => 'Stima mese';

  @override
  String get estimatedAnnualCost => 'Costo annuo stimato';

  @override
  String get habitsAndTimes => 'Abitudini e orari';

  @override
  String get habitsAndTimesSubtitle =>
      'Ritmo, giorni e fascia oraria più attiva';

  @override
  String get peakHour => 'Ora picco';

  @override
  String underLimitStreak(int count, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni consecutivi sotto il limite ($limit)',
      one: '1 giorno consecutivo sotto il limite ($limit)',
    );
    return '$_temp0';
  }

  @override
  String activeStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attivo da $count giorni consecutivi',
      one: 'Attivo da 1 giorno consecutivo',
    );
    return '$_temp0';
  }

  @override
  String get bestDay => 'Giorno migliore';

  @override
  String get worstDay => 'Giorno peggiore';

  @override
  String get hourlyDistribution => 'DISTRIBUZIONE ORARIA';

  @override
  String thinDataNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Stime basate su $count giorni di dati: diventeranno attendibili con qualche giorno in più.',
      one:
          'Stime basate su un giorno di dati: diventeranno attendibili con qualche giorno in più.',
    );
    return '$_temp0';
  }

  @override
  String get trend30Days => 'TREND ULTIMI 30 GIORNI';

  @override
  String get sevenDays => '7 giorni';

  @override
  String get thirtyDays => '30 giorni';

  @override
  String get all => 'Tutto';

  @override
  String get customShort => 'Personalizzato';

  @override
  String weekOf(String label) {
    return 'Settimana $label';
  }

  @override
  String get entriesSection => 'REGISTRAZIONI';

  @override
  String get days => 'Giorni';

  @override
  String get weeks => 'Settimane';

  @override
  String get months => 'Mesi';

  @override
  String get entryRemoved => 'Registrazione rimossa';

  @override
  String get achievementsTitle => 'Obiettivi & Badge';

  @override
  String get unlockedSection => 'SBLOCCATI';

  @override
  String get noBadgesYet => 'Registra le prime attività per sbloccare i badge!';

  @override
  String get lockedSection => 'DA SBLOCCARE';

  @override
  String get allBadgesUnlocked => 'Hai sbloccato tutti i badge! 🎉';

  @override
  String badgeProgress(int unlocked, int total) {
    return '$unlocked / $total badge';
  }

  @override
  String get setReductionPlan => 'Imposta piano di riduzione';

  @override
  String get planStatusAhead => 'AVANTI';

  @override
  String get planStatusOnTrack => 'IN LINEA';

  @override
  String get planStatusBehind => 'IN RITARDO';

  @override
  String get planStatusActive => 'ATTIVO';

  @override
  String get reductionPlanSection => 'PIANO DI RIDUZIONE';

  @override
  String productLabel(String name) {
    return 'Prodotto: $name';
  }

  @override
  String get planStart => 'Inizio';

  @override
  String get unitsPerDayShort => 'unità/g';

  @override
  String get average7Days => 'Media 7 giorni';

  @override
  String get targetToday => 'Target oggi';

  @override
  String get finalGoal => 'Obiettivo finale';

  @override
  String planWeek(int current, int total) {
    return 'Settimana $current / $total';
  }

  @override
  String get planCompleted => 'Completato!';

  @override
  String daysRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni rimanenti',
      one: '1 giorno rimanente',
    );
    return '$_temp0';
  }

  @override
  String get planAheadMessage => 'Sei sotto il target settimanale previsto.';

  @override
  String get planOnTrackMessage => 'Sei in linea con il piano attivo.';

  @override
  String get planBehindMessage => 'Sei sopra il target settimanale previsto.';

  @override
  String get planActiveMessage => 'Piano attivo su questo prodotto.';

  @override
  String get edit => 'Modifica';

  @override
  String get deletePlanTitle => 'Elimina piano';

  @override
  String get deletePlanBody => 'Vuoi eliminare il piano di riduzione?';

  @override
  String badgeLockedSemantics(String title) {
    return '$title, da sbloccare';
  }

  @override
  String badgeUnlockedSemantics(String title, String date) {
    return '$title, sbloccato il $date';
  }

  @override
  String unlockedOn(String date) {
    return 'Sbloccato il $date';
  }

  @override
  String get notUnlockedYet => 'Non ancora sbloccato';

  @override
  String get close => 'Chiudi';

  @override
  String average14Days(String value) {
    return 'Media degli ultimi 14 giorni: $value unità/giorno';
  }

  @override
  String finalGoalValue(String value) {
    return 'Obiettivo finale: $value unità/giorno';
  }

  @override
  String planDuration(int count) {
    return 'Durata: $count settimane';
  }

  @override
  String planReductionSummary(String value, int weeks) {
    return 'Riduzione di $value unità/g in $weeks settimane.';
  }

  @override
  String get updatePlan => 'Aggiorna piano';

  @override
  String get setPlan => 'Imposta piano';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';
}
