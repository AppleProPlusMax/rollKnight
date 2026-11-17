export const CORES = [
  {
    id: "loaded_dice",
    name: { zh: "灌铅骰子", en: "Loaded Dice" },
    color: "#6ec472",
    icon: "🎲",
    desc: {
      zh: "每波开始额外获得 +2 次微调 (Nudge) 次数，立即 +2 微调",
      en: "Gain +2 extra Nudges every wave (and +2 immediately)",
    },
    onAcquire(state) {
      state.nudgesPerWave += 2;
      state.nudges += 2;
    },
  },
  {
    id: "golden_lever",
    name: { zh: "黄金拉杆", en: "Golden Lever" },
    color: "#f6c945",
    icon: "🎰",
    desc: {
      zh: "每波首次抽奖免费，且后续每次抽奖涨价幅度减半",
      en: "First spin each wave is FREE, and spin cost ramps slower",
    },
    onAcquire(state) {
      state.freeFirstSpin = true;
      state.spinCostStep = Math.max(1, Math.floor(state.spinCostStep / 2));
    },
  },
  {
    id: "blood_pact",
    name: { zh: "鲜血吞噬契约", en: "Blood Pact" },
    color: "#e85d5d",
    icon: "🩸",
    desc: {
      zh: "吞噬单位时提供 +1 额外经验，并永久提升目标 18% 攻击力",
      en: "Absorbing grants +1 bonus Essence & +18% permanent ATK",
    },
  },
  {
    id: "meteor_resonance",
    name: { zh: "陨星共鸣", en: "Meteor Resonance" },
    color: "#ff7c43",
    icon: "☄",
    desc: {
      zh: "所有己方单位每第 5 次攻击都会召唤一颗火焰陨石轰炸敌阵",
      en: "Every 5th allied attack calls down a fiery AoE Meteor",
    },
  },
  {
    id: "phalanx_banner",
    name: { zh: "铁壁战旗", en: "Phalanx Banner" },
    color: "#5b9bd5",
    icon: "🛡",
    desc: {
      zh: "全体前排/骑兵最大生命值 +40%，并反弹 25% 近战伤害",
      en: "Frontline & Cavalry gain +40% Max HP and 25% Thorns",
    },
    onAcquire(state) {
      for (const u of state.roster) {
        if (u.role === "frontline" || u.role === "vanguard") {
          const bonus = Math.round(u.maxHp * 0.4);
          u.maxHp += bonus;
          u.hp += bonus;
        }
      }
    },
  },
  {
    id: "wind_quiver",
    name: { zh: "疾风箭袋", en: "Wind Quiver" },
    color: "#57d1c9",
    icon: "🏹",
    desc: {
      zh: "全体远程弹道穿透 +1，攻速提高 22%",
      en: "All projectiles gain +1 Pierce and +22% Attack Speed",
    },
  },
  {
    id: "vampiric_crown",
    name: { zh: "嗜血王冠", en: "Vampiric Crown" },
    color: "#c77dff",
    icon: "👑",
    desc: {
      zh: "单位击杀敌人后回复 15% 生命并获得 3 秒杀戮狂热 (+35% 攻速)",
      en: "Kills heal 15% HP & trigger 3s Kill Overdrive (+35% ASPD)",
    },
  },
  {
    id: "jackpot_magnet",
    name: { zh: "头奖磁铁", en: "Jackpot Magnet" },
    color: "#ffdf6b",
    icon: "🧲",
    desc: {
      zh: "永久提高转盘中【王冠】与【金币】的出现权重，并立即 +35 金币",
      en: "Boosts Crown & Gold reel weights; gain +35 Gold now",
    },
    onAcquire(state) {
      state.symbolWeights.crown = (state.symbolWeights.crown || 6) + 6;
      state.symbolWeights.coin = (state.symbolWeights.coin || 16) + 8;
      state.gold += 35;
      state.rebuildReels();
    },
  },
  {
    id: "jester_trick",
    name: { zh: "弄臣戏法", en: "Jester's Trick" },
    color: "#ff99c8",
    icon: "🃏",
    desc: {
      zh: "斜线 (Diagonal) 连线命中时双倍召唤单位或双倍金币奖励",
      en: "Diagonal payline matches grant 2x units or 2x gold!",
    },
  },
  {
    id: "castle_mason",
    name: { zh: "城防工匠", en: "Royal Mason" },
    color: "#90be6d",
    icon: "🏰",
    desc: {
      zh: "立即恢复 3 点城堡生命并提高上限，每波结束额外获得 +12 金币",
      en: "Heal +3 Hearts (increases max) & earn +12 Gold per wave",
    },
    onAcquire(state) {
      state.maxHearts += 3;
      state.hearts = Math.min(state.maxHearts, state.hearts + 3);
    },
  },
];
