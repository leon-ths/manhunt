import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manhunt/models/game_lobby.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:uuid/uuid.dart';

class LobbyService {
  LobbyService(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Future<String> createLobby({
    required String hostUid,
    required String name,
    required GeoPoint center,
    required double radiusMeters,
    required int durationMinutes,
    int pingIntervalMinutes = 5,
    int speedhuntCooldownMinutes = 15,
  }) async {
    final lobbyRef = _firestore.collection('lobbies').doc();
    final inviteCode = _uuid.v4().substring(0, 6).toUpperCase();
    await lobbyRef.set({
      'hostUid': hostUid,
      'name': name,
      'inviteCode': inviteCode,
      'radiusMeters': radiusMeters,
      'center': center,
      'durationMinutes': durationMinutes,
      'pingIntervalMinutes': pingIntervalMinutes,
      'speedhuntCooldownMinutes': speedhuntCooldownMinutes,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'lobby',
    });
    return lobbyRef.id;
  }

  Future<void> joinLobby({
    required String lobbyId,
    required GamePlayer player,
  }) async {
    final playerRef = _firestore
        .collection('lobbies')
        .doc(lobbyId)
        .collection('players')
        .doc(player.uid);
    await playerRef.set(player.toMap());
  }

  Future<void> updateRole({
    required String lobbyId,
    required String playerUid,
    required bool isHunter,
  }) async {
    final playerRef = _firestore
        .collection('lobbies')
        .doc(lobbyId)
        .collection('players')
        .doc(playerUid);
    await playerRef.update({'isHunter': isHunter});
  }

  Stream<List<GameLobby>> watchLobbies() {
    return _firestore.collection('lobbies').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => GameLobby.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<GamePlayer>> watchPlayers(String lobbyId) {
    return _firestore
        .collection('lobbies')
        .doc(lobbyId)
        .collection('players')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => GamePlayer.fromMap(doc.data())).toList(),
        );
  }
}
