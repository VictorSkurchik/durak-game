export const SUITS = ["hearts", "diamonds", "clubs", "spades"] as const;
export type Suit = (typeof SUITS)[number];

export const RANKS = [6, 7, 8, 9, 10, 11, 12, 13, 14] as const;
export type Rank = (typeof RANKS)[number];

export interface Card {
  readonly suit: Suit;
  readonly rank: Rank;
}

export function cardsEqual(a: Card, b: Card): boolean {
  return a.suit === b.suit && a.rank === b.rank;
}

/** Can `defender` legally beat `attacker` given the trump suit? */
export function beats(defender: Card, attacker: Card, trumpSuit: Suit): boolean {
  if (defender.suit === attacker.suit) {
    return defender.rank > attacker.rank;
  }
  return defender.suit === trumpSuit && attacker.suit !== trumpSuit;
}
