import 'card.dart';

class TableSlot {
  final GameCard attack;
  final GameCard? defense;

  const TableSlot({required this.attack, this.defense});

  factory TableSlot.fromJson(Map<String, dynamic> json) => TableSlot(
        attack: GameCard.fromJson(json['attack'] as Map<String, dynamic>),
        defense: json['defense'] == null ? null : GameCard.fromJson(json['defense'] as Map<String, dynamic>),
      );
}
