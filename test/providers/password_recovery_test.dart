import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner_app/providers/auth_provider.dart';

class RecordingFirebaseAuth extends Fake implements FirebaseAuth {
  String? submittedEmail;
  FirebaseAuthException? failure;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    submittedEmail = email;
    if (failure != null) throw failure!;
  }
}

class UnusedFirestore extends Fake implements FirebaseFirestore {}

void main() {
  late RecordingFirebaseAuth auth;
  late AuthService service;

  setUp(() {
    auth = RecordingFirebaseAuth();
    service = AuthService(auth, UnusedFirestore());
  });

  test('trims email before requesting a reset link', () async {
    expect(await service.resetPassword(email: ' alex@example.com '), isNull);
    expect(auth.submittedEmail, 'alex@example.com');
  });

  test('does not send requests for empty or malformed email', () async {
    for (final email in ['', 'alex', '@example.com', 'alex@']) {
      expect(await service.resetPassword(email: email), isNotNull);
    }
    expect(auth.submittedEmail, isNull);
  });

  test('does not reveal whether an email belongs to an account', () async {
    auth.failure = FirebaseAuthException(code: 'user-not-found');
    expect(await service.resetPassword(email: 'alex@example.com'), isNull);
  });

  test('reports network errors', () async {
    auth.failure = FirebaseAuthException(code: 'network-request-failed');
    expect(
      await service.resetPassword(email: 'alex@example.com'),
      'Network error. Please check your connection.',
    );
  });
}