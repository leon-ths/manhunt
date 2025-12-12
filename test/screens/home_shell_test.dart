import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhunt/screens/home_shell.dart';
import 'package:manhunt/services/friend_service.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('HomeShell switches tabs and shows friends disabled state', (tester) async {
    final mockAuth = MockFirebaseAuth(signedIn: true);
    final fakeStore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LobbyService>(create: (_) => LobbyService(fakeStore)),
          Provider<FriendService>(create: (_) => FriendService(fakeStore, mockAuth)),
        ],
        child: MaterialApp(
          home: HomeShell(
            isAnonymous: true,
            screensOverride: const [
              Scaffold(body: Center(child: Text('Lobby'))),
              Scaffold(body: Center(child: Text('Leaderboard'))),
              Scaffold(body: Center(child: Text('Freunde Content'))),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Lobbys'), findsOneWidget);

    await tester.tap(find.text('Freunde'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Freunde Content'), findsOneWidget);
  });
}
