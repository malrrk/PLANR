import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'firebase_providers.dart';

export 'firebase_providers.dart';

final currentFirebaseUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
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

/// A failure whose message is safe to show to the user.
class ProfileException implements Exception {
  const ProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserProfileService {
  UserProfileService(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const int maxDisplayNameLength = 60;
  static const int maxBioLength = 300;

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
      throw const ProfileException('Display name is required.');
    }

    if (trimmedDisplayName.length > maxDisplayNameLength) {
      throw const ProfileException(
        'Display name can be at most $maxDisplayNameLength characters.',
      );
    }

    if (trimmedBio != null && trimmedBio.length > maxBioLength) {
      throw const ProfileException(
        'Bio can be at most $maxBioLength characters.',
      );
    }

    final data = <String, dynamic>{
      'uid': uid,
      'displayName': trimmedDisplayName,
      'bio': trimmedBio == null || trimmedBio.isEmpty ? null : trimmedBio,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    if (backgroundImageUrl != null) {
      data['backgroundImageUrl'] = backgroundImageUrl;
    }

    await _firestore.collection('users').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('users/$uid/profile.jpg');

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'ownerUid': uid,
            'kind': 'profilePhoto',
          },
        ),
      );

      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized') {
        throw const ProfileException('Profile photo upload is not allowed.');
      }

      throw const ProfileException('Profile photo upload failed.');
    }
  }

  Future<String> uploadProfileBackground({
    required String uid,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('users/$uid/background.jpg');

      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'ownerUid': uid,
            'kind': 'profileBackground',
          },
        ),
      );

      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized') {
        throw const ProfileException('Background upload is not allowed.');
      }

      throw const ProfileException('Background upload failed.');
    }
  }

  Future<void> updatePinnedStoryImageUrls({
    required String uid,
    required List<String> imageUrls,
  }) async {
    if (imageUrls.length > 3) {
      throw const ProfileException('You can only pin up to 3 stories.');
    }

    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'pinnedStoryImageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Refreshes the copies of this profile other people see (friend lists, attendee lists,
  /// event hosts, stories). Best effort: a failed copy never fails the profile save.
  Future<void> propagateProfileChange({
    required String uid,
    required String displayName,
    String? bio,
    String? photoUrl,
    String? backgroundImageUrl,
  }) async {
    final friendCopy = <String, dynamic>{
      'displayName': displayName,
      'bio': bio,
      'photoUrl': ?photoUrl,
      'backgroundImageUrl': ?backgroundImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final attendeeCopy = <String, dynamic>{
      'displayName': displayName,
      'photoUrl': ?photoUrl,
    };
    final hostCopy = <String, dynamic>{
      'creatorDisplayName': displayName,
      'creatorPhotoUrl': ?photoUrl,
    };
    final profileHostCopy = <String, dynamic>{
      ...hostCopy,
      'organizerDisplayName': displayName,
      'organizerPhotoUrl': ?photoUrl,
    };
    final storyCopy = <String, dynamic>{
      'ownerDisplayName': displayName,
      'ownerPhotoUrl': ?photoUrl,
    };

    final tasks = <Future<void> Function()>[];

    Future<void> Function() update(
      DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data,
    ) {
      return () async {
        try {
          await ref.update(data);
        } catch (_) {}
      };
    }

    try {
      final friends =
          await _firestore.collection('users').doc(uid).collection('friends').get();
      for (final friend in friends.docs) {
        tasks.add(update(
          _firestore
              .collection('users')
              .doc(friend.id)
              .collection('friends')
              .doc(uid),
          friendCopy,
        ));
      }

      final myEvents =
          await _firestore.collection('users').doc(uid).collection('my_events').get();
      for (final doc in myEvents.docs) {
        final eventRef = _firestore.collection('events').doc(doc.id);

        tasks.add(update(eventRef.collection('attendees').doc(uid), attendeeCopy));

        if (doc.data()['creatorUid'] != uid) continue;

        final hostFields =
            doc.data()['organizerType'] == 'profile' ? profileHostCopy : hostCopy;

        tasks.add(update(eventRef, hostFields));

        final attendees = await eventRef.collection('attendees').get();
        for (final attendee in attendees.docs) {
          tasks.add(update(
            _firestore
                .collection('users')
                .doc(attendee.id)
                .collection('my_events')
                .doc(doc.id),
            hostFields,
          ));
        }
      }

      final stories = await _firestore
          .collection('stories')
          .where('ownerUid', isEqualTo: uid)
          .where('ownerType', isEqualTo: 'user')
          .get();
      for (final story in stories.docs) {
        tasks.add(update(story.reference, storyCopy));
      }
    } catch (_) {
      // Fall through: copies that were collected are still refreshed.
    }

    const parallel = 15;
    for (var i = 0; i < tasks.length; i += parallel) {
      final end = i + parallel > tasks.length ? tasks.length : i + parallel;
      await Future.wait(tasks.sublist(i, end).map((task) => task()));
    }
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