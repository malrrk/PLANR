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

## Known gaps

- Firestore and Storage security rules are not stored in this repository; verify the deployed rules before release.
- Image uploads use `dart:io` files and are not web compatible yet.
- Android and iOS identifiers still use the `com.example` template values, and Android release builds use debug signing.
