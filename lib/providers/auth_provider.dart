import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_providers.dart';

/// True while sign-up is creating the account and its profile documents.
final ValueNotifier<bool> signUpInProgress = ValueNotifier<bool>(false);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final authProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final usernameAvailabilityProvider =
    FutureProvider.family<bool, String>((ref, username) async {
  final service = ref.read(authProvider);
  return service.isUsernameAvailable(username);
});

class _UsernameTakenException implements Exception {
  const _UsernameTakenException();
}

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const Set<String> _reservedUsernames = {
    'admin',
    'administrator',
    'support',
    'help',
    'planr',
    'official',
    'team',
    'null',
    'undefined',
    'deleted',
    'unknown',
    'system',
  };

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Username or password is incorrect.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  String? validateUsername(String username) {
    final normalized = normalizeUsername(username);

    if (normalized.isEmpty) {
      return 'Please enter a username.';
    }

    if (normalized.length < 3) {
      return 'Username must be at least 3 characters.';
    }

    if (normalized.length > 20) {
      return 'Username must be at most 20 characters.';
    }

    final validPattern = RegExp(r'^[a-z0-9._]+$');
    if (!validPattern.hasMatch(normalized)) {
      return 'Username can only contain letters, numbers, dots and underscores.';
    }

    if (normalized.startsWith('.') ||
        normalized.endsWith('.') ||
        normalized.startsWith('_') ||
        normalized.endsWith('_')) {
      return 'Username cannot start or end with a dot or underscore.';
    }

    if (normalized.contains('..') || normalized.contains('__')) {
      return 'Username cannot contain repeated dots or underscores.';
    }

    if (_reservedUsernames.contains(normalized)) {
      return 'This username is reserved.';
    }

    return null;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final normalized = normalizeUsername(username);
    final validationError = validateUsername(normalized);

    if (validationError != null) {
      return false;
    }

    final doc = await _firestore.collection('usernames').doc(normalized).get();
    return !doc.exists;
  }

  Future<String?> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final normalizedUsername = normalizeUsername(username);
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty ||
        normalizedUsername.isEmpty ||
        trimmedEmail.isEmpty ||
        trimmedPassword.isEmpty) {
      return 'Please fill in all fields.';
    }

    final usernameError = validateUsername(normalizedUsername);
    if (usernameError != null) {
      return usernameError;
    }

    if (trimmedName.length > 60) {
      return 'Name can be at most 60 characters.';
    }

    signUpInProgress.value = true;
    try {
      final usernameDoc =
          await _firestore.collection('usernames').doc(normalizedUsername).get();

      if (usernameDoc.exists) {
        return 'Username is already taken.';
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final user = credential.user;

      if (user == null) {
        return 'User creation failed.';
      }

      try {
        await user.updateDisplayName(trimmedName);
        await user.reload();

        final userRef = _firestore.collection('users').doc(user.uid);
        final usernameRef =
            _firestore.collection('usernames').doc(normalizedUsername);

        await _firestore.runTransaction((transaction) async {
          final usernameSnapshot = await transaction.get(usernameRef);

          if (usernameSnapshot.exists) {
            throw const _UsernameTakenException();
          }

          transaction.set(usernameRef, {
            'uid': user.uid,
            'username': normalizedUsername,
            'displayName': trimmedName,
            'email': trimmedEmail,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(userRef, {
            'uid': user.uid,
            'displayName': trimmedName,
            'username': normalizedUsername,
            'usernameLower': normalizedUsername,
            'photoUrl': user.photoURL,
            'bio': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        try {
          await user.sendEmailVerification();
        } catch (_) {
          // The profile banner lets users request the email again.
        }

        return null;
      } catch (e) {
        try {
          await user.delete();
        } catch (_) {}

        if (e is _UsernameTakenException) {
          return 'Username is already taken.';
        }

        return 'Could not finish creating your account. Please try again.';
      }
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (_) {
      return 'Something went wrong.';
    } finally {
      signUpInProgress.value = false;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      final identifier = email.trim();
      final trimmedPassword = password.trim();

      if (identifier.isEmpty || trimmedPassword.isEmpty) {
        return 'Please fill in all fields.';
      }

      String loginEmail = identifier;

      final looksLikeEmail = identifier.contains('@');

      if (!looksLikeEmail) {
        final normalizedUsername = normalizeUsername(identifier);

        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(normalizedUsername)
            .get();

        if (!usernameDoc.exists || usernameDoc.data() == null) {
          return 'No account found with this username.';
        }

        final foundEmail = usernameDoc.data()!['email'] as String?;

        if (foundEmail == null || foundEmail.isEmpty) {
          return 'No email found for this username.';
        }

        loginEmail = foundEmail;
      }

      await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: trimmedPassword,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e);
    } catch (_) {
      return 'Something went wrong.';
    }
  }

  Future<String?> resetPassword({required String email}) async {
    final trimmedEmail = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address.';
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') return null;
      return _authErrorMessage(error);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}