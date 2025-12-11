import 'package:cloud_firestore/cloud_firestore.dart';

class GameLobby {
  final String id;
  final String hostUid;
  final String name;
  final double radiusMeters;
  final GeoPoint center;
  final int durationMinutes;
  final int pingIntervalMinutes;
  final int speedhuntCooldownMinutes;
  final Timestamp createdAt;
  final String status; // lobby, running, finished

  const GameLobby({
    required this.id,
    required this.hostUid,
    required this.name,
    required this.radiusMeters,
    required this.center,
    required this.durationMinutes,
    required this.pingIntervalMinutes,
    required this.speedhuntCooldownMinutes,
    required this.createdAt,
    required this.status,
  });

  factory GameLobby.fromMap(String id, Map<String, dynamic> data) {
    return GameLobby(
      id: id,
      hostUid: data['hostUid'] as String,
      name: data['name'] as String,
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      center: data['center'] as GeoPoint,
      durationMinutes: data['durationMinutes'] as int,
      pingIntervalMinutes: data['pingIntervalMinutes'] as int,
      speedhuntCooldownMinutes: data['speedhuntCooldownMinutes'] as int,
      createdAt: data['createdAt'] as Timestamp,
      status: data['status'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'hostUid': hostUid,
        'name': name,
        'radiusMeters': radiusMeters,
        'center': center,
        'durationMinutes': durationMinutes,
        'pingIntervalMinutes': pingIntervalMinutes,
        'speedhuntCooldownMinutes': speedhuntCooldownMinutes,
        'createdAt': createdAt,
        'status': status,
      };
}
