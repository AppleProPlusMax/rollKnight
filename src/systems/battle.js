import { ENEMY_TYPES } from "../data/waves.js";

export const ARENA = {
  x: 396,
  y: 78,
  w: 866,
  h: 552,
  castleX: 432,
  spawnX: 1236,
  rightBound: 1240,
  minY: 118,
  maxY: 594,
};

let nextEntityId = 1;
export function genId(prefix = "e") {
  return `${prefix}_${nextEntityId++}`;
}

export function spawnEnemyFromPlan(entry) {
  const tpl = ENEMY_TYPES[entry.type];
  const scale = entry.scale || 1;
  const maxHp = Math.round(tpl.hp * scale);
  const atk = Math.round(tpl.atk * (1 + (scale - 1) * 0.55));
  const y = ARENA.minY + 26 + Math.random() * (ARENA.maxY - ARENA.minY - 52);

  return {
    id: genId("foe"),
    typeId: tpl.id,
    name: tpl.name,
    isBoss: !!tpl.isBoss,
    targetsBackline: !!tpl.targetsBackline,
    x: ARENA.rightBound - Math.random() * 14,
    y,
    vx: 0,
    vy: 0,
    hp: maxHp,
    maxHp,
    atk,
    aspd: tpl.aspd,
    speed: tpl.speed,
    range: tpl.range,
    projSpeed: tpl.projSpeed || 0,
    gold: Math.round(tpl.gold * (1 + (scale - 1) * 0.25)),
    radius: tpl.radius,
    color: tpl.color,
    accent: tpl.accent,
    cooldown: 0.2 + Math.random() * 0.3,
    hitFlash: 0,
    attackAnim: 0,
  };
}

export function spawnSkeletonAlly(x, y, waveScale = 1) {
  const maxHp = Math.round(52 * (1 + (waveScale - 1) * 0.25));
  const atk = Math.round(12 * (1 + (waveScale - 1) * 0.25));
  return {
    id: genId("skel"),
    baseId: "skeleton",
    isSummon: true,
    name: { zh: "骷髅兵", en: "Skeleton" },
    role: "frontline",
    x: Math.min(ARENA.rightBound - 10, x + (Math.random() - 0.5) * 18),
    y: Math.max(ARENA.minY, Math.min(ARENA.maxY, y + (Math.random() - 0.5) * 24)),
    homeX: x,
    homeY: y,
    hp: maxHp,
    maxHp,
    atk,
    aspd: 1.2,
    range: 36,
    speed: 92,
    color: "#cbd5e1",
    accent: "#64dfdf",
    attackType: "melee",
    tier: 1,
    xp: 0,
    kills: 0,
    attackCount: 0,
    cooldown: 0.2,
    hitFlash: 0,
    attackAnim: 0,
    overdriveTimer: 0,
    radius: 12,
  };
}

export function assignFormationPositions(roster) {
  const groups = { frontline: [], vanguard: [], midline: [], backline: [] };
  for (const u of roster) {
    const bucket = groups[u.role] || groups.frontline;
    bucket.push(u);
  }

  for (const role of Object.keys(groups)) {
    const list = groups[role];
    const n = list.length;
    for (let i = 0; i < n; i++) {
      const u = list[i];
      const frac = n === 1 ? 0.5 : (i + 0.5) / n;
      const laneX = ARENA.castleX + 46 + (u.laneX ?? 0.35) * (ARENA.w - 170);
      const jitterX = (i % 2 === 0 ? -12 : 12);
      const homeY = ARENA.minY + 18 + frac * (ARENA.maxY - ARENA.minY - 36);
      u.homeX = Math.max(ARENA.castleX + 36, Math.min(ARENA.spawnX - 180, laneX + jitterX));
      u.homeY = homeY;
      if (!u.inBattlePosInitialized) {
        u.x = u.homeX;
        u.y = u.homeY;
        u.inBattlePosInitialized = true;
      }
    }
  }
}

