import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/game_view.dart';
import '../../domain/entities/table_slot.dart';
import '../state/game_controller.dart';
import '../state/providers.dart';
import '../theme/durak_colors.dart';
import '../widgets/felt_background.dart';
import '../widgets/game_table_widget.dart';
import '../widgets/gold_button.dart';
import '../widgets/hand_widget.dart';
import '../widgets/playing_card_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameCard? _selectedCard;

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final view = controllerState.view;

    if (view == null) {
      return _WaitingScaffold(roomId: controllerState.roomId, error: controllerState.errorMessage);
    }

    final youAreAttacker = view.isYouAttacker;
    final undefendedExists = view.table.any((s) => s.defense == null);
    final tableFullyDefended = view.table.isNotEmpty && view.table.every((s) => s.defense != null);

    return Scaffold(
      backgroundColor: DurakColors.feltShadow,
      body: FeltBackground(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      children: [
                        _OpponentBar(view: view),
                        _TrumpAndDeckBar(view: view),
                        Expanded(
                          child: GameTableWidget(
                            table: view.table,
                            onSlotTap: (slot) => _onSlotTap(controller, view, slot),
                          ),
                        ),
                        _TurnBanner(view: view, errorMessage: controllerState.errorMessage),
                        _ActionBar(
                          youAreAttacker: youAreAttacker,
                          canTake: view.isYouDefender && undefendedExists,
                          canPass: youAreAttacker && tableFullyDefended,
                          isFinished: view.phase == GamePhase.finished,
                          onTake: () {
                            controller.take();
                            setState(() => _selectedCard = null);
                          },
                          onPass: () {
                            controller.pass();
                            setState(() => _selectedCard = null);
                          },
                        ),
                        HandWidget(
                          hand: view.you.hand,
                          selected: _selectedCard,
                          onCardTap: (card) => _onCardTap(controller, view, card),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (view.phase == GamePhase.finished)
              _GameOverOverlay(view: view, onPlayAgain: controller.leaveRoom),
          ],
        ),
      ),
    );
  }

  void _onCardTap(GameController controller, GameView view, GameCard card) {
    if (view.phase == GamePhase.finished) return;

    if (view.isYouAttacker) {
      controller.attack(card);
      return;
    }

    setState(() => _selectedCard = _selectedCard == card ? null : card);
  }

  void _onSlotTap(GameController controller, GameView view, TableSlot slot) {
    if (!view.isYouDefender || slot.defense != null || _selectedCard == null) return;
    controller.defend(_selectedCard!, slot.attack);
    setState(() => _selectedCard = null);
  }
}

