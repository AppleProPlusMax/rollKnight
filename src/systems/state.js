import { ADVANCED_CLASSES, BASE_UNITS, xpNeededForTier } from "../data/units.js";
import { CORES } from "../data/cores.js";
import { MAX_WAVES, buildWavePlan } from "../data/waves.js";
import { SlotMachine } from "./slotMachine.js";
import { assignFormationPositions, genId, updateBattle } from "./battle.js";

export const MAX_ROSTER = 10;

export function createUnitInstance(baseId, tierOverride = null) {
  const tpl = BASE_UNITS[baseId];
  const tier = tierOverride ?? tpl.startingTier ?? 1;
  const mult = tier === 2 ? 1.55 : 1.0;

  return {
    id: genId("unit"),
    baseId: tpl.id,
    classId: null,
    name: tpl.name,
    role: tpl.role,
    laneX: tpl.laneX,
    tier,
    xp: 0,
    hp: Math.round(tpl.hp * mult),
    maxHp: Math.round(tpl.hp * mult),
    atk: Math.round(tpl.atk * mult),
    aspd: tpl.aspd,
    range: tpl.range,
    speed: tpl.speed,
    color: tpl.color,
    accent: tpl.accent,
    attackType: tpl.attackType,
    projSpeed: tpl.projSpeed || 0,
    pierce: tpl.pierce || 0,
    splash: tpl.splash || 0,
    knockback: tpl.knockback || 0,
    cleaveRadius: tpl.cleaveRadius || 0,
    critChance: tpl.critChance || 0,
    summonOnKill: !!tpl.summonOnKill,
    summonCount: tpl.summonCount || 1,
    thorns: 0,
    healOnHit: 0,
    lifesteal: 0,
    overdriveOnKill: false,
    multishot: 0,
    chainTargets: 0,
    meteorEvery: 0,
    sellGold: tpl.sellGold,
    xpValue: tpl.xpValue,
    traits: tpl.traits,
    branches: tpl.branches,
    kills: 0,
    attackCount: 0,
    cooldown: 0.1,
    hitFlash: 0,
    attackAnim: 0,
    overdriveTimer: 0,
    radius: tier >= 2 ? 17 : 15,
    x: 500,
    y: 340,
    homeX: 500,
    homeY: 340,
    inBattlePosInitialized: false,
  };
}

export class GameState {
  constructor(audio) {
    this.audio = audio;
    this.phase = "menu"; // menu | spin | battle | gameover | victory
    this.wave = 1;
    this.waveActive = false;
    this.fastForward = false;
    this.paused = false;

    this.gold = 35;
    this.hearts = 10;
    this.maxHearts = 10;
    this.nudges = 2;
    this.nudgesPerWave = 2;

    this.baseSpinCost = 5;
    this.spinCostStep = 3;
    this.spinsThisWave = 0;
    this.freeFirstSpin = false;

    this.symbolWeights = {};
    this.slot = new SlotMachine(this.symbolWeights);

    this.roster = [];
    this.summons = [];
    this.enemies = [];
    this.projectiles = [];
    this.meteors = [];
    this.vfx = [];
    this.floatingTexts = [];

    this.cores = [];
    this.coreModal = null; // { choices: Core[] }
    this.classModal = null; // { unitId, choices: Class[] }

    this.selectedUnitId = null;
    this.feedMode = false;
    this.feedSacrificeId = null;

    this.wavePlan = null;
    this.waveElapsed = 0;
    this.spawnCursor = 0;
    this.totalKills = 0;

    this.screenShake = 0;
    this.jackpotFlash = 0;
    this.bossBannerTimer = 0;
    this.bannerText = "";
    this.bannerTimer = 0;
  }

  hasCore(coreId) {
    return this.cores.some((c) => c.id === coreId);
  }

  rebuildReels() {
    this.slot.rebuild(this.symbolWeights);
  }

  currentSpinCost() {
    if (this.freeFirstSpin && this.spinsThisWave === 0) return 0;
    return this.baseSpinCost + this.spinsThisWave * this.spinCostStep;
  }

