import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/state/providers.dart';
import 'presentation/theme/durak_colors.dart';
import 'presentation/widgets/felt_background.dart';

void main() {
  runApp(const ProviderScope(child: DurakApp()));
}

class DurakApp extends StatelessWidget {
  const DurakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Дурак',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: DurakColors.goldCore, brightness: Brightness.dark).copyWith(
          primary: DurakColors.goldCore,
          onPrimary: DurakColors.feltShadow,
          surface: DurakColors.feltMid,
          onSurface: DurakColors.textPrimary,
          error: DurakColors.alertAmber,
        ),
        scaffoldBackgroundColor: DurakColors.feltShadow,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: DurakColors.feltMid,
          contentTextStyle: const TextStyle(color: DurakColors.textPrimary),
        ),
      ),
      home: const _AppBootstrap(),
    );
  }
}

/// Waits for [playerIdProvider] to resolve before mounting anything that
/// depends on [gameControllerProvider]. Without this gate, a user could
/// dispatch an action (e.g. create room) against the transient placeholder
/// controller built while the id is still loading; by the time the network
/// response arrives, playerIdProvider has resolved, gameControllerProvider
/// has rebuilt, and the original controller instance is already disposed.
class _AppBootstrap extends ConsumerWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerId = ref.watch(playerIdProvider);
    return playerId.when(
      data: (_) => const HomeScreen(),
      loading: () => const Scaffold(
        backgroundColor: DurakColors.feltShadow,
        body: FeltBackground(child: Center(child: CircularProgressIndicator(color: DurakColors.goldCore))),
      ),
      error: (_, _) => const HomeScreen(),
    );
  }
}
