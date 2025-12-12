import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/models/game_lobby.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/screens/map_screen.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:manhunt/widgets/design_components.dart';
import 'package:provider/provider.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key, required this.lobbyId, required this.asHost});

  final String lobbyId;
  final bool asHost;

  @override
  Widget build(BuildContext context) {
    final lobbyService = context.watch<LobbyService>();

    return ScreenBackground(
      child: StreamBuilder<GameLobby>(
        stream: lobbyService.watchLobby(lobbyId),
        builder: (context, lobbySnap) {
          if (!lobbySnap.hasData) {
            return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
          }
          final lobby = lobbySnap.data!;

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ScreenHeader(title: lobby.name, subtitle: 'GAME ID: ${lobby.id}'),
                  ),
                  const SizedBox(height: 24),

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
                              _TechMetaPanel(lobby: lobby, playerCount: players.length),
                              const SizedBox(height: 24),
                              _RoleSelector(players: players, lobbyId: lobbyId),
                              const SizedBox(height: 24),
                              if (asHost) ...[
                                _HostControls(lobby: lobby),
                                const SizedBox(height: 24),
                              ],
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _TeamList(title: 'HUNTERS', players: hunters, color: const Color(0xFFFF2D55))),
                                  const SizedBox(width: 16),
                                  Expanded(child: _TeamList(title: 'RUNNERS', players: runners, color: const Color(0xFF32D74B))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            floatingActionButton: _WaitingActions(lobby: lobby, asHost: asHost),
          );
        },
      ),
    );
  }
}

class _TechMetaPanel extends StatelessWidget {
  final GameLobby lobby;
  final int playerCount;
  const _TechMetaPanel({required this.lobby, required this.playerCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetaItem(label: "RADIUS", value: "${lobby.radiusMeters.toInt()}m", icon: Icons.radar)),
        const SizedBox(width: 12),
        Expanded(child: _MetaItem(label: "PING", value: "${lobby.pingIntervalMinutes}min", icon: Icons.timelapse)),
        const SizedBox(width: 12),
        Expanded(child: _MetaItem(label: "AGENTS", value: "$playerCount", icon: Icons.group)),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetaItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TechCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
        ],
      ),
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
    // Fallback falls Spielerdaten noch nicht geladen sind
    final me = players.isEmpty
        ? null
        : players.firstWhere(
            (p) => p.uid == user?.uid,
        orElse: () => players.first
    );

    // Wenn User nicht gefunden (selten), leeres Widget zeigen
    if (me == null) return const SizedBox.shrink();

    return TechCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT ALLEGIANCE', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RoleButton(
                  label: 'HUNTER',
                  isSelected: me.isHunter,
                  color: const Color(0xFFFF2D55),
                  onTap: () => context.read<LobbyService>().updateRole(lobbyId: lobbyId, playerUid: me.uid, isHunter: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleButton(
                  label: 'RUNNER',
                  isSelected: !me.isHunter,
                  color: const Color(0xFF32D74B),
                  onTap: () => context.read<LobbyService>().updateRole(lobbyId: lobbyId, playerUid: me.uid, isHunter: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.isSelected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.white10, width: isSelected ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
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
    return TechCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MISSION PARAMETERS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pingController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Ping (Min)', prefixIcon: Icon(Icons.timelapse, size: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _radiusController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'Radius (m)', prefixIcon: Icon(Icons.map, size: 18)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('HUNTER DELAY', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${_escapeValue.round()} MIN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.white,
                  overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _escapeValue,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) => setState(() => _escapeValue = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parameter updated.")));
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
              ),
              child: const Text('UPDATE SYSTEM', style: TextStyle(letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamList extends StatelessWidget {
  final String title;
  final List<GamePlayer> players;
  final Color color;

  const _TeamList({required this.title, required this.players, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
        const SizedBox(height: 8),
        if (players.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("- Empty -", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
          ),
        ...players.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(p.isHunter ? Icons.gavel : Icons.directions_run, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(p.displayName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
        )),
      ],
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<LobbyService>().startLobby(lobby.id);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => MapScreen(lobbyId: lobby.id)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                  shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                child: const Text('INITIATE MISSION'),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                if (user == null) return;
                await context.read<LobbyService>().leaveLobby(lobbyId: lobby.id, playerUid: user.uid);
                if (context.mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.7),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('ABORT MISSION'),
            ),
          ),
        ],
      ),
    );
  }
}

