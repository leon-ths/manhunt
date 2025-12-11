import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // TODO: use new APIs when refactoring state mgmt
import 'package:manhunt/models/game_lobby.dart';
import 'package:manhunt/models/game_player.dart';
import 'package:manhunt/screens/map_screen.dart';
import 'package:manhunt/services/auth_service.dart';
import 'package:manhunt/services/lobby_service.dart';

final lobbySearchProvider = StateProvider.autoDispose<String>((ref) => '');

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final lobbiesAsync = ref.watch(lobbiesProvider);
    final search = ref.watch(lobbySearchProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniManhunt'),
        actions: [
          IconButton(
            onPressed: ref.read(authServiceProvider).signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => ref.read(lobbySearchProvider.notifier).state = value,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Lobbynamen oder Host suchen…',
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
              ),
            ),
          ),
        ),
      ),
      body: lobbiesAsync.when(
        data: (lobbies) => _buildLobbyList(context, lobbies, search),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (err, _) => Center(child: Text('Lobbies Fehler: $err')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _showCreateLobbySheet,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Lobby erstellen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showJoinLobbySheet,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Beitreten'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyList(BuildContext context, List<GameLobby> lobbies, String search) {
    if (lobbies.isEmpty) {
      return const _EmptyState();
    }
    final filtered = lobbies.where((lobby) {
      if (search.isEmpty) return true;
      final query = search.toLowerCase();
      return lobby.name.toLowerCase().contains(query) ||
          lobby.hostUid.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: filtered.length,
        separatorBuilder: (context, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lobby = filtered[index];
          return _LobbyCard(
            lobby: lobby,
            onTap: () => _joinLobby(lobby.id),
          );
        },
      ),
    );
  }

  Future<void> _joinLobby(String lobbyId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final lobbyService = ref.read(lobbyServiceProvider);
    final player = GamePlayer(
      uid: user.uid,
      displayName: user.uid.substring(0, 6),
      isHunter: false,
      isEliminated: false,
      lastPosition: const GeoPoint(0, 0),
      lastUpdate: Timestamp.now(),
    );
    await lobbyService.joinLobby(lobbyId: lobbyId, player: player);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            lobbyIdProvider.overrideWithValue(lobbyId),
          ],
          child: const MapScreen(),
        ),
      ),
    );
  }

  Future<void> _showCreateLobbySheet() async {
    final nameController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final radiusController = TextEditingController(text: '500');

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lobby erstellen',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Dauer (Minuten)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(labelText: 'Radius (Meter)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = ref.read(authStateProvider).value;
                        if (user == null) return;
                        final lobbyService = ref.read(lobbyServiceProvider);
                        final lobbyId = await lobbyService.createLobby(
                          hostUid: user.uid,
                          name: nameController.text,
                          center: const GeoPoint(48.137154, 11.576124),
                          radiusMeters: double.tryParse(radiusController.text) ?? 500,
                          durationMinutes: int.tryParse(durationController.text) ?? 60,
                        );
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                        await _joinLobby(lobbyId);
                      },
                      child: const Text('Erstellen'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showJoinLobbySheet() async {
    final codeController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lobby beitreten',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Lobby ID oder Beitrcode'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final code = codeController.text.trim();
                        if (code.isEmpty) return;
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                        await _joinLobby(code);
                      },
                      child: const Text('Beitreten'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LobbyCard extends StatelessWidget {
  const _LobbyCard({required this.lobby, required this.onTap});

  final GameLobby lobby;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: scheme.surfaceContainerHigh,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                ),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lobby.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lobby.durationMinutes} Min · ${lobby.radiusMeters.toStringAsFixed(0)} m Radius',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text('Keine Lobbies in deiner Nähe.'),
          const SizedBox(height: 8),
          const Text('Erstelle die erste Runde und lade deine Freunde ein!'),
        ],
      ),
    );
  }
}
