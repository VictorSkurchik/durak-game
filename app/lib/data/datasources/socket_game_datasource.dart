import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../domain/entities/game_action.dart';
import '../../domain/entities/game_view.dart';

Map<String, dynamic> _asJsonMap(dynamic data) => Map<String, dynamic>.from(data as Map);

/// Owns the single socket.io connection and turns its raw events into typed
/// streams. This is the only place in the app that knows socket.io exists.
class SocketGameDataSource {
  final String baseUrl;
  late final socket_io.Socket _socket;

  final _stateController = StreamController<GameView>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _waitingController = StreamController<void>.broadcast();

  Stream<GameView> get stateUpdates => _stateController.stream;
  Stream<String> get errors => _errorController.stream;
  Stream<void> get waitingForOpponent => _waitingController.stream;

  SocketGameDataSource({required this.baseUrl}) {
    _socket = socket_io.io(
      baseUrl,
      socket_io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket.onConnect((_) {});
    _socket.on('game_state', (data) => _stateController.add(GameView.fromJson(_asJsonMap(data))));
    _socket.on('room_error', (data) => _errorController.add(_asJsonMap(data)['message'] as String));
    _socket.on('action_error', (data) => _errorController.add(_asJsonMap(data)['message'] as String));
    _socket.on('waiting_for_opponent', (_) => _waitingController.add(null));
    _socket.connect();
  }

  void joinRoom({required String roomId, required String playerId, required String playerName}) {
    _socket.emit('join_room', {'roomId': roomId, 'playerId': playerId, 'playerName': playerName});
  }

  void sendAction(String roomId, GameAction action) {
    _socket.emit('game_action', {'roomId': roomId, 'action': action.toJson()});
  }

  void dispose() {
    _socket.dispose();
    _stateController.close();
    _errorController.close();
    _waitingController.close();
  }
}
