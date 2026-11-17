local Color = require("src.utils.color")

local M = {}

M.MAX_WAVES = 20

M.ENEMY_TYPES = {
  goblin = {
    id = "goblin",
    name = { zh = "哥布林斥候", en = "Goblin" },
    hp = 46,
    atk = 9,
    aspd = 1.15,
    speed = 62,
    range = 34,
    gold = 3,
    radius = 13,
    color = Color.hex("#7bc950"),
    accent = Color.hex("#b7e489"),
  },
  slime = {
    id = "slime",
    name = { zh = "酸液史莱姆", en = "Slime" },
    hp = 65,
    atk = 11,
    aspd = 0.9,
    speed = 44,
    range = 34,
    gold = 4,
    radius = 15,
    color = Color.hex("#4cc9f0"),
    accent = Color.hex("#a9def9"),
  },
  orc = {
    id = "orc",
    name = { zh = "兽人重甲兵", en = "Orc Brute" },
    hp = 155,
    atk = 18,
    aspd = 0.8,
    speed = 36,
    range = 38,
    gold = 7,
    radius = 18,
    color = Color.hex("#d95d39"),
    accent = Color.hex("#f39c6b"),
  },
  archer_foe = {
    id = "archer_foe",
    name = { zh = "暗影弓手", en = "Shadow Archer" },
    hp = 68,
    atk = 14,
    aspd = 0.95,
    speed = 42,
    range = 240,
    projSpeed = 320,
    gold = 5,
    radius = 13,
    color = Color.hex("#8b5fbf"),
    accent = Color.hex("#d0b3f5"),
  },
  dark_knight = {
    id = "dark_knight",
    name = { zh = "黑铁骑士", en = "Dark Knight" },
    hp = 290,
    atk = 28,
    aspd = 0.9,
    speed = 42,
    range = 42,
    gold = 13,
    radius = 20,
    color = Color.hex("#4a4e69"),
    accent = Color.hex("#f28482"),
  },
  boss_warlord = {
    id = "boss_warlord",
    name = { zh = "兽人战争领主", en = "Orc Warlord" },
    isBoss = true,
    hp = 1050,
    atk = 42,
    aspd = 0.85,
    speed = 30,
    range = 52,
    gold = 45,
    radius = 28,
    color = Color.hex("#b5173c"),
    accent = Color.hex("#ffb703"),
  },
  boss_beholder = {
    id = "boss_beholder",
    name = { zh = "审判之眼 · 邪眼领主", en = "Judgment Beholder" },
    isBoss = true,
    targetsBackline = true,
    hp = 1850,
    atk = 46,
    aspd = 0.78,
    speed = 26,
    range = 420,
    projSpeed = 360,
    gold = 70,
    radius = 30,
    color = Color.hex("#7209b7"),
    accent = Color.hex("#ff006e"),
  },
  boss_dread = {
    id = "boss_dread",
    name = { zh = "永夜恐惧领主", en = "Dread Sovereign" },
    isBoss = true,
    hp = 3400,
    atk = 64,
    aspd = 0.9,
    speed = 32,
    range = 56,
    gold = 100,
    radius = 32,
    color = Color.hex("#2b2d42"),
    accent = Color.hex("#ef233c"),
  },
  boss_abyss = {
    id = "boss_abyss",
    name = { zh = "终焉审判 · 深渊暴君", en = "Abyssal Judgment" },
    isBoss = true,
    targetsBackline = true,
    hp = 6200,
    atk = 78,
    aspd = 0.95,
    speed = 28,
    range = 430,
    projSpeed = 400,
    gold = 200,
    radius = 34,
    color = Color.hex("#540b0e"),
    accent = Color.hex("#ffbe0b"),
  },
}

function M.buildWavePlan(wave, diffMult)
  diffMult = diffMult or 1.0
  local scale = (1 + (wave - 1) * 0.14 + math.max(0, wave - 8) * 0.06) * diffMult
  local spawns = {}
  local totalCount = 5 + math.floor(wave * 1.65)

  local function add(enemyType, delay)
    spawns[#spawns + 1] = { type = enemyType, delay = delay, scale = scale }
  end

  local t = 0.4
  for _ = 1, totalCount do
    local enemyType = "goblin"
    local r = math.random()
    if wave >= 2 and r < 0.28 then
      enemyType = "slime"
    elseif wave >= 3 and r >= 0.28 and r < 0.52 then
      enemyType = "orc"
    elseif wave >= 4 and r >= 0.52 and r < 0.72 then
      enemyType = "archer_foe"
    elseif wave >= 7 and r >= 0.72 and r < 0.88 then
      enemyType = "dark_knight"
    end
    add(enemyType, t)
    t = t + math.max(0.32, 1.15 - wave * 0.032)
  end

  local bossType = nil
  if wave == 5 then
    bossType = "boss_warlord"
  elseif wave == 10 then
    bossType = "boss_beholder"
  elseif wave == 15 then
    bossType = "boss_dread"
  elseif wave == 20 then
    bossType = "boss_abyss"
  end

  if bossType then
    add(bossType, t + 0.8)
  end

  return {
    wave = wave,
    isBossWave = bossType ~= nil,
    bossType = bossType,
    spawns = spawns,
  }
end

return M
