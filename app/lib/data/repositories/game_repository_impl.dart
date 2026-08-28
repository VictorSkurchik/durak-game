import '../../domain/entities/game_action.dart';
import '../../domain/entities/game_view.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/room_api.dart';
import '../datasources/socket_game_datasource.dart';

class GameRepositoryImpl implements GameRepository {
  final RoomApi _roomApi;
  final SocketGameDataSource _socket;

  GameRepositoryImpl({required RoomApi roomApi, required SocketGameDataSource socket})
      : _roomApi = roomApi,
        _socket = socket; // named params can't be initializing formals with different public names

  @override
  Stream<GameView> get stateUpdates => _socket.stateUpdates;

  @override
  Stream<String> get errors => _socket.errors;

  @override
  Stream<void> get waitingForOpponent => _socket.waitingForOpponent;

  @override
  Stream<void> get opponentDisconnected => _socket.opponentDisconnected;

  @override
  Future<String> createRoom({required String hostId, required String hostName}) =>
      _roomApi.createRoom(hostId: hostId, hostName: hostName);

  @override
  void joinRoom({required String roomId, required String playerId, required String playerName}) =>
      _socket.joinRoom(roomId: roomId, playerId: playerId, playerName: playerName);

  @override
  void sendAction(String roomId, GameAction action) => _socket.sendAction(roomId, action);

  @override
  void leaveRoom(String roomId, String playerId) => _socket.leaveRoom(roomId, playerId);

  @override
  void dispose() => _socket.dispose();
}
