import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manhunt/screens/home_shell.dart';
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
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

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
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = context.watch<FirebaseAuth>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) {
          return HomeShell(isAnonymous: user.isAnonymous);
        }

        return Scaffold(
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _AuthHeader(primaryColor: primaryColor, theme: theme),
                    const SizedBox(height: 32),
                    if (_error != null) _ErrorBanner(message: _error!),
                    _AuthTabs(tabController: _tabController, primaryColor: primaryColor),
                    const SizedBox(height: 24),
                    _AuthForms(
                      tabController: _tabController,
                      buildForm: (isRegister) => _buildAuthForm(isRegister: isRegister),
                    ),
                    const SizedBox(height: 24),
                    _GuestAccessButton(isLoading: _isLoading, onTap: _signInAnonymously),
                    const SizedBox(height: 16),
                    const _FooterNote(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthForm({required bool isRegister}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuroraField(
          controller: _emailController,
          label: 'E-MAIL ADRESSE',
          icon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        if (isRegister) ...[
          const SizedBox(height: 16),
          _AuroraField(
            controller: _usernameController,
            label: 'CODENAME',
            icon: Icons.badge,
          ),
        ],
        const SizedBox(height: 16),
        _AuroraField(
          controller: _passwordController,
          label: 'PASSWORT',
          icon: Icons.key,
          obscureText: _obscurePassword,
          trailing: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _submitEmailPassword(isRegister: isRegister),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isRegister ? 'ACCOUNT ERSTELLEN' : 'SYSTEM ZUGRIFF'),
        ),
      ],
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
          username: _usernameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapFirebaseError(e.code));
    } catch (e) {
      setState(() => _error = "Ein unbekannter Fehler ist aufgetreten.");
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
      setState(() => _error = _mapFirebaseError(e.code));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Zugangsdaten ungültig.';
      case 'email-already-in-use':
        return 'Diese E-Mail wird bereits verwendet.';
      case 'weak-password':
        return 'Das Passwort ist zu schwach.';
      case 'invalid-email':
        return 'Ungültige E-Mail Adresse.';
      default:
        return 'Fehler: $code';
    }
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.primaryColor,
    required this.theme,
  });

  final Color primaryColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.lock_person, size: 64, color: primaryColor),
        const SizedBox(height: 16),
        Text(
          'MANHUNT',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        Text(
          'ACCESS TERMINAL',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.tabController,
    required this.primaryColor,
  });

  final TabController tabController;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
            ]
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        tabs: const [
          Tab(text: 'LOGIN'),
          Tab(text: 'REGISTER'),
        ],
      ),
    );
  }
}

class _AuthForms extends StatelessWidget {
  const _AuthForms({
    required this.tabController,
    required this.buildForm,
  });

  final TabController tabController;
  final Widget Function(bool isRegister) buildForm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: TabBarView(
        controller: tabController,
        children: [
          buildForm(false),
          buildForm(true),
        ],
      ),
    );
  }
}

class _GuestAccessButton extends StatelessWidget {
  const _GuestAccessButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: const Icon(Icons.visibility_off),
      label: const Text('GAST ZUGANG'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.7),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "SECURE CONNECTION ESTABLISHED",
        style: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AuroraField extends StatelessWidget {
  const _AuroraField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.trailing,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? trailing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, letterSpacing: 1),
        prefixIcon: Icon(icon, size: 20, color: Colors.white),
        suffixIcon: trailing != null
            ? Container(
          width: 48,
          alignment: Alignment.centerRight,
          child: trailing,
        )
            : null,
      ),
    );
  }
}
