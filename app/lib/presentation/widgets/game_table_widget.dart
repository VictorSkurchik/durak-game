import 'package:flutter/material.dart';
import '../../domain/entities/table_slot.dart';
import 'playing_card_widget.dart';

class GameTableWidget extends StatelessWidget {
  final List<TableSlot> table;
  final void Function(TableSlot slot)? onSlotTap;

  const GameTableWidget({super.key, required this.table, this.onSlotTap});

  @override
  Widget build(BuildContext context) {
    if (table.isEmpty) {
      return const Center(
        child: Text('Стол пуст', style: TextStyle(color: Colors.white70)),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: table.map((slot) {
        return GestureDetector(
          onTap: onSlotTap == null ? null : () => onSlotTap!(slot),
          child: SizedBox(
            width: 64,
            height: 96,
            child: Stack(
              children: [
                PlayingCardWidget(card: slot.attack),
                if (slot.defense != null)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: PlayingCardWidget(card: slot.defense!),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
