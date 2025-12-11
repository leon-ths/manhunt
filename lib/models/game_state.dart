import 'package:manhunt/models/game_player.dart';

class GameState {
  final DateTime gameEndsAt;
  final List<GamePlayer> hunters;
  final List<GamePlayer> runners;
  final bool speedhuntActive;
  final String? speedhuntTargetUid;

  const GameState({
    required this.gameEndsAt,
    required this.hunters,
    required this.runners,
    required this.speedhuntActive,
    required this.speedhuntTargetUid,
  });
}
