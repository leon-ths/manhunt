import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhunt/services/auth_service.dart';

void main() {
  test('signInWithEmail calls FirebaseAuth', () async {
    final mockAuth = MockFirebaseAuth();
    final mockFirestore = FakeFirebaseFirestore();
    final service = AuthService(mockAuth, mockFirestore);
    await service.registerWithEmail(email: 'test@test.de', password: '123456', username: 'user');
    expect(mockAuth.currentUser, isNotNull);
  });
}
