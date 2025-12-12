import 'package:cloud_firestore/cloud_firestore.dart';

class GameLobby {
  final String id;
  final String hostUid;
  final String name;
  final double radiusMeters;
  final GeoPoint center;
  final int durationMinutes;
  final int pingIntervalMinutes;
  final int escapeMinutes;
  final bool functionsEnabled;
  final String playAreaMode;
  final List<GeoPoint> polygon;
  final Timestamp createdAt;
  final String status; // lobby, running, finished
  final Timestamp? startedAt;

  const GameLobby({
    required this.id,
    required this.hostUid,
    required this.name,
    required this.radiusMeters,
    required this.center,
    required this.durationMinutes,
    required this.pingIntervalMinutes,
    required this.escapeMinutes,
    required this.functionsEnabled,
    required this.playAreaMode,
    required this.polygon,
    required this.createdAt,
    required this.status,
    this.startedAt,
  });

  factory GameLobby.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return GameLobby(
      id: doc.id,
      hostUid: data['hostUid'] as String,
      name: data['name'] as String,
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      center: data['center'] as GeoPoint,
      durationMinutes: (data['durationMinutes'] as num).toInt(),
      pingIntervalMinutes: (data['pingIntervalMinutes'] as num?)?.toInt() ?? 5,
      escapeMinutes: (data['escapeMinutes'] as num?)?.toInt() ?? 2,
      functionsEnabled: data['functionsEnabled'] as bool? ?? false,
      playAreaMode: data['playAreaMode'] as String? ?? 'circle',
      polygon: ((data['polygon'] as List<dynamic>?) ?? [])
          .map((p) => p as GeoPoint)
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      status: data['status'] as String,
      startedAt: data['startedAt'] as Timestamp?,
    );
  }

  factory GameLobby.fromMap(String id, Map<String, dynamic> data) {
    return GameLobby(
      id: id,
      hostUid: data['hostUid'] as String,
      name: data['name'] as String,
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      center: data['center'] as GeoPoint,
      durationMinutes: (data['durationMinutes'] as num).toInt(),
      pingIntervalMinutes: (data['pingIntervalMinutes'] as num?)?.toInt() ?? 5,
      escapeMinutes: (data['escapeMinutes'] as num?)?.toInt() ?? 2,
      functionsEnabled: data['functionsEnabled'] as bool? ?? false,
      playAreaMode: data['playAreaMode'] as String? ?? 'circle',
      polygon: ((data['polygon'] as List<dynamic>?) ?? [])
          .map((p) => p as GeoPoint)
          .toList(),
      createdAt: data['createdAt'] as Timestamp,
      status: data['status'] as String,
      startedAt: data['startedAt'] as Timestamp?,
    );
  }
}
