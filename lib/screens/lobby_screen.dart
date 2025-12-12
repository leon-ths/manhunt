import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/models/game_lobby.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/screens/waiting_lobby_screen.dart';
import 'package:manhunt/services/auth_service.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:provider/provider.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: userDocStream,
            builder: (context, userSnap) {
              final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
              final activeLobbyId = userData['activeLobbyId'] as String?;
              return StreamBuilder<List<GameLobby>>(
                stream: context.watch<LobbyService>().watchLobbies(),
                builder: (context, snapshot) {
                  final lobbies = snapshot.data ?? [];
                  GameLobby? myLobby;
                  try {
                    myLobby = lobbies.firstWhere((lobby) => lobby.id == activeLobbyId);
                  } catch (_) {
                    myLobby = null;
                  }
                  final hasActiveLobby = myLobby != null && myLobby.status != 'finished';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(onLogout: () => context.read<AuthService>().signOut()),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _HeroProfile(user: user, userData: userData),
                              const SizedBox(height: 24),
                              _StatsGrid(userData: userData, uid: user.uid),
                              const SizedBox(height: 24),
                              if (hasActiveLobby)
                                _ContinueBanner(
                                  lobby: myLobby,
                                  onContinue: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WaitingLobbyScreen(lobbyId: myLobby!.id, asHost: myLobby.hostUid == user.uid),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              _LobbyList(lobbies: lobbies, joinLobby: _joinLobby),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _ActionButtons(
        onCreate: _showCreateLobbySheet,
        onJoin: _showJoinLobbySheet,
      ),
    );
  }

  Future<void> _joinLobby(String lobbyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final lobbyService = context.read<LobbyService>();
    final player = GamePlayer(
      uid: user.uid,
      displayName: user.displayName ?? user.uid.substring(0, 4),
      isHunter: false,
      isEliminated: false,
      lastPosition: const GeoPoint(0, 0),
      lastUpdate: Timestamp.now(),
    );
    await lobbyService.joinLobby(lobbyId: lobbyId, player: player);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'activeLobbyId': lobbyId});
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WaitingLobbyScreen(lobbyId: lobbyId, asHost: false)),
    );
  }

  Future<void> _showCreateLobbySheet() async {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final radiusController = TextEditingController(text: '500');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _CreateLobbySheet(
        nameController: nameController,
        durationController: durationController,
        radiusController: radiusController,
        onSubmit: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          final lobbyService = context.read<LobbyService>();
          final lobbyId = await lobbyService.createLobby(
            hostUid: user.uid,
            name: nameController.text,
            center: const GeoPoint(48.137154, 11.576124),
            radiusMeters: double.tryParse(radiusController.text) ?? 500,
            durationMinutes: int.tryParse(durationController.text) ?? 60,
          );
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'activeLobbyId': lobbyId});
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WaitingLobbyScreen(lobbyId: lobbyId, asHost: true)),
          );
        },
      ),
    );
  }

  Future<void> _showJoinLobbySheet() async {
    final codeController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _JoinLobbySheet(
        codeController: codeController,
        onSubmit: () {
          final code = codeController.text.trim();
          if (code.isEmpty) return;
          Navigator.pop(context);
          _joinLobby(code);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onLogout;

  const _Header({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANHUNT',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'OPERATOR STATUS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroProfile extends StatelessWidget {
  final User user;
  final Map<String, dynamic> userData;

  const _HeroProfile({required this.user, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user.displayName ?? "Unknown Agent";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.surface,
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName.toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'RANK: ${userData['rank'] ?? "RECRUIT"}',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const _StatsGrid({required this.uid, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(label: "GAMES", value: userData['gamesPlayed']?.toString() ?? "0", icon: Icons.videogame_asset)),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(label: "WINS", value: userData['wins']?.toString() ?? "0", icon: Icons.emoji_events)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatCard(label: "METER", value: (userData['distanceMeters'] as num?)?.toInt().toString() ?? "0", icon: Icons.directions_walk)),
            // Platzhalter für 4. Stat, falls gewünscht (z.B. K/D)
            // const SizedBox(width: 16),
            // Expanded(child: _StatCard(label: "K/D", value: "0.0", icon: Icons.pie_chart)),
          ],
        ),
        const SizedBox(height: 16),

        // Die große Profil-Karte für die Rolle
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // Roter Border für Hunter, Grüner für Runner (oder Theme Primary)
              color: (userData['preferredRole'] as String? ?? "RUNNER").toUpperCase() == "HUNTER"
                  ? const Color(0xFFFF2D55).withOpacity(0.5)
                  : const Color(0xFF32D74B).withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PREFERRED ROLE", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(
                    (userData['preferredRole'] as String? ?? "RUNNER").toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                      color: (userData['preferredRole'] as String? ?? "RUNNER").toUpperCase() == "HUNTER" ? const Color(0xFFFF2D55) : const Color(0xFF32D74B),
                    ),
                  ),
                ],
              ),
              Icon(
                  (userData['preferredRole'] as String? ?? "RUNNER").toUpperCase() == "HUNTER" ? Icons.gavel : Icons.directions_run,
                  color: (userData['preferredRole'] as String? ?? "RUNNER").toUpperCase() == "HUNTER" ? const Color(0xFFFF2D55) : const Color(0xFF32D74B),
                  size: 30
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContinueBanner extends StatelessWidget {
  final GameLobby lobby;
  final VoidCallback onContinue;

  const _ContinueBanner({required this.lobby, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOBBY: ${lobby.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${lobby.status.toUpperCase()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('WEITERSPIELEN'),
          ),
        ],
      ),
    );
  }
}

class _LobbyList extends StatelessWidget {
  final List<GameLobby> lobbies;
  final Future<void> Function(String) joinLobby;

  const _LobbyList({required this.lobbies, required this.joinLobby});

  @override
  Widget build(BuildContext context) {
    if (lobbies.isEmpty) {
      return Center(
        child: Text(
          'Keine Lobbys gefunden.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      );
    }
    return Column(
      children: lobbies.map((lobby) {
        final isActive = lobby.status != 'finished';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? Theme.of(context).colorScheme.surface : Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lobby.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Host: ${lobby.hostUid}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isActive ? () => joinLobby(lobby.id) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isActive ? 'BEITRETEN' : 'FERTIG'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _ActionButtons({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('ERSTELLEN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.qr_code),
              label: const Text('BEITRETEN'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateLobbySheet extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController durationController;
  final TextEditingController radiusController;
  final VoidCallback onSubmit;

  const _CreateLobbySheet({
    required this.nameController,
    required this.durationController,
    required this.radiusController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NEUE MISSION', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 20),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Mission Name', prefixIcon: Icon(Icons.tag))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dauer (Min)', prefixIcon: Icon(Icons.timer)))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: radiusController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Radius (m)', prefixIcon: Icon(Icons.radar)))),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text('STARTEN'),
            ),
          )
        ],
      ),
    );
  }
}

class _JoinLobbySheet extends StatelessWidget {
  final TextEditingController codeController;
  final VoidCallback onSubmit;

  const _JoinLobbySheet({
    required this.codeController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BEITRETEN', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 20),
          TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Lobby ID / Code', prefixIcon: Icon(Icons.key))),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text('CONNECT'),
            ),
          )
        ],
      ),
    );
  }
}