class _WaitingScaffold extends ConsumerWidget {
  final String? roomId;
  final String? error;
  const _WaitingScaffold({required this.roomId, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = this.roomId;
    return Scaffold(
      backgroundColor: DurakColors.feltShadow,
      body: FeltBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ShuffleLoader(),
              const SizedBox(height: 24),
              if (roomId != null) ...[
                const Text('Код комнаты — отправьте сопернику:', style: TextStyle(color: DurakColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < roomId.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 200 + i * 60),
                          curve: Curves.easeOutBack,
                          tween: Tween(begin: 0, end: 1),
                          builder: (_, t, child) => Opacity(
                            opacity: t.clamp(0, 1),
                            child: Transform.scale(scale: t.clamp(0, 1), child: child),
                          ),
                          child: Container(
                            width: 34,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: DurakColors.feltMid,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: DurakColors.goldCore, width: 1.5),
                            ),
                            child: Text(
                              roomId.substring(i, i + 1),
                              style: const TextStyle(
                                color: DurakColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                GoldOutlinedButton(
                  label: 'Скопировать код',
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Скопировано!'), duration: Duration(milliseconds: 1200)),
                    );
                  },
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(error!, style: const TextStyle(color: DurakColors.alertAmber)),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.read(gameControllerProvider.notifier).leaveRoom(),
                child: const Text('Выйти в лобби', style: TextStyle(color: DurakColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small bobbing 3-card "shuffle" loader shown while waiting for the
/// opponent — a bit friendlier than a bare spinner while keeping the same
/// felt-and-gold visual language as the rest of the screen.
class _ShuffleLoader extends StatefulWidget {
  const _ShuffleLoader();

  @override
  State<_ShuffleLoader> createState() => _ShuffleLoaderState();
}

class _ShuffleLoaderState extends State<_ShuffleLoader> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 74,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 22.0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  final offset = math.sin((_controller.value + i / 3.0) * 2 * math.pi) * 6;
                  return Transform.translate(offset: Offset(0, offset), child: child);
                },
                child: const FaceDownCardWidget(width: 40, height: 58),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpponentBar extends StatelessWidget {
  final GameView view;
  const _OpponentBar({required this.view});

  @override
  Widget build(BuildContext context) {
    final isNarrowLocal = MediaQuery.of(context).size.width < 720;
    final visibleCount = view.opponent.cardCount.clamp(0, isNarrowLocal ? 4 : 6);
    final extra = view.opponent.cardCount - visibleCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '${view.opponent.name} · ${view.opponent.cardCount} карт',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: DurakColors.textSecondary),
            ),
          ),
          SizedBox(
            height: 62,
            // +16 buffer absorbs the bounding-box growth from Transform.rotate on
            // the fanned cards below, which otherwise gets hard-clipped by Stack.
            width: 40.0 + (visibleCount - 1).clamp(0, 999) * 18.0 + (extra > 0 ? 28 : 0) + 16,
            child: Stack(
              children: [
                for (var i = 0; i < visibleCount; i++)
                  Positioned(
                    left: i * 18.0,
                    child: Transform.rotate(
                      angle: (i - visibleCount / 2) * 0.05,
                      child: const FaceDownCardWidget(width: 40, height: 58),
                    ),
                  ),
                if (extra > 0)
                  Positioned(
                    left: visibleCount * 18.0,
                    top: 18,
                    child: Container(
                      width: 26,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DurakColors.feltMid,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: DurakColors.goldCore, width: 1),
                      ),
                      child: Text(
                        '+$extra',
                        style: const TextStyle(color: DurakColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrumpAndDeckBar extends StatelessWidget {
  final GameView view;
  const _TrumpAndDeckBar({required this.view});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.8,
      color: DurakColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('КОЗЫРЬ', style: labelStyle),
          const SizedBox(width: 8),
          PlayingCardWidget(card: view.trumpCard),
          const SizedBox(width: 16),
          const Text('В КОЛОДЕ', style: labelStyle),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DurakColors.feltMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DurakColors.goldCore.withValues(alpha: 0.5)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '${view.deckCount}',
                key: ValueKey(view.deckCount),
                style: const TextStyle(color: DurakColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  final GameView view;
  final String? errorMessage;
  const _TurnBanner({required this.view, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final text = view.isYouAttacker ? 'Ваш ход: атакуйте' : 'Ход соперника: защищайтесь';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: DurakColors.feltMid,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DurakColors.goldCore, width: 1.5),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  text,
                  key: ValueKey(text),
                  style: const TextStyle(color: DurakColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DurakColors.alertAmber, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool youAreAttacker;
  final bool canTake;
  final bool canPass;
  final bool isFinished;
  final VoidCallback onTake;
  final VoidCallback onPass;

  const _ActionBar({
    required this.youAreAttacker,
    required this.canTake,
    required this.canPass,
    required this.isFinished,
    required this.onTake,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    if (isFinished) {
      return const SizedBox(height: 44);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canTake)
            GoldOutlinedButton(label: 'Взять', icon: Icons.download_rounded, onPressed: onTake),
          if (canPass) ...[
            const SizedBox(width: 12),
            GoldPillButton(label: 'Бито', icon: Icons.check_circle_rounded, onPressed: onPass),
          ],
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final GameView view;
  final VoidCallback onPlayAgain;
  const _GameOverOverlay({required this.view, required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    final youWon = view.winnerOrder.contains(view.you.id);
    final isDraw = view.loserId == null;
    final IconData icon = isDraw ? Icons.handshake : (youWon ? Icons.emoji_events : Icons.sentiment_dissatisfied);
    final Color iconColor = isDraw || !youWon ? DurakColors.textSecondary : DurakColors.goldCore;
    final String text = isDraw ? 'Ничья!' : (youWon ? 'Вы победили!' : 'Вы — дурак');
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Opacity(opacity: t.clamp(0, 1), child: Transform.scale(scale: 0.85 + 0.15 * t, child: child)),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: DurakColors.ivory,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DurakColors.goldCore, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 56, color: iconColor),
                const SizedBox(height: 12),
                Text(text, style: const TextStyle(color: DurakColors.feltShadow, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                GoldPillButton(label: 'Играть снова', icon: Icons.replay, onPressed: onPlayAgain),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