function dist(a, b) {
  return Math.hypot(a.x - b.x, a.y - b.y);
}

function spawnVfx(state, vfx) {
  state.vfx.push(vfx);
}

function addFloatingText(state, x, y, text, color = "#ffffff", scale = 1) {
  state.floatingTexts.push({
    x,
    y,
    vy: -34,
    text,
    color,
    life: 0.75,
    maxLife: 0.75,
    scale,
  });
}

export function callMeteor(state, targetX, targetY, damage, radius = 78) {
  state.meteors.push({
    x: targetX,
    y: targetY,
    startX: targetX - 90,
    startY: targetY - 260,
    progress: 0,
    duration: 0.38,
    damage,
    radius,
  });
}

function damageEnemy(state, enemy, rawDmg, attacker, isCrit = false, knockback = 0) {
  if (!enemy || enemy.hp <= 0) return false;
  const dmg = Math.max(1, Math.round(rawDmg));
  enemy.hp -= dmg;
  enemy.hitFlash = 0.14;

  if (knockback > 0 && !enemy.isBoss) {
    enemy.x = Math.min(ARENA.rightBound, enemy.x + knockback);
  } else if (knockback > 0 && enemy.isBoss) {
    enemy.x = Math.min(ARENA.rightBound, enemy.x + knockback * 0.25);
  }

  addFloatingText(
    state,
    enemy.x + (Math.random() - 0.5) * 14,
    enemy.y - enemy.radius - 6,
    isCrit ? `${dmg}!` : `${dmg}`,
    isCrit ? "#ffdf6b" : "#ffffff",
    isCrit ? 1.25 : 1
  );

  if (attacker && attacker.lifesteal) {
    attacker.hp = Math.min(attacker.maxHp, attacker.hp + Math.round(dmg * attacker.lifesteal));
  }
  if (attacker && attacker.healOnHit) {
    attacker.hp = Math.min(attacker.maxHp, attacker.hp + attacker.healOnHit);
  }

  if (enemy.hp <= 0) {
    handleEnemyDeath(state, enemy, attacker);
    return true;
  }
  return false;
}

function handleEnemyDeath(state, enemy, killer) {
  state.gold += enemy.gold;
  state.totalKills += 1;
  state.audio.playCoin();

  addFloatingText(state, enemy.x, enemy.y - 24, `+${enemy.gold}g`, "#f6c945", 1.05);

  for (let i = 0; i < (enemy.isBoss ? 22 : 9); i++) {
    const ang = Math.random() * Math.PI * 2;
    const spd = 40 + Math.random() * 110;
    spawnVfx(state, {
      kind: "particle",
      x: enemy.x,
      y: enemy.y,
      vx: Math.cos(ang) * spd,
      vy: Math.sin(ang) * spd,
      color: i % 2 === 0 ? enemy.color : enemy.accent,
      size: enemy.isBoss ? 5 : 3,
      life: 0.4 + Math.random() * 0.25,
      maxLife: 0.65,
    });
  }

  if (killer) {
    killer.kills = (killer.kills || 0) + 1;

    if (killer.overdriveOnKill || state.hasCore("vampiric_crown")) {
      killer.overdriveTimer = 3.0;
      if (state.hasCore("vampiric_crown")) {
        killer.hp = Math.min(killer.maxHp, killer.hp + Math.round(killer.maxHp * 0.15));
      }
      addFloatingText(state, killer.x, killer.y - 30, "OVERDRIVE!", "#ff8866", 0.9);
    }

    if (killer.summonOnKill) {
      const count = killer.summonCount || 1;
      for (let i = 0; i < count; i++) {
        if (state.summons.length < 14) {
          state.summons.push(spawnSkeletonAlly(enemy.x - 16, enemy.y, 1 + (state.wave - 1) * 0.12));
        }
      }
    }
  }
}

