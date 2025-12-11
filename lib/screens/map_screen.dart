import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/services/location_service.dart';

final lobbyIdProvider = Provider<String>((_) => 'demo-lobby-id');
final currentUserIdProvider = Provider<String?>(
  (_) => FirebaseAuth.instance.currentUser?.uid,
);

final gamePlayersProvider = StreamProvider<List<GamePlayer>>((ref) {
  final lobbyId = ref.watch(lobbyIdProvider);
  return FirebaseFirestore.instance
      .collection('lobbies')
      .doc(lobbyId)
      .collection('players')
      .snapshots()
      .map((snapshot) =>
      snapshot.docs.map((doc) => GamePlayer.fromMap(doc.data())).toList());
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(48.137154, 11.576124);
  double _radiusMeters = 500;
  int _pingIntervalMinutes = 5;
  Timer? _pingTimer;
  bool _speedhuntLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLobbyMeta();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadLobbyMeta() async {
    final lobbyId = ref.read(lobbyIdProvider);
    final lobbyDoc =
        await FirebaseFirestore.instance.collection('lobbies').doc(lobbyId).get();
    if (!lobbyDoc.exists) return;
    final data = lobbyDoc.data()!;
    setState(() {
      final geoPoint = data['center'] as GeoPoint;
      _center = LatLng(geoPoint.latitude, geoPoint.longitude);
      _radiusMeters = (data['radiusMeters'] as num).toDouble();
      _pingIntervalMinutes = (data['pingIntervalMinutes'] as num?)?.toInt() ?? 5;
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
    final lobbyId = ref.read(lobbyIdProvider);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('triggerSilentPing')
          .call({'lobbyId': lobbyId});
    } catch (error, stack) {
      debugPrint('Silent ping failed: $error');
      debugPrint('$stack');
    }
  }

  Future<void> _triggerSpeedhunt() async {
    final lobbyId = ref.read(lobbyIdProvider);
    setState(() => _speedhuntLoading = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('startSpeedhunt')
          .call({'lobbyId': lobbyId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speedhunt aktiviert.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speedhunt fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _speedhuntLoading = false);
      }
    }
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
    final hunterUid = ref.read(currentUserIdProvider);
    if (hunterUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst einloggen.')),
      );
      return;
    }
    final lobbyId = ref.read(lobbyIdProvider);
    final firestore = FirebaseFirestore.instance;
    final runnerRef = firestore
        .collection('lobbies')
        .doc(lobbyId)
        .collection('players')
        .doc(runner.uid);
    final eventsRef = firestore
        .collection('lobbies')
        .doc(lobbyId)
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
    final positionAsync = ref.watch(positionStreamProvider);
    final playersAsync = ref.watch(gamePlayersProvider);

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
      body: Stack(
        children: [
          positionAsync.when(
            data: (pos) => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(pos.latitude, pos.longitude),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              circles: {
                Circle(
                  circleId: const CircleId('play-area'),
                  center: _center,
                  radius: _radiusMeters,
                  fillColor: Colors.redAccent.withValues(alpha: 0.1),
                  strokeColor: Colors.redAccent,
                  strokeWidth: 2,
                ),
              },
              markers: _buildMarkers(playersAsync.value ?? [], pos),
              onMapCreated: (controller) => _mapController = controller,
            ),
            loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
            error: (err, _) => Center(child: Text('GPS Fehler: $err')),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: positionAsync.maybeWhen(
              data: (pos) => ElevatedButton(
                onPressed: () => _showCatchDialog(playersAsync.value ?? [], pos),
                child: const Text('Catch prüfen'),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<GamePlayer> players, Position? myPos) {
    final markers = <Marker>{};
    for (final player in players) {
      final latLng =
      LatLng(player.lastPosition.latitude, player.lastPosition.longitude);
      markers.add(
        Marker(
          markerId: MarkerId(player.uid),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            player.isHunter ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: player.displayName,
            snippet: player.isHunter ? 'Hunter' : 'Runner',
          ),
        ),
      );
    }
    if (myPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(myPos.latitude, myPos.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Ich'),
        ),
      );
    }
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
