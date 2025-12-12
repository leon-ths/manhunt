import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('wins', descending: true)
        .limit(20)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _AuroraEmptyState(message: 'Noch keine Statistiken.');
          }
          return _AuroraBackground(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 32, 16, 32),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final name = data['username'] ?? 'Spieler';
                final wins = data['wins'] ?? 0;
                final meters = (data['distanceMeters'] ?? 0).toDouble();
                return _LeaderboardTile(
                  rank: index + 1,
                  username: name,
                  wins: wins,
                  meters: meters,
                  highlight: index < 3,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B051A), Color(0xFF160A34), Color(0xFF031125)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.username,
    required this.wins,
    required this.meters,
    required this.highlight,
  });

  final int rank;
  final String username;
  final int wins;
  final double meters;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final gradient = highlight
        ? const LinearGradient(colors: [Color(0xFFFF5F6D), Color(0xFF7A3EFD)])
        : const LinearGradient(colors: [Color(0xFF1F1C2C), Color(0xFF302B63)]);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Siege: $wins · ${meters.toStringAsFixed(0)} m',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white70),
        ],
      ),
    );
  }
}

class _AuroraEmptyState extends StatelessWidget {
  const _AuroraEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _AuroraBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_graph_rounded, size: 48, color: Colors.white30),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
