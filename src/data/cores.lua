local Color = require("src.utils.color")

local CORES = {
  {
    id = "loaded_dice",
    name = { zh = "灌铅骰子", en = "Loaded Dice" },
    color = Color.hex("#6ec472"),
    badge = "DICE",
    desc = { zh = "每波开始额外获得 +2 次微调 (Nudge) 次数，立即 +2 微调", en = "Gain +2 extra Nudges every wave (and +2 immediately)" },
    onAcquire = function(state)
      state.nudgesPerWave = state.nudgesPerWave + 2
      state.nudges = state.nudges + 2
    end,
  },
  {
    id = "golden_lever",
    name = { zh = "黄金拉杆", en = "Golden Lever" },
    color = Color.hex("#f6c945"),
    badge = "SPIN",
    desc = { zh = "每波首次抽奖免费，且后续每次抽奖涨价幅度减半", en = "First spin each wave is FREE, and spin cost ramps slower" },
    onAcquire = function(state)
      state.freeFirstSpin = true
      state.spinCostStep = math.max(1, math.floor(state.spinCostStep / 2))
    end,
  },
  {
    id = "blood_pact",
    name = { zh = "鲜血吞噬契约", en = "Blood Pact" },
    color = Color.hex("#e85d5d"),
    badge = "PACT",
    desc = { zh = "吞噬单位时提供 +1 额外经验，并永久提升目标 18% 攻击力", en = "Absorbing grants +1 bonus Essence & +18% permanent ATK" },
  },
  {
    id = "meteor_resonance",
    name = { zh = "陨星共鸣", en = "Meteor Resonance" },
    color = Color.hex("#ff7c43"),
    badge = "STAR",
    desc = { zh = "所有己方单位每第 5 次攻击都会召唤一颗火焰陨石轰炸敌阵", en = "Every 5th allied attack calls down a fiery AoE Meteor" },
  },
  {
    id = "phalanx_banner",
    name = { zh = "铁壁战旗", en = "Phalanx Banner" },
    color = Color.hex("#5b9bd5"),
    badge = "SHLD",
    desc = { zh = "全体前排/骑兵最大生命值 +40%，并反弹 25% 近战伤害", en = "Frontline & Cavalry gain +40% Max HP and 25% Thorns" },
    onAcquire = function(state)
      for _, u in ipairs(state.roster) do
        if u.role == "frontline" or u.role == "vanguard" then
          local bonus = math.floor(u.maxHp * 0.4 + 0.5)
          u.maxHp = u.maxHp + bonus
          u.hp = u.hp + bonus
        end
      end
    end,
  },
  {
    id = "wind_quiver",
    name = { zh = "疾风箭袋", en = "Wind Quiver" },
    color = Color.hex("#57d1c9"),
    badge = "WIND",
    desc = { zh = "全体远程弹道穿透 +1，攻速提高 22%", en = "All projectiles gain +1 Pierce and +22% Attack Speed" },
  },
  {
    id = "vampiric_crown",
    name = { zh = "嗜血王冠", en = "Vampiric Crown" },
    color = Color.hex("#c77dff"),
    badge = "KILL",
    desc = { zh = "单位击杀敌人后回复 15% 生命并获得 3 秒杀戮狂热 (+35% 攻速)", en = "Kills heal 15% HP & trigger 3s Kill Overdrive (+35% ASPD)" },
  },
  {
    id = "jackpot_magnet",
    name = { zh = "头奖磁铁", en = "Jackpot Magnet" },
    color = Color.hex("#ffdf6b"),
    badge = "LUCK",
    desc = { zh = "永久提高转盘中【王冠】与【金币】的出现权重，并立即 +35 金币", en = "Boosts Crown & Gold reel weights; gain +35 Gold now" },
    onAcquire = function(state)
      state.symbolWeights.crown = (state.symbolWeights.crown or 6) + 6
      state.symbolWeights.coin = (state.symbolWeights.coin or 16) + 8
      state.gold = state.gold + 35
      state:rebuildReels()
    end,
  },
  {
    id = "jester_trick",
    name = { zh = "弄臣戏法", en = "Jester's Trick" },
    color = Color.hex("#ff99c8"),
    badge = "2X",
    desc = { zh = "斜线 (Diagonal) 连线命中时双倍召唤单位或双倍金币奖励", en = "Diagonal payline matches grant 2x units or 2x gold!" },
  },
  {
    id = "castle_mason",
    name = { zh = "城防工匠", en = "Royal Mason" },
    color = Color.hex("#90be6d"),
    badge = "WALL",
    desc = { zh = "立即恢复 3 点城堡生命并提高上限，每波结束额外获得 +12 金币", en = "Heal +3 Hearts (increases max) & earn +12 Gold per wave" },
    onAcquire = function(state)
      state.maxHearts = state.maxHearts + 3
      state.hearts = math.min(state.maxHearts, state.hearts + 3)
    end,
  },
}

return CORES
