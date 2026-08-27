import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_config.dart';
import '../../data/datasources/room_api.dart';
import '../../data/datasources/socket_game_datasource.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_controller.dart';

/// A stable per-app-launch player id. In a production app this would come
/// from an auth session; for this demo a generated id is enough to identify
/// "this browser tab / this device" across reconnects within the same run.
final playerIdProvider = Provider<String>((ref) => const Uuid().v4());

final roomApiProvider = Provider<RoomApi>((ref) => RoomApi(baseUrl: AppConfig.serverBaseUrl));

final socketDataSourceProvider = Provider<SocketGameDataSource>((ref) {
  final source = SocketGameDataSource(baseUrl: AppConfig.serverBaseUrl);
  ref.onDispose(source.dispose);
  return source;
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(
    roomApi: ref.watch(roomApiProvider),
    socket: ref.watch(socketDataSourceProvider),
  );
});

final gameControllerProvider = StateNotifierProvider<GameController, GameControllerState>((ref) {
  return GameController(
    repository: ref.watch(gameRepositoryProvider),
    playerId: ref.watch(playerIdProvider),
  );
});
