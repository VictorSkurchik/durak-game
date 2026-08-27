import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/game_view.dart';
import '../../domain/entities/table_slot.dart';
import '../state/game_controller.dart';
import '../state/providers.dart';
import '../widgets/game_table_widget.dart';
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
      backgroundColor: const Color(0xFF0B3D2E),
      body: SafeArea(
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
            _TurnBanner(view: view),
            if (view.phase == GamePhase.finished)
              _GameOverBanner(view: view)
            else
              _ActionBar(
                youAreAttacker: youAreAttacker,
                canTake: view.isYouDefender && undefendedExists,
                canPass: youAreAttacker && tableFullyDefended,
                onTake: controller.take,
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

class _WaitingScaffold extends StatelessWidget {
  final String? roomId;
  final String? error;
  const _WaitingScaffold({required this.roomId, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white70),
            const SizedBox(height: 24),
            if (roomId != null) ...[
              const Text('Код комнаты — отправьте сопернику:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: roomId!)),
                child: Text(
                  roomId!,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 8),
              const Text('(нажмите, чтобы скопировать)', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpponentBar extends StatelessWidget {
  final GameView view;
  const _OpponentBar({required this.view});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${view.opponent.name} · ${view.opponent.cardCount} карт',
              style: const TextStyle(color: Colors.white70)),
          Row(children: List.generate(view.opponent.cardCount.clamp(0, 6), (_) => const Padding(
                padding: EdgeInsets.only(left: 4),
                child: FaceDownCardWidget(),
              ))),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Козырь: ', style: TextStyle(color: Colors.white70)),
          PlayingCardWidget(card: view.trumpCard),
          const SizedBox(width: 16),
          Text('В колоде: ${view.deckCount}', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  final GameView view;
  const _TurnBanner({required this.view});

  @override
  Widget build(BuildContext context) {
    final text = view.isYouAttacker ? 'Ваш ход: атакуйте' : 'Ход соперника: защищайтесь';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool youAreAttacker;
  final bool canTake;
  final bool canPass;
  final VoidCallback onTake;
  final VoidCallback onPass;

  const _ActionBar({
    required this.youAreAttacker,
    required this.canTake,
    required this.canPass,
    required this.onTake,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canTake)
            FilledButton.tonal(onPressed: onTake, child: const Text('Взять')),
          if (canPass) ...[
            const SizedBox(width: 12),
            FilledButton(onPressed: onPass, child: const Text('Бито')),
          ],
        ],
      ),
    );
  }
}

class _GameOverBanner extends StatelessWidget {
  final GameView view;
  const _GameOverBanner({required this.view});

  @override
  Widget build(BuildContext context) {
    final youWon = view.winnerOrder.contains(view.you.id);
    final isDraw = view.loserId == null;
    final text = isDraw ? 'Ничья!' : (youWon ? 'Вы победили! 🎉' : 'Вы — дурак 🙃');
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}
