import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manhunt/models/game_lobby.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:uuid/uuid.dart';

class LobbyService {
  LobbyService(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _lobbyCollection => _firestore.collection('lobbies');

  Future<String> createLobby({
    required String hostUid,
    required String name,
    required GeoPoint center,
    required double radiusMeters,
    required int durationMinutes,
    int pingIntervalMinutes = 5,
    int escapeMinutes = 2,
    bool functionsEnabled = false,
    String playAreaMode = 'circle',
    List<GeoPoint>? polygon,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Lobby benötigt einen Namen.');
    }
    if (radiusMeters <= 0) {
      throw ArgumentError('Radius muss größer als 0 sein.');
    }
    if (durationMinutes <= 0) {
      throw ArgumentError('Spielzeit muss größer als 0 sein.');
    }
    if (playAreaMode == 'polygon' && (polygon == null || polygon.length < 3)) {
      throw ArgumentError('Polygon-Fläche benötigt mindestens drei Punkte.');
    }
    final doc = await _lobbyCollection.add({
      'hostUid': hostUid,
      'name': name,
      'center': center,
      'radiusMeters': radiusMeters,
      'durationMinutes': durationMinutes,
      'pingIntervalMinutes': pingIntervalMinutes,
      'escapeMinutes': escapeMinutes,
      'functionsEnabled': functionsEnabled,
      'playAreaMode': playAreaMode,
      'polygon': polygon,
      'status': 'lobby',
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
    });
    return doc.id;
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
    return _lobbyCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => GameLobby.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<GameLobby> watchLobby(String lobbyId) => _lobbyCollection
      .doc(lobbyId)
      .snapshots()
      .map((doc) => GameLobby.fromMap(doc.id, doc.data()!));

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

  Future<void> leaveLobby({required String lobbyId, required String playerUid}) async {
    final playerRef = _lobbyCollection.doc(lobbyId).collection('players').doc(playerUid);
    await playerRef.delete();
  }

  Future<void> updateLobbySettings({
    required String lobbyId,
    required int pingIntervalMinutes,
    required double radiusMeters,
    required int escapeMinutes,
  }) async {
    await _lobbyCollection.doc(lobbyId).update({
      'pingIntervalMinutes': pingIntervalMinutes,
      'radiusMeters': radiusMeters,
      'escapeMinutes': escapeMinutes,
    });
  }

  Future<void> startLobby(String lobbyId) async {
    await _lobbyCollection.doc(lobbyId).update({
      'status': 'running',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }
}
