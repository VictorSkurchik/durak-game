import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';
import 'suit_icon.dart';

class PlayingCardWidget extends StatelessWidget {
  final GameCard card;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  const PlayingCardWidget({super.key, required this.card, this.selected = false, this.dimmed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed ? Colors.red.shade700 : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        transform: selected ? (Matrix4.identity()..translateByDouble(0.0, -12.0, 0.0, 1.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: dimmed ? Colors.grey.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.black26, width: selected ? 2 : 1),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.rankLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            SuitIcon(suit: card.suit, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class FaceDownCardWidget extends StatelessWidget {
  const FaceDownCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.indigo.shade400,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade900),
      ),
      child: Center(
        child: Icon(Icons.style, color: Colors.indigo.shade100, size: 24),
      ),
    );
  }
}
