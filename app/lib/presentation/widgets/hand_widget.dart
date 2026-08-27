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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: hand
            .map((card) => PlayingCardWidget(
                  card: card,
                  selected: card == selected,
                  onTap: () => onCardTap(card),
                ))
            .toList(),
      ),
    );
  }
}
