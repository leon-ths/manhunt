import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manhunt/firebase_options.dart';
import 'package:manhunt/screens/auth_gate.dart';
import 'package:manhunt/services/auth_service.dart';
import 'package:manhunt/services/friend_service.dart';
import 'package:manhunt/services/lobby_service.dart';
import 'package:manhunt/services/location_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseAuth>(create: (_) => FirebaseAuth.instance),
        Provider<AuthService>(
          create: (ctx) => AuthService(
            ctx.read<FirebaseAuth>(),
            FirebaseFirestore.instance,
          ),
        ),
        Provider<LobbyService>(create: (_) => LobbyService(FirebaseFirestore.instance)),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<FriendService>(
          create: (ctx) => FriendService(
            FirebaseFirestore.instance,
            ctx.read<FirebaseAuth>(),
          ),
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
    const neonPink = Color(0xFFFF2D55);
    const darkBackground = Color(0xFF09090F);
    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme);

    return MaterialApp(
      title: 'Manhunt',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: neonPink,
          surface: Color(0xFF1C1C1E),
          onSurface: Colors.white,
        ),
        textTheme: baseTextTheme.copyWith(
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
          labelSmall: baseTextTheme.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonPink,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: neonPink.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1C1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neonPink, width: 2),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const AuthGate(),
    );
  }
}