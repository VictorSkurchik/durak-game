import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/game_action.dart';
import '../../domain/entities/game_view.dart';
import '../../domain/repositories/game_repository.dart';

enum ConnectionStatus { idle, waitingForOpponent, inGame }

class GameControllerState {
  final ConnectionStatus status;
  final String? roomId;
  final GameView? view;
  final String? errorMessage;

  const GameControllerState({this.status = ConnectionStatus.idle, this.roomId, this.view, this.errorMessage});

  GameControllerState copyWith({
    ConnectionStatus? status,
    String? roomId,
    GameView? view,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GameControllerState(
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      view: view ?? this.view,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Presentation-layer state machine for a single game session. Talks only to
/// [GameRepository] — it has no idea whether that's backed by sockets, REST,
/// or a fake in a test.
class GameController extends StateNotifier<GameControllerState> {
  final GameRepository _repository;
  final String playerId;

  late final StreamSubscription _stateSub;
  late final StreamSubscription _errorSub;
  late final StreamSubscription _waitingSub;
  late final StreamSubscription _opponentDisconnectedSub;

  GameController({required GameRepository repository, required this.playerId})
      : _repository = repository,
        super(const GameControllerState()) {
    _stateSub = _repository.stateUpdates.listen((view) {
      state = state.copyWith(view: view, status: ConnectionStatus.inGame, clearError: true);
    });
    _errorSub = _repository.errors.listen((message) {
      state = state.copyWith(errorMessage: message);
    });
    _waitingSub = _repository.waitingForOpponent.listen((_) {
      state = state.copyWith(status: ConnectionStatus.waitingForOpponent);
    });
    _opponentDisconnectedSub = _repository.opponentDisconnected.listen((_) {
      state = state.copyWith(errorMessage: 'Соперник отключился');
    });
  }

  Future<void> createRoom(String playerName) async {
    try {
      final roomId = await _repository.createRoom(hostId: playerId, hostName: playerName);
      state = state.copyWith(roomId: roomId, clearError: true);
      _repository.joinRoom(roomId: roomId, playerId: playerId, playerName: playerName);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Не удалось создать комнату. Проверьте соединение и попробуйте снова.');
    }
  }

  void joinRoom(String roomId, String playerName) {
    state = state.copyWith(roomId: roomId, clearError: true);
    _repository.joinRoom(roomId: roomId, playerId: playerId, playerName: playerName);
  }

  void attack(GameCard card) => _dispatch(AttackAction(playerId: playerId, card: card));

  void defend(GameCard card, GameCard against) =>
      _dispatch(DefendAction(playerId: playerId, card: card, against: against));

  void take() => _dispatch(TakeAction(playerId: playerId));

  void pass() => _dispatch(PassAction(playerId: playerId));

  void leaveRoom() {
    final roomId = state.roomId;
    if (roomId != null) {
      _repository.leaveRoom(roomId, playerId);
    }
    state = const GameControllerState();
  }

  void _dispatch(GameAction action) {
    final roomId = state.roomId;
    if (roomId == null) return;
    _repository.sendAction(roomId, action);
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _errorSub.cancel();
    _waitingSub.cancel();
    _opponentDisconnectedSub.cancel();
    super.dispose();
  }
}
