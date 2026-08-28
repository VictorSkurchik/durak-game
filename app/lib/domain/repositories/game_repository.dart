import '../entities/game_action.dart';
import '../entities/game_view.dart';

/// Boundary between presentation and the outside world (REST + realtime
/// transport). Presentation code depends only on this abstraction, never on
/// socket.io or http directly, so the transport can be swapped or faked in
/// tests without touching UI code.
abstract class GameRepository {
  Stream<GameView> get stateUpdates;
  Stream<String> get errors;
  Stream<void> get waitingForOpponent;
  Stream<void> get opponentDisconnected;

  Future<String> createRoom({required String hostId, required String hostName});
  void joinRoom({required String roomId, required String playerId, required String playerName});
  void sendAction(String roomId, GameAction action);
  void leaveRoom(String roomId, String playerId);
  void dispose();
}
