import 'package:cloud_firestore/cloud_firestore.dart';

class GamePlayer {
  final String uid;
  final String displayName;
  final bool isHunter;
  final bool isEliminated;
  final GeoPoint lastPosition;
  final Timestamp lastUpdate;

  const GamePlayer({
    required this.uid,
    required this.displayName,
    required this.isHunter,
    required this.isEliminated,
    required this.lastPosition,
    required this.lastUpdate,
  });

  factory GamePlayer.fromMap(Map<String, dynamic> data) {
    return GamePlayer(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String,
      isHunter: data['isHunter'] as bool,
      isEliminated: data['isEliminated'] as bool,
      lastPosition: data['lastPosition'] as GeoPoint,
      lastUpdate: data['lastUpdate'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'isHunter': isHunter,
    'isEliminated': isEliminated,
    'lastPosition': lastPosition,
    'lastUpdate': lastUpdate,
  };
}
