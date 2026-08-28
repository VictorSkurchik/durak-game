import 'package:flutter/material.dart';
import '../theme/durak_colors.dart';

/// Shared felt-table backdrop (radial gradient + vignette) used by every
/// screen so the "Emerald Rail" look stays identical everywhere instead of
/// three separately-hand-tuned gradients.
class FeltBackground extends StatelessWidget {
  final Widget child;

  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [DurakColors.feltHighlight, DurakColors.feltMid, DurakColors.feltShadow],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.3,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
