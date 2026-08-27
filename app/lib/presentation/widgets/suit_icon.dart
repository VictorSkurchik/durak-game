import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';

/// Draws suit glyphs instead of relying on the ♥♦♣♠ Unicode characters —
/// Flutter web's bundled font doesn't include them, which renders as tofu
/// boxes. A CustomPainter guarantees identical output on every platform.
class SuitIcon extends StatelessWidget {
  final Suit suit;
  final double size;
  final Color color;

  const SuitIcon({super.key, required this.suit, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _SuitPainter(suit, color));
  }
}

class _SuitPainter extends CustomPainter {
  final Suit suit;
  final Color color;
  _SuitPainter(this.suit, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    switch (suit) {
      case Suit.hearts:
        canvas.drawPath(_heart(size), paint);
      case Suit.diamonds:
        canvas.drawPath(_diamond(size), paint);
      case Suit.spades:
        canvas.drawPath(_spade(size), paint);
      case Suit.clubs:
        _drawClub(canvas, size, paint);
    }
  }

  Path _heart(Size s) {
    return Path()
      ..moveTo(s.width * 0.5, s.height * 0.35)
      ..cubicTo(s.width * 0.2, s.height * 0.05, -s.width * 0.05, s.height * 0.3, s.width * 0.5, s.height * 0.78)
      ..cubicTo(s.width * 1.05, s.height * 0.3, s.width * 0.8, s.height * 0.05, s.width * 0.5, s.height * 0.35)
      ..close();
  }

  Path _diamond(Size s) {
    return Path()
      ..moveTo(s.width * 0.5, 0)
      ..lineTo(s.width, s.height * 0.5)
      ..lineTo(s.width * 0.5, s.height)
      ..lineTo(0, s.height * 0.5)
      ..close();
  }

  Path _spade(Size s) {
    final bulb = Path()
      ..moveTo(s.width * 0.5, s.height * 0.05)
      ..cubicTo(s.width * 1.05, s.height * 0.55, s.width * 0.8, s.height * 0.8, s.width * 0.5, s.height * 0.5)
      ..cubicTo(s.width * 0.2, s.height * 0.8, -s.width * 0.05, s.height * 0.55, s.width * 0.5, s.height * 0.05)
      ..close();
    final stem = Path()
      ..moveTo(s.width * 0.38, s.height * 0.72)
      ..lineTo(s.width * 0.62, s.height * 0.72)
      ..lineTo(s.width * 0.5, s.height)
      ..close();
    return Path.combine(PathOperation.union, bulb, stem);
  }

  void _drawClub(Canvas canvas, Size s, Paint paint) {
    final r = s.width * 0.22;
    canvas.drawCircle(Offset(s.width * 0.5, s.height * 0.32), r, paint);
    canvas.drawCircle(Offset(s.width * 0.28, s.height * 0.58), r, paint);
    canvas.drawCircle(Offset(s.width * 0.72, s.height * 0.58), r, paint);
    final stem = Path()
      ..moveTo(s.width * 0.4, s.height * 0.62)
      ..lineTo(s.width * 0.6, s.height * 0.62)
      ..lineTo(s.width * 0.5, s.height)
      ..close();
    canvas.drawPath(stem, paint);
  }

  @override
  bool shouldRepaint(covariant _SuitPainter oldDelegate) => oldDelegate.suit != suit || oldDelegate.color != color;
}
