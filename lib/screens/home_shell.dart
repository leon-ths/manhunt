import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:manhunt/screens/lobby_screen.dart';
import 'package:manhunt/screens/leaderboard_screen.dart';
import 'package:manhunt/screens/friends_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.isAnonymous, this.screensOverride});

  final bool isAnonymous;
  final List<Widget>? screensOverride;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = widget.screensOverride ?? [
      const LobbyScreen(),
      const LeaderboardScreen(),
      FriendsScreen(disabled: widget.isAnonymous),
    ];
    return Scaffold(
      extendBody: true,
      body: screens[_index],
      bottomNavigationBar: _GlassNavBar(
        currentIndex: _index,
        onSelect: (value) => setState(() => _index = value),
        items: const [
          _GlassNavItem(icon: Icons.map_rounded, label: 'Lobbys'),
          _GlassNavItem(icon: Icons.auto_graph_rounded, label: 'Ranking'),
          _GlassNavItem(icon: Icons.people_alt_rounded, label: 'Freunde'),
        ],
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0x33FFFFFF), Color(0x22000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final selected = index == currentIndex;
                  final item = items[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelect(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF5F6D), Color(0xFF7A3EFD)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: selected ? Colors.white : Colors.white70,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: selected ? Colors.white : Colors.white70,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                          ],
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
