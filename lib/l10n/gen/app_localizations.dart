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
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Planr'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get navCreate;

  /// No description provided for @navMyPlanr.
  ///
  /// In en, this message translates to:
  /// **'MyPlanr'**
  String get navMyPlanr;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoad;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get tryAgainLater;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your PLANR identity'**
  String get profileSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photo, background and bio'**
  String get editProfileSubtitle;

  /// No description provided for @profileCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileCardTitle;

  /// No description provided for @profileCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your public details'**
  String get profileCardSubtitle;

  /// No description provided for @socialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialTitle;

  /// No description provided for @socialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People and requests'**
  String get socialSubtitle;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// No description provided for @friendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See your circle'**
  String get friendsSubtitle;

  /// No description provided for @findFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find friends'**
  String get findFriendsTitle;

  /// No description provided for @findFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search by username'**
  String get findFriendsSubtitle;

  /// No description provided for @friendRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequestsTitle;

  /// No description provided for @friendRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept new connections'**
  String get friendRequestsSubtitle;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to your email address. Open it to confirm this account.'**
  String get verifyEmailBody;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// No description provided for @iVerifiedIt.
  ///
  /// In en, this message translates to:
  /// **'I verified it'**
  String get iVerifiedIt;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get verificationEmailSent;

  /// No description provided for @emailVerifiedThanks.
  ///
  /// In en, this message translates to:
  /// **'Email verified. Thank you!'**
  String get emailVerifiedThanks;

  /// No description provided for @notVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet.'**
  String get notVerifiedYet;

  /// No description provided for @waitBeforeRetry.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment before trying again.'**
  String get waitBeforeRetry;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notifyInvitations.
  ///
  /// In en, this message translates to:
  /// **'Event invitations'**
  String get notifyInvitations;

  /// No description provided for @notifyInvitationsHint.
  ///
  /// In en, this message translates to:
  /// **'Show pending invitations in your notifications'**
  String get notifyInvitationsHint;

  /// No description provided for @notifyFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get notifyFriendRequests;

  /// No description provided for @notifyFriendRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Show pending friend requests in your notifications'**
  String get notifyFriendRequestsHint;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get emailVerified;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get emailNotVerified;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Send a reset link to your email'**
  String get resetPasswordHint;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link has been sent.'**
  String get resetPasswordSent;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutHint.
  ///
  /// In en, this message translates to:
  /// **'Leave this device'**
  String get logOutHint;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirmBody;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your data'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your profile, your events, stories and friendships.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteAccountFinalTitle;

  /// No description provided for @deleteAccountFinalBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent and cannot be undone.'**
  String get deleteAccountFinalBody;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @confirmWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm with your password'**
  String get confirmWithPassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPassword;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & safety'**
  String get settingsPrivacy;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// No description provided for @blockedUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Manage who you blocked'**
  String get blockedUsersHint;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @noBlockedUsersHint.
  ///
  /// In en, this message translates to:
  /// **'People you block will show up here.'**
  String get noBlockedUsersHint;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get unknownUser;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'{name} is unblocked.'**
  String userUnblocked(String name);

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & legal'**
  String get settingsHelp;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsAndPrivacy;

  /// No description provided for @termsAndPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Community rules and your data'**
  String get termsAndPrivacyHint;

  /// No description provided for @supportContact.
  ///
  /// In en, this message translates to:
  /// **'Support: {email}'**
  String supportContact(String email);

  /// No description provided for @supportContactMissing.
  ///
  /// In en, this message translates to:
  /// **'Support and problem reports are not available yet.'**
  String get supportContactMissing;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @findFriendsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Friends'**
  String get findFriendsScreenTitle;

  /// No description provided for @discoverPeople.
  ///
  /// In en, this message translates to:
  /// **'Discover people'**
  String get discoverPeople;

  /// No description provided for @discoverPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Search usernames and send friend requests.'**
  String get discoverPeopleHint;

  /// No description provided for @searchUsername.
  ///
  /// In en, this message translates to:
  /// **'Search username'**
  String get searchUsername;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by username'**
  String get searchByUsername;

  /// No description provided for @searchByUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing a username to find people on PLANR.'**
  String get searchByUsernameHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @noUsersFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Try another username or check the spelling.'**
  String get noUsersFoundHint;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not search users'**
  String get searchFailed;

  /// No description provided for @searchFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get searchFailedHint;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String searchResults(int count);

  /// No description provided for @createEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEventTitle;
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
