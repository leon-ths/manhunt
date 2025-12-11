import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/services/lobby_service.dart';

void main() {
  group('LobbyService', () {
    late FakeFirebaseFirestore firestore;
    late LobbyService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = LobbyService(firestore);
    });

    test('createLobby stores lobby document', () async {
      final lobbyId = await service.createLobby(
        hostUid: 'host-123',
        name: 'Test Lobby',
        center: const GeoPoint(48.0, 11.0),
        radiusMeters: 500,
        durationMinutes: 60,
      );

      final snapshot = await firestore.collection('lobbies').doc(lobbyId).get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['name'], 'Test Lobby');
    });

    test('joinLobby writes player into subcollection', () async {
      final lobbyId = await service.createLobby(
        hostUid: 'host-123',
        name: 'Test Lobby',
        center: const GeoPoint(48.0, 11.0),
        radiusMeters: 500,
        durationMinutes: 60,
      );

      final player = GamePlayer(
        uid: 'player-1',
        displayName: 'Player 1',
        isHunter: false,
        isEliminated: false,
        lastPosition: const GeoPoint(0, 0),
        lastUpdate: Timestamp.now(),
      );

      await service.joinLobby(lobbyId: lobbyId, player: player);

      final snapshot = await firestore
          .collection('lobbies')
          .doc(lobbyId)
          .collection('players')
          .doc('player-1')
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['displayName'], 'Player 1');
    });
  });
}
