import { describe, expect, it } from "vitest";
import { Card } from "./card.js";
import { applyAction, createGame } from "./durak-engine.js";
import { GameState } from "./game-state.js";

/** Deterministic PRNG so dealing/shuffling is reproducible in tests. */
function seededRandom(seed: number): () => number {
  let state = seed;
  return () => {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    return state / 0x7fffffff;
  };
}

function fixtureState(overrides: Partial<GameState> = {}): GameState {
  const base: GameState = {
    id: "game-1",
    phase: "in_progress",
    players: [
      { id: "p1", name: "Alice", hand: [] },
      { id: "p2", name: "Bob", hand: [] },
    ],
    deck: [],
    trumpSuit: "spades",
    trumpCard: { suit: "spades", rank: 6 },
    table: [],
    discardCount: 0,
    attackerId: "p1",
    defenderId: "p2",
    winnerOrder: [],
  };
  return { ...base, ...overrides };
}

const c = (suit: Card["suit"], rank: Card["rank"]): Card => ({ suit, rank });

describe("createGame", () => {
  it("deals 6 cards to each player and exposes a trump card", () => {
    const game = createGame("g1", { id: "p1", name: "Alice" }, { id: "p2", name: "Bob" }, seededRandom(42));
    expect(game.players[0].hand).toHaveLength(6);
    expect(game.players[1].hand).toHaveLength(6);
    expect(game.trumpCard).toBeDefined();
    expect(game.deck.length).toBe(36 - 12);
    expect([game.attackerId, game.defenderId].sort()).toEqual(["p1", "p2"]);
  });
});

describe("applyAction ATTACK", () => {
  it("rejects an attack from the non-attacker", () => {
    const state = fixtureState({ players: [
      { id: "p1", name: "A", hand: [c("hearts", 6)] },
      { id: "p2", name: "B", hand: [c("hearts", 7)] },
    ] });
    const result = applyAction(state, { type: "ATTACK", playerId: "p2", card: c("hearts", 7) });
    expect(result.ok).toBe(false);
  });

  it("requires later attack cards to match a rank already on the table", () => {
    const state = fixtureState({
      players: [
        { id: "p1", name: "A", hand: [c("hearts", 8)] },
        { id: "p2", name: "B", hand: [c("hearts", 9), c("clubs", 6)] },
      ],
      table: [{ attack: c("hearts", 6), defense: c("hearts", 9) }],
    });
    const result = applyAction(state, { type: "ATTACK", playerId: "p1", card: c("hearts", 8) });
    expect(result.ok).toBe(false);
  });

  it("accepts a matching-rank throw-in", () => {
    const state = fixtureState({
      players: [
        { id: "p1", name: "A", hand: [c("clubs", 6)] },
        { id: "p2", name: "B", hand: [c("hearts", 9)] },
      ],
      table: [{ attack: c("hearts", 6), defense: c("hearts", 9) }],
    });
    const result = applyAction(state, { type: "ATTACK", playerId: "p1", card: c("clubs", 6) });
    expect(result.ok).toBe(true);
    if (result.ok) expect(result.state.table).toHaveLength(2);
  });
});

describe("applyAction DEFEND", () => {
  it("beats a same-suit higher card", () => {
    const state = fixtureState({
      players: [
        { id: "p1", name: "A", hand: [] },
        { id: "p2", name: "B", hand: [c("hearts", 10)] },
      ],
      table: [{ attack: c("hearts", 6) }],
    });
    const result = applyAction(state, { type: "DEFEND", playerId: "p2", card: c("hearts", 10), against: c("hearts", 6) });
    expect(result.ok).toBe(true);
  });

  it("rejects a lower card of the same suit", () => {
    const state = fixtureState({
      players: [
        { id: "p1", name: "A", hand: [] },
        { id: "p2", name: "B", hand: [c("hearts", 6)] },
      ],
      table: [{ attack: c("hearts", 10) }],
    });
    const result = applyAction(state, { type: "DEFEND", playerId: "p2", card: c("hearts", 6), against: c("hearts", 10) });
    expect(result.ok).toBe(false);
  });

  it("allows a trump to beat a non-trump", () => {
    const state = fixtureState({
      trumpSuit: "spades",
      players: [
        { id: "p1", name: "A", hand: [] },
        { id: "p2", name: "B", hand: [c("spades", 6)] },
      ],
      table: [{ attack: c("hearts", 14) }],
    });
    const result = applyAction(state, { type: "DEFEND", playerId: "p2", card: c("spades", 6), against: c("hearts", 14) });
    expect(result.ok).toBe(true);
  });
});

describe("applyAction TAKE", () => {
  it("moves all table cards into the defender's hand and keeps roles unchanged", () => {
    const state = fixtureState({
      deck: [c("clubs", 6), c("clubs", 7)],
      players: [
        { id: "p1", name: "A", hand: [] },
        { id: "p2", name: "B", hand: [] },
      ],
      table: [{ attack: c("hearts", 6) }, { attack: c("diamonds", 6) }],
    });
    const result = applyAction(state, { type: "TAKE", playerId: "p2" });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.state.table).toHaveLength(0);
    expect(result.state.players[1].hand).toHaveLength(2);
    expect(result.state.attackerId).toBe("p1");
    expect(result.state.defenderId).toBe("p2");
  });

  it("rejects taking when the table is already fully defended", () => {
    const state = fixtureState({
      table: [{ attack: c("hearts", 6), defense: c("hearts", 10) }],
    });
    const result = applyAction(state, { type: "TAKE", playerId: "p2" });
    expect(result.ok).toBe(false);
  });
});

describe("applyAction PASS", () => {
  it("rejects passing while a slot is undefended", () => {
    const state = fixtureState({ table: [{ attack: c("hearts", 6) }] });
    const result = applyAction(state, { type: "PASS", playerId: "p1" });
    expect(result.ok).toBe(false);
  });

  it("clears the table, discards, and swaps attacker/defender roles", () => {
    const state = fixtureState({
      deck: [c("clubs", 6), c("clubs", 7)],
      players: [
        { id: "p1", name: "A", hand: [] },
        { id: "p2", name: "B", hand: [] },
      ],
      table: [{ attack: c("hearts", 6), defense: c("hearts", 10) }],
    });
    const result = applyAction(state, { type: "PASS", playerId: "p1" });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.state.table).toHaveLength(0);
    expect(result.state.discardCount).toBe(2);
    expect(result.state.attackerId).toBe("p2");
    expect(result.state.defenderId).toBe("p1");
  });

  it("ends the game once the deck is empty and one player is out of cards", () => {
    const state = fixtureState({
      deck: [],
      players: [
        { id: "p1", name: "A", hand: [] },
        { id: "p2", name: "B", hand: [c("clubs", 6)] },
      ],
      table: [{ attack: c("hearts", 6), defense: c("hearts", 10) }],
    });
    const result = applyAction(state, { type: "PASS", playerId: "p1" });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.state.phase).toBe("finished");
    expect(result.state.winnerOrder).toContain("p1");
    expect(result.state.loserId).toBe("p2");
  });
});
