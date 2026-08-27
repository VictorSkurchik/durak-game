import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import 'game_screen.dart';
import 'lobby_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRoom = ref.watch(gameControllerProvider.select((s) => s.roomId != null));
    return hasRoom ? const GameScreen() : const LobbyScreen();
  }
}
