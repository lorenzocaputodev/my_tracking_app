import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

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
    Locale('en'),
    Locale('it')
  ];

  /// No description provided for @loading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento...'**
  String get loading;

  /// No description provided for @bootstrapErrorTitle.
  ///
  /// In it, this message translates to:
  /// **'Avvio non completato'**
  String get bootstrapErrorTitle;

  /// No description provided for @bootstrapErrorBody.
  ///
  /// In it, this message translates to:
  /// **'Si è verificato un problema durante il caricamento iniziale. Puoi riprovare senza chiudere l\'app.'**
  String get bootstrapErrorBody;

  /// No description provided for @retry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get retry;

  /// No description provided for @backupErrorEmpty.
  ///
  /// In it, this message translates to:
  /// **'Backup CSV vuoto.'**
  String get backupErrorEmpty;

  /// No description provided for @backupErrorUnknownFormat.
  ///
  /// In it, this message translates to:
  /// **'Formato backup CSV non riconosciuto.'**
  String get backupErrorUnknownFormat;

  /// No description provided for @backupErrorMissingVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione backup mancante.'**
  String get backupErrorMissingVersion;

  /// No description provided for @backupErrorInvalidSection.
  ///
  /// In it, this message translates to:
  /// **'Sezione backup non valida alla riga {line}.'**
  String backupErrorInvalidSection(int line);

  /// No description provided for @backupErrorMissingHeader.
  ///
  /// In it, this message translates to:
  /// **'Header mancante per la sezione \"{section}\".'**
  String backupErrorMissingHeader(String section);

  /// No description provided for @backupErrorMissingProduct.
  ///
  /// In it, this message translates to:
  /// **'La cronologia fa riferimento a un prodotto mancante: {id}.'**
  String backupErrorMissingProduct(String id);

  /// No description provided for @backupErrorMissingMeta.
  ///
  /// In it, this message translates to:
  /// **'Sezione meta mancante nel backup.'**
  String get backupErrorMissingMeta;

  /// No description provided for @backupErrorInvalidMetaHeader.
  ///
  /// In it, this message translates to:
  /// **'Header meta non valido.'**
  String get backupErrorInvalidMetaHeader;

  /// No description provided for @backupErrorMissingProducts.
  ///
  /// In it, this message translates to:
  /// **'Sezione prodotti mancante nel backup.'**
  String get backupErrorMissingProducts;

  /// No description provided for @backupErrorIncompleteProduct.
  ///
  /// In it, this message translates to:
  /// **'Riga prodotti incompleta.'**
  String get backupErrorIncompleteProduct;

  /// No description provided for @backupErrorMissingHistory.
  ///
  /// In it, this message translates to:
  /// **'Sezione cronologia mancante nel backup.'**
  String get backupErrorMissingHistory;

  /// No description provided for @backupErrorIncompleteEntry.
  ///
  /// In it, this message translates to:
  /// **'Riga cronologia incompleta.'**
  String get backupErrorIncompleteEntry;

  /// No description provided for @backupErrorIncompleteAchievement.
  ///
  /// In it, this message translates to:
  /// **'Riga achievement incompleta.'**
  String get backupErrorIncompleteAchievement;

  /// No description provided for @backupErrorIncompletePlan.
  ///
  /// In it, this message translates to:
  /// **'Riga piano di riduzione incompleta.'**
  String get backupErrorIncompletePlan;

  /// No description provided for @backupErrorInvalidValue.
  ///
  /// In it, this message translates to:
  /// **'Valore non valido nel backup: \"{value}\".'**
  String backupErrorInvalidValue(String value);

  /// No description provided for @backupErrorInvalidHeader.
  ///
  /// In it, this message translates to:
  /// **'Header {section} non valido.'**
  String backupErrorInvalidHeader(String section);

  /// No description provided for @backupSectionProducts.
  ///
  /// In it, this message translates to:
  /// **'prodotti'**
  String get backupSectionProducts;

  /// No description provided for @backupSectionHistory.
  ///
  /// In it, this message translates to:
  /// **'cronologia'**
  String get backupSectionHistory;

  /// No description provided for @backupSectionAchievements.
  ///
  /// In it, this message translates to:
  /// **'achievement'**
  String get backupSectionAchievements;

  /// No description provided for @backupSectionPlan.
  ///
  /// In it, this message translates to:
  /// **'piano di riduzione'**
  String get backupSectionPlan;

  /// No description provided for @backupSectionReminder.
  ///
  /// In it, this message translates to:
  /// **'promemoria globale'**
  String get backupSectionReminder;

  /// No description provided for @backupErrorEntriesNotSaved.
  ///
  /// In it, this message translates to:
  /// **'Salvate {stored} registrazioni su {total}. I dati non sono stati ripristinati: riprova.'**
  String backupErrorEntriesNotSaved(int stored, int total);

  /// No description provided for @backupErrorProductsNotSaved.
  ///
  /// In it, this message translates to:
  /// **'Salvati {stored} prodotti su {total}. I dati non sono stati ripristinati: riprova.'**
  String backupErrorProductsNotSaved(int stored, int total);

  /// No description provided for @errorProductNotFound.
  ///
  /// In it, this message translates to:
  /// **'Prodotto non trovato.'**
  String get errorProductNotFound;

  /// No description provided for @errorStockCorrectionUnavailable.
  ///
  /// In it, this message translates to:
  /// **'La correzione della scorta non è disponibile.'**
  String get errorStockCorrectionUnavailable;

  /// No description provided for @achFirstEntryTitle.
  ///
  /// In it, this message translates to:
  /// **'Prima tracciata'**
  String get achFirstEntryTitle;

  /// No description provided for @achFirstEntryDesc.
  ///
  /// In it, this message translates to:
  /// **'Hai registrato la prima unità.'**
  String get achFirstEntryDesc;

  /// No description provided for @achTracked7Title.
  ///
  /// In it, this message translates to:
  /// **'7 giorni di dati'**
  String get achTracked7Title;

  /// No description provided for @achTracked7Desc.
  ///
  /// In it, this message translates to:
  /// **'Attività registrata per 7 giorni distinti.'**
  String get achTracked7Desc;

  /// No description provided for @achTracked30Title.
  ///
  /// In it, this message translates to:
  /// **'30 giorni di dati'**
  String get achTracked30Title;

  /// No description provided for @achTracked30Desc.
  ///
  /// In it, this message translates to:
  /// **'Attività registrata per 30 giorni distinti.'**
  String get achTracked30Desc;

  /// No description provided for @achStreak3Title.
  ///
  /// In it, this message translates to:
  /// **'3 giorni di fila'**
  String get achStreak3Title;

  /// No description provided for @achStreak3Desc.
  ///
  /// In it, this message translates to:
  /// **'Attivo 3 giorni consecutivi.'**
  String get achStreak3Desc;

  /// No description provided for @achStreak7Title.
  ///
  /// In it, this message translates to:
  /// **'Settimana intera'**
  String get achStreak7Title;

  /// No description provided for @achStreak7Desc.
  ///
  /// In it, this message translates to:
  /// **'Attivo 7 giorni consecutivi.'**
  String get achStreak7Desc;

  /// No description provided for @achStreak14Title.
  ///
  /// In it, this message translates to:
  /// **'Due settimane'**
  String get achStreak14Title;

  /// No description provided for @achStreak14Desc.
  ///
  /// In it, this message translates to:
  /// **'Attivo 14 giorni consecutivi.'**
  String get achStreak14Desc;

  /// No description provided for @achStreak30Title.
  ///
  /// In it, this message translates to:
  /// **'Un mese intero'**
  String get achStreak30Title;

  /// No description provided for @achStreak30Desc.
  ///
  /// In it, this message translates to:
  /// **'Attivo 30 giorni consecutivi.'**
  String get achStreak30Desc;

  /// No description provided for @achUnderLimit1Title.
  ///
  /// In it, this message translates to:
  /// **'Primo giorno ok'**
  String get achUnderLimit1Title;

  /// No description provided for @achUnderLimit1Desc.
  ///
  /// In it, this message translates to:
  /// **'1 giorno sotto il limite giornaliero.'**
  String get achUnderLimit1Desc;

  /// No description provided for @achUnderLimit3Title.
  ///
  /// In it, this message translates to:
  /// **'Tre giorni ok'**
  String get achUnderLimit3Title;

  /// No description provided for @achUnderLimit3Desc.
  ///
  /// In it, this message translates to:
  /// **'3 giorni consecutivi sotto il limite.'**
  String get achUnderLimit3Desc;

  /// No description provided for @achUnderLimit7Title.
  ///
  /// In it, this message translates to:
  /// **'Settimana ok'**
  String get achUnderLimit7Title;

  /// No description provided for @achUnderLimit7Desc.
  ///
  /// In it, this message translates to:
  /// **'7 giorni consecutivi sotto il limite.'**
  String get achUnderLimit7Desc;

  /// No description provided for @achUnderLimit30Title.
  ///
  /// In it, this message translates to:
  /// **'Mese sotto controllo'**
  String get achUnderLimit30Title;

  /// No description provided for @achUnderLimit30Desc.
  ///
  /// In it, this message translates to:
  /// **'30 giorni consecutivi sotto il limite.'**
  String get achUnderLimit30Desc;

  /// No description provided for @achReduction10Title.
  ///
  /// In it, this message translates to:
  /// **'-10% media'**
  String get achReduction10Title;

  /// No description provided for @achReduction10Desc.
  ///
  /// In it, this message translates to:
  /// **'Media ridotta del 10% rispetto all\'inizio del piano.'**
  String get achReduction10Desc;

  /// No description provided for @achReduction25Title.
  ///
  /// In it, this message translates to:
  /// **'-25% media'**
  String get achReduction25Title;

  /// No description provided for @achReduction25Desc.
  ///
  /// In it, this message translates to:
  /// **'Media ridotta del 25% rispetto all\'inizio del piano.'**
  String get achReduction25Desc;

  /// No description provided for @achReduction50Title.
  ///
  /// In it, this message translates to:
  /// **'-50% media'**
  String get achReduction50Title;

  /// No description provided for @achReduction50Desc.
  ///
  /// In it, this message translates to:
  /// **'Hai dimezzato la tua media. Eccezionale!'**
  String get achReduction50Desc;

  /// No description provided for @reminderChannelName.
  ///
  /// In it, this message translates to:
  /// **'Promemoria registrazione'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In it, this message translates to:
  /// **'Promemoria generali per ricordare di registrare i prodotti tracciati.'**
  String get reminderChannelDescription;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In it, this message translates to:
  /// **'Promemoria'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In it, this message translates to:
  /// **'Ricordati di registrare i prodotti tracciati.'**
  String get reminderNotificationBody;

  /// No description provided for @productAddedInUse.
  ///
  /// In it, this message translates to:
  /// **'{name} aggiunto e in uso'**
  String productAddedInUse(String name);

  /// No description provided for @backupFilesUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Import/export file disponibile solo su Android e Windows.'**
  String get backupFilesUnsupported;

  /// No description provided for @fileSaveUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Salvataggio file non supportato su questa piattaforma.'**
  String get fileSaveUnsupported;

  /// No description provided for @backupSaved.
  ///
  /// In it, this message translates to:
  /// **'Backup CSV salvato'**
  String get backupSaved;

  /// No description provided for @backupExportFailed.
  ///
  /// In it, this message translates to:
  /// **'Esportazione CSV non riuscita.'**
  String get backupExportFailed;

  /// No description provided for @browserOpenFailed.
  ///
  /// In it, this message translates to:
  /// **'Non riesco ad aprire il browser.'**
  String get browserOpenFailed;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Cancella tutto?'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryBody.
  ///
  /// In it, this message translates to:
  /// **'Questa azione elimina permanentemente tutta la cronologia registrata finora.'**
  String get clearHistoryBody;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @stockCount.
  ///
  /// In it, this message translates to:
  /// **'{remaining}/{total} in scorta'**
  String stockCount(int remaining, int total);

  /// No description provided for @noStock.
  ///
  /// In it, this message translates to:
  /// **'Senza scorta'**
  String get noStock;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @settingsSectionProducts.
  ///
  /// In it, this message translates to:
  /// **'PRODOTTI'**
  String get settingsSectionProducts;

  /// No description provided for @addProduct.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi prodotto'**
  String get addProduct;

  /// No description provided for @archivedCount.
  ///
  /// In it, this message translates to:
  /// **'Archiviati ({count})  ›'**
  String archivedCount(int count);

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In it, this message translates to:
  /// **'ASPETTO'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLanguageCurrency.
  ///
  /// In it, this message translates to:
  /// **'LINGUA E VALUTA'**
  String get settingsSectionLanguageCurrency;

  /// No description provided for @settingsSectionReminders.
  ///
  /// In it, this message translates to:
  /// **'PROMEMORIA'**
  String get settingsSectionReminders;

  /// No description provided for @theme.
  ///
  /// In it, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get themeLight;

  /// No description provided for @system.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get system;

  /// No description provided for @language.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get language;

  /// No description provided for @widgetTheme.
  ///
  /// In it, this message translates to:
  /// **'Tema del widget'**
  String get widgetTheme;

  /// No description provided for @currency.
  ///
  /// In it, this message translates to:
  /// **'Valuta'**
  String get currency;

  /// No description provided for @settingsSectionData.
  ///
  /// In it, this message translates to:
  /// **'DATI'**
  String get settingsSectionData;

  /// No description provided for @exportBackup.
  ///
  /// In it, this message translates to:
  /// **'Esporta backup'**
  String get exportBackup;

  /// No description provided for @lastBackupOn.
  ///
  /// In it, this message translates to:
  /// **'Ultimo backup: {date}'**
  String lastBackupOn(String date);

  /// No description provided for @noBackupYet.
  ///
  /// In it, this message translates to:
  /// **'Nessun backup ancora: salva un file CSV con tutti i dati'**
  String get noBackupYet;

  /// No description provided for @importBackup.
  ///
  /// In it, this message translates to:
  /// **'Importa backup'**
  String get importBackup;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Sostituisce i dati attuali'**
  String get importBackupSubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In it, this message translates to:
  /// **'INFORMAZIONI'**
  String get settingsSectionAbout;

  /// No description provided for @checkForUpdates.
  ///
  /// In it, this message translates to:
  /// **'Controlla aggiornamenti'**
  String get checkForUpdates;

  /// No description provided for @installedVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione installata {version} · apre GitHub'**
  String installedVersion(String version);

  /// No description provided for @opensReleasesPage.
  ///
  /// In it, this message translates to:
  /// **'Apre la pagina delle versioni su GitHub'**
  String get opensReleasesPage;

  /// No description provided for @clearHistory.
  ///
  /// In it, this message translates to:
  /// **'Cancella cronologia'**
  String get clearHistory;

  /// No description provided for @widgetHint.
  ///
  /// In it, this message translates to:
  /// **'Tieni premuto sulla schermata Home del telefono per aggiungere il widget.'**
  String get widgetHint;

  /// No description provided for @inUseBadge.
  ///
  /// In it, this message translates to:
  /// **'IN USO'**
  String get inUseBadge;

  /// No description provided for @durationMinutes.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 minuto} other{{count} minuti}}'**
  String durationMinutes(int count);

  /// No description provided for @durationHours.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 ora} other{{count} ore}}'**
  String durationHours(int count);

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In it, this message translates to:
  /// **'Permesso notifiche non concesso.'**
  String get notificationPermissionDenied;

  /// No description provided for @remindMeEvery.
  ///
  /// In it, this message translates to:
  /// **'Ricordamelo ogni'**
  String get remindMeEvery;

  /// No description provided for @reminders.
  ///
  /// In it, this message translates to:
  /// **'Promemoria'**
  String get reminders;

  /// No description provided for @remindersSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ti ricorda di registrare'**
  String get remindersSubtitle;

  /// No description provided for @androidOnly.
  ///
  /// In it, this message translates to:
  /// **'Disponibile solo su Android'**
  String get androidOnly;

  /// No description provided for @frequency.
  ///
  /// In it, this message translates to:
  /// **'Frequenza'**
  String get frequency;

  /// No description provided for @every.
  ///
  /// In it, this message translates to:
  /// **'Ogni {interval}'**
  String every(String interval);

  /// No description provided for @fileImportUnsupported.
  ///
  /// In it, this message translates to:
  /// **'Importazione file non supportata su questa piattaforma.'**
  String get fileImportUnsupported;

  /// No description provided for @restoreCompleted.
  ///
  /// In it, this message translates to:
  /// **'Ripristino completato: {summary}.'**
  String restoreCompleted(String summary);

  /// No description provided for @restoreCompletedRemindersOff.
  ///
  /// In it, this message translates to:
  /// **'Ripristino completato: {summary}. Promemoria disattivati: permesso notifiche non concesso.'**
  String restoreCompletedRemindersOff(String summary);

  /// No description provided for @backupInvalid.
  ///
  /// In it, this message translates to:
  /// **'Backup CSV non valido'**
  String get backupInvalid;

  /// No description provided for @backupImportFailed.
  ///
  /// In it, this message translates to:
  /// **'Importazione CSV non riuscita.'**
  String get backupImportFailed;

  /// No description provided for @emptyBackupTitle.
  ///
  /// In it, this message translates to:
  /// **'Backup senza cronologia'**
  String get emptyBackupTitle;

  /// No description provided for @emptyBackupBody.
  ///
  /// In it, this message translates to:
  /// **'Questo file non contiene nessuna registrazione. Importarlo sostituisce i dati attuali e la cronologia resta vuota.'**
  String get emptyBackupBody;

  /// No description provided for @importAnyway.
  ///
  /// In it, this message translates to:
  /// **'Importa comunque'**
  String get importAnyway;

  /// No description provided for @restoreSummary.
  ///
  /// In it, this message translates to:
  /// **'{entries} e {products}'**
  String restoreSummary(String entries, String products);

  /// No description provided for @entriesCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 registrazione} other{{count} registrazioni}}'**
  String entriesCount(int count);

  /// No description provided for @productsCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 prodotto} other{{count} prodotti}}'**
  String productsCount(int count);

  /// No description provided for @productRestored.
  ///
  /// In it, this message translates to:
  /// **'{name} ripristinato'**
  String productRestored(String name);

  /// No description provided for @deletePermanentlyTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare definitivamente?'**
  String get deletePermanentlyTitle;

  /// No description provided for @deletePermanentlyBody.
  ///
  /// In it, this message translates to:
  /// **'Questa azione rimuove {name} e tutta la cronologia collegata.'**
  String deletePermanentlyBody(String name);

  /// No description provided for @productDeleted.
  ///
  /// In it, this message translates to:
  /// **'{name} eliminato definitivamente'**
  String productDeleted(String name);

  /// No description provided for @archivedTitle.
  ///
  /// In it, this message translates to:
  /// **'Archiviati'**
  String get archivedTitle;

  /// No description provided for @archivedIntro.
  ///
  /// In it, this message translates to:
  /// **'I prodotti archiviati non compaiono in home, ma la loro cronologia resta. Ripristinandoli tornano come prima.'**
  String get archivedIntro;

  /// No description provided for @noArchivedProducts.
  ///
  /// In it, this message translates to:
  /// **'Nessun prodotto archiviato'**
  String get noArchivedProducts;

  /// No description provided for @historyKept.
  ///
  /// In it, this message translates to:
  /// **'Storico conservato'**
  String get historyKept;

  /// No description provided for @restore.
  ///
  /// In it, this message translates to:
  /// **'Ripristina'**
  String get restore;

  /// No description provided for @deletePermanently.
  ///
  /// In it, this message translates to:
  /// **'Elimina definitivamente'**
  String get deletePermanently;

  /// No description provided for @newProduct.
  ///
  /// In it, this message translates to:
  /// **'Nuovo prodotto'**
  String get newProduct;

  /// No description provided for @setupTitle.
  ///
  /// In it, this message translates to:
  /// **'Configura il tuo prodotto'**
  String get setupTitle;

  /// No description provided for @startTracking.
  ///
  /// In it, this message translates to:
  /// **'Inizia a tracciare'**
  String get startTracking;

  /// No description provided for @haveBackup.
  ///
  /// In it, this message translates to:
  /// **'Ho già un backup'**
  String get haveBackup;

  /// No description provided for @haveBackupSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina i tuoi dati da un file CSV'**
  String get haveBackupSubtitle;

  /// No description provided for @setupQuestion.
  ///
  /// In it, this message translates to:
  /// **'Cosa vuoi tracciare?'**
  String get setupQuestion;

  /// No description provided for @setupSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Puoi modificare tutto nelle impostazioni in qualsiasi momento.'**
  String get setupSubtitle;

  /// No description provided for @remindersSection.
  ///
  /// In it, this message translates to:
  /// **'PROMEMORIA'**
  String get remindersSection;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto su\nMy Tracking App'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In it, this message translates to:
  /// **'Tieni d\'occhio quanto usi, quanto spendi e come cambiano le tue abitudini. Tutti i dati restano sul tuo telefono.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingTrackTitle.
  ///
  /// In it, this message translates to:
  /// **'Tieni traccia\ndi tutto'**
  String get onboardingTrackTitle;

  /// No description provided for @onboardingTrackBody.
  ///
  /// In it, this message translates to:
  /// **'Puoi seguire più prodotti insieme. Ognuno ha la sua cronologia, i suoi costi e il suo obiettivo.'**
  String get onboardingTrackBody;

  /// No description provided for @onboardingCustomizeTitle.
  ///
  /// In it, this message translates to:
  /// **'Personalizza\nil tuo prodotto'**
  String get onboardingCustomizeTitle;

  /// No description provided for @onboardingCustomizeBody.
  ///
  /// In it, this message translates to:
  /// **'Indica nome, costo e confezione, e se vuoi un limite giornaliero: il costo di ogni utilizzo lo calcola l\'app.'**
  String get onboardingCustomizeBody;

  /// No description provided for @onboardingTimeTitle.
  ///
  /// In it, this message translates to:
  /// **'Quanto tempo\nti costa?'**
  String get onboardingTimeTitle;

  /// No description provided for @onboardingTimeBody.
  ///
  /// In it, this message translates to:
  /// **'Puoi aggiungere una stima dei minuti di vita persi per ogni utilizzo: è un valore simbolico, non il tempo per consumarlo. Se non ti serve, scegli «Nessuna stima».'**
  String get onboardingTimeBody;

  /// No description provided for @onboardingTapTitle.
  ///
  /// In it, this message translates to:
  /// **'Un tocco\nper registrare'**
  String get onboardingTapTitle;

  /// No description provided for @onboardingTapBody.
  ///
  /// In it, this message translates to:
  /// **'Premi HO USATO ogni volta, oppure registra tutto a fine giornata. Se tocchi per sbaglio puoi annullare subito, e su Android c\'è anche il widget.'**
  String get onboardingTapBody;

  /// No description provided for @onboardingProgressTitle.
  ///
  /// In it, this message translates to:
  /// **'Osserva\ni tuoi progressi'**
  String get onboardingProgressTitle;

  /// No description provided for @onboardingProgressBody.
  ///
  /// In it, this message translates to:
  /// **'Cronologia per giorni, settimane e mesi, obiettivi e un piano di riduzione. Con il backup non perdi nulla.'**
  String get onboardingProgressBody;

  /// No description provided for @skip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get skip;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get start;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get next;

  /// No description provided for @historyTitle.
  ///
  /// In it, this message translates to:
  /// **'Cronologia'**
  String get historyTitle;

  /// No description provided for @achievementsTooltip.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi e badge'**
  String get achievementsTooltip;

  /// No description provided for @today.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get today;

  /// No description provided for @lifeLostToday.
  ///
  /// In it, this message translates to:
  /// **'Vita persa oggi'**
  String get lifeLostToday;

  /// No description provided for @totalSpent.
  ///
  /// In it, this message translates to:
  /// **'Totale speso'**
  String get totalSpent;

  /// No description provided for @lastEntry.
  ///
  /// In it, this message translates to:
  /// **'ULTIMA: {time}'**
  String lastEntry(String time);

  /// No description provided for @logButton.
  ///
  /// In it, this message translates to:
  /// **'HO USATO'**
  String get logButton;

  /// No description provided for @loggedToday.
  ///
  /// In it, this message translates to:
  /// **'Registrato · {count} oggi'**
  String loggedToday(int count);

  /// No description provided for @undo.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get undo;

  /// No description provided for @creatorMessage.
  ///
  /// In it, this message translates to:
  /// **'Applicazione creata da Lorenzo Caputo, with love <3'**
  String get creatorMessage;

  /// No description provided for @stockFinished.
  ///
  /// In it, this message translates to:
  /// **'📦 {name} terminato!'**
  String stockFinished(String name);

  /// No description provided for @overLimit.
  ///
  /// In it, this message translates to:
  /// **'Sopra il limite impostato ({count}/{limit})'**
  String overLimit(int count, int limit);

  /// No description provided for @dailyLimitReached.
  ///
  /// In it, this message translates to:
  /// **'Limite giornaliero raggiunto ({count}/{limit})'**
  String dailyLimitReached(int count, int limit);

  /// No description provided for @newStockButton.
  ///
  /// In it, this message translates to:
  /// **'NUOVA\nSCORTA'**
  String get newStockButton;

  /// No description provided for @productInUse.
  ///
  /// In it, this message translates to:
  /// **'Prodotto in uso'**
  String get productInUse;

  /// No description provided for @todayCaps.
  ///
  /// In it, this message translates to:
  /// **'OGGI'**
  String get todayCaps;

  /// No description provided for @unitCost.
  ///
  /// In it, this message translates to:
  /// **'Costo unitario'**
  String get unitCost;

  /// No description provided for @costPerUse.
  ///
  /// In it, this message translates to:
  /// **'Costo per utilizzo'**
  String get costPerUse;

  /// No description provided for @labelValue.
  ///
  /// In it, this message translates to:
  /// **'{label}: {value}'**
  String labelValue(String label, String value);

  /// No description provided for @never.
  ///
  /// In it, this message translates to:
  /// **'Mai'**
  String get never;

  /// No description provided for @justNow.
  ///
  /// In it, this message translates to:
  /// **'Adesso'**
  String get justNow;

  /// No description provided for @daysAgo.
  ///
  /// In it, this message translates to:
  /// **'{count}g fa'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In it, this message translates to:
  /// **'{count}h fa'**
  String hoursAgo(int count);

  /// No description provided for @hoursMinutesAgo.
  ///
  /// In it, this message translates to:
  /// **'{hours}h {minutes}m fa'**
  String hoursMinutesAgo(int hours, int minutes);

  /// No description provided for @minutesAgo.
  ///
  /// In it, this message translates to:
  /// **'{count}m fa'**
  String minutesAgo(int count);

  /// No description provided for @insightPlanAhead.
  ///
  /// In it, this message translates to:
  /// **'Piano: avanti'**
  String get insightPlanAhead;

  /// No description provided for @insightPlanOnTrack.
  ///
  /// In it, this message translates to:
  /// **'Piano: in linea'**
  String get insightPlanOnTrack;

  /// No description provided for @insightPlanBehind.
  ///
  /// In it, this message translates to:
  /// **'Piano: in ritardo'**
  String get insightPlanBehind;

  /// No description provided for @insightLimitRemaining.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{Manca 1 unità al limite} other{Mancano {count} unità al limite}}'**
  String insightLimitRemaining(int count);

  /// No description provided for @insightComparedToYesterday.
  ///
  /// In it, this message translates to:
  /// **'{delta} rispetto a ieri'**
  String insightComparedToYesterday(String delta);

  /// No description provided for @changesSaved.
  ///
  /// In it, this message translates to:
  /// **'Modifiche salvate'**
  String get changesSaved;

  /// No description provided for @discardChangesTitle.
  ///
  /// In it, this message translates to:
  /// **'Scartare le modifiche?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In it, this message translates to:
  /// **'Le modifiche non salvate andranno perse.'**
  String get discardChangesBody;

  /// No description provided for @discard.
  ///
  /// In it, this message translates to:
  /// **'Scarta'**
  String get discard;

  /// No description provided for @productInUseFeedback.
  ///
  /// In it, this message translates to:
  /// **'{name} in uso'**
  String productInUseFeedback(String name);

  /// No description provided for @keepOneActiveProduct.
  ///
  /// In it, this message translates to:
  /// **'Devi mantenere almeno un prodotto attivo'**
  String get keepOneActiveProduct;

  /// No description provided for @productArchived.
  ///
  /// In it, this message translates to:
  /// **'{name} archiviato'**
  String productArchived(String name);

  /// No description provided for @moreActions.
  ///
  /// In it, this message translates to:
  /// **'Altre azioni'**
  String get moreActions;

  /// No description provided for @useThisProduct.
  ///
  /// In it, this message translates to:
  /// **'Usa questo prodotto'**
  String get useThisProduct;

  /// No description provided for @useThisProductSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Diventa quello registrato in home'**
  String get useThisProductSubtitle;

  /// No description provided for @archive.
  ///
  /// In it, this message translates to:
  /// **'Archivia'**
  String get archive;

  /// No description provided for @archiveSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Sparisce dalla home, la cronologia resta'**
  String get archiveSubtitle;

  /// No description provided for @unsavedChanges.
  ///
  /// In it, this message translates to:
  /// **'Modifiche non salvate'**
  String get unsavedChanges;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @newPackTitle.
  ///
  /// In it, this message translates to:
  /// **'Nuova confezione?'**
  String get newPackTitle;

  /// No description provided for @newPackBody.
  ///
  /// In it, this message translates to:
  /// **'La scorta di {name} torna a {pieces}/{pieces}.'**
  String newPackBody(String name, int pieces);

  /// No description provided for @restock.
  ///
  /// In it, this message translates to:
  /// **'Reintegra'**
  String get restock;

  /// No description provided for @stockRestocked.
  ///
  /// In it, this message translates to:
  /// **'Scorta reintegrata'**
  String get stockRestocked;

  /// No description provided for @correctStockTitle.
  ///
  /// In it, this message translates to:
  /// **'Correggi scorta'**
  String get correctStockTitle;

  /// No description provided for @correctStockBody.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il numero reale di unità rimaste per allineare la scorta attuale.'**
  String get correctStockBody;

  /// No description provided for @unitsLeft.
  ///
  /// In it, this message translates to:
  /// **'Unità rimaste'**
  String get unitsLeft;

  /// No description provided for @enterWholeNumber.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un numero intero.'**
  String get enterWholeNumber;

  /// No description provided for @enterValidWholeNumber.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un numero intero valido.'**
  String get enterValidWholeNumber;

  /// No description provided for @valueNotNegative.
  ///
  /// In it, this message translates to:
  /// **'Il valore non può essere negativo.'**
  String get valueNotNegative;

  /// No description provided for @valueAtMost.
  ///
  /// In it, this message translates to:
  /// **'Il valore non può superare {max}.'**
  String valueAtMost(int max);

  /// No description provided for @confirm.
  ///
  /// In it, this message translates to:
  /// **'Conferma'**
  String get confirm;

  /// No description provided for @correctStockFailed.
  ///
  /// In it, this message translates to:
  /// **'Correzione scorta non riuscita.'**
  String get correctStockFailed;

  /// No description provided for @stock.
  ///
  /// In it, this message translates to:
  /// **'Scorta'**
  String get stock;

  /// No description provided for @correct.
  ///
  /// In it, this message translates to:
  /// **'Correggi'**
  String get correct;

  /// No description provided for @productNameLabel.
  ///
  /// In it, this message translates to:
  /// **'NOME PRODOTTO'**
  String get productNameLabel;

  /// No description provided for @productNameHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Sigarette'**
  String get productNameHint;

  /// No description provided for @enterName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un nome'**
  String get enterName;

  /// No description provided for @productModeLabel.
  ///
  /// In it, this message translates to:
  /// **'MODALITÀ PRODOTTO'**
  String get productModeLabel;

  /// No description provided for @packCostLabel.
  ///
  /// In it, this message translates to:
  /// **'COSTO CONFEZIONE'**
  String get packCostLabel;

  /// No description provided for @packCostHint.
  ///
  /// In it, this message translates to:
  /// **'Es. 6,00'**
  String get packCostHint;

  /// No description provided for @enterAmount.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un importo'**
  String get enterAmount;

  /// No description provided for @invalidAmount.
  ///
  /// In it, this message translates to:
  /// **'Importo non valido'**
  String get invalidAmount;

  /// No description provided for @unitsPerPackLabel.
  ///
  /// In it, this message translates to:
  /// **'UNITÀ / USI STIMATI PER CONFEZIONE'**
  String get unitsPerPackLabel;

  /// No description provided for @unitsPerPackHint.
  ///
  /// In it, this message translates to:
  /// **'Es. 20'**
  String get unitsPerPackHint;

  /// No description provided for @enterNumber.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un numero'**
  String get enterNumber;

  /// No description provided for @invalidNumber.
  ///
  /// In it, this message translates to:
  /// **'Numero non valido'**
  String get invalidNumber;

  /// No description provided for @unitsPerPackHelp.
  ///
  /// In it, this message translates to:
  /// **'Puoi inserire anche il numero medio di usi ottenibili da una confezione.'**
  String get unitsPerPackHelp;

  /// No description provided for @costPerUseLabel.
  ///
  /// In it, this message translates to:
  /// **'COSTO PER UTILIZZO'**
  String get costPerUseLabel;

  /// No description provided for @costPerUseHint.
  ///
  /// In it, this message translates to:
  /// **'Facoltativo, es. 0,10'**
  String get costPerUseHint;

  /// No description provided for @costPerUseHelp.
  ///
  /// In it, this message translates to:
  /// **'Lascia vuoto se vuoi registrare solo gli utilizzi, senza calcolare costi.'**
  String get costPerUseHelp;

  /// No description provided for @minutesLostLabel.
  ///
  /// In it, this message translates to:
  /// **'MINUTI DI VITA PERSI PER UTILIZZO'**
  String get minutesLostLabel;

  /// No description provided for @enterValue.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un valore'**
  String get enterValue;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In it, this message translates to:
  /// **'OBIETTIVO GIORNALIERO'**
  String get dailyGoalLabel;

  /// No description provided for @noDailyLimit.
  ///
  /// In it, this message translates to:
  /// **'Nessun limite giornaliero'**
  String get noDailyLimit;

  /// No description provided for @dailyGoalText.
  ///
  /// In it, this message translates to:
  /// **'Voglio stare sotto {count} al giorno'**
  String dailyGoalText(int count);

  /// No description provided for @noLimit.
  ///
  /// In it, this message translates to:
  /// **'Nessun limite'**
  String get noLimit;

  /// No description provided for @zeroNoLimit.
  ///
  /// In it, this message translates to:
  /// **'0 = nessun limite impostato'**
  String get zeroNoLimit;

  /// No description provided for @withStock.
  ///
  /// In it, this message translates to:
  /// **'Con scorta'**
  String get withStock;

  /// No description provided for @withStockHelp.
  ///
  /// In it, this message translates to:
  /// **'Il prodotto usa una scorta residua e può essere reintegrato quando termina.'**
  String get withStockHelp;

  /// No description provided for @noStockHelp.
  ///
  /// In it, this message translates to:
  /// **'Il prodotto registra solo gli utilizzi, senza gestire confezioni o residuo.'**
  String get noStockHelp;

  /// No description provided for @minutesLostSheetTitle.
  ///
  /// In it, this message translates to:
  /// **'Minuti di vita persi'**
  String get minutesLostSheetTitle;

  /// No description provided for @noEstimate.
  ///
  /// In it, this message translates to:
  /// **'Nessuna stima'**
  String get noEstimate;

  /// No description provided for @noEstimateSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Non conta la vita persa'**
  String get noEstimateSubtitle;

  /// No description provided for @minutesEstimate.
  ///
  /// In it, this message translates to:
  /// **'{count} min (stima)'**
  String minutesEstimate(int count);

  /// No description provided for @minutesPresetLabel.
  ///
  /// In it, this message translates to:
  /// **'{name} — {estimate}'**
  String minutesPresetLabel(String name, String estimate);

  /// No description provided for @presetCigarette.
  ///
  /// In it, this message translates to:
  /// **'Sigaretta'**
  String get presetCigarette;

  /// No description provided for @presetEcigarette.
  ///
  /// In it, this message translates to:
  /// **'Sigaretta elettronica'**
  String get presetEcigarette;

  /// No description provided for @presetHeatedTobacco.
  ///
  /// In it, this message translates to:
  /// **'Riscaldatore di tabacco'**
  String get presetHeatedTobacco;

  /// No description provided for @presetCigar.
  ///
  /// In it, this message translates to:
  /// **'Sigaro'**
  String get presetCigar;

  /// No description provided for @presetHookah.
  ///
  /// In it, this message translates to:
  /// **'Narghilè (sessione)'**
  String get presetHookah;

  /// No description provided for @custom.
  ///
  /// In it, this message translates to:
  /// **'Personalizzato…'**
  String get custom;

  /// No description provided for @minutesPerUse.
  ///
  /// In it, this message translates to:
  /// **'Minuti per utilizzo'**
  String get minutesPerUse;

  /// No description provided for @last7Days.
  ///
  /// In it, this message translates to:
  /// **'ULTIMI 7 GIORNI'**
  String get last7Days;

  /// No description provided for @averagePerDay.
  ///
  /// In it, this message translates to:
  /// **'media {value}/giorno'**
  String averagePerDay(String value);

  /// No description provided for @weekdaysShort.
  ///
  /// In it, this message translates to:
  /// **'LUN,MAR,MER,GIO,VEN,SAB,DOM'**
  String get weekdaysShort;

  /// No description provided for @openCsv.
  ///
  /// In it, this message translates to:
  /// **'Apri CSV'**
  String get openCsv;

  /// No description provided for @saveCsv.
  ///
  /// In it, this message translates to:
  /// **'Salva CSV'**
  String get saveCsv;

  /// No description provided for @unreadableBackupFile.
  ///
  /// In it, this message translates to:
  /// **'File non leggibile: usa il backup CSV esportato dall\'app, senza modificarlo.'**
  String get unreadableBackupFile;

  /// No description provided for @last7DaysTitle.
  ///
  /// In it, this message translates to:
  /// **'Ultimi 7 giorni'**
  String get last7DaysTitle;

  /// No description provided for @last30DaysTitle.
  ///
  /// In it, this message translates to:
  /// **'Ultimi 30 giorni'**
  String get last30DaysTitle;

  /// No description provided for @entireHistory.
  ///
  /// In it, this message translates to:
  /// **'Tutta la cronologia'**
  String get entireHistory;

  /// No description provided for @customPeriod.
  ///
  /// In it, this message translates to:
  /// **'Periodo personalizzato'**
  String get customPeriod;

  /// No description provided for @selectRange.
  ///
  /// In it, this message translates to:
  /// **'Seleziona intervallo'**
  String get selectRange;

  /// No description provided for @noDataLogged.
  ///
  /// In it, this message translates to:
  /// **'Nessun dato registrato'**
  String get noDataLogged;

  /// No description provided for @noDataLoggedBody.
  ///
  /// In it, this message translates to:
  /// **'La cronologia apparirà qui dopo i primi utilizzi.'**
  String get noDataLoggedBody;

  /// No description provided for @noFilterResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato nel filtro selezionato'**
  String get noFilterResults;

  /// No description provided for @noFilterResultsBody.
  ///
  /// In it, this message translates to:
  /// **'Prova un altro prodotto o un intervallo di date più ampio.'**
  String get noFilterResultsBody;

  /// No description provided for @filters.
  ///
  /// In it, this message translates to:
  /// **'FILTRI'**
  String get filters;

  /// No description provided for @product.
  ///
  /// In it, this message translates to:
  /// **'Prodotto'**
  String get product;

  /// No description provided for @allProducts.
  ///
  /// In it, this message translates to:
  /// **'Tutti i prodotti'**
  String get allProducts;

  /// No description provided for @statistics.
  ///
  /// In it, this message translates to:
  /// **'STATISTICHE'**
  String get statistics;

  /// No description provided for @periodOverview.
  ///
  /// In it, this message translates to:
  /// **'Panoramica periodo'**
  String get periodOverview;

  /// No description provided for @periodOverviewSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Medie e riepilogo del filtro selezionato'**
  String get periodOverviewSubtitle;

  /// No description provided for @periodTotal.
  ///
  /// In it, this message translates to:
  /// **'Totale periodo'**
  String get periodTotal;

  /// No description provided for @mixedProductsNote.
  ///
  /// In it, this message translates to:
  /// **'Prodotti diversi non si sommano: scegli un prodotto per vedere medie e andamento.'**
  String get mixedProductsNote;

  /// No description provided for @periodAveragePerDay.
  ///
  /// In it, this message translates to:
  /// **'Media periodo/g'**
  String get periodAveragePerDay;

  /// No description provided for @trend7Days.
  ///
  /// In it, this message translates to:
  /// **'Trend 7g'**
  String get trend7Days;

  /// No description provided for @average30Days.
  ///
  /// In it, this message translates to:
  /// **'Media 30 giorni'**
  String get average30Days;

  /// No description provided for @unitsCount.
  ///
  /// In it, this message translates to:
  /// **'{count} unità'**
  String unitsCount(int count);

  /// No description provided for @costsAndProjections.
  ///
  /// In it, this message translates to:
  /// **'Costi e proiezioni'**
  String get costsAndProjections;

  /// No description provided for @costsAndProjectionsSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Spesa attuale e stime future'**
  String get costsAndProjectionsSubtitle;

  /// No description provided for @periodCost.
  ///
  /// In it, this message translates to:
  /// **'Costo periodo'**
  String get periodCost;

  /// No description provided for @monthlyProjection.
  ///
  /// In it, this message translates to:
  /// **'Proiezione mese'**
  String get monthlyProjection;

  /// No description provided for @annualEstimate.
  ///
  /// In it, this message translates to:
  /// **'Stima annua'**
  String get annualEstimate;

  /// No description provided for @monthlyEstimate.
  ///
  /// In it, this message translates to:
  /// **'Stima mese'**
  String get monthlyEstimate;

  /// No description provided for @estimatedAnnualCost.
  ///
  /// In it, this message translates to:
  /// **'Costo annuo stimato'**
  String get estimatedAnnualCost;

  /// No description provided for @habitsAndTimes.
  ///
  /// In it, this message translates to:
  /// **'Abitudini e orari'**
  String get habitsAndTimes;

  /// No description provided for @habitsAndTimesSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ritmo, giorni e fascia oraria più attiva'**
  String get habitsAndTimesSubtitle;

  /// No description provided for @peakHour.
  ///
  /// In it, this message translates to:
  /// **'Ora picco'**
  String get peakHour;

  /// No description provided for @underLimitStreak.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 giorno consecutivo sotto il limite ({limit})} other{{count} giorni consecutivi sotto il limite ({limit})}}'**
  String underLimitStreak(int count, int limit);

  /// No description provided for @activeStreak.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{Attivo da 1 giorno consecutivo} other{Attivo da {count} giorni consecutivi}}'**
  String activeStreak(int count);

  /// No description provided for @bestDay.
  ///
  /// In it, this message translates to:
  /// **'Giorno migliore'**
  String get bestDay;

  /// No description provided for @worstDay.
  ///
  /// In it, this message translates to:
  /// **'Giorno peggiore'**
  String get worstDay;

  /// No description provided for @hourlyDistribution.
  ///
  /// In it, this message translates to:
  /// **'DISTRIBUZIONE ORARIA'**
  String get hourlyDistribution;

  /// No description provided for @thinDataNote.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{Stime basate su un giorno di dati: diventeranno attendibili con qualche giorno in più.} other{Stime basate su {count} giorni di dati: diventeranno attendibili con qualche giorno in più.}}'**
  String thinDataNote(int count);

  /// No description provided for @trend30Days.
  ///
  /// In it, this message translates to:
  /// **'TREND ULTIMI 30 GIORNI'**
  String get trend30Days;

  /// No description provided for @sevenDays.
  ///
  /// In it, this message translates to:
  /// **'7 giorni'**
  String get sevenDays;

  /// No description provided for @thirtyDays.
  ///
  /// In it, this message translates to:
  /// **'30 giorni'**
  String get thirtyDays;

  /// No description provided for @all.
  ///
  /// In it, this message translates to:
  /// **'Tutto'**
  String get all;

  /// No description provided for @customShort.
  ///
  /// In it, this message translates to:
  /// **'Personalizzato'**
  String get customShort;

  /// No description provided for @weekOf.
  ///
  /// In it, this message translates to:
  /// **'Settimana {label}'**
  String weekOf(String label);

  /// No description provided for @entriesSection.
  ///
  /// In it, this message translates to:
  /// **'REGISTRAZIONI'**
  String get entriesSection;

  /// No description provided for @days.
  ///
  /// In it, this message translates to:
  /// **'Giorni'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In it, this message translates to:
  /// **'Settimane'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In it, this message translates to:
  /// **'Mesi'**
  String get months;

  /// No description provided for @entryRemoved.
  ///
  /// In it, this message translates to:
  /// **'Registrazione rimossa'**
  String get entryRemoved;

  /// No description provided for @achievementsTitle.
  ///
  /// In it, this message translates to:
  /// **'Obiettivi & Badge'**
  String get achievementsTitle;

  /// No description provided for @unlockedSection.
  ///
  /// In it, this message translates to:
  /// **'SBLOCCATI'**
  String get unlockedSection;

  /// No description provided for @noBadgesYet.
  ///
  /// In it, this message translates to:
  /// **'Registra le prime attività per sbloccare i badge!'**
  String get noBadgesYet;

  /// No description provided for @lockedSection.
  ///
  /// In it, this message translates to:
  /// **'DA SBLOCCARE'**
  String get lockedSection;

  /// No description provided for @allBadgesUnlocked.
  ///
  /// In it, this message translates to:
  /// **'Hai sbloccato tutti i badge! 🎉'**
  String get allBadgesUnlocked;

  /// No description provided for @badgeProgress.
  ///
  /// In it, this message translates to:
  /// **'{unlocked} / {total} badge'**
  String badgeProgress(int unlocked, int total);

  /// No description provided for @setReductionPlan.
  ///
  /// In it, this message translates to:
  /// **'Imposta piano di riduzione'**
  String get setReductionPlan;

  /// No description provided for @planStatusAhead.
  ///
  /// In it, this message translates to:
  /// **'AVANTI'**
  String get planStatusAhead;

  /// No description provided for @planStatusOnTrack.
  ///
  /// In it, this message translates to:
  /// **'IN LINEA'**
  String get planStatusOnTrack;

  /// No description provided for @planStatusBehind.
  ///
  /// In it, this message translates to:
  /// **'IN RITARDO'**
  String get planStatusBehind;

  /// No description provided for @planStatusActive.
  ///
  /// In it, this message translates to:
  /// **'ATTIVO'**
  String get planStatusActive;

  /// No description provided for @reductionPlanSection.
  ///
  /// In it, this message translates to:
  /// **'PIANO DI RIDUZIONE'**
  String get reductionPlanSection;

  /// No description provided for @productLabel.
  ///
  /// In it, this message translates to:
  /// **'Prodotto: {name}'**
  String productLabel(String name);

  /// No description provided for @planStart.
  ///
  /// In it, this message translates to:
  /// **'Inizio'**
  String get planStart;

  /// No description provided for @unitsPerDayShort.
  ///
  /// In it, this message translates to:
  /// **'unità/g'**
  String get unitsPerDayShort;

  /// No description provided for @average7Days.
  ///
  /// In it, this message translates to:
  /// **'Media 7 giorni'**
  String get average7Days;

  /// No description provided for @targetToday.
  ///
  /// In it, this message translates to:
  /// **'Target oggi'**
  String get targetToday;

  /// No description provided for @finalGoal.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo finale'**
  String get finalGoal;

  /// No description provided for @planWeek.
  ///
  /// In it, this message translates to:
  /// **'Settimana {current} / {total}'**
  String planWeek(int current, int total);

  /// No description provided for @planCompleted.
  ///
  /// In it, this message translates to:
  /// **'Completato!'**
  String get planCompleted;

  /// No description provided for @daysRemaining.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{1 giorno rimanente} other{{count} giorni rimanenti}}'**
  String daysRemaining(int count);

  /// No description provided for @planAheadMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei sotto il target settimanale previsto.'**
  String get planAheadMessage;

  /// No description provided for @planOnTrackMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei in linea con il piano attivo.'**
  String get planOnTrackMessage;

  /// No description provided for @planBehindMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei sopra il target settimanale previsto.'**
  String get planBehindMessage;

  /// No description provided for @planActiveMessage.
  ///
  /// In it, this message translates to:
  /// **'Piano attivo su questo prodotto.'**
  String get planActiveMessage;

  /// No description provided for @edit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get edit;

  /// No description provided for @deletePlanTitle.
  ///
  /// In it, this message translates to:
  /// **'Elimina piano'**
  String get deletePlanTitle;

  /// No description provided for @deletePlanBody.
  ///
  /// In it, this message translates to:
  /// **'Vuoi eliminare il piano di riduzione?'**
  String get deletePlanBody;

  /// No description provided for @badgeLockedSemantics.
  ///
  /// In it, this message translates to:
  /// **'{title}, da sbloccare'**
  String badgeLockedSemantics(String title);

  /// No description provided for @badgeUnlockedSemantics.
  ///
  /// In it, this message translates to:
  /// **'{title}, sbloccato il {date}'**
  String badgeUnlockedSemantics(String title, String date);

  /// No description provided for @unlockedOn.
  ///
  /// In it, this message translates to:
  /// **'Sbloccato il {date}'**
  String unlockedOn(String date);

  /// No description provided for @notUnlockedYet.
  ///
  /// In it, this message translates to:
  /// **'Non ancora sbloccato'**
  String get notUnlockedYet;

  /// No description provided for @close.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get close;

  /// No description provided for @average14Days.
  ///
  /// In it, this message translates to:
  /// **'Media degli ultimi 14 giorni: {value} unità/giorno'**
  String average14Days(String value);

  /// No description provided for @finalGoalValue.
  ///
  /// In it, this message translates to:
  /// **'Obiettivo finale: {value} unità/giorno'**
  String finalGoalValue(String value);

  /// No description provided for @planDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata: {count} settimane'**
  String planDuration(int count);

  /// No description provided for @planReductionSummary.
  ///
  /// In it, this message translates to:
  /// **'Riduzione di {value} unità/g in {weeks} settimane.'**
  String planReductionSummary(String value, int weeks);

  /// No description provided for @updatePlan.
  ///
  /// In it, this message translates to:
  /// **'Aggiorna piano'**
  String get updatePlan;

  /// No description provided for @setPlan.
  ///
  /// In it, this message translates to:
  /// **'Imposta piano'**
  String get setPlan;

  /// No description provided for @languageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageEnglish.
  ///
  /// In it, this message translates to:
  /// **'English'**
  String get languageEnglish;
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
