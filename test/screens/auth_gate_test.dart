import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
    final mockFirestore = FakeFirebaseFirestore();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<FirebaseAuth>(create: (_) => mockAuth),
          Provider<AuthService>(create: (_) => AuthService(mockAuth, mockFirestore)),
        ],
        child: MaterialApp(
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 900,
              child: const AuthGate(),
            ),
          ),
        ),
       ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MANHUNT'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    await tester.tap(find.text('REGISTER'));
    await tester.pumpAndSettle();
    expect(find.text('CODENAME'), findsOneWidget);
  });
 }
