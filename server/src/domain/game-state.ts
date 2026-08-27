import { Card, Suit } from "./card.js";

export interface PlayerState {
  readonly id: string;
  readonly name: string;
  readonly hand: Card[];
}

export interface TableSlot {
  readonly attack: Card;
  defense?: Card;
}

export type GamePhase = "in_progress" | "finished";

export interface GameState {
  readonly id: string;
  phase: GamePhase;
  players: [PlayerState, PlayerState];
  deck: Card[];
  readonly trumpSuit: Suit;
  readonly trumpCard: Card;
  table: TableSlot[];
  discardCount: number;
  attackerId: string;
  defenderId: string;
  winnerOrder: string[];
  loserId?: string;
}

export function otherPlayerId(state: GameState, playerId: string): string {
  const other = state.players.find((p) => p.id !== playerId);
  if (!other) throw new Error(`No opponent found for player ${playerId}`);
  return other.id;
}

export function getPlayer(state: GameState, playerId: string): PlayerState {
  const player = state.players.find((p) => p.id === playerId);
  if (!player) throw new Error(`Unknown player ${playerId}`);
  return player;
}