  startRun() {
    this.phase = "spin";
    this.wave = 1;
    this.waveActive = false;
    this.paused = false;
    this.gold = 38;
    this.hearts = 10;
    this.maxHearts = 10;
    this.nudgesPerWave = 2;
    this.nudges = 2;
    this.baseSpinCost = 5;
    this.spinCostStep = 3;
    this.spinsThisWave = 0;
    this.freeFirstSpin = false;
    this.symbolWeights = {};
    this.slot = new SlotMachine(this.symbolWeights);

    this.roster = [createUnitInstance("warrior"), createUnitInstance("ranger")];
    assignFormationPositions(this.roster);
    this.summons = [];
    this.enemies = [];
    this.projectiles = [];
    this.meteors = [];
    this.vfx = [];
    this.floatingTexts = [];
    this.cores = [];
    this.coreModal = null;
    this.classModal = null;
    this.selectedUnitId = this.roster[0].id;
    this.feedMode = false;
    this.feedSacrificeId = null;
    this.totalKills = 0;
    this.wavePlan = null;
    this.jackpotFlash = 0;
    this.bossBannerTimer = 0;
  }

  canSpin() {
    return (
      (this.phase === "spin" || this.phase === "battle") &&
      !this.coreModal &&
      !this.classModal &&
      !this.slot.spinning &&
      this.gold >= this.currentSpinCost()
    );
  }

  spin() {
    if (!this.canSpin()) return false;
    const cost = this.currentSpinCost();
    this.gold -= cost;
    this.spinsThisWave += 1;
    this.slot.startSpin();
    this.audio.playLever();
    return true;
  }

  nudgeReel(col, dir) {
    if (
      (this.phase !== "spin" && this.phase !== "battle") ||
      this.coreModal ||
      this.classModal ||
      this.slot.spinning ||
      this.nudges <= 0
    ) {
      return false;
    }
    if (this.slot.nudge(col, dir)) {
      this.nudges -= 1;
      this.audio.playNudge();
      this.applySlotMatches();
      return true;
    }
    return false;
  }

  applySlotMatches() {
    const matches = this.slot.collectNewMatches();
    if (matches.length === 0) return [];

    let triggeredJackpot = false;
    const jesterActive = this.hasCore("jester_trick");

    for (const m of matches) {
      const mult = jesterActive && m.isDiagonal ? 2 : 1;

      if (m.isPureJackpot) {
        triggeredJackpot = true;
        const goldGain = (m.symbol.payoutGold || 15) * mult;
        this.gold += goldGain;
        for (let i = 0; i < mult; i++) {
          this.summonUnit("champion");
        }
        this.floatingTexts.push({
          x: 205,
          y: 255,
          vy: -28,
          text: `JACKPOT +${goldGain}g!`,
          color: "#ffdf6b",
          life: 1.3,
          maxLife: 1.3,
          scale: 1.35,
        });
      } else if (m.symbol.unitId) {
        for (let i = 0; i < mult; i++) {
          this.summonUnit(m.symbol.unitId);
        }
        if (m.crownCount > 0) {
          const bonus = 6 * m.crownCount;
          this.gold += bonus;
        }
      } else if (m.symbol.payoutGold > 0) {
        const gain = m.symbol.payoutGold * mult;
        this.gold += gain;
        this.audio.playCoin();
        this.floatingTexts.push({
          x: 205,
          y: 280,
          vy: -30,
          text: `+${gain}g`,
          color: "#f6c945",
          life: 1.0,
          maxLife: 1.0,
          scale: 1.25,
        });
      }
    }

    if (triggeredJackpot) {
      this.jackpotFlash = 1.0;
      this.screenShake = Math.max(this.screenShake, 10);
      this.audio.playJackpot();
    } else {
      this.audio.playMatch(matches.length);
    }

    return matches;
  }

  summonUnit(baseId) {
    if (this.roster.length < MAX_ROSTER) {
      const unit = createUnitInstance(baseId);
      this.roster.push(unit);
      assignFormationPositions(this.roster);
      this.selectedUnitId = unit.id;
      this.floatingTexts.push({
        x: unit.x,
        y: unit.y - 26,
        vy: -28,
        text: `+${unit.name.zh}`,
        color: unit.accent,
        life: 0.9,
        maxLife: 0.9,
        scale: 1.05,
      });
      return unit;
    }

    // Roster full -> auto-merge XP into lowest-tier unit or refund gold
    const target = this.roster.find((u) => u.baseId === baseId && u.tier < 3) || this.roster.find((u) => u.tier < 3);
    if (target) {
      this.grantUnitXp(target, 1);
      return target;
    }

    const refund = (BASE_UNITS[baseId]?.sellGold ?? 6);
    this.gold += refund;
    this.floatingTexts.push({
      x: 210,
      y: 320,
      vy: -26,
      text: `满编折现 +${refund}g`,
      color: "#f6c945",
      life: 0.9,
      maxLife: 0.9,
      scale: 1.05,
    });
    return null;
  }

