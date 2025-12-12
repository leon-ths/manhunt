import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/services/friend_service.dart';
import 'package:manhunt/widgets/design_components.dart';
import 'package:provider/provider.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key, required this.disabled});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return const ScreenBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'ACCESS DENIED',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 20
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AUTHENTICATION REQUIRED FOR NETWORK ACCESS',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final friendService = context.read<FriendService>();
    final profileStream = friendService.watchProfile(user.uid);
    final requestStream = friendService.watchFriendRequests(user.uid);

    return ScreenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // Header machen wir selbst
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: ScreenHeader(title: 'NETWORK', subtitle: 'ALLIES & REQUESTS'),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: TechCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => _showAddDialog(context, friendService),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'AGENTEN REKRUTIEREN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: profileStream,
                  builder: (context, profileSnapshot) {
                    final friends = (profileSnapshot.data?.data()?['friends'] as List<dynamic>?) ?? [];

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _SectionLabel(text: 'ALLIES (${friends.length})'),
                        const SizedBox(height: 12),
                        if (friends.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text("NO ALLIES FOUND", style: TextStyle(color: Colors.white24, letterSpacing: 1, fontSize: 12)),
                          )
                        else
                          ...friends.map((uid) => _FriendCard(username: uid.toString())),

                        const SizedBox(height: 32),

                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: requestStream,
                          builder: (context, requestSnapshot) {
                            final requests = requestSnapshot.data?.docs ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionLabel(text: 'INCOMING REQUESTS (${requests.length})'),
                                const SizedBox(height: 12),
                                if (requests.isEmpty)
                                  const Text("NO PENDING REQUESTS", style: TextStyle(color: Colors.white24, letterSpacing: 1, fontSize: 12)),
                                ...requests.map(
                                      (doc) => _RequestCard(
                                    name: doc['fromName'] ?? 'Unknown',
                                    onAccept: () => friendService.respondToRequest(requestUid: doc.id, accepted: true),
                                    onDecline: () => friendService.respondToRequest(requestUid: doc.id, accepted: false),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 100), // Padding für Bottom Navigation
                      ],
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

  Future<void> _showAddDialog(BuildContext context, FriendService service) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        title: const Text('REKRUTIEREN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Codename',
            labelStyle: const TextStyle(color: Colors.white54),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ABBRECHEN', style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () async {
              try {
                await service.sendFriendRequest(toUsername: controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Einladung gesendet.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: $e')),
                );
              }
            },
            child: Text('SENDEN', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.bold
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final String username;
  const _FriendCard({required this.username});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TechCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white, letterSpacing: 0.5),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF32D74B),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0xFF32D74B), blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String name;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({required this.name, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TechCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        child: Row(
          children: [
            const Icon(Icons.mail_outline, color: Colors.white54, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  const Text('REQUESTING ACCESS', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: onDecline,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF32D74B)),
              onPressed: onAccept,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}