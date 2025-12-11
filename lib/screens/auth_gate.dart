import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/screens/lobby_screen.dart';
import 'package:manhunt/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = context.watch<FirebaseAuth>();
    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return const LobbyScreen();
        }
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Auth Fehler: ${snapshot.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 32),
                Icon(Icons.radar, size: 96, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'MiniManhunt',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('Melde dich an oder erstelle ein Konto, um zu spielen'),
                const SizedBox(height: 24),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Registrieren'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAuthForm(context, isRegister: false),
                      _buildAuthForm(context, isRegister: true),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Anonym ausprobieren'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthForm(BuildContext context, {required bool isRegister}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-Mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Passwort'),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const Spacer(),
          FilledButton(
            onPressed:
                _isLoading ? null : () => _submitEmailPassword(isRegister: isRegister),
            child: Text(isRegister ? 'Konto erstellen' : 'Einloggen'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmailPassword({required bool isRegister}) async {
    final authService = context.read<AuthService>();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (isRegister) {
        await authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAnonymously() async {
    final authService = context.read<AuthService>();
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await authService.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
