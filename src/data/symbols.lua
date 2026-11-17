local Color = require("src.utils.color")

local M = {}

M.SYMBOLS = {
  shield = {
    id = "shield",
    name = { zh = "盾卫", en = "Warrior" },
    unitId = "warrior",
    color = Color.hex("#5b9bd5"),
    weight = 24,
    payoutGold = 0,
  },
  bow = {
    id = "bow",
    name = { zh = "游侠", en = "Ranger" },
    unitId = "ranger",
    color = Color.hex("#6ec472"),
    weight = 22,
    payoutGold = 0,
  },
  staff = {
    id = "staff",
    name = { zh = "法师", en = "Mage" },
    unitId = "mage",
    color = Color.hex("#b07fe8"),
    weight = 18,
    payoutGold = 0,
  },
  horse = {
    id = "horse",
    name = { zh = "骑兵", en = "Cavalry" },
    unitId = "cavalry",
    color = Color.hex("#e69d45"),
    weight = 16,
    payoutGold = 0,
  },
  skull = {
    id = "skull",
    name = { zh = "死灵", en = "Necro" },
    unitId = "necro",
    color = Color.hex("#57d1c9"),
    weight = 12,
    payoutGold = 0,
  },
  coin = {
    id = "coin",
    name = { zh = "金币", en = "Gold" },
    unitId = nil,
    color = Color.hex("#f6c945"),
    weight = 16,
    payoutGold = 22,
  },
  crown = {
    id = "crown",
    name = { zh = "头奖", en = "Jackpot" },
    unitId = "champion",
    color = Color.hex("#ffdf6b"),
    weight = 6,
    payoutGold = 15,
    isJackpot = true,
  },
}

M.SYMBOL_KEYS = { "shield", "bow", "staff", "horse", "skull", "coin", "crown" }

-- 8 standard 3x3 paylines using 1-based [col, row] coordinates (1..3)
M.PAYLINES = {
  { id = "row1", name = "Top Row", isDiagonal = false, cells = { { 1, 1 }, { 2, 1 }, { 3, 1 } } },
  { id = "row2", name = "Mid Row", isDiagonal = false, cells = { { 1, 2 }, { 2, 2 }, { 3, 2 } } },
  { id = "row3", name = "Bot Row", isDiagonal = false, cells = { { 1, 3 }, { 2, 3 }, { 3, 3 } } },
  { id = "col1", name = "Left Col", isDiagonal = false, cells = { { 1, 1 }, { 1, 2 }, { 1, 3 } } },
  { id = "col2", name = "Mid Col", isDiagonal = false, cells = { { 2, 1 }, { 2, 2 }, { 2, 3 } } },
  { id = "col3", name = "Right Col", isDiagonal = false, cells = { { 3, 1 }, { 3, 2 }, { 3, 3 } } },
  { id = "diag1", name = "Diag \\", isDiagonal = true, cells = { { 1, 1 }, { 2, 2 }, { 3, 3 } } },
  { id = "diag2", name = "Diag /", isDiagonal = true, cells = { { 1, 3 }, { 2, 2 }, { 3, 1 } } },
}

function M.buildReelStrip(weightsOverride)
  weightsOverride = weightsOverride or {}
  local pool = {}
  for _, key in ipairs(M.SYMBOL_KEYS) do
    local w = math.max(1, math.floor((weightsOverride[key] or M.SYMBOLS[key].weight) + 0.5))
    for _ = 1, w do
      pool[#pool + 1] = key
    end
  end
  for i = #pool, 2, -1 do
    local j = math.random(1, i)
    pool[i], pool[j] = pool[j], pool[i]
  end
  return pool
end

return M
