export const SYMBOLS = {
  shield: {
    id: "shield",
    name: { zh: "盾卫", en: "Warrior" },
    unitId: "warrior",
    color: "#5b9bd5",
    weight: 24,
    payoutGold: 0,
  },
  bow: {
    id: "bow",
    name: { zh: "游侠", en: "Ranger" },
    unitId: "ranger",
    color: "#6ec472",
    weight: 22,
    payoutGold: 0,
  },
  staff: {
    id: "staff",
    name: { zh: "法师", en: "Mage" },
    unitId: "mage",
    color: "#b07fe8",
    weight: 18,
    payoutGold: 0,
  },
  horse: {
    id: "horse",
    name: { zh: "骑兵", en: "Cavalry" },
    unitId: "cavalry",
    color: "#e69d45",
    weight: 16,
    payoutGold: 0,
  },
  skull: {
    id: "skull",
    name: { zh: "死灵", en: "Necro" },
    unitId: "necro",
    color: "#57d1c9",
    weight: 12,
    payoutGold: 0,
  },
  coin: {
    id: "coin",
    name: { zh: "金币", en: "Gold" },
    unitId: null,
    color: "#f6c945",
    weight: 16,
    payoutGold: 22,
  },
  crown: {
    id: "crown",
    name: { zh: "头奖", en: "Jackpot" },
    unitId: "champion",
    color: "#ffdf6b",
    weight: 6,
    payoutGold: 15,
    isJackpot: true,
  },
};

export const SYMBOL_KEYS = Object.keys(SYMBOLS);

/**
 * 8 standard 3x3 paylines: [col0Row, col1Row, col2Row]
 * Coordinates are [col, row] where col in 0..2, row in 0..2.
 */
export const PAYLINES = [
  { id: "row0", name: "Top Row", isDiagonal: false, cells: [[0, 0], [1, 0], [2, 0]] },
  { id: "row1", name: "Mid Row", isDiagonal: false, cells: [[0, 1], [1, 1], [2, 1]] },
  { id: "row2", name: "Bot Row", isDiagonal: false, cells: [[0, 2], [1, 2], [2, 2]] },
  { id: "col0", name: "Left Col", isDiagonal: false, cells: [[0, 0], [0, 1], [0, 2]] },
  { id: "col1", name: "Mid Col", isDiagonal: false, cells: [[1, 0], [1, 1], [1, 2]] },
  { id: "col2", name: "Right Col", isDiagonal: false, cells: [[2, 0], [2, 1], [2, 2]] },
  { id: "diag0", name: "Diag \\", isDiagonal: true, cells: [[0, 0], [1, 1], [2, 2]] },
  { id: "diag1", name: "Diag /", isDiagonal: true, cells: [[0, 2], [1, 1], [2, 0]] },
];

export function buildReelStrip(weightsOverride = {}) {
  const pool = [];
  for (const key of SYMBOL_KEYS) {
    const w = Math.max(1, Math.round(weightsOverride[key] ?? SYMBOLS[key].weight));
    for (let i = 0; i < w; i++) {
      pool.push(key);
    }
  }
  // Fisher-Yates shuffle for a balanced reel strip
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool;
}
