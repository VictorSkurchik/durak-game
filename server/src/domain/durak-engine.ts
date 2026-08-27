import { beats, Card, cardId, cardsEqual, Rank } from "./card.js";
import { buildFullDeck, shuffle } from "./deck.js";
import { GameState, getPlayer, otherPlayerId, PlayerState } from "./game-state.js";

export type GameAction =
  | { type: "ATTACK"; playerId: string; card: Card }
  | { type: "DEFEND"; playerId: string; card: Card; against: Card }
  | { type: "TAKE"; playerId: string }
  | { type: "PASS"; playerId: string };

export type Result =
  | { ok: true; state: GameState }
  | { ok: false; error: string };

const HAND_SIZE = 6;
const MAX_TABLE_SLOTS = 6;

export interface NewPlayer {
  id: string;
  name: string;
}

export function createGame(
  id: string,
  playerA: NewPlayer,
  playerB: NewPlayer,
  random: () => number = Math.random
): GameState {
  const deck = shuffle(buildFullDeck(), random);

  const handA = deck.splice(0, HAND_SIZE);
  const handB = deck.splice(0, HAND_SIZE);
  const trumpCard = deck[deck.length - 1];

  const players: [PlayerState, PlayerState] = [
    { id: playerA.id, name: playerA.name, hand: handA },
    { id: playerB.id, name: playerB.name, hand: handB },
  ];

  const attackerId = pickFirstAttacker(players, trumpCard.suit);
  const defenderId = players.find((p) => p.id !== attackerId)!.id;

  return {
    id,
    phase: "in_progress",
    players,
    deck,
    trumpSuit: trumpCard.suit,
    trumpCard,
    table: [],
    discardCount: 0,
    attackerId,
    defenderId,
    winnerOrder: [],
  };
}

function pickFirstAttacker(players: [PlayerState, PlayerState], trumpSuit: string): string {
  let best: { playerId: string; rank: number } | null = null;
  for (const player of players) {
    for (const card of player.hand) {
      if (card.suit !== trumpSuit) continue;
      if (!best || card.rank < best.rank) {
        best = { playerId: player.id, rank: card.rank };
      }
    }
  }
  return best?.playerId ?? players[0].id;
}

export function applyAction(state: GameState, action: GameAction): Result {
  if (state.phase === "finished") {
    return { ok: false, error: "Game is already finished" };
  }

  switch (action.type) {
    case "ATTACK":
      return applyAttack(state, action.playerId, action.card);
    case "DEFEND":
      return applyDefend(state, action.playerId, action.card, action.against);
    case "TAKE":
      return applyTake(state, action.playerId);
    case "PASS":
      return applyPass(state, action.playerId);
  }
}

function applyAttack(state: GameState, playerId: string, card: Card): Result {
  if (playerId !== state.attackerId) {
    return { ok: false, error: "Only the attacker may add an attacking card" };
  }
  const attacker = getPlayer(state, playerId);
  const defender = getPlayer(state, state.defenderId);
  const inHand = attacker.hand.some((c) => cardsEqual(c, card));
  if (!inHand) {
    return { ok: false, error: "Card is not in your hand" };
  }
  if (state.table.length >= MAX_TABLE_SLOTS) {
    return { ok: false, error: "Table is full" };
  }
  const undefendedCount = state.table.filter((s) => !s.defense).length;
  if (defender.hand.length - undefendedCount <= 0) {
    return { ok: false, error: "Defender has no cards left to respond with" };
  }
  if (state.table.length > 0) {
    const ranksInPlay = new Set(
      state.table.flatMap((slot) => [slot.attack.rank, slot.defense?.rank].filter((r): r is Rank => r !== undefined))
    );
    if (!ranksInPlay.has(card.rank)) {
      return { ok: false, error: "Card rank must already be in play on the table" };
    }
  }

  const nextState = cloneState(state);
  removeFromHand(nextState, playerId, card);
  nextState.table.push({ attack: card });
  return { ok: true, state: nextState };
}

