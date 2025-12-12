import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:manhunt/screens/lobby_screen.dart';
import 'package:manhunt/screens/leaderboard_screen.dart';
import 'package:manhunt/screens/friends_screen.dart';

import '../widgets/design_components.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.isAnonymous,
    this.screensOverride,
    this.lastLobbyId,
  });

  final bool isAnonymous;
  final List<Widget>? screensOverride;
  final String? lastLobbyId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<_GlassNavItem> _defaultNavItems = [
    _GlassNavItem(icon: Icons.map_rounded, label: 'Lobbys'),
    _GlassNavItem(icon: Icons.auto_graph_rounded, label: 'Ranking'),
    _GlassNavItem(icon: Icons.people_alt_rounded, label: 'Freunde'),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = (widget.screensOverride?.isNotEmpty ?? false)
        ? widget.screensOverride!
        : [
            if (widget.lastLobbyId != null)
              LobbyScreen(lobbyId: widget.lastLobbyId!, asHost: false)
            else
              const _EmptyLobbyPlaceholder(),
            const LeaderboardScreen(),
            FriendsScreen(disabled: widget.isAnonymous),
          ];
    final hasScreens = screens.isNotEmpty;
    final int safeIndex = hasScreens
        ? (_index >= screens.length ? screens.length - 1 : _index)
        : 0;
    final navItems = List<_GlassNavItem>.generate(
      screens.length,
      (i) => i < _defaultNavItems.length
          ? _defaultNavItems[i]
          : _GlassNavItem(icon: Icons.circle, label: 'TAB ${i + 1}'),
    );
    return Scaffold(
      extendBody: true,
      body: hasScreens ? screens[safeIndex] : const SizedBox.shrink(),
      bottomNavigationBar: navItems.isEmpty
          ? null
          : _GlassNavBar(
              currentIndex: safeIndex,
              onSelect: (value) {
                if (value >= screens.length || _index == value) return;
                setState(() => _index = value);
              },
              items: navItems,
            ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.currentIndex,
    required this.onSelect,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<_GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [Color(0xD91B0D18), Color(0xCC0B0B16)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 25,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final selected = index == currentIndex;
                  final item = items[index];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onSelect(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF5F6D), Color(0xFF7A3EFD)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: selected ? null : Colors.white.withValues(alpha: 0.03),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: selected ? 0.25 : 0.08),
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.35),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  color: selected ? Colors.white : Colors.white70,
                                  size: 22,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: selected ? Colors.white : Colors.white60,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem {
  const _GlassNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _EmptyLobbyPlaceholder extends StatelessWidget {
  const _EmptyLobbyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ScreenBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.radar, size: 56, color: Colors.white24),
                SizedBox(height: 18),
                Text(
                  'KEIN AKTIVES MATCH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Starte eine neue Mission oder tritt einer Lobby bei, um das Hauptquartier zu aktivieren.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, letterSpacing: 1, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
