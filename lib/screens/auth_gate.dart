import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhunt/screens/lobby_screen.dart';
import 'package:manhunt/services/auth_service.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 96, color: colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'MiniManhunt',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Starte anonym und erstelle eine Lobby, um sofort loszulegen.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => ref.read(authServiceProvider).signInAnonymously(),
                    icon: const Icon(Icons.bolt),
                    label: const Text('Anonym anmelden'),
                  ),
                ],
              ),
            ),
          );
        }
        return const LobbyScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) => Scaffold(body: Center(child: Text('Auth Fehler: $err'))),
    );
  }
}
