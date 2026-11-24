# PLANR

Flutter app (Riverpod state, Firebase backend) for creating and discovering events, friends, stories, and public pages.

## Requirements

- Flutter stable with Dart `^3.11.3`
- A Firebase project (Auth, Cloud Firestore, Storage); platform options are in `lib/firebase_options.dart`
- Node 20 for the Cloud Functions in `functions/`

## Run

```
flutter pub get
flutter run
```

## Test and analyze

```
flutter test
dart analyze lib test
```

Tests currently cover the data models and their handling of older Firestore documents.

## Structure

- `lib/models` - data classes and Firestore (de)serialization
- `lib/providers` - Riverpod providers and Firebase-backed services
  - `firebase_providers.dart` exposes the shared Firebase instances
- `lib/screens`, `lib/widgets` - UI
- `lib/core` - theme and shared widgets
- `functions` - Firebase Cloud Functions (TypeScript)

## Cloud Functions

```
cd functions
npm install
npm run build
firebase deploy --only functions
```

The Flutter client currently accepts friend requests itself and does not call the `acceptFriendRequest` function.

## Home and announcements

Home shows upcoming plans, a hosting filter, saved events, followed pages, and event suggestions. Public events you attend or manage appear in Chats as organizer-only announcement channels; private plan chats remain separate. Announcement read positions are stored per user under `users/{uid}/announcement_reads` and require the corresponding Firestore rules to be deployed.

## Known gaps

- Firestore and Storage security rules are stored in this repository; verify and deploy them to the intended Firebase project before release.
- Private story metadata is audience-restricted, but story image access and download URLs do not yet enforce the same audience. Do not rely on private story media for confidentiality until this is addressed.
- Sign-in uses email and password. Older app versions that use username sign-in need to be updated, and existing username documents containing email need to be cleaned up.
- Image uploads use `dart:io` files and are not web compatible yet.
- Android and iOS identifiers still use the `com.example` template values. Configure a release keystore in `android/key.properties`; release builds no longer fall back to debug signing.
