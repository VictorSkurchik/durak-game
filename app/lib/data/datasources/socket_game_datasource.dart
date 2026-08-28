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
  final _opponentDisconnectedController = StreamController<void>.broadcast();

  Stream<GameView> get stateUpdates => _stateController.stream;
  Stream<String> get errors => _errorController.stream;
  Stream<void> get waitingForOpponent => _waitingController.stream;
  Stream<void> get opponentDisconnected => _opponentDisconnectedController.stream;

  SocketGameDataSource({required this.baseUrl}) {
    _socket = socket_io.io(
      baseUrl,
      socket_io.OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    // NOTE: on the socket.io client's own auto-reconnect (a new underlying
    // transport on this same Socket object), room membership is not
    // automatically re-established server-side. Re-emitting join_room after
    // a transport reconnect would require this datasource to know the last
    // room/player identity, which lives in GameController — that coordination
    // is a known follow-up, intentionally not built here.
    _socket.onConnect((_) {});
    _socket.on('game_state', (data) {
      try {
        _stateController.add(GameView.fromJson(_asJsonMap(data)));
      } catch (err) {
        _errorController.add('Received malformed data from server: ${err.toString()}');
      }
    });
    _socket.on('room_error', (data) {
      try {
        _errorController.add(_asJsonMap(data)['message'] as String);
      } catch (err) {
        _errorController.add('Received malformed data from server: ${err.toString()}');
      }
    });
    _socket.on('action_error', (data) {
      try {
        _errorController.add(_asJsonMap(data)['message'] as String);
      } catch (err) {
        _errorController.add('Received malformed data from server: ${err.toString()}');
      }
    });
    _socket.on('waiting_for_opponent', (_) => _waitingController.add(null));
    _socket.on('opponent_disconnected', (_) => _opponentDisconnectedController.add(null));
    _socket.connect();
  }

  void joinRoom({required String roomId, required String playerId, required String playerName}) {
    _socket.emit('join_room', {'roomId': roomId, 'playerId': playerId, 'playerName': playerName});
  }

  void sendAction(String roomId, GameAction action) {
    _socket.emit('game_action', {'roomId': roomId, 'action': action.toJson()});
  }

  void leaveRoom(String roomId, String playerId) {
    _socket.emit('leave_room', {'roomId': roomId, 'playerId': playerId});
  }

  void dispose() {
    _socket.dispose();
    _stateController.close();
    _errorController.close();
    _waitingController.close();
    _opponentDisconnectedController.close();
  }
}
