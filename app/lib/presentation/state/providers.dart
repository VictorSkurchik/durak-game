import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/app_config.dart';
import '../../data/datasources/room_api.dart';
import '../../data/datasources/socket_game_datasource.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../domain/repositories/game_repository.dart';
import 'game_controller.dart';

/// A stable player id persisted to local storage. In a production app this
/// would come from an auth session; for this demo a generated id that
/// survives page refreshes / app restarts is enough to let the server's
/// reconnect-by-playerId support actually work.
final playerIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  const key = 'durak_player_id';
  final existing = prefs.getString(key);
  if (existing != null) return existing;
  final fresh = const Uuid().v4();
  await prefs.setString(key, fresh);
  return fresh;
});

final roomApiProvider = Provider<RoomApi>((ref) => RoomApi(baseUrl: AppConfig.serverBaseUrl));

final socketDataSourceProvider = Provider<SocketGameDataSource>((ref) {
  final source = SocketGameDataSource(baseUrl: AppConfig.serverBaseUrl);
  ref.onDispose(source.dispose);
  return source;
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final repository = GameRepositoryImpl(
    roomApi: ref.watch(roomApiProvider),
    socket: ref.watch(socketDataSourceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Only ever watched after `_AppBootstrap` (main.dart) confirms
/// [playerIdProvider] has resolved, so `requireValue` is safe here — it
/// avoids rebuilding this controller (and disposing an in-flight one) when
/// the async id first resolves.
final gameControllerProvider = StateNotifierProvider<GameController, GameControllerState>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  final playerId = ref.watch(playerIdProvider).requireValue;
  return GameController(repository: repository, playerId: playerId);
});