  grantUnitXp(target, amount) {
    if (!target || target.tier >= 3) return;
    target.xp += amount;
    const needed = xpNeededForTier(target.tier);
    if (target.xp >= needed) {
      target.xp -= needed;
      target.tier += 1;
      target.radius = target.tier >= 2 ? 17 : 15;
      this.audio.playEvolve();

      if (target.tier === 2) {
        target.maxHp = Math.round(target.maxHp * 1.55);
        target.hp = target.maxHp;
        target.atk = Math.round(target.atk * 1.48);
        target.aspd = Number((target.aspd * 1.12).toFixed(2));
        this.floatingTexts.push({
          x: target.x,
          y: target.y - 32,
          vy: -32,
          text: "★ 2★ 晋升!",
          color: "#ffdf6b",
          life: 1.15,
          maxLife: 1.15,
          scale: 1.25,
        });
      } else if (target.tier === 3) {
        target.xp = 0;
        const branchIds = target.branches || ["paladin", "berserker"];
        this.classModal = {
          unitId: target.id,
          choices: branchIds.map((id) => ADVANCED_CLASSES[id]).filter(Boolean),
        };
      }
    }
  }

  absorbUnit(sacrificeId, targetId) {
    if (!sacrificeId || !targetId || sacrificeId === targetId) return false;
    const sacIdx = this.roster.findIndex((u) => u.id === sacrificeId);
    const tgt = this.roster.find((u) => u.id === targetId);
    if (sacIdx < 0 || !tgt || tgt.tier >= 3) return false;

    const sac = this.roster[sacIdx];
    const sameTypeBonus = sac.baseId === tgt.baseId ? 1 : 0;
    const bloodPact = this.hasCore("blood_pact");
    const xpGain = (sac.xpValue || 1) + (sac.tier - 1) * 2 + sameTypeBonus + (bloodPact ? 1 : 0);

    if (bloodPact) {
      tgt.atk = Math.round(tgt.atk * 1.18);
    }

    this.roster.splice(sacIdx, 1);
    assignFormationPositions(this.roster);
    this.selectedUnitId = tgt.id;
    this.feedSacrificeId = null;
    this.feedMode = false;

    this.grantUnitXp(tgt, xpGain);
    this.floatingTexts.push({
      x: tgt.x,
      y: tgt.y - 20,
      vy: -30,
      text: `+${xpGain} EXP`,
      color: "#80ffdb",
      life: 0.9,
      maxLife: 0.9,
      scale: 1.15,
    });
    return true;
  }

  dismissUnit(unitId) {
    if (this.roster.length <= 1) return false;
    const idx = this.roster.findIndex((u) => u.id === unitId);
    if (idx < 0) return false;
    const unit = this.roster[idx];
    const gain = Math.round((unit.sellGold || 6) * unit.tier);
    this.gold += gain;
    this.roster.splice(idx, 1);
    assignFormationPositions(this.roster);
    this.selectedUnitId = this.roster[0]?.id ?? null;
    this.audio.playCoin();
    return true;
  }

  chooseClass(classId) {
    if (!this.classModal) return false;
    const unit = this.roster.find((u) => u.id === this.classModal.unitId);
    const cls = ADVANCED_CLASSES[classId];
    if (!unit || !cls) {
      this.classModal = null;
      return false;
    }

    unit.classId = cls.id;
    unit.name = cls.name;
    unit.color = cls.color;
    unit.accent = cls.accent;
    unit.maxHp = Math.round(unit.maxHp * cls.hpMult);
    unit.hp = unit.maxHp;
    unit.atk = Math.round(unit.atk * cls.atkMult);
    unit.aspd = Number((unit.aspd * cls.aspdMult).toFixed(2));
    if (cls.role) unit.role = cls.role;
    if (cls.laneX) unit.laneX = cls.laneX;
    if (cls.range) unit.range = cls.range;
    if (cls.rangeBonus) unit.range += cls.rangeBonus;
    if (cls.attackType) unit.attackType = cls.attackType;
    if (cls.projSpeed) unit.projSpeed = cls.projSpeed;
    if (cls.pierce) unit.pierce = (unit.pierce || 0) + cls.pierce;
    if (cls.splash) unit.splash = cls.splash;
    if (cls.knockback) unit.knockback = cls.knockback;
    if (cls.cleaveRadius) unit.cleaveRadius = cls.cleaveRadius;
    if (cls.critChance) unit.critChance = Math.max(unit.critChance || 0, cls.critChance);
    if (cls.thorns) unit.thorns = cls.thorns;
    if (cls.healOnHit) unit.healOnHit = cls.healOnHit;
    if (cls.lifesteal) unit.lifesteal = cls.lifesteal;
    if (cls.overdriveOnKill) unit.overdriveOnKill = true;
    if (cls.summonOnKill) unit.summonOnKill = true;
    if (cls.summonCount) unit.summonCount = cls.summonCount;
    if (cls.multishot) unit.multishot = cls.multishot;
    if (cls.chainTargets) unit.chainTargets = cls.chainTargets;
    if (cls.meteorEvery) unit.meteorEvery = cls.meteorEvery;
    unit.traits = cls.desc;
    unit.radius = 19;

    assignFormationPositions(this.roster);
    this.classModal = null;
    this.audio.playJackpot();
    return true;
  }

