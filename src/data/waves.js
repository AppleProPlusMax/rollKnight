export const ENEMY_TYPES = {
  goblin: {
    id: "goblin",
    name: { zh: "哥布林斥候", en: "Goblin" },
    hp: 46,
    atk: 9,
    aspd: 1.15,
    speed: 62,
    range: 34,
    gold: 3,
    radius: 13,
    color: "#7bc950",
    accent: "#b7e489",
  },
  slime: {
    id: "slime",
    name: { zh: "酸液史莱姆", en: "Slime" },
    hp: 65,
    atk: 11,
    aspd: 0.9,
    speed: 44,
    range: 34,
    gold: 4,
    radius: 15,
    color: "#4cc9f0",
    accent: "#a9def9",
  },
  orc: {
    id: "orc",
    name: { zh: "兽人重甲兵", en: "Orc Brute" },
    hp: 155,
    atk: 18,
    aspd: 0.8,
    speed: 36,
    range: 38,
    gold: 7,
    radius: 18,
    color: "#d95d39",
    accent: "#f39c6b",
  },
  archer_foe: {
    id: "archer_foe",
    name: { zh: "暗影弓手", en: "Shadow Archer" },
    hp: 68,
    atk: 14,
    aspd: 0.95,
    speed: 42,
    range: 240,
    projSpeed: 320,
    gold: 5,
    radius: 13,
    color: "#8b5fbf",
    accent: "#d0b3f5",
  },
  dark_knight: {
    id: "dark_knight",
    name: { zh: "黑铁骑士", en: "Dark Knight" },
    hp: 290,
    atk: 28,
    aspd: 0.9,
    speed: 42,
    range: 42,
    gold: 13,
    radius: 20,
    color: "#4a4e69",
    accent: "#f28482",
  },
  boss_warlord: {
    id: "boss_warlord",
    name: { zh: "兽人战争领主", en: "Orc Warlord" },
    isBoss: true,
    hp: 1050,
    atk: 42,
    aspd: 0.85,
    speed: 30,
    range: 52,
    gold: 45,
    radius: 28,
    color: "#b5173c",
    accent: "#ffb703",
  },
  boss_beholder: {
    id: "boss_beholder",
    name: { zh: "审判之眼 · 邪眼领主", en: "Judgment Beholder" },
    isBoss: true,
    targetsBackline: true,
    hp: 1850,
    atk: 46,
    aspd: 0.78,
    speed: 26,
    range: 420,
    projSpeed: 360,
    gold: 70,
    radius: 30,
    color: "#7209b7",
    accent: "#ff006e",
  },
  boss_dread: {
    id: "boss_dread",
    name: { zh: "永夜恐惧领主", en: "Dread Sovereign" },
    isBoss: true,
    hp: 3400,
    atk: 64,
    aspd: 0.9,
    speed: 32,
    range: 56,
    gold: 100,
    radius: 32,
    color: "#2b2d42",
    accent: "#ef233c",
  },
  boss_abyss: {
    id: "boss_abyss",
    name: { zh: "终焉审判 · 深渊暴君", en: "Abyssal Judgment" },
    isBoss: true,
    targetsBackline: true,
    hp: 6200,
    atk: 78,
    aspd: 0.95,
    speed: 28,
    range: 430,
    projSpeed: 400,
    gold: 200,
    radius: 34,
    color: "#540b0e",
    accent: "#ffbe0b",
  },
};

export const MAX_WAVES = 20;

export function buildWavePlan(wave) {
  const scale = 1 + (wave - 1) * 0.14 + Math.max(0, wave - 8) * 0.06;
  const spawns = [];
  const totalCount = 5 + Math.floor(wave * 1.65);

  const add = (type, delay) => spawns.push({ type, delay, scale });

  let t = 0.4;
  for (let i = 0; i < totalCount; i++) {
    let type = "goblin";
    const r = Math.random();
    if (wave >= 2 && r < 0.28) type = "slime";
    if (wave >= 3 && r >= 0.28 && r < 0.52) type = "orc";
    if (wave >= 4 && r >= 0.52 && r < 0.72) type = "archer_foe";
    if (wave >= 7 && r >= 0.72 && r < 0.88) type = "dark_knight";
    add(type, t);
    t += Math.max(0.32, 1.15 - wave * 0.032);
  }

  let isBossWave = false;
  let bossType = null;
  if (wave === 5) {
    isBossWave = true;
    bossType = "boss_warlord";
  } else if (wave === 10) {
    isBossWave = true;
    bossType = "boss_beholder";
  } else if (wave === 15) {
    isBossWave = true;
    bossType = "boss_dread";
  } else if (wave === 20) {
    isBossWave = true;
    bossType = "boss_abyss";
  }

  if (bossType) {
    add(bossType, t + 0.8);
  }

  return {
    wave,
    isBossWave,
    bossType,
    spawns,
  };
}