function applyDefend(state: GameState, playerId: string, card: Card, against: Card): Result {
  if (playerId !== state.defenderId) {
    return { ok: false, error: "Only the defender may defend" };
  }
  const defender = getPlayer(state, playerId);
  if (!defender.hand.some((c) => cardsEqual(c, card))) {
    return { ok: false, error: "Card is not in your hand" };
  }
  const slot = state.table.find((s) => cardsEqual(s.attack, against) && !s.defense);
  if (!slot) {
    return { ok: false, error: "No matching undefended attack on the table" };
  }
  if (!beats(card, slot.attack, state.trumpSuit)) {
    return { ok: false, error: "That card cannot beat the attacking card" };
  }

  const nextState = cloneState(state);
  removeFromHand(nextState, playerId, card);
  const nextSlot = nextState.table.find((s) => cardsEqual(s.attack, against))!;
  nextSlot.defense = card;
  return { ok: true, state: nextState };
}

function applyTake(state: GameState, playerId: string): Result {
  if (playerId !== state.defenderId) {
    return { ok: false, error: "Only the defender may take the cards" };
  }
  if (state.table.length === 0) {
    return { ok: false, error: "Nothing to take" };
  }

  const nextState = cloneState(state);
  const defender = getPlayer(nextState, playerId);
  for (const slot of nextState.table) {
    defender.hand.push(slot.attack);
    if (slot.defense) defender.hand.push(slot.defense);
  }
  nextState.table = [];

  drawUpTo(nextState, [nextState.attackerId, nextState.defenderId]);
  // Roles stay the same: the defender who took cards keeps defending next round.
  return { ok: true, state: finalizeRound(nextState) };
}

function applyPass(state: GameState, playerId: string): Result {
  if (playerId !== state.attackerId) {
    return { ok: false, error: "Only the attacker may declare done attacking" };
  }
  if (state.table.length === 0) {
    return { ok: false, error: "No cards on the table yet" };
  }
  const fullyDefended = state.table.every((slot) => slot.defense);
  if (!fullyDefended) {
    return { ok: false, error: "Cannot pass while an attack is still undefended" };
  }

  const nextState = cloneState(state);
  nextState.discardCount += nextState.table.length * 2;
  nextState.table = [];

  drawUpTo(nextState, [nextState.attackerId, nextState.defenderId]);
  // Successful defense: roles swap, the defender becomes the next attacker.
  const previousDefender = nextState.defenderId;
  nextState.defenderId = nextState.attackerId;
  nextState.attackerId = previousDefender;

  return { ok: true, state: finalizeRound(nextState) };
}

function drawUpTo(state: GameState, order: string[]): void {
  for (const playerId of order) {
    const player = getPlayer(state, playerId);
    while (player.hand.length < HAND_SIZE && state.deck.length > 0) {
      player.hand.push(state.deck.shift()!);
    }
  }
}

function finalizeRound(state: GameState): GameState {
  if (state.deck.length > 0) return state;

  for (const player of state.players) {
    if (player.hand.length === 0 && !state.winnerOrder.includes(player.id)) {
      state.winnerOrder.push(player.id);
    }
  }

  const remaining = state.players.filter((p) => p.hand.length > 0);
  if (remaining.length <= 1) {
    state.phase = "finished";
    state.loserId = remaining.length === 1 ? remaining[0].id : undefined;
  }
  return state;
}

function removeFromHand(state: GameState, playerId: string, card: Card): void {
  const player = getPlayer(state, playerId);
  const index = player.hand.findIndex((c) => cardsEqual(c, card));
  player.hand.splice(index, 1);
}

function cloneState(state: GameState): GameState {
  return {
    ...state,
    players: state.players.map((p) => ({ ...p, hand: [...p.hand] })) as GameState["players"],
    deck: [...state.deck],
    table: state.table.map((slot) => ({ ...slot })),
    winnerOrder: [...state.winnerOrder],
  };
}

export function undefendedSlots(state: GameState) {
  return state.table.filter((slot) => !slot.defense);
}

export { cardId };
