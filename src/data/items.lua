local Color = require("src.utils.color")

local M = {}

M.ITEMS = {
  greedy_pearl = {
    id = "greedy_pearl",
    name = { zh = "贪婪珍珠", en = "Greedy Pearl" },
    rarity = "common",
    color = Color.hex("#cbd5e1"),
    cost = 2,
    badge = "PRL",
    kind = "passive",
    desc = { zh = "每次使用微调 (Nudge) 额外获得 +8 金币", en = "Each Nudge grants +8 bonus Gold" },
  },
  rewind_clock = {
    id = "rewind_clock",
    name = { zh = "倒流怀表", en = "Rewind Clock" },
    rarity = "uncommon",
    color = Color.hex("#4ade80"),
    cost = 2,
    badge = "CLK",
    kind = "passive",
    desc = { zh = "空转未中奖后，下次拉杆费用降低 3g", en = "After a blank spin, next spin costs 3g less" },
  },
  trickster_cube = {
    id = "trickster_cube",
    name = { zh = "诡术魔方", en = "Trickster's Cube" },
    rarity = "rare",
    color = Color.hex("#38bdf8"),
    cost = 3,
    badge = "CUB",
    kind = "active_slot",
    usesPerWave = 1,
    desc = { zh = "【主动 1/波】点击将转盘左上角 2x2 区域顺时针旋转 90 度", en = "[Active 1/wave] Rotate top-left 2x2 reel cells 90 deg CW" },
  },
  gate_net = {
    id = "gate_net",
    name = { zh = "城门捕网", en = "Gate Net" },
    rarity = "uncommon",
    color = Color.hex("#a3e635"),
    cost = 3,
    badge = "NET",
    kind = "passive",
    desc = { zh = "每场战斗自动定身逼近城堡的敌人 2.5 秒（最多触发 2 次）", en = "Roots enemies near the castle for 2.5s (2/battle)" },
  },
  war_drum = {
    id = "war_drum",
    name = { zh = "战鼓号角", en = "War Drum" },
    rarity = "uncommon",
    color = Color.hex("#fb923c"),
    cost = 3,
    badge = "DRM",
    kind = "passive",
    desc = { zh = "全军攻击速度永久提高 +18%", en = "All allies gain +18% Attack Speed" },
  },
  frost_flask = {
    id = "frost_flask",
    name = { zh = "急冻魔药", en = "Frost Flask" },
    rarity = "rare",
    color = Color.hex("#22d3ee"),
    cost = 3,
    badge = "ICE",
    kind = "active_battle",
    usesPerWave = 1,
    desc = { zh = "【战斗主动 1/波】点击冻结并冰缓场上全部敌人 4 秒", en = "[Battle Active 1/wave] Chill all enemies for 4s" },
  },
  golden_chalice = {
    id = "golden_chalice",
    name = { zh = "圣金圣杯", en = "Golden Chalice" },
    rarity = "rare",
    color = Color.hex("#facc15"),
    cost = 4,
    badge = "CUP",
    kind = "passive",
    desc = { zh = "每波结算额外获得 +15 金币与 +1 蓝水晶", en = "Wave clear grants +15 Gold & +1 Crystal" },
  },
  lucky_clover = {
    id = "lucky_clover",
    name = { zh = "四叶草徽记", en = "Lucky Clover" },
    rarity = "uncommon",
    color = Color.hex("#22c55e"),
    cost = 2,
    badge = "CLV",
    kind = "passive",
    desc = { zh = "提高召唤【稀有/史诗/棱镜】品质单位的概率", en = "Boosts Rare, Epic & Prism unit roll odds" },
    onAcquire = function(state)
      state.prismBonus = (state.prismBonus or 0) + 4
    end,
  },
}

M.ITEM_KEYS = {
  "greedy_pearl", "rewind_clock", "trickster_cube", "gate_net",
  "war_drum", "frost_flask", "golden_chalice", "lucky_clover",
}

return M
