import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/services/friend_service.dart';
import 'package:provider/provider.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key, required this.disabled});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return const _AuroraFriendsScaffold(
        title: 'Freunde',
        child: _AuroraEmptyMessage(
          icon: Icons.lock_outline,
          message: 'Melde dich mit E-Mail an, um Freundschaften und Einladungen zu nutzen.',
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
    return _AuroraFriendsScaffold(
      title: 'Freunde',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Freund hinzufügen'),
              onPressed: () => _showAddDialog(context, friendService),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: profileStream,
              builder: (context, profileSnapshot) {
                final friends = (profileSnapshot.data?.data()?['friends'] as List<dynamic>?) ?? [];
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    const _SectionLabel(text: 'Freunde'),
                    const SizedBox(height: 8),
                    if (friends.isEmpty)
                      const _AuroraEmptyMessage(icon: Icons.people_outline, message: 'Noch keine Freunde.')
                    else
                      ...friends.map((uid) => _FriendCard(username: uid.toString())),
                    const SizedBox(height: 24),
                    const _SectionLabel(text: 'Anfragen'),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: requestStream,
                      builder: (context, requestSnapshot) {
                        final requests = requestSnapshot.data?.docs ?? [];
                        if (requests.isEmpty) {
                          return const _AuroraEmptyMessage(icon: Icons.inbox_outlined, message: 'Keine offenen Anfragen.');
                        }
                        return Column(
                          children: requests
                              .map(
                                (doc) => _RequestCard(
                                  name: doc['fromName'] ?? 'Unbekannt',
                                  onAccept: () => friendService.respondToRequest(requestUid: doc.id, accepted: true),
                                  onDecline: () => friendService.respondToRequest(requestUid: doc.id, accepted: false),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, FriendService service) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Freund hinzufügen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Benutzername'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () async {
              try {
                await service.sendFriendRequest(toUsername: controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anfrage gesendet.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler: $e')),
                );
              }
            },
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }
}

class _AuroraFriendsScaffold extends StatelessWidget {
  const _AuroraFriendsScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B051A), Color(0xFF200A3B), Color(0xFF051937)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _AuroraEmptyMessage extends StatelessWidget {
  const _AuroraEmptyMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF1F1C2C), Color(0xFF302B63)]),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white70),
            onPressed: () {},
          )
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.name, required this.onAccept, required this.onDecline});

  final String name;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFFF5F6D), Color(0xFF7A3EFD)]),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Möchte dich hinzufügen.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          IconButton(onPressed: onDecline, icon: const Icon(Icons.close, color: Colors.white)),
          IconButton(onPressed: onAccept, icon: const Icon(Icons.check, color: Colors.white))
        ],
      ),
    );
  }
}
