import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/widgets/design_components.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('wins', descending: true)
        .limit(20)
        .snapshots();

    return ScreenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // Header wird im Body gerendert
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                    width: double.infinity,
                    child: ScreenHeader(title: 'RANKING', subtitle: 'TOP AGENTS')
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                            'NO DATA AVAILABLE',
                            style: TextStyle(color: Colors.white24, letterSpacing: 2)
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final name = data['username'] ?? 'Unknown Agent';
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
    final primary = Theme.of(context).colorScheme.primary;
    // Top 3 erhalten die Primärfarbe (Neon Pink), der Rest dezentes Weiß
    final rankColor = highlight ? primary : Colors.white54;

    return TechCard(
      // Top 3 bekommen einen dezenten farbigen Rand
      borderColor: highlight ? primary.withValues(alpha: 0.3) : null,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              "#$rank",
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    username,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5
                    )
                ),
                const SizedBox(height: 4),
                Text(
                    "$wins WINS  •  ${meters.toInt()} M",
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold
                    )
                ),
              ],
            ),
          ),
          if (highlight)
            Icon(Icons.emoji_events, color: primary, size: 20)
          else
            const Icon(Icons.shield_outlined, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}