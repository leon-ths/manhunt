import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  FriendService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFriendRequests(String uid) {
    return _firestore.collection('users').doc(uid).collection('friendRequests').snapshots();
  }

  Future<void> sendFriendRequest({required String toUsername}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final query = await _firestore
        .collection('users')
        .where('usernameLower', isEqualTo: toUsername.toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Kein Spieler mit diesem Benutzernamen gefunden.');
    }
    final targetDoc = query.docs.first.reference;
    await targetDoc.collection('friendRequests').doc(currentUser.uid).set({
      'fromUid': currentUser.uid,
      'fromName': currentUser.displayName ?? 'Unbekannt',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToRequest({required String requestUid, required bool accepted}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final userRef = _firestore.collection('users').doc(currentUser.uid);
    final requestRef = userRef.collection('friendRequests').doc(requestUid);
    await _firestore.runTransaction((txn) async {
      final requestSnap = await txn.get(requestRef);
      if (!requestSnap.exists) return;
      txn.delete(requestRef);
      if (!accepted) return;
      final otherRef = _firestore.collection('users').doc(requestUid);
      txn.update(userRef, {
        'friends': FieldValue.arrayUnion([requestUid]),
      });
      txn.update(otherRef, {
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });
    });
  }
}

