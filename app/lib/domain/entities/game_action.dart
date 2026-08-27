import 'card.dart';

sealed class GameAction {
  final String playerId;
  const GameAction(this.playerId);

  Map<String, dynamic> toJson();
}

class AttackAction extends GameAction {
  final GameCard card;
  const AttackAction({required String playerId, required this.card}) : super(playerId);

  @override
  Map<String, dynamic> toJson() => {'type': 'ATTACK', 'playerId': playerId, 'card': card.toJson()};
}

class DefendAction extends GameAction {
  final GameCard card;
  final GameCard against;
  const DefendAction({required String playerId, required this.card, required this.against}) : super(playerId);

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'DEFEND', 'playerId': playerId, 'card': card.toJson(), 'against': against.toJson()};
}

class TakeAction extends GameAction {
  const TakeAction({required String playerId}) : super(playerId);

  @override
  Map<String, dynamic> toJson() => {'type': 'TAKE', 'playerId': playerId};
}

class PassAction extends GameAction {
  const PassAction({required String playerId}) : super(playerId);

  @override
  Map<String, dynamic> toJson() => {'type': 'PASS', 'playerId': playerId};
}
