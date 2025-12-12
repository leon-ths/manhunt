import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._firebaseAuth, this._firestore);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(username);
    await _firestore.collection('users').doc(credential.user?.uid).set({
      'username': username,
      'usernameLower': username.toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
      'wins': 0,
      'distanceMeters': 0,
      'friends': <String>[],
    });
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> signInAnonymously() => _firebaseAuth.signInAnonymously();
}
