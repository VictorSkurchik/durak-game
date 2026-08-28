import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';
import '../theme/durak_colors.dart';
import 'suit_icon.dart';

class PlayingCardWidget extends StatelessWidget {
  final GameCard card;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  const PlayingCardWidget({super.key, required this.card, this.selected = false, this.dimmed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed ? DurakColors.suitRed : DurakColors.suitBlack;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          transform: selected ? (Matrix4.identity()..translateByDouble(0.0, -12.0, 0.0, 1.0)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: dimmed ? DurakColors.ivory.withValues(alpha: 0.55) : DurakColors.ivory,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? DurakColors.goldCore : DurakColors.cardBorder.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: [
              const BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1)),
              const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              if (selected)
                BoxShadow(color: DurakColors.goldCore.withValues(alpha: 0.55), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.rankLabel, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                  SuitIcon(suit: card.suit, color: color, size: 18),
                ],
              ),
              Positioned(
                top: 3,
                left: 4,
                child: Text(card.rankLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
              ),
              Positioned(
                bottom: 3,
                right: 4,
                child: Transform.rotate(
                  angle: math.pi,
                  child: Text(
                    card.rankLabel,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceDownCardWidget extends StatelessWidget {
  final double width;
  final double height;

  const FaceDownCardWidget({super.key, this.width = 56, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DurakColors.cardBackTop, DurakColors.cardBackBottom],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DurakColors.goldCore, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _CardBackPainter(),
        child: Center(
          child: Opacity(
            opacity: 0.35,
            child: SuitIcon(suit: Suit.spades, color: DurakColors.goldCore, size: width * 0.35),
          ),
        ),
      ),
    );
  }
}

/// Paints a subtle diagonal diamond-lattice pattern on the card back —
/// static and cheap, so it never needs to repaint.
class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DurakColors.goldCore.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (var i = -size.height.toInt(); i < size.width.toInt(); i += 10) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i + size.height, size.height), paint);
      canvas.drawLine(Offset(size.width - i.toDouble(), 0), Offset(size.width - i - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardBackPainter oldDelegate) => false;
}
