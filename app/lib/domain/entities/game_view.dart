import 'card.dart';
import 'table_slot.dart';

enum GamePhase { inProgress, finished }

GamePhase _phaseFromWire(String value) => value == 'finished' ? GamePhase.finished : GamePhase.inProgress;

class YouInfo {
  final String id;
  final String name;
  final List<GameCard> hand;

  const YouInfo({required this.id, required this.name, required this.hand});

  factory YouInfo.fromJson(Map<String, dynamic> json) => YouInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        hand: (json['hand'] as List).map((c) => GameCard.fromJson(c as Map<String, dynamic>)).toList(),
      );
}

class OpponentInfo {
  final String id;
  final String name;
  final int cardCount;

  const OpponentInfo({required this.id, required this.name, required this.cardCount});

  factory OpponentInfo.fromJson(Map<String, dynamic> json) => OpponentInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        cardCount: json['cardCount'] as int,
      );
}

/// Mirrors the server's redacted per-player projection (`GameView` on the
/// backend) — the client only ever sees its own hand, never the opponent's.
class GameView {
  final String gameId;
  final GamePhase phase;
  final YouInfo you;
  final OpponentInfo opponent;
  final int deckCount;
  final GameCard trumpCard;
  final Suit trumpSuit;
  final List<TableSlot> table;
  final String attackerId;
  final String defenderId;
  final List<String> winnerOrder;
  final String? loserId;

  const GameView({
    required this.gameId,
    required this.phase,
    required this.you,
    required this.opponent,
    required this.deckCount,
    required this.trumpCard,
    required this.trumpSuit,
    required this.table,
    required this.attackerId,
    required this.defenderId,
    required this.winnerOrder,
    this.loserId,
  });

  bool get isYouAttacker => you.id == attackerId;
  bool get isYouDefender => you.id == defenderId;

  factory GameView.fromJson(Map<String, dynamic> json) => GameView(
        gameId: json['gameId'] as String,
        phase: _phaseFromWire(json['phase'] as String),
        you: YouInfo.fromJson(json['you'] as Map<String, dynamic>),
        opponent: OpponentInfo.fromJson(json['opponent'] as Map<String, dynamic>),
        deckCount: json['deckCount'] as int,
        trumpCard: GameCard.fromJson(json['trumpCard'] as Map<String, dynamic>),
        trumpSuit: suitFromWire(json['trumpSuit'] as String),
        table: (json['table'] as List).map((s) => TableSlot.fromJson(s as Map<String, dynamic>)).toList(),
        attackerId: json['attackerId'] as String,
        defenderId: json['defenderId'] as String,
        winnerOrder: (json['winnerOrder'] as List).cast<String>(),
        loserId: json['loserId'] as String?,
      );
}
