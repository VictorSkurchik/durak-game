import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:durak_app/domain/entities/game_action.dart';
import 'package:durak_app/domain/entities/game_view.dart';
import 'package:durak_app/domain/repositories/game_repository.dart';
import 'package:durak_app/main.dart';
import 'package:durak_app/presentation/state/providers.dart';

/// The repository abstraction means widget tests never need a real socket
/// connection — a fake standing in for [GameRepository] is enough to render
/// and interact with the UI in isolation.
class FakeGameRepository implements GameRepository {
  @override
  Stream<GameView> get stateUpdates => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  Stream<void> get waitingForOpponent => const Stream.empty();
  @override
  Stream<void> get opponentDisconnected => const Stream.empty();
  @override
  Future<String> createRoom({required String hostId, required String hostName}) async => 'ABC123';
  @override
  void joinRoom({required String roomId, required String playerId, required String playerName}) {}
  @override
  void sendAction(String roomId, GameAction action) {}
  @override
  void leaveRoom(String roomId, String playerId) {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('Lobby screen renders and lets the user type a name', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameRepositoryProvider.overrideWithValue(FakeGameRepository()),
          // Avoids depending on the real shared_preferences plugin (unmocked
          // in widget tests) for the id `_AppBootstrap` (main.dart) gates on.
          playerIdProvider.overrideWith((ref) async => 'test-player-id'),
        ],
        child: const DurakApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Дурак'), findsOneWidget);
    expect(find.text('Создать комнату'), findsOneWidget);
    expect(find.text('Войти в комнату'), findsOneWidget);
  });
}
