import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/firebase_options.dart';
import 'package:manhunt/screens/auth_gate.dart';
import 'package:manhunt/services/auth_service.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:manhunt/services/location_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseAuth>(
          create: (_) => FirebaseAuth.instance,
        ),
        Provider<AuthService>(
          create: (ctx) => AuthService(ctx.read<FirebaseAuth>()),
        ),
        Provider<LobbyService>(
          create: (_) => LobbyService(FirebaseFirestore.instance),
        ),
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
      ],
      child: const MiniManhuntApp(),
    ),
  );
}

class MiniManhuntApp extends StatelessWidget {
  const MiniManhuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF3E55),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF3E55),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'MiniManhunt',
      theme: _themeFromScheme(lightScheme),
      darkTheme: _themeFromScheme(darkScheme),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

ThemeData _themeFromScheme(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface.withValues(alpha: 0.95),
      surfaceTintColor: scheme.surfaceTint,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