export function updateBattle(state, dt) {
  const plan = state.wavePlan;
  if (plan) {
    state.waveElapsed += dt;
    while (state.spawnCursor < plan.spawns.length && state.waveElapsed >= plan.spawns[state.spawnCursor].delay) {
      const entry = plan.spawns[state.spawnCursor];
      const foe = spawnEnemyFromPlan(entry);
      state.enemies.push(foe);
      if (foe.isBoss) {
        state.bossBannerTimer = 2.6;
        state.screenShake = Math.max(state.screenShake, 8);
      }
      state.spawnCursor++;
    }
  }

  const allAllies = [...state.roster, ...state.summons].filter((u) => u.hp > 0);

  // Update allied units
  for (const unit of allAllies) {
    unit.hitFlash = Math.max(0, (unit.hitFlash || 0) - dt);
    unit.attackAnim = Math.max(0, (unit.attackAnim || 0) - dt);
    unit.overdriveTimer = Math.max(0, (unit.overdriveTimer || 0) - dt);

    const speedBonus = unit.overdriveTimer > 0 ? 1.4 : 1.0;
    const coreAspdBonus =
      !unit.isSummon && (unit.attackType === "arrow" || unit.attackType === "multishot" || unit.attackType === "magic") && state.hasCore("wind_quiver")
        ? 1.22
        : 1.0;

    unit.cooldown -= dt * speedBonus * coreAspdBonus;

    // Find closest alive enemy
    let target = null;
    let bestD = Infinity;
    for (const foe of state.enemies) {
      if (foe.hp <= 0) continue;
      const d = dist(unit, foe);
      if (d < bestD) {
        bestD = d;
        target = foe;
      }
    }

    if (target) {
      const effectiveRange = unit.range + (target.radius || 14) * 0.6;
      if (bestD > effectiveRange) {
        const dx = target.x - unit.x;
        const dy = target.y - unit.y;
        const len = Math.hypot(dx, dy) || 1;
        // Backline stays left of midline when possible, but advances far enough to keep edge enemies in range
        const maxAdvanceX =
          unit.role === "backline"
            ? Math.max(ARENA.castleX + 360, ARENA.rightBound - unit.range + 40)
            : ARENA.rightBound - 6;
        const nx = unit.x + (dx / len) * unit.speed * dt;
        const ny = unit.y + (dy / len) * unit.speed * dt;
        unit.x = Math.min(maxAdvanceX, Math.max(ARENA.castleX + 26, nx));
        unit.y = Math.max(ARENA.minY, Math.min(ARENA.maxY, ny));
      } else if (unit.cooldown <= 0) {
        performAllyAttack(state, unit, target);
      }
    } else {
      // Drift smoothly back to formation
      const dx = unit.homeX - unit.x;
      const dy = unit.homeY - unit.y;
      const d = Math.hypot(dx, dy);
      if (d > 4) {
        unit.x += (dx / d) * Math.min(d, unit.speed * dt);
        unit.y += (dy / d) * Math.min(d, unit.speed * dt);
      }
    }
  }

  // Update enemies
  for (const foe of state.enemies) {
    if (foe.hp <= 0) continue;
    foe.hitFlash = Math.max(0, foe.hitFlash - dt);
    foe.attackAnim = Math.max(0, foe.attackAnim - dt);
    foe.cooldown -= dt;

    // Target selection (Beholder targets backline!)
    let target = null;
    let bestScore = Infinity;
    for (const ally of allAllies) {
      if (ally.hp <= 0) continue;
      const d = dist(foe, ally);
      if (foe.targetsBackline && d <= foe.range) {
        // Prioritize leftmost (backline) units
        const score = ally.x;
        if (score < bestScore) {
          bestScore = score;
          target = ally;
        }
      } else if (!foe.targetsBackline) {
        if (d < bestScore) {
          bestScore = d;
          target = ally;
        }
      }
    }

    if (!target && allAllies.length > 0) {
      // Fallback closest ally
      let minD = Infinity;
      for (const ally of allAllies) {
        if (ally.hp <= 0) continue;
        const d = dist(foe, ally);
        if (d < minD) {
          minD = d;
          target = ally;
        }
      }
    }

    const dToTarget = target ? dist(foe, target) : Infinity;
    const enteredArena = foe.x <= ARENA.rightBound - 18;

    if (target && enteredArena && dToTarget <= foe.range) {
      if (foe.cooldown <= 0) {
        foe.cooldown = 1 / foe.aspd;
        foe.attackAnim = 0.18;
        if (foe.projSpeed > 0) {
          state.projectiles.push({
            fromEnemy: true,
            x: foe.x - 10,
            y: foe.y,
            vx: ((target.x - foe.x) / (dToTarget || 1)) * foe.projSpeed,
            vy: ((target.y - foe.y) / (dToTarget || 1)) * foe.projSpeed,
            damage: foe.atk,
            color: foe.accent,
            radius: foe.isBoss ? 7 : 4,
            pierceLeft: 0,
            hitIds: new Set(),
            life: 2.2,
          });
        } else {
          damageAlly(state, target, foe.atk, foe);
          spawnVfx(state, {
            kind: "slash",
            x: target.x,
            y: target.y,
            color: foe.accent,
            life: 0.16,
            maxLife: 0.16,
            radius: 18,
          });
        }
      }
    } else {
      // Advance left toward castle, slightly steering toward nearby target if close
      let moveX = -foe.speed;
      let moveY = 0;
      if (target && Math.abs(target.x - foe.x) < 160) {
        const dy = target.y - foe.y;
        const len = Math.hypot(target.x - foe.x, dy) || 1;
        moveX = ((target.x - foe.x) / len) * foe.speed;
        moveY = (dy / len) * foe.speed;
      }
      foe.x += moveX * dt;
      foe.y = Math.max(ARENA.minY, Math.min(ARENA.maxY, foe.y + moveY * dt));
    }

    // Breach castle wall check
    if (foe.x <= ARENA.castleX) {
      const heartLoss = foe.isBoss ? 3 : 1;
      state.hearts = Math.max(0, state.hearts - heartLoss);
      state.screenShake = Math.max(state.screenShake, 12);
      state.audio.playHurtBase();
      addFloatingText(state, ARENA.castleX + 18, foe.y, `-${heartLoss} ♥`, "#ff4d6d", 1.35);
      foe.hp = 0;
    }
  }

  // Update projectiles
  for (const p of state.projectiles) {
    p.x += p.vx * dt;
    p.y += p.vy * dt;
    p.life -= dt;

    if (p.fromEnemy) {
      for (const ally of allAllies) {
        if (ally.hp <= 0 || p.hitIds.has(ally.id)) continue;
        if (Math.hypot(p.x - ally.x, p.y - ally.y) <= (ally.radius || 15) + p.radius) {
          p.hitIds.add(ally.id);
          damageAlly(state, ally, p.damage, null);
          p.life = 0;
          break;
        }
      }
    } else {
      for (const foe of state.enemies) {
        if (foe.hp <= 0 || p.hitIds.has(foe.id)) continue;
        if (Math.hypot(p.x - foe.x, p.y - foe.y) <= foe.radius + p.radius + 4) {
          p.hitIds.add(foe.id);
          if (p.splash > 0) {
            for (const near of state.enemies) {
              if (near.hp > 0 && Math.hypot(near.x - p.x, near.y - p.y) <= p.splash) {
                damageEnemy(state, near, p.damage * (near === foe ? 1 : 0.65), p.attacker, p.isCrit);
              }
            }
            spawnVfx(state, {
              kind: "ring",
              x: p.x,
              y: p.y,
              color: p.color,
              radius: p.splash,
              life: 0.22,
              maxLife: 0.22,
            });
          } else {
            damageEnemy(state, foe, p.damage, p.attacker, p.isCrit);
          }

          if (p.chainTargets > 0) {
            let chained = 0;
            for (const near of state.enemies) {
              if (near !== foe && near.hp > 0 && Math.hypot(near.x - foe.x, near.y - foe.y) <= 130) {
                damageEnemy(state, near, p.damage * 0.6, p.attacker, false);
                spawnVfx(state, {
                  kind: "beam",
                  x1: foe.x,
                  y1: foe.y,
                  x2: near.x,
                  y2: near.y,
                  color: "#d9b8ff",
                  life: 0.18,
                  maxLife: 0.18,
                });
                chained++;
                if (chained >= p.chainTargets) break;
              }
            }
          }

          if (p.pierceLeft > 0) {
            p.pierceLeft--;
          } else {
            p.life = 0;
            break;
          }
        }
      }
    }
  }

  // Update meteors
  for (const m of state.meteors) {
    m.progress += dt / m.duration;
    if (m.progress >= 1) {
      m.impacted = true;
      state.screenShake = Math.max(state.screenShake, 7);
      state.audio.playMeteor();
      for (const foe of state.enemies) {
        if (foe.hp > 0 && Math.hypot(foe.x - m.x, foe.y - m.y) <= m.radius) {
          damageEnemy(state, foe, m.damage, m.attacker, true, 16);
        }
      }
      spawnVfx(state, {
        kind: "ring",
        x: m.x,
        y: m.y,
        color: "#ff7c43",
        radius: m.radius,
        life: 0.32,
        maxLife: 0.32,
      });
      for (let i = 0; i < 12; i++) {
        const ang = Math.random() * Math.PI * 2;
        const spd = 60 + Math.random() * 140;
        spawnVfx(state, {
          kind: "particle",
          x: m.x,
          y: m.y,
          vx: Math.cos(ang) * spd,
          vy: Math.sin(ang) * spd,
          color: i % 2 === 0 ? "#ffbe0b" : "#fb5607",
          size: 4,
          life: 0.42,
          maxLife: 0.42,
        });
      }
    }
  }

  // Cleanup dead entities & expired effects
  state.enemies = state.enemies.filter((e) => e.hp > 0);
  state.roster = state.roster.filter((u) => u.hp > 0);
  state.summons = state.summons.filter((u) => u.hp > 0);
  state.projectiles = state.projectiles.filter((p) => p.life > 0 && p.x >= ARENA.x - 20 && p.x <= ARENA.spawnX + 60);
  state.meteors = state.meteors.filter((m) => !m.impacted);
}

