local Color = require("src.utils.color")

local M = {}

M.SYMBOLS = {
  shield = {
    id = "shield",
    name = { zh = "盾卫", en = "Warrior" },
    unitId = "warrior",
    color = Color.hex("#5b9bd5"),
    weight = 22,
    payoutGold = 0,
  },
  bow = {
    id = "bow",
    name = { zh = "游侠", en = "Ranger" },
    unitId = "ranger",
    color = Color.hex("#6ec472"),
    weight = 20,
    payoutGold = 0,
  },
  staff = {
    id = "staff",
    name = { zh = "法师", en = "Mage" },
    unitId = "mage",
    color = Color.hex("#b07fe8"),
    weight = 17,
    payoutGold = 0,
  },
  horse = {
    id = "horse",
    name = { zh = "骑兵", en = "Cavalry" },
    unitId = "cavalry",
    color = Color.hex("#e69d45"),
    weight = 15,
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
    payoutGold = 24,
  },
  jester = {
    id = "jester",
    name = { zh = "弄臣", en = "Jester" },
    unitId = "jester",
    color = Color.hex("#ff4d6d"),
    weight = 7,
    payoutGold = 8,
    isWild = true,
  },
  crown = {
    id = "crown",
    name = { zh = "头奖", en = "Jackpot" },
    unitId = "champion",
    color = Color.hex("#ffdf6b"),
    weight = 6,
    payoutGold = 18,
    isJackpot = true,
    isWild = true,
  },
}

M.SYMBOL_KEYS = { "shield", "bow", "staff", "horse", "skull", "coin", "jester", "crown" }

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

local function shuffle(list)
  for i = #list, 2, -1 do
    local j = math.random(1, i)
    list[i], list[j] = list[j], list[i]
  end
end

--- Build a balanced reel strip using small shuffled blocks so symbols never suffer long dry streaks.
function M.buildReelStrip(weightsOverride)
  weightsOverride = weightsOverride or {}
  local buckets = {}
  local maxW = 0
  for _, key in ipairs(M.SYMBOL_KEYS) do
    local w = math.max(1, math.floor((weightsOverride[key] or M.SYMBOLS[key].weight) + 0.5))
    buckets[key] = w
    if w > maxW then maxW = w end
  end

  local blocks = 4
  local pool = {}
  for b = 1, blocks do
    local sub = {}
    for _, key in ipairs(M.SYMBOL_KEYS) do
      local w = buckets[key]
      local count = math.floor(w / blocks) + ((b <= (w % blocks)) and 1 or 0)
      for _ = 1, count do
        sub[#sub + 1] = key
      end
    end
    shuffle(sub)
    for _, sym in ipairs(sub) do
      pool[#pool + 1] = sym
    end
  end
  return pool
end

return M
