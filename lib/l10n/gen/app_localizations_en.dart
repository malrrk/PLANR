// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Planr';

  @override
  String get navHome => 'Home';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navCreate => 'Create';

  @override
  String get navChats => 'Chats';

  @override
  String get navProfile => 'Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get retry => 'Retry';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get couldNotLoad => 'Could not load';

  @override
  String get tryAgainLater => 'Please try again later.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Your PLANR identity';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileSubtitle => 'Photo, background and bio';

  @override
  String get profileCardTitle => 'Profile';

  @override
  String get profileCardSubtitle => 'Your public details';

  @override
  String get socialTitle => 'Social';

  @override
  String get socialSubtitle => 'People and requests';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsSubtitle => 'See your circle';

  @override
  String get findFriendsTitle => 'Find friends';

  @override
  String get findFriendsSubtitle => 'Search by username';

  @override
  String get friendRequestsTitle => 'Friend requests';

  @override
  String get friendRequestsSubtitle => 'Accept new connections';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String get verifyEmailBody =>
      'We sent a link to your email address. Open it to confirm this account.';

  @override
  String get resendEmail => 'Resend email';

  @override
  String get iVerifiedIt => 'I verified it';

  @override
  String get verificationEmailSent => 'Verification email sent.';

  @override
  String get emailVerifiedThanks => 'Email verified. Thank you!';

  @override
  String get notVerifiedYet => 'Not verified yet.';

  @override
  String get waitBeforeRetry => 'Please wait a moment before trying again.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get notifyInvitations => 'Event invitations';

  @override
  String get notifyInvitationsHint =>
      'Show pending invitations in your notifications';

  @override
  String get notifyFriendRequests => 'Friend requests';

  @override
  String get notifyFriendRequestsHint =>
      'Show pending friend requests in your notifications';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsEmail => 'Email';

  @override
  String get emailVerified => 'Verified';

  @override
  String get emailNotVerified => 'Not verified';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordHint => 'Send a reset link to your email';

  @override
  String get resetPasswordSent =>
      'If an account exists for this email, a reset link has been sent.';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutHint => 'Leave this device';

  @override
  String get logOutConfirmTitle => 'Log out?';

  @override
  String get logOutConfirmBody => 'Are you sure you want to log out?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint => 'Permanently remove your data';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your profile, your events, stories and friendships.';

  @override
  String get deleteAccountFinalTitle => 'Are you sure?';

  @override
  String get deleteAccountFinalBody =>
      'Deleting your account is permanent and cannot be undone.';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get confirmWithPassword => 'Confirm with your password';

  @override
  String get enterPassword => 'Enter your password.';

  @override
  String get settingsPrivacy => 'Privacy & safety';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get blockedUsersHint => 'Manage who you blocked';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get noBlockedUsersHint => 'People you block will show up here.';

  @override
  String get unblock => 'Unblock';

  @override
  String get unknownUser => 'Unknown user';

  @override
  String userUnblocked(String name) {
    return '$name is unblocked.';
  }

  @override
  String get settingsHelp => 'Help & legal';

  @override
  String get termsAndPrivacy => 'Terms & Privacy';

  @override
  String get termsAndPrivacyHint => 'Community rules and your data';

  @override
  String supportContact(String email) {
    return 'Support: $email';
  }

  @override
  String get supportContactMissing =>
      'Support and problem reports are not available yet.';

  @override
  String get appVersion => 'App version';

  @override
  String get findFriendsScreenTitle => 'Find Friends';

  @override
  String get discoverPeople => 'Discover people';

  @override
  String get discoverPeopleHint => 'Search usernames and send friend requests.';

  @override
  String get searchUsername => 'Search username';

  @override
  String get searchByUsername => 'Search by username';

  @override
  String get searchByUsernameHint =>
      'Start typing a username to find people on PLANR.';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get noUsersFoundHint => 'Try another username or check the spelling.';

  @override
  String get searchFailed => 'Could not search users';

  @override
  String get searchFailedHint => 'Check your connection and try again.';

  @override
  String searchResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get createEventTitle => 'Create Event';
}
