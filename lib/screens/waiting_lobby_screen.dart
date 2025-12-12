import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/models/game_lobby.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/screens/map_screen.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:provider/provider.dart';

class WaitingLobbyScreen extends StatelessWidget {
  const WaitingLobbyScreen({super.key, required this.lobbyId, required this.asHost});

  final String lobbyId;
  final bool asHost;

  @override
  Widget build(BuildContext context) {
    final lobbyService = context.watch<LobbyService>();
    return StreamBuilder<GameLobby>(
      stream: lobbyService.watchLobby(lobbyId),
      builder: (context, lobbySnap) {
        if (!lobbySnap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final lobby = lobbySnap.data!;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF09090F), Color(0xFF1B1B1F), Color(0xFF250A0F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WaitingHeader(lobby: lobby),
                  Expanded(
                    child: StreamBuilder<List<GamePlayer>>(
                      stream: lobbyService.watchPlayers(lobbyId),
                      builder: (context, playersSnap) {
                        final players = playersSnap.data ?? [];
                        final hunters = players.where((p) => p.isHunter).toList();
                        final runners = players.where((p) => !p.isHunter).toList();

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 140),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LobbyMetaPanel(lobby: lobby, hunters: hunters.length, runners: runners.length),
                              const SizedBox(height: 24),
                              _RoleSelector(players: players, lobbyId: lobbyId),
                              const SizedBox(height: 24),
                              if (asHost)
                                _HostControls(lobby: lobby),
                              const SizedBox(height: 24),
                              _PlayerList(title: 'Hunter', players: hunters, color: const Color(0xFFFF5F6D)),
                              const SizedBox(height: 16),
                              _PlayerList(title: 'Runner', players: runners, color: const Color(0xFF32D74B)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: _WaitingActions(lobby: lobby, asHost: asHost),
        );
      },
    );
  }
}

class _WaitingHeader extends StatelessWidget {
  const _WaitingHeader({required this.lobby});

  final GameLobby lobby;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lobby.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'GAME ID: ${lobby.id}',
            style: TextStyle(color: Colors.white.withOpacity(0.7), letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _LobbyMetaPanel extends StatelessWidget {
  const _LobbyMetaPanel({required this.lobby, required this.hunters, required this.runners});

  final GameLobby lobby;
  final int hunters;
  final int runners;

  @override
  Widget build(BuildContext context) {
    Widget buildChip(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildChip('PINGS', '${lobby.pingIntervalMinutes} MIN'),
            const SizedBox(width: 12),
            buildChip('RADIUS', '${lobby.radiusMeters.toStringAsFixed(0)} M'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            buildChip('ESCAPE TIME', '${lobby.escapeMinutes} MIN'),
            const SizedBox(width: 12),
            buildChip('PLAYERS', '$hunters H / $runners R'),
          ],
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.players, required this.lobbyId});

  final List<GamePlayer> players;
  final String lobbyId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final me = players.firstWhere((p) => p.uid == user?.uid, orElse: () => players.isEmpty
        ? GamePlayer(
            uid: user!.uid,
            displayName: user.displayName ?? 'Agent',
            isHunter: false,
            isEliminated: false,
            lastPosition: const GeoPoint(0, 0),
            lastUpdate: Timestamp.now(),
          )
        : players.first);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ROLE SELECTION', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoleChip(
                label: 'Hunter',
                selected: me.isHunter,
                color: const Color(0xFFFF5F6D),
                onTap: () => context.read<LobbyService>().updateRole(
                      lobbyId: lobbyId,
                      playerUid: me.uid,
                      isHunter: true,
                    ),
              ),
              const SizedBox(width: 12),
              _RoleChip(
                label: 'Runner',
                selected: !me.isHunter,
                color: const Color(0xFF32D74B),
                onTap: () => context.read<LobbyService>().updateRole(
                      lobbyId: lobbyId,
                      playerUid: me.uid,
                      isHunter: false,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.selected, required this.color, required this.onTap});

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HostControls extends StatefulWidget {
  const _HostControls({required this.lobby});

  final GameLobby lobby;

  @override
  State<_HostControls> createState() => _HostControlsState();
}

class _HostControlsState extends State<_HostControls> {
  late final TextEditingController _pingController;
  late final TextEditingController _radiusController;
  double _escapeValue = 0;

  @override
  void initState() {
    super.initState();
    _pingController = TextEditingController(text: widget.lobby.pingIntervalMinutes.toString());
    _radiusController = TextEditingController(text: widget.lobby.radiusMeters.toStringAsFixed(0));
    _escapeValue = widget.lobby.escapeMinutes.toDouble();
  }

  @override
  void dispose() {
    _pingController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOST CONTROLS', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _pingController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ping Intervall (Min)', prefixIcon: Icon(Icons.timelapse)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _radiusController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Spielfeld Radius (m)', prefixIcon: Icon(Icons.circle_outlined)),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hunter Delay (Min)', style: TextStyle(color: Colors.white70)),
              Slider(
                value: _escapeValue,
                min: 1,
                max: 10,
                divisions: 9,
                label: '${_escapeValue.round()} Min',
                onChanged: (value) => setState(() => _escapeValue = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await context.read<LobbyService>().updateLobbySettings(
                      lobbyId: widget.lobby.id,
                      pingIntervalMinutes: int.tryParse(_pingController.text) ?? widget.lobby.pingIntervalMinutes,
                      radiusMeters: double.tryParse(_radiusController.text) ?? widget.lobby.radiusMeters,
                      escapeMinutes: _escapeValue.round(),
                    );
              },
              child: const Text('ÄNDERUNGEN SPEICHERN'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.title, required this.players, required this.color});

  final String title;
  final List<GamePlayer> players;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title (${players.length})', style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...players.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(p.isHunter ? Icons.gavel : Icons.directions_run, color: color)),
              title: Text(p.displayName, style: const TextStyle(color: Colors.white)),
              subtitle: Text(p.uid.substring(0, 6), style: TextStyle(color: Colors.white.withOpacity(0.5))),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingActions extends StatelessWidget {
  const _WaitingActions({required this.lobby, required this.asHost});

  final GameLobby lobby;
  final bool asHost;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asHost)
            FilledButton(
              onPressed: () async {
                await context.read<LobbyService>().startLobby(lobby.id);
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => MapScreen(lobbyId: lobby.id)),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5F6D),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('SPIEL STARTEN'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              if (user == null) return;
              await context.read<LobbyService>().leaveLobby(lobbyId: lobby.id, playerUid: user.uid);
              if (context.mounted) Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('AUFGEBEN'),
          ),
        ],
      ),
    );
  }
}
