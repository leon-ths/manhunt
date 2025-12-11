import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhunt/screens/auth_gate.dart';
import 'package:manhunt/services/auth_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AuthGate shows login form when signed out', (tester) async {
    final mockAuth = MockFirebaseAuth();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>(create: (_) => mockAuth),
          Provider<AuthService>(create: (_) => AuthService(mockAuth)),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MiniManhunt'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
