import 'package:flutter/material.dart';
import '../../domain/entities/card.dart';
import '../../domain/entities/table_slot.dart';
import 'playing_card_widget.dart';
import '../theme/durak_colors.dart';
import 'suit_icon.dart';

class GameTableWidget extends StatelessWidget {
  final List<TableSlot> table;
  final void Function(TableSlot slot)? onSlotTap;
  final bool highlightAvailable;

  const GameTableWidget({
    super.key,
    required this.table,
    this.onSlotTap,
    this.highlightAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DurakColors.feltMid,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DurakColors.goldCore, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: table.isEmpty
          ? Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.08,
                    child: SuitIcon(
                      suit: Suit.spades,
                      color: DurakColors.textPrimary,
                      size: 96,
                    ),
                  ),
                  Text(
                    'Стол пуст',
                    style: TextStyle(
                      color: DurakColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: table.map((slot) {
                return GestureDetector(
                  onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      boxShadow: (highlightAvailable && slot.defense == null)
                          ? [
                              BoxShadow(
                                color: DurakColors.goldCore.withValues(alpha: 0.6),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: SizedBox(
                      width: 64,
                      height: 96,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('${slot.attack.rank}${slot.attack.suit}'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        builder: (_, t, child) => Opacity(
                          opacity: t.clamp(0, 1),
                          child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            PlayingCardWidget(card: slot.attack),
                            if (slot.defense != null)
                              Positioned(
                                left: 14,
                                top: 14,
                                child: Transform.rotate(
                                  angle: 0.12,
                                  child: PlayingCardWidget(card: slot.defense!),
                                ),
                              ),
                            if (slot.defense != null)
                              Positioned(
                                right: -4,
                                bottom: -6,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: DurakColors.ivory,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: DurakColors.goldCore, width: 1.5),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 3),
                                    ],
                                  ),
                                  child: Icon(Icons.check, size: 12, color: DurakColors.feltShadow),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
