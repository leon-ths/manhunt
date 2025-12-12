import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:manhunt/services/location_service.dart';
import 'package:manhunt/widgets/design_components.dart';
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

  // ignore: unused_field
  int _pingIntervalMinutes = 5;
  Timer? _pingTimer;
  final bool _speedhuntLoading = false;

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
    final lobbyDoc = await FirebaseFirestore.instance.collection('lobbies').doc(widget.lobbyId).get();
    if (!lobbyDoc.exists) return;
    final data = lobbyDoc.data()!;
    setState(() {
      final geoPoint = data['center'] as GeoPoint;
      _center = ll.LatLng(geoPoint.latitude, geoPoint.longitude);
      _radiusMeters = (data['radiusMeters'] as num).toDouble();
      _pingIntervalMinutes = (data['pingIntervalMinutes'] as num?)?.toInt() ?? 5;
    });
    // _startPingTimer();
  }

  // Platzhalter für Game-Logik (Ping, Catch, Speedhunt)
  void _showCatchDialog(List<GamePlayer> players, Position hunterPos) {
    // Implementierung deiner Catch-Logik hier
  }
  Future<void> _triggerSpeedhunt() async {
    // Implementierung deiner Speedhunt-Logik hier
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final playersStream = context.watch<LobbyService>().watchPlayers(widget.lobbyId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: StreamBuilder<Position>(
        stream: locationService.positionStream,
        builder: (context, positionSnapshot) {
          if (!positionSnapshot.hasData) {
            return const ScreenBackground(child: Center(child: CircularProgressIndicator()));
          }
          final pos = positionSnapshot.data!;

          return StreamBuilder<List<GamePlayer>>(
            stream: playersStream,
            builder: (context, playersSnapshot) {
              final players = playersSnapshot.data ?? [];
              return Stack(
                children: [
                  // 1. Die Karte (Dark Tech Look)
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: ll.LatLng(pos.latitude, pos.longitude),
                      initialZoom: 16,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      // Invertierungs-Filter für Dark Mode
                      ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -1, 0, 0, 0, 255, // Red invert
                          0, -1, 0, 0, 255, // Green invert
                          0, 0, -1, 0, 255, // Blue invert
                          0, 0, 0, 1, 0,    // Alpha
                        ]),
                        child: TileLayer(
                          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: const ['a', 'b', 'c'],
                          userAgentPackageName: 'cloud.tonhaeuser.manhunt',
                        ),
                      ),
                      // Abdunklungs-Overlay
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          const Color(0xFF000000).withValues(alpha: 0.85),
                          BlendMode.darken,
                        ),
                        child: Container(color: Colors.transparent), // Dummy child für Filter
                      ),

                      // Spielzone
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _center,
                            radius: _radiusMeters,
                            useRadiusInMeter: true,
                            color: const Color(0xFF32D74B).withValues(alpha: 0.05),
                            borderStrokeWidth: 1,
                            borderColor: const Color(0xFF32D74B).withValues(alpha: 0.5),
                          ),
                        ],
                      ),

                      // Spieler Marker
                      MarkerLayer(markers: _buildMarkers(players, pos)),
                    ],
                  ),

                  // 2. HUD Overlay (Oben) - Status
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    right: 20,
                    left: 80, // Platz lassen für Back Button
                    child: TechCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatusCounter(
                              label: 'RUNNER',
                              count: players.where((p) => !p.isHunter).length,
                              color: const Color(0xFF32D74B)
                          ),
                          Container(width: 1, height: 24, color: Colors.white10),
                          _StatusCounter(
                              label: 'HUNTER',
                              count: players.where((p) => p.isHunter).length,
                              color: const Color(0xFFFF2D55)
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Action Bar (Unten)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        _TechFab(
                          icon: Icons.flash_on,
                          color: Colors.yellow,
                          isLoading: _speedhuntLoading,
                          onTap: _speedhuntLoading ? null : _triggerSpeedhunt,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF2D55).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2D55),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => _showCatchDialog(players, pos),
                              child: const Text(
                                  'ELIMINATE TARGET',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _TechFab(
                          icon: Icons.my_location,
                          color: Colors.white,
                          onTap: () {
                            _mapController.move(ll.LatLng(pos.latitude, pos.longitude), 17);
                          },
                        ),
                      ],
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
      if(player.isEliminated) continue;

      final latLng = ll.LatLng(player.lastPosition.latitude, player.lastPosition.longitude);
      final isHunter = player.isHunter;
      final color = isHunter ? const Color(0xFFFF2D55) : const Color(0xFF32D74B);

      markers.add(
        Marker(
          width: 50,
          height: 60,
          point: latLng,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)
                    ]
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isHunter ? Icons.gavel : Icons.directions_run,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    player.displayName,
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Eigener Standort
    markers.add(
      Marker(
        width: 60,
        height: 60,
        point: ll.LatLng(myPos.latitude, myPos.longitude),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.15),
            border: Border.all(color: Colors.blueAccent, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10)
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 24),
        ),
      ),
    );
    return markers;
  }
}

class _StatusCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCounter({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 8),
        Text(
          "$count $label",
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1
          ),
        ),
      ],
    );
  }
}

class _TechFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _TechFab({required this.icon, required this.color, this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                : Icon(icon, color: color),
          ),
        ),
      ),
    );
  }
}