import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:manhunt/services/location_service.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({required this.lobbyId, super.key});

  final String lobbyId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  ll.LatLng _center = const ll.LatLng(48.137154, 11.576124);
  double _radiusMeters = 500;
  int _pingIntervalMinutes = 5;
  Timer? _pingTimer;
  bool _speedhuntLoading = false;
  bool _functionsAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadLobbyMeta();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLobbyMeta() async {
    final lobbyDoc = await FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.lobbyId)
        .get();
    if (!lobbyDoc.exists) return;
    final data = lobbyDoc.data()!;
    setState(() {
      final geoPoint = data['center'] as GeoPoint;
      _center = ll.LatLng(geoPoint.latitude, geoPoint.longitude);
      _radiusMeters = (data['radiusMeters'] as num).toDouble();
      _pingIntervalMinutes = (data['pingIntervalMinutes'] as num?)?.toInt() ?? 5;
      _functionsAvailable = data['functionsEnabled'] as bool? ?? true;
    });
    _startPingTimer();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    if (_pingIntervalMinutes <= 0) return;
    _sendSilentPing();
    _pingTimer = Timer.periodic(
      Duration(minutes: _pingIntervalMinutes),
      (_) => _sendSilentPing(),
    );
  }

  Future<void> _sendSilentPing() async {
    if (!_functionsAvailable) {
      debugPrint('Silent ping skipped: Cloud Functions disabled for this lobby.');
      return;
    }
    try {
      await FirebaseFunctions.instance
          .httpsCallable('triggerSilentPing')
          .call({'lobbyId': widget.lobbyId});
    } on FirebaseFunctionsException catch (error, stack) {
      if (error.code == 'not-found') {
        _handleFunctionsUnavailable(stack);
        return;
      }
      debugPrint('Silent ping failed: $error');
      debugPrint('$stack');
    } catch (error, stack) {
      debugPrint('Silent ping failed: $error');
      debugPrint('$stack');
    }
  }

  Future<void> _triggerSpeedhunt() async {
    if (!_functionsAvailable) {
      _showFunctionsUnavailableMessage();
      return;
    }
    setState(() => _speedhuntLoading = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('startSpeedhunt')
          .call({'lobbyId': widget.lobbyId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speedhunt aktiviert.')),
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found') {
        _handleFunctionsUnavailable();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speedhunt fehlgeschlagen: ${error.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speedhunt fehlgeschlagen: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _speedhuntLoading = false);
      }
    }
  }

  void _handleFunctionsUnavailable([StackTrace? stack]) {
    _functionsAvailable = false;
    _pingTimer?.cancel();
    debugPrint('Cloud Functions unavailable, disabling remote pings.');
    if (stack != null) {
      debugPrint('$stack');
    }
    _showFunctionsUnavailableMessage();
  }

  void _showFunctionsUnavailableMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cloud Functions nicht gefunden. Bitte Funktionen bereitstellen oder in den Einstellungen deaktivieren.',
        ),
      ),
    );
  }

  Future<void> _attemptCatch(GamePlayer runner, Position hunterPos) async {
    final distance = Geolocator.distanceBetween(
      hunterPos.latitude,
      hunterPos.longitude,
      runner.lastPosition.latitude,
      runner.lastPosition.longitude,
    );
    if (distance > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Runner ist zu weit entfernt.')),
      );
      return;
    }
    final hunterUid = FirebaseAuth.instance.currentUser?.uid;
    if (hunterUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst einloggen.')),
      );
      return;
    }
    final firestore = FirebaseFirestore.instance;
    final runnerRef = firestore
        .collection('lobbies')
        .doc(widget.lobbyId)
        .collection('players')
        .doc(runner.uid);
    final eventsRef = firestore
        .collection('lobbies')
        .doc(widget.lobbyId)
        .collection('events')
        .doc();
    try {
      await firestore.runTransaction((txn) async {
        txn.update(runnerRef, {
          'isEliminated': true,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
        txn.set(eventsRef, {
          'type': 'catch',
          'runnerUid': runner.uid,
          'hunterUid': hunterUid,
          'occurredAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${runner.displayName} gefangen.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catch fehlgeschlagen: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final playersStream = context.watch<LobbyService>().watchPlayers(widget.lobbyId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniManhunt Map'),
        actions: [
          IconButton(
            onPressed: _speedhuntLoading ? null : _triggerSpeedhunt,
            icon: const Icon(Icons.flash_on),
            tooltip: 'Speedhunt starten',
          ),
        ],
      ),
      body: StreamBuilder<Position>(
        stream: locationService.positionStream,
        builder: (context, positionSnapshot) {
          if (positionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (positionSnapshot.hasError || !positionSnapshot.hasData) {
            return Center(
              child: Text('GPS Fehler: ${positionSnapshot.error ?? 'keine Daten'}'),
            );
          }
          final pos = positionSnapshot.data!;
          return StreamBuilder<List<GamePlayer>>(
            stream: playersStream,
            builder: (context, playersSnapshot) {
              final players = playersSnapshot.data ?? [];
              return Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: ll.LatLng(pos.latitude, pos.longitude),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'cloud.tonhaeuser.manhunt',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _center,
                            radius: _radiusMeters,
                            color: Colors.redAccent.withOpacity(0.1),
                            borderStrokeWidth: 2,
                            borderColor: Colors.redAccent,
                          ),
                        ],
                      ),
                      MarkerLayer(markers: _buildMarkers(players, pos)),
                    ],
                  ),
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      onPressed: () => _showCatchDialog(players, pos),
                      child: const Text('Catch prüfen'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers(List<GamePlayer> players, Position myPos) {
    final markers = <Marker>[];
    for (final player in players) {
      final latLng =
          ll.LatLng(player.lastPosition.latitude, player.lastPosition.longitude);
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: latLng,
          child: Icon(
            player.isHunter ? Icons.hiking : Icons.person,
            color: player.isHunter ? Colors.blue : Colors.red,
            size: 32,
          ),
        ),
      );
    }
    markers.add(
      Marker(
        width: 40,
        height: 40,
        point: ll.LatLng(myPos.latitude, myPos.longitude),
        child: const Icon(
          Icons.my_location,
          color: Colors.green,
          size: 32,
        ),
      ),
    );
    return markers;
  }

  void _showCatchDialog(List<GamePlayer> players, Position hunterPos) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final runners =
            players.where((p) => !p.isHunter && !p.isEliminated).toList();
        return ListView.builder(
          itemCount: runners.length,
          itemBuilder: (context, index) {
            final runner = runners[index];
            final distance = Geolocator.distanceBetween(
              hunterPos.latitude,
              hunterPos.longitude,
              runner.lastPosition.latitude,
              runner.lastPosition.longitude,
            );
            final isCatchable = distance <= 15;
            return ListTile(
              title: Text(runner.displayName),
              subtitle: Text('Distanz: ${distance.toStringAsFixed(1)} m'),
              trailing: isCatchable
                  ? ElevatedButton(
                      onPressed: () => _attemptCatch(runner, hunterPos),
                      child: const Text('Catch'),
                    )
                  : const Text('Zu weit'),
            );
          },
        );
      },
    );
  }
}
