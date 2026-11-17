import test from "node:test";
import assert from "node:assert/strict";

import { evaluateGrid, resolveLineSymbols, SlotMachine } from "../src/systems/slotMachine.js";
import { GameState } from "../src/systems/state.js";

const mockAudio = {
  playLever() {},
  playReelTick() {},
  playReelStop() {},
  playNudge() {},
  playMatch() {},
  playJackpot() {},
  playHit() {},
  playBow() {},
  playMagic() {},
  playMeteor() {},
  playCoin() {},
  playEvolve() {},
  playHurtBase() {},
};

test("resolveLineSymbols handles pure matches, wildcard crowns, and pure jackpots", () => {
  assert.deepEqual(resolveLineSymbols("shield", "shield", "shield"), {
    matchedSymbolId: "shield",
    isPureJackpot: false,
    crownCount: 0,
  });

  assert.deepEqual(resolveLineSymbols("bow", "crown", "bow"), {
    matchedSymbolId: "bow",
    isPureJackpot: false,
    crownCount: 1,
  });

  assert.deepEqual(resolveLineSymbols("crown", "crown", "crown"), {
    matchedSymbolId: "crown",
    isPureJackpot: true,
    crownCount: 3,
  });

  assert.equal(resolveLineSymbols("shield", "bow", "shield"), null);
});

test("evaluateGrid detects rows, columns, and diagonals across 3x3 grid", () => {
  const grid = [
    ["shield", "bow", "coin"],
    ["shield", "shield", "staff"],
    ["shield", "horse", "crown"],
  ];
  const matches = evaluateGrid(grid);
  const ids = matches.map((m) => m.lineId);
  assert.ok(ids.includes("row0"));
  assert.ok(ids.includes("diag0"));
  assert.equal(matches.length, 2);
});

test("SlotMachine nudge shifts reel and collectNewMatches prevents double claiming", () => {
  const slot = new SlotMachine();
  slot.strips = [
    ["shield", "bow", "staff", "coin"],
    ["shield", "bow", "staff", "coin"],
    ["coin", "shield", "bow", "staff"],
  ];
  slot.offsets = [0, 0, 0];

  // Initially no horizontal match on row0 ([shield, shield, coin])
  assert.equal(slot.collectNewMatches().length, 0);

  // Nudge col 2 down by 1 -> offset 1 => [shield, bow, staff] on col 2 -> matches all 3 rows!
  assert.equal(slot.nudge(2, 1), true);
  const firstCollect = slot.collectNewMatches();
  assert.equal(firstCollect.length, 3);

  // Re-collecting without a new spin returns 0
  assert.equal(slot.collectNewMatches().length, 0);
});

test("GameState unit absorption evolves to 2★ and opens classModal at 3★", () => {
  const state = new GameState(mockAudio);
  state.startRun();
  assert.equal(state.roster.length, 2);

  // Summon 4 extra warriors to feed into the first warrior
  const main = state.roster[0];
  const w1 = state.summonUnit("warrior");
  const w2 = state.summonUnit("warrior");
  assert.ok(state.absorbUnit(w1.id, main.id)); // +2 XP (same baseId) -> 2★!
  assert.equal(main.tier, 2);

  const w3 = state.summonUnit("warrior");
  const w4 = state.summonUnit("warrior");
  assert.ok(state.absorbUnit(w3.id, main.id)); // +2 XP
  assert.equal(main.tier, 2);
  assert.ok(state.absorbUnit(w4.id, main.id)); // +2 XP -> reaches 4 XP -> 3★ & classModal!
  assert.equal(main.tier, 3);
  assert.ok(state.classModal);
  assert.equal(state.classModal.choices.length, 2);

  const chosenId = state.classModal.choices[0].id;
  assert.equal(state.chooseClass(chosenId), true);
  assert.equal(state.classModal, null);
  assert.equal(main.classId, chosenId);
});

test("GameState battle simulation clears wave 1 and opens coreModal", () => {
  const state = new GameState(mockAudio);
  state.startRun();
  // Add an extra champion so wave 1 clears easily
  state.summonUnit("champion");
  state.startWave();
  assert.equal(state.phase, "battle");
  assert.equal(state.waveActive, true);

  for (let i = 0; i < 600; i++) {
    state.update(0.05);
    if (state.phase === "spin") break;
  }

  assert.equal(state.phase, "spin");
  assert.equal(state.wave, 2);
  assert.ok(state.coreModal, "Clearing wave 1 should present a Core relic draft");
  assert.equal(state.coreModal.choices.length, 3);
});