  openCoreDraft() {
    const ownedIds = new Set(this.cores.map((c) => c.id));
    const pool = CORES.filter((c) => !ownedIds.has(c.id));
    if (pool.length === 0) return;

    const shuffled = [...pool].sort(() => Math.random() - 0.5);
    this.coreModal = { choices: shuffled.slice(0, 3) };
  }

  chooseCore(coreId) {
    if (!this.coreModal) return false;
    const core = this.coreModal.choices.find((c) => c.id === coreId);
    if (!core) return false;
    this.cores.push(core);
    if (core.onAcquire) {
      core.onAcquire(this);
    }
    this.coreModal = null;
    this.audio.playEvolve();
    return true;
  }

  startWave() {
    if (this.phase !== "spin" || this.coreModal || this.classModal) return false;
    this.phase = "battle";
    this.waveActive = true;
    this.feedMode = false;
    this.feedSacrificeId = null;
    this.wavePlan = buildWavePlan(this.wave);
    this.waveElapsed = 0;
    this.spawnCursor = 0;
    this.summons = [];
    this.projectiles = [];
    this.meteors = [];
    assignFormationPositions(this.roster);
    return true;
  }

  completeWave() {
    this.waveActive = false;
    this.summons = [];
    this.projectiles = [];
    this.meteors = [];

    // Heal surviving units between waves
    for (const u of this.roster) {
      u.hp = u.maxHp;
      u.overdriveTimer = 0;
      u.x = u.homeX;
      u.y = u.homeY;
    }

    if (this.wave >= MAX_WAVES) {
      this.phase = "victory";
      this.audio.playJackpot();
      return;
    }

    const waveBonus = 14 + this.wave * 2 + (this.hasCore("castle_mason") ? 12 : 0);
    this.gold += waveBonus;

    const clearedWave = this.wave;
    this.wave += 1;
    this.spinsThisWave = 0;
    this.nudges = this.nudgesPerWave;
    this.phase = "spin";

    // Open Core Relic modal on key milestone waves
    if ([1, 3, 5, 7, 10, 13, 16, 19].includes(clearedWave)) {
      this.openCoreDraft();
    }
  }

  update(rawDt) {
    const dt = Math.min(0.05, rawDt);
    this.screenShake = Math.max(0, this.screenShake - dt * 28);
    this.jackpotFlash = Math.max(0, this.jackpotFlash - dt * 1.6);
    this.bossBannerTimer = Math.max(0, this.bossBannerTimer - dt);
    this.bannerTimer = Math.max(0, this.bannerTimer - dt);

    // Update floating texts & particles even during spin
    for (const ft of this.floatingTexts) {
      ft.y += ft.vy * dt;
      ft.life -= dt;
    }
    this.floatingTexts = this.floatingTexts.filter((f) => f.life > 0);

    for (const v of this.vfx) {
      v.life -= dt;
      if (v.kind === "particle") {
        v.x += v.vx * dt;
        v.y += v.vy * dt;
        v.vx *= 0.94;
        v.vy *= 0.94;
      }
    }
    this.vfx = this.vfx.filter((v) => v.life > 0);

    if (this.paused || this.coreModal || this.classModal) {
      return;
    }

    // Slot machine updates during spin or mid-battle spin
    if (this.slot.spinning) {
      const res = this.slot.update(dt);
      if (res.ticked) this.audio.playReelTick();
      for (const col of res.stoppedCols) {
        this.audio.playReelStop(col);
      }
      if (res.finished) {
        this.applySlotMatches();
      }
    }

    if (this.phase === "battle" && this.waveActive) {
      const simDt = this.fastForward ? dt * 2.0 : dt;
      updateBattle(this, simDt);

      if (this.hearts <= 0) {
        this.phase = "gameover";
        this.waveActive = false;
        return;
      }

      const allSpawned = this.wavePlan && this.spawnCursor >= this.wavePlan.spawns.length;
      if (allSpawned && this.enemies.length === 0) {
        this.completeWave();
      }
    }
  }
}
