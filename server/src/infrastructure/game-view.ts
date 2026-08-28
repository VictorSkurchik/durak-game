import { Card } from "../domain/card.js";
import { GameState, otherPlayerId } from "../domain/game-state.js";

/**
 * A player should never receive the opponent's actual hand over the wire,
 * only how many cards they hold. This projects the shared GameState into
 * a per-recipient DTO safe to send over the socket.
 */
export interface GameView {
  gameId: string;
  phase: GameState["phase"];
  you: { id: string; name: string; hand: Card[] };
  opponent: { id: string; name: string; cardCount: number };
  deckCount: number;
  discardCount: number;
  trumpCard: Card;
  trumpSuit: Card["suit"];
  table: { attack: Card; defense?: Card }[];
  attackerId: string;
  defenderId: string;
  winnerOrder: string[];
  loserId?: string;
}

export function toGameView(state: GameState, forPlayerId: string): GameView {
  const you = state.players.find((p) => p.id === forPlayerId)!;
  const opponentId = otherPlayerId(state, forPlayerId);
  const opponent = state.players.find((p) => p.id === opponentId)!;

  return {
    gameId: state.id,
    phase: state.phase,
    you: { id: you.id, name: you.name, hand: you.hand },
    opponent: { id: opponent.id, name: opponent.name, cardCount: opponent.hand.length },
    deckCount: state.deck.length,
    discardCount: state.discardCount,
    trumpCard: state.trumpCard,
    trumpSuit: state.trumpSuit,
    table: state.table,
    attackerId: state.attackerId,
    defenderId: state.defenderId,
    winnerOrder: state.winnerOrder,
    loserId: state.loserId,
  };
}
