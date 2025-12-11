import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhunt/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('signInWithEmail delegates to FirebaseAuth', () async {
      final mockAuth = MockFirebaseAuth();
      final service = AuthService(mockAuth);

      await service.registerWithEmail(email: 'user@test.de', password: 'pass123');
      final credential = await service.signInWithEmail(email: 'user@test.de', password: 'pass123');

      expect(credential.user, isNotNull);
      expect(credential.user!.email, 'user@test.de');
    });

    test('signOut clears current user', () async {
      final mockAuth = MockFirebaseAuth(signedIn: true);
      final service = AuthService(mockAuth);

      await service.signOut();

      expect(mockAuth.currentUser, isNull);
    });
  });
}

