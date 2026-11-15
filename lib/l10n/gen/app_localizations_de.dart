// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Planr';

  @override
  String get navHome => 'Start';

  @override
  String get navDiscover => 'Entdecken';

  @override
  String get navCreate => 'Erstellen';

  @override
  String get navChats => 'Chats';

  @override
  String get navProfile => 'Profil';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get continueAction => 'Weiter';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get somethingWentWrong =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get couldNotLoad => 'Laden fehlgeschlagen';

  @override
  String get tryAgainLater => 'Bitte versuche es später erneut.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSubtitle => 'Deine PLANR-Identität';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get editProfileTitle => 'Profil bearbeiten';

  @override
  String get editProfileSubtitle => 'Foto, Hintergrund und Bio';

  @override
  String get profileCardTitle => 'Profil';

  @override
  String get profileCardSubtitle => 'Deine öffentlichen Angaben';

  @override
  String get socialTitle => 'Soziales';

  @override
  String get socialSubtitle => 'Personen und Anfragen';

  @override
  String get friendsTitle => 'Freunde';

  @override
  String get friendsSubtitle => 'Dein Kreis';

  @override
  String get findFriendsTitle => 'Freunde finden';

  @override
  String get findFriendsSubtitle => 'Nach Benutzername suchen';

  @override
  String get friendRequestsTitle => 'Freundschaftsanfragen';

  @override
  String get friendRequestsSubtitle => 'Neue Kontakte annehmen';

  @override
  String get verifyEmailTitle => 'E-Mail bestätigen';

  @override
  String get verifyEmailBody =>
      'Wir haben dir einen Link an deine E-Mail-Adresse geschickt. Öffne ihn, um dieses Konto zu bestätigen.';

  @override
  String get resendEmail => 'E-Mail erneut senden';

  @override
  String get iVerifiedIt => 'Ich habe bestätigt';

  @override
  String get verificationEmailSent => 'Bestätigungs-E-Mail gesendet.';

  @override
  String get emailVerifiedThanks => 'E-Mail bestätigt. Danke!';

  @override
  String get notVerifiedYet => 'Noch nicht bestätigt.';

  @override
  String get waitBeforeRetry =>
      'Bitte warte einen Moment, bevor du es erneut versuchst.';

  @override
  String get settingsPreferences => 'Präferenzen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get notifyInvitations => 'Einladungen zu Events';

  @override
  String get notifyInvitationsHint =>
      'Offene Einladungen in deinen Benachrichtigungen anzeigen';

  @override
  String get notifyFriendRequests => 'Freundschaftsanfragen';

  @override
  String get notifyFriendRequestsHint =>
      'Offene Freundschaftsanfragen in deinen Benachrichtigungen anzeigen';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsEmail => 'E-Mail';

  @override
  String get emailVerified => 'Bestätigt';

  @override
  String get emailNotVerified => 'Nicht bestätigt';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get resetPasswordHint =>
      'Link zum Zurücksetzen an deine E-Mail senden';

  @override
  String get resetPasswordSent =>
      'Falls zu dieser E-Mail ein Konto existiert, wurde ein Link zum Zurücksetzen gesendet.';

  @override
  String get logOut => 'Abmelden';

  @override
  String get logOutHint => 'Dieses Gerät verlassen';

  @override
  String get logOutConfirmTitle => 'Abmelden?';

  @override
  String get logOutConfirmBody => 'Möchtest du dich wirklich abmelden?';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountHint => 'Deine Daten dauerhaft entfernen';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountBody =>
      'Dadurch werden dein Profil, deine Events, Stories und Freundschaften dauerhaft gelöscht.';

  @override
  String get deleteAccountFinalTitle => 'Bist du sicher?';

  @override
  String get deleteAccountFinalBody =>
      'Das Löschen deines Kontos ist endgültig und kann nicht rückgängig gemacht werden.';

  @override
  String get deletePermanently => 'Endgültig löschen';

  @override
  String get confirmWithPassword => 'Mit deinem Passwort bestätigen';

  @override
  String get enterPassword => 'Gib dein Passwort ein.';

  @override
  String get settingsPrivacy => 'Datenschutz & Sicherheit';

  @override
  String get blockedUsersTitle => 'Blockierte Nutzer';

  @override
  String get blockedUsersHint => 'Verwalte, wen du blockiert hast';

  @override
  String get noBlockedUsers => 'Keine blockierten Nutzer';

  @override
  String get noBlockedUsersHint =>
      'Personen, die du blockierst, erscheinen hier.';

  @override
  String get unblock => 'Entblocken';

  @override
  String get unknownUser => 'Unbekannter Nutzer';

  @override
  String userUnblocked(String name) {
    return '$name wurde entblockt.';
  }

  @override
  String get settingsHelp => 'Hilfe & Rechtliches';

  @override
  String get termsAndPrivacy => 'Nutzungsbedingungen & Datenschutz';

  @override
  String get termsAndPrivacyHint => 'Community-Regeln und deine Daten';

  @override
  String supportContact(String email) {
    return 'Support: $email';
  }

  @override
  String get supportContactMissing =>
      'Support und Problemmeldungen sind noch nicht verfügbar.';

  @override
  String get appVersion => 'App-Version';

  @override
  String get findFriendsScreenTitle => 'Freunde finden';

  @override
  String get discoverPeople => 'Personen entdecken';

  @override
  String get discoverPeopleHint =>
      'Suche nach Benutzernamen und sende Freundschaftsanfragen.';

  @override
  String get searchUsername => 'Benutzername suchen';

  @override
  String get searchByUsername => 'Nach Benutzername suchen';

  @override
  String get searchByUsernameHint =>
      'Beginne einen Benutzernamen einzugeben, um Personen auf PLANR zu finden.';

  @override
  String get noUsersFound => 'Keine Nutzer gefunden';

  @override
  String get noUsersFoundHint =>
      'Versuche einen anderen Benutzernamen oder prüfe die Schreibweise.';

  @override
  String get searchFailed => 'Suche fehlgeschlagen';

  @override
  String get searchFailedHint =>
      'Prüfe deine Verbindung und versuche es erneut.';

  @override
  String searchResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
    );
    return '$_temp0';
  }

  @override
  String get createEventTitle => 'Event erstellen';
}
