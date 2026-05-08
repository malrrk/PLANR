import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final currentFirebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(currentFirebaseUserProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      return ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return UserProfile.fromMap(doc.data()!);
      });
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

final userProfileByIdProvider =
    StreamProvider.family<UserProfile?, String>((ref, uid) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  });
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
  );
});

class UserProfileService {
  UserProfileService(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String username,
    required String email,
    String? photoUrl,
    String? bio,
    String? backgroundImageUrl,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final profile = UserProfile(
      uid: uid,
      displayName: displayName.trim(),
      username: normalizedUsername,
      usernameLower: normalizedUsername,
      email: email.trim(),
      photoUrl: photoUrl,
      bio: bio,
      backgroundImageUrl: backgroundImageUrl,
    );

    await _firestore.collection('users').doc(uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    String? bio,
    String? photoUrl,
    String? backgroundImageUrl,
  }) async {
    final trimmedDisplayName = displayName.trim();
    final trimmedBio = bio?.trim();

    if (trimmedDisplayName.isEmpty) {
      throw Exception('Display name cannot be empty.');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'displayName': trimmedDisplayName,
        'bio': trimmedBio == null || trimmedBio.isEmpty ? null : trimmedBio,
        'photoUrl': ?photoUrl,
        'backgroundImageUrl': ?backgroundImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('users/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadProfileBackground({
    required String uid,
    required File file,
  }) async {
    final ref = _storage.ref().child('users/$uid/background.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> updatePinnedStoryImageUrls({
    required String uid,
    required List<String> imageUrls,
  }) async {
    if (imageUrls.length > 3) {
      throw Exception('You can only pin up to 3 stories.');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'pinnedStoryImageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    final result = await _firestore
        .collection('users')
        .orderBy('usernameLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(20)
        .get();

    return result.docs
        .map((doc) => UserProfile.fromMap(doc.data()))
        .toList();
  }
}