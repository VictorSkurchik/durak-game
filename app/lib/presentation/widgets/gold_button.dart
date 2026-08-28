import 'package:flutter/material.dart';
import '../theme/durak_colors.dart';

class _PressScale extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _PressScale({required this.onPressed, required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

/// Primary CTA — gold-gradient pill. Used for the main action on a screen
/// (create room, play again).
class GoldPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GoldPillButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return _PressScale(
      onPressed: onPressed,
      child: Container(
        // The shadow lives on this unclipped outer box so its blur can bleed
        // outward past the pill; the gradient fill is clipped separately
        // below so it can never bleed a square sliver past the rounded
        // corners (a BoxDecoration painting a gradient + borderRadius
        // together isn't reliably anti-aliased at the corners on web).
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? [BoxShadow(color: DurakColors.goldCore.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(colors: [DurakColors.goldHighlight, DurakColors.goldCore, DurakColors.goldShadow])
                    : null,
                color: enabled ? null : DurakColors.goldShadow.withValues(alpha: 0.4),
              ),
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(icon, size: 18, color: DurakColors.feltShadow)),
                    Text(label, style: const TextStyle(color: DurakColors.feltShadow, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action — gold-outlined pill. Used for join/leave/cancel-style
/// actions that shouldn't compete visually with the primary CTA.
class GoldOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GoldOutlinedButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onPressed: onPressed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: DurakColors.goldCore, width: 1.5),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) Padding(padding: const EdgeInsets.only(right: 8), child: Icon(icon, size: 18, color: DurakColors.goldCore)),
              Text(label, style: const TextStyle(color: DurakColors.goldCore, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ]),
          ),
        ),
      ),
    );
  }
}
