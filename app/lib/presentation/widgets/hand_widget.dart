import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';
import 'playing_card_widget.dart';

class HandWidget extends StatelessWidget {
  final List<GameCard> hand;
  final GameCard? selected;
  final ValueChanged<GameCard> onCardTap;

  const HandWidget({super.key, required this.hand, required this.onCardTap, this.selected});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const estimatedCardWidth = 62.0;
        final estimatedWidth = hand.length * estimatedCardWidth;

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(hand.length, (index) {
            final card = hand[index];
            return TweenAnimationBuilder<double>(
              key: ValueKey('${card.suit}-${card.rank}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 250 + index * 40),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 16),
                  child: child,
                ),
              ),
              child: PlayingCardWidget(
                card: card,
                selected: card == selected,
                onTap: () => onCardTap(card),
              ),
            );
          }),
        );

        if (estimatedWidth < constraints.maxWidth) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: row),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: row,
        );
      },
    );
  }
}
