local Color = require("src.utils.color")

local M = {}

M.SHOP_UPGRADES = {
  {
    id = "nudge_cap",
    name = { zh = "机械微调齿轮", en = "Precision Gear" },
    color = Color.hex("#4ade80"),
    baseCost = 22,
    costScale = 14,
    maxLevel = 4,
    desc = { zh = "每波微调次数上限 +1（立即 +1）", en = "+1 Nudge per wave (+1 immediately)" },
    apply = function(state)
      state.nudgesPerWave = state.nudgesPerWave + 1
      state.nudges = state.nudges + 1
    end,
  },
  {
    id = "army_cap",
    name = { zh = "军营扩建令", en = "Barracks Expansion" },
    color = Color.hex("#c084fc"),
    baseCost = 25,
    costScale = 18,
    maxLevel = 4,
    desc = { zh = "最大上阵兵力上限 +1（最高 14）", en = "+1 Max Army Cap (up to 14)" },
    apply = function(state)
      state.maxRoster = state.maxRoster + 1
    end,
  },
  {
    id = "spin_discount",
    name = { zh = "润滑拉杆", en = "Oiled Lever" },
    color = Color.hex("#facc15"),
    baseCost = 20,
    costScale = 14,
    maxLevel = 3,
    desc = { zh = "每次拉杆的基础与递增费用降低", en = "Reduces base spin cost & ramp" },
    apply = function(state)
      state.baseSpinCost = math.max(2, state.baseSpinCost - 1)
      state.spinCostStep = math.max(1, state.spinCostStep - 1)
    end,
  },
  {
    id = "prism_polish",
    name = { zh = "棱镜抛光", en = "Prism Polish" },
    color = Color.hex("#ff70a6"),
    baseCost = 26,
    costScale = 18,
    maxLevel = 3,
    desc = { zh = "大幅提高召唤出【史诗/棱镜】品质单位的概率", en = "Boosts Epic & Prism unit roll odds" },
    apply = function(state)
      state.prismBonus = (state.prismBonus or 0) + 5
    end,
  },
  {
    id = "lucky_weights",
    name = { zh = "幸运砝码", en = "Weighted Reels" },
    color = Color.hex("#ffdf6b"),
    baseCost = 18,
    costScale = 12,
    maxLevel = 4,
    desc = { zh = "提高【王冠】【弄臣】【金币】转盘出现权重", en = "Boosts Crown, Jester & Gold weights" },
    apply = function(state)
      state.symbolWeights.crown = (state.symbolWeights.crown or 5) + 3
      state.symbolWeights.jester = (state.symbolWeights.jester or 6) + 3
      state.symbolWeights.coin = (state.symbolWeights.coin or 16) + 4
      state:rebuildReels()
    end,
  },
  {
    id = "repair_castle",
    name = { zh = "修复城墙", en = "Repair Bastion" },
    color = Color.hex("#fb7185"),
    baseCost = 16,
    costScale = 8,
    maxLevel = 99,
    desc = { zh = "立即恢复 2 点城堡生命", en = "Restore +2 Castle Hearts immediately" },
    apply = function(state)
      state.hearts = math.min(state.maxHearts, state.hearts + 2)
    end,
  },
}

function M.getCost(upg, level)
  return upg.baseCost + (level or 0) * upg.costScale
end

return M