function damageAlly(state, ally, rawDmg, attacker) {
  if (!ally || ally.hp <= 0) return;
  const dmg = Math.max(1, Math.round(rawDmg));
  ally.hp -= dmg;
  ally.hitFlash = 0.14;

  if (attacker && attacker.hp > 0) {
    let thornsPct = ally.thorns || 0;
    if ((ally.role === "frontline" || ally.role === "vanguard") && state.hasCore("phalanx_banner")) {
      thornsPct += 0.25;
    }
    if (thornsPct > 0) {
      damageEnemy(state, attacker, dmg * thornsPct, ally, false);
    }
  }

  if (ally.hp <= 0) {
    addFloatingText(state, ally.x, ally.y - 18, "✕", "#ff6b6b", 1.1);
    for (let i = 0; i < 8; i++) {
      const ang = Math.random() * Math.PI * 2;
      spawnVfx(state, {
        kind: "particle",
        x: ally.x,
        y: ally.y,
        vx: Math.cos(ang) * 70,
        vy: Math.sin(ang) * 70,
        color: ally.color,
        size: 3,
        life: 0.35,
        maxLife: 0.35,
      });
    }
  }
}

function performAllyAttack(state, unit, target) {
  unit.cooldown = 1 / unit.aspd;
  unit.attackAnim = 0.18;
  unit.attackCount = (unit.attackCount || 0) + 1;

  const overdriveMult = unit.overdriveTimer > 0 ? 1.35 : 1.0;
  const isCrit = Math.random() < (unit.critChance || 0);
  const dmg = unit.atk * overdriveMult * (isCrit ? 1.75 : 1.0);

  // Core: Meteor Resonance (every 5th attack) or Dragon Knight (every 3rd attack)
  if ((unit.meteorEvery && unit.attackCount % unit.meteorEvery === 0) ||
      (!unit.isSummon && state.hasCore("meteor_resonance") && unit.attackCount % 5 === 0)) {
    callMeteor(state, target.x, target.y, dmg * 1.45, 76);
  }

  const dx = target.x - unit.x;
  const dy = target.y - unit.y;
  const d = Math.hypot(dx, dy) || 1;
  const extraPierce = state.hasCore("wind_quiver") ? 1 : 0;

  if (unit.attackType === "meteor") {
    state.audio.playMagic();
    callMeteor(state, target.x, target.y, dmg * 1.25, unit.splash || 85);
    return;
  }

  if (unit.attackType === "arrow" || unit.attackType === "magic" || unit.attackType === "soul") {
    if (unit.attackType === "arrow") state.audio.playBow();
    else state.audio.playMagic();

    const spd = unit.projSpeed || 420;
    state.projectiles.push({
      fromEnemy: false,
      attacker: unit,
      x: unit.x + 12,
      y: unit.y,
      vx: (dx / d) * spd,
      vy: (dy / d) * spd,
      damage: dmg,
      isCrit,
      splash: unit.splash || 0,
      chainTargets: unit.chainTargets || 0,
      pierceLeft: (unit.pierce || 0) + extraPierce,
      hitIds: new Set(),
      color: unit.accent,
      radius: unit.attackType === "magic" ? 6 : 4,
      life: 2.0,
    });
    return;
  }

  if (unit.attackType === "multishot") {
    state.audio.playBow();
    const spd = unit.projSpeed || 500;
    const baseAngle = Math.atan2(dy, dx);
    const count = unit.multishot || 3;
    for (let i = 0; i < count; i++) {
      const offset = (i - (count - 1) / 2) * 0.16;
      const ang = baseAngle + offset;
      state.projectiles.push({
        fromEnemy: false,
        attacker: unit,
        x: unit.x + 12,
        y: unit.y,
        vx: Math.cos(ang) * spd,
        vy: Math.sin(ang) * spd,
        damage: dmg * 0.72,
        isCrit,
        splash: 0,
        pierceLeft: (unit.pierce || 0) + extraPierce,
        hitIds: new Set(),
        color: unit.accent,
        radius: 4,
        life: 1.8,
      });
    }
    return;
  }

  // Melee / Lance / Cleave
  state.audio.playHit();
  if (unit.attackType === "cleave" || unit.attackType === "lance") {
    const r = unit.cleaveRadius || 54;
    let hits = 0;
    const maxHits = unit.attackType === "lance" ? 1 + (unit.pierce || 1) : 99;
    for (const foe of state.enemies) {
      if (foe.hp > 0 && Math.hypot(foe.x - target.x, foe.y - target.y) <= r) {
        damageEnemy(state, foe, dmg, unit, isCrit, unit.knockback || 0);
        hits++;
        if (hits >= maxHits) break;
      }
    }
    spawnVfx(state, {
      kind: "slash",
      x: target.x,
      y: target.y,
      color: unit.accent,
      life: 0.2,
      maxLife: 0.2,
      radius: unit.attackType === "cleave" ? 30 : 24,
    });
  } else {
    damageEnemy(state, target, dmg, unit, isCrit, unit.knockback || 0);
    spawnVfx(state, {
      kind: "slash",
      x: target.x,
      y: target.y,
      color: unit.accent,
      life: 0.16,
      maxLife: 0.16,
      radius: 18,
    });
  }
}
