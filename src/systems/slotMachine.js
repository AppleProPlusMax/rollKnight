import { PAYLINES, SYMBOLS, buildReelStrip } from "../data/symbols.js";

/**
 * Resolves a 3-symbol line where `crown` acts as a wildcard for any symbol.
 * Returns { matchedSymbolId, isPureJackpot, crownCount } or null.
 */
export function resolveLineSymbols(a, b, c) {
  const arr = [a, b, c];
  const crowns = arr.filter((s) => s === "crown").length;
  const nonCrowns = arr.filter((s) => s !== "crown");

  if (nonCrowns.length === 0) {
    return { matchedSymbolId: "crown", isPureJackpot: true, crownCount: 3 };
  }

  const first = nonCrowns[0];
  if (nonCrowns.every((s) => s === first)) {
    return { matchedSymbolId: first, isPureJackpot: false, crownCount: crowns };
  }

  return null;
}

/**
 * Evaluates a 3x3 grid: grid[col][row] (3 cols x 3 rows).
 * Returns array of matched payline descriptors.
 */
export function evaluateGrid(grid) {
  const matches = [];
  for (const line of PAYLINES) {
    const [c0, r0] = line.cells[0];
    const [c1, r1] = line.cells[1];
    const [c2, r2] = line.cells[2];
    const resolved = resolveLineSymbols(grid[c0][r0], grid[c1][r1], grid[c2][r2]);
    if (resolved) {
      matches.push({
        lineId: line.id,
        lineName: line.name,
        isDiagonal: line.isDiagonal,
        cells: line.cells,
        symbolId: resolved.matchedSymbolId,
        isPureJackpot: resolved.isPureJackpot,
        crownCount: resolved.crownCount,
        symbol: SYMBOLS[resolved.matchedSymbolId],
      });
    }
  }
  return matches;
}

export class SlotMachine {
  constructor(weights = {}) {
    this.strips = [
      buildReelStrip(weights),
      buildReelStrip(weights),
      buildReelStrip(weights),
    ];
    this.offsets = [0, 0, 0];
    this.spinning = false;
    this.reelSpinning = [false, false, false];
    this.reelTimers = [0, 0, 0];
    this.reelVisualShift = [0, 0, 0];
    this.tickAccum = [0, 0, 0];
    this.claimedLines = new Set();
    this.activeMatches = [];
    this.justStoppedReels = [];
  }

  rebuild(weights = {}) {
    this.strips = [
      buildReelStrip(weights),
      buildReelStrip(weights),
      buildReelStrip(weights),
    ];
    this.offsets = this.offsets.map((o, col) => ((o % this.strips[col].length) + this.strips[col].length) % this.strips[col].length);
  }

  getGrid() {
    const grid = [[], [], []];
    for (let col = 0; col < 3; col++) {
      const strip = this.strips[col];
      const len = strip.length;
      const base = this.offsets[col];
      for (let row = 0; row < 3; row++) {
        const idx = (((base + row) % len) + len) % len;
        grid[col][row] = strip[idx];
      }
    }
    return grid;
  }

  startSpin() {
    this.spinning = true;
    this.reelSpinning = [true, true, true];
    this.reelTimers = [0.36, 0.56, 0.78];
    this.reelVisualShift = [0, 0, 0];
    this.tickAccum = [0, 0, 0];
    this.claimedLines.clear();
    this.activeMatches = [];
    this.justStoppedReels = [];

    for (let col = 0; col < 3; col++) {
      const len = this.strips[col].length;
      this.offsets[col] = Math.floor(Math.random() * len);
    }
  }

  /**
   * Advances reel animation. Returns { finished: boolean, stoppedCols: number[], ticked: boolean }.
   */
  update(dt) {
    if (!this.spinning) {
      return { finished: false, stoppedCols: [], ticked: false };
    }

    const stoppedCols = [];
    let ticked = false;

    for (let col = 0; col < 3; col++) {
      if (!this.reelSpinning[col]) continue;
      this.reelTimers[col] -= dt;
      this.tickAccum[col] += dt;
      this.reelVisualShift[col] = (this.reelVisualShift[col] + dt * 16) % 1;

      if (this.tickAccum[col] >= 0.06) {
        this.tickAccum[col] = 0;
        const len = this.strips[col].length;
        this.offsets[col] = (this.offsets[col] + 1) % len;
        ticked = true;
      }

      if (this.reelTimers[col] <= 0) {
        this.reelSpinning[col] = false;
        this.reelVisualShift[col] = 0;
        const len = this.strips[col].length;
        this.offsets[col] = Math.floor(Math.random() * len);
        stoppedCols.push(col);
      }
    }

    const allStopped = this.reelSpinning.every((s) => !s);
    if (allStopped) {
      this.spinning = false;
      return { finished: true, stoppedCols, ticked };
    }

    return { finished: false, stoppedCols, ticked };
  }

  /**
   * Shifts a single reel by dir (-1 up, +1 down).
   */
  nudge(col, dir) {
    if (this.spinning || col < 0 || col > 2) return false;
    const len = this.strips[col].length;
    this.offsets[col] = (((this.offsets[col] + dir) % len) + len) % len;
    return true;
  }

  /**
   * Evaluates current grid and returns ONLY newly matched paylines not yet claimed this spin,
   * while updating activeMatches for highlighting.
   */
  collectNewMatches() {
    const allMatches = evaluateGrid(this.getGrid());
    this.activeMatches = allMatches;
    const newlyMatched = [];
    for (const m of allMatches) {
      if (!this.claimedLines.has(m.lineId)) {
        this.claimedLines.add(m.lineId);
        newlyMatched.push(m);
      }
    }
    return newlyMatched;
  }
}
