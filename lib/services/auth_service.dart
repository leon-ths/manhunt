import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  Future<UserCredential> signInAnonymously() {
    return _firebaseAuth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
