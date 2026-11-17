local Waves = require("src.data.waves")
local Color = require("src.utils.color")

local M = {}

M.ARENA = {
  x = 396,
  y = 78,
  w = 866,
  h = 552,
  castleX = 432,
  spawnX = 1236,
  rightBound = 1240,
  minY = 118,
  maxY = 594,
}

local nextEntityId = 1
function M.genId(prefix)
  prefix = prefix or "e"
  local id = prefix .. "_" .. tostring(nextEntityId)
  nextEntityId = nextEntityId + 1
  return id
end

local function dist(a, b)
  local dx = a.x - b.x
  local dy = a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end

local function addFloatingText(state, x, y, text, color, scale)
  state.floatingTexts[#state.floatingTexts + 1] = {
    x = x,
    y = y,
    vy = -34,
    text = text,
    color = color or { 1, 1, 1, 1 },
    life = 0.75,
    maxLife = 0.75,
    scale = scale or 1,
  }
end

local function spawnVfx(state, vfx)
  state.vfx[#state.vfx + 1] = vfx
end

function M.spawnEnemyFromPlan(entry)
  local tpl = Waves.ENEMY_TYPES[entry.type]
  local scale = entry.scale or 1
  local maxHp = math.floor(tpl.hp * scale + 0.5)
  local atk = math.floor(tpl.atk * (1 + (scale - 1) * 0.55) + 0.5)
  local y = M.ARENA.minY + 26 + math.random() * (M.ARENA.maxY - M.ARENA.minY - 52)

  return {
    id = M.genId("foe"),
    typeId = tpl.id,
    name = tpl.name,
    isBoss = tpl.isBoss or false,
    targetsBackline = tpl.targetsBackline or false,
    x = M.ARENA.rightBound - math.random() * 14,
    y = y,
    hp = maxHp,
    maxHp = maxHp,
    atk = atk,
    aspd = tpl.aspd,
    speed = tpl.speed,
    range = tpl.range,
    projSpeed = tpl.projSpeed or 0,
    gold = math.floor(tpl.gold * (1 + (scale - 1) * 0.25) + 0.5),
    radius = tpl.radius,
    color = tpl.color,
    accent = tpl.accent,
    cooldown = 0.2 + math.random() * 0.3,
    hitFlash = 0,
    attackAnim = 0,
  }
end

function M.spawnSkeletonAlly(x, y, waveScale)
  waveScale = waveScale or 1
  local maxHp = math.floor(52 * (1 + (waveScale - 1) * 0.25) + 0.5)
  local atk = math.floor(12 * (1 + (waveScale - 1) * 0.25) + 0.5)
  return {
    id = M.genId("skel"),
    baseId = "skeleton",
    isSummon = true,
    name = { zh = "骷髅兵", en = "Skeleton" },
    role = "frontline",
    x = math.min(M.ARENA.rightBound - 10, x + (math.random() - 0.5) * 18),
    y = math.max(M.ARENA.minY, math.min(M.ARENA.maxY, y + (math.random() - 0.5) * 24)),
    homeX = x,
    homeY = y,
    hp = maxHp,
    maxHp = maxHp,
    atk = atk,
    aspd = 1.2,
    range = 36,
    speed = 92,
    color = Color.hex("#cbd5e1"),
    accent = Color.hex("#64dfdf"),
    attackType = "melee",
    tier = 1,
    xp = 0,
    kills = 0,
    attackCount = 0,
    cooldown = 0.2,
    hitFlash = 0,
    attackAnim = 0,
    overdriveTimer = 0,
    radius = 12,
  }
end

function M.assignFormationPositions(roster)
  local groups = { frontline = {}, vanguard = {}, midline = {}, backline = {} }
  for _, u in ipairs(roster) do
    local bucket = groups[u.role] or groups.frontline
    bucket[#bucket + 1] = u
  end

  for _, list in pairs(groups) do
    local n = #list
    for i, u in ipairs(list) do
      local frac = (n == 1) and 0.5 or ((i - 0.5) / n)
      local laneX = M.ARENA.castleX + 46 + (u.laneX or 0.35) * (M.ARENA.w - 170)
      local jitterX = (i % 2 == 1) and -12 or 12
      local homeY = M.ARENA.minY + 18 + frac * (M.ARENA.maxY - M.ARENA.minY - 36)
      u.homeX = math.max(M.ARENA.castleX + 36, math.min(M.ARENA.spawnX - 180, laneX + jitterX))
      u.homeY = homeY
      if not u.inBattlePosInitialized then
        u.x = u.homeX
        u.y = u.homeY
        u.inBattlePosInitialized = true
      end
    end
  end
end

function M.callMeteor(state, targetX, targetY, damage, radius, attacker)
  state.meteors[#state.meteors + 1] = {
    x = targetX,
    y = targetY,
    startX = targetX - 90,
    startY = targetY - 260,
    progress = 0,
    duration = 0.38,
    damage = damage,
    radius = radius or 78,
    attacker = attacker,
  }
end

local function handleEnemyDeath(state, enemy, killer)
  state.gold = state.gold + enemy.gold
  state.totalKills = state.totalKills + 1
  state.audio:playCoin()

  addFloatingText(state, enemy.x, enemy.y - 24, "+" .. tostring(enemy.gold) .. "g", Color.hex("#f6c945"), 1.05)

  local pCount = enemy.isBoss and 22 or 9
  for i = 1, pCount do
    local ang = math.random() * math.pi * 2
    local spd = 40 + math.random() * 110
    spawnVfx(state, {
      kind = "particle",
      x = enemy.x,
      y = enemy.y,
      vx = math.cos(ang) * spd,
      vy = math.sin(ang) * spd,
      color = (i % 2 == 0) and enemy.color or enemy.accent,
      size = enemy.isBoss and 5 or 3,
      life = 0.4 + math.random() * 0.25,
      maxLife = 0.65,
    })
  end

  if killer then
    killer.kills = (killer.kills or 0) + 1
    if killer.overdriveOnKill or state:hasCore("vampiric_crown") then
      killer.overdriveTimer = 3.0
      if state:hasCore("vampiric_crown") then
        killer.hp = math.min(killer.maxHp, killer.hp + math.floor(killer.maxHp * 0.15 + 0.5))
      end
      addFloatingText(state, killer.x, killer.y - 30, "OVERDRIVE!", Color.hex("#ff8866"), 0.9)
    end

    if killer.summonOnKill then
      local count = killer.summonCount or 1
      for _ = 1, count do
        if #state.summons < 14 then
          state.summons[#state.summons + 1] = M.spawnSkeletonAlly(enemy.x - 16, enemy.y, 1 + (state.wave - 1) * 0.12)
        end
      end
    end
  end
end

local function damageEnemy(state, enemy, rawDmg, attacker, isCrit, knockback)
  if not enemy or enemy.hp <= 0 then return false end
  local dmg = math.max(1, math.floor(rawDmg + 0.5))
  enemy.hp = enemy.hp - dmg
  enemy.hitFlash = 0.14

  knockback = knockback or 0
  if knockback > 0 then
    local kb = enemy.isBoss and (knockback * 0.25) or knockback
    enemy.x = math.min(M.ARENA.rightBound, enemy.x + kb)
  end

  addFloatingText(
    state,
    enemy.x + (math.random() - 0.5) * 14,
    enemy.y - enemy.radius - 6,
    isCrit and (tostring(dmg) .. "!") or tostring(dmg),
    isCrit and Color.hex("#ffdf6b") or Color.hex("#ffffff"),
    isCrit and 1.25 or 1.0
  )

  if attacker and attacker.lifesteal and attacker.lifesteal > 0 then
    attacker.hp = math.min(attacker.maxHp, attacker.hp + math.floor(dmg * attacker.lifesteal + 0.5))
  end
  if attacker and attacker.healOnHit and attacker.healOnHit > 0 then
    attacker.hp = math.min(attacker.maxHp, attacker.hp + attacker.healOnHit)
  end

  if enemy.hp <= 0 then
    handleEnemyDeath(state, enemy, attacker)
    return true
  end
  return false
end

local function damageAlly(state, ally, rawDmg, attacker)
  if not ally or ally.hp <= 0 then return end
  local dmg = math.max(1, math.floor(rawDmg + 0.5))
  ally.hp = ally.hp - dmg
  ally.hitFlash = 0.14

  if attacker and attacker.hp > 0 then
    local thornsPct = ally.thorns or 0
    if (ally.role == "frontline" or ally.role == "vanguard") and state:hasCore("phalanx_banner") then
      thornsPct = thornsPct + 0.25
    end
    if thornsPct > 0 then
      damageEnemy(state, attacker, dmg * thornsPct, ally, false, 0)
    end
  end

  if ally.hp <= 0 then
    addFloatingText(state, ally.x, ally.y - 18, "X", Color.hex("#ff6b6b"), 1.1)
    for _ = 1, 8 do
      local ang = math.random() * math.pi * 2
      spawnVfx(state, {
        kind = "particle",
        x = ally.x,
        y = ally.y,
        vx = math.cos(ang) * 70,
        vy = math.sin(ang) * 70,
        color = ally.color,
        size = 3,
        life = 0.35,
        maxLife = 0.35,
      })
    end
  end
end

local function performAllyAttack(state, unit, target)
  unit.cooldown = 1 / unit.aspd
  unit.attackAnim = 0.18
  unit.attackCount = (unit.attackCount or 0) + 1

  local overdriveMult = (unit.overdriveTimer and unit.overdriveTimer > 0) and 1.35 or 1.0
  local isCrit = math.random() < (unit.critChance or 0)
  local dmg = unit.atk * overdriveMult * (isCrit and 1.75 or 1.0)

  if (unit.meteorEvery and unit.meteorEvery > 0 and unit.attackCount % unit.meteorEvery == 0)
     or (not unit.isSummon and state:hasCore("meteor_resonance") and unit.attackCount % 5 == 0) then
    M.callMeteor(state, target.x, target.y, dmg * 1.45, 76, unit)
  end

  local dx = target.x - unit.x
  local dy = target.y - unit.y
  local d = math.sqrt(dx * dx + dy * dy)
  if d == 0 then d = 1 end
  local extraPierce = state:hasCore("wind_quiver") and 1 or 0

  if unit.attackType == "meteor" then
    state.audio:playMagic()
    M.callMeteor(state, target.x, target.y, dmg * 1.25, unit.splash or 85, unit)
    return
  end

  if unit.attackType == "arrow" or unit.attackType == "magic" or unit.attackType == "soul" then
    if unit.attackType == "arrow" then state.audio:playBow() else state.audio:playMagic() end
    local spd = unit.projSpeed or 420
    state.projectiles[#state.projectiles + 1] = {
      fromEnemy = false,
      attacker = unit,
      x = unit.x + 12,
      y = unit.y,
      vx = (dx / d) * spd,
      vy = (dy / d) * spd,
      damage = dmg,
      isCrit = isCrit,
      splash = unit.splash or 0,
      chainTargets = unit.chainTargets or 0,
      pierceLeft = (unit.pierce or 0) + extraPierce,
      hitIds = {},
      color = unit.accent,
      radius = (unit.attackType == "magic") and 6 or 4,
      life = 2.0,
    }
    return
  end

  if unit.attackType == "multishot" then
    state.audio:playBow()
    local spd = unit.projSpeed or 500
    local baseAngle = math.atan2(dy, dx)
    local count = unit.multishot or 3
    for i = 1, count do
      local offset = ((i - 1) - (count - 1) / 2) * 0.16
      local ang = baseAngle + offset
      state.projectiles[#state.projectiles + 1] = {
        fromEnemy = false,
        attacker = unit,
        x = unit.x + 12,
        y = unit.y,
        vx = math.cos(ang) * spd,
        vy = math.sin(ang) * spd,
        damage = dmg * 0.72,
        isCrit = isCrit,
        splash = 0,
        chainTargets = 0,
        pierceLeft = (unit.pierce or 0) + extraPierce,
        hitIds = {},
        color = unit.accent,
        radius = 4,
        life = 1.8,
      }
    end
    return
  end

  state.audio:playHit()
  if unit.attackType == "cleave" or unit.attackType == "lance" then
    local r = unit.cleaveRadius or 54
    local hits = 0
    local maxHits = (unit.attackType == "lance") and (1 + (unit.pierce or 1)) or 99
    for _, foe in ipairs(state.enemies) do
      if foe.hp > 0 and dist(foe, target) <= r then
        damageEnemy(state, foe, dmg, unit, isCrit, unit.knockback or 0)
        hits = hits + 1
        if hits >= maxHits then break end
      end
    end
    spawnVfx(state, {
      kind = "slash",
      x = target.x,
      y = target.y,
      color = unit.accent,
      life = 0.2,
      maxLife = 0.2,
      radius = (unit.attackType == "cleave") and 30 or 24,
    })
  else
    damageEnemy(state, target, dmg, unit, isCrit, unit.knockback or 0)
    spawnVfx(state, {
      kind = "slash",
      x = target.x,
      y = target.y,
      color = unit.accent,
      life = 0.16,
      maxLife = 0.16,
      radius = 18,
    })
  end
end

function M.updateBattle(state, dt)
  local plan = state.wavePlan
  if plan then
    state.waveElapsed = state.waveElapsed + dt
    while state.spawnCursor <= #plan.spawns and state.waveElapsed >= plan.spawns[state.spawnCursor].delay do
      local entry = plan.spawns[state.spawnCursor]
      local foe = M.spawnEnemyFromPlan(entry)
      state.enemies[#state.enemies + 1] = foe
      if foe.isBoss then
        state.bossBannerTimer = 2.6
        state.screenShake = math.max(state.screenShake, 8)
      end
      state.spawnCursor = state.spawnCursor + 1
    end
  end

  local allAllies = {}
  for _, u in ipairs(state.roster) do
    if u.hp > 0 then allAllies[#allAllies + 1] = u end
  end
  for _, u in ipairs(state.summons) do
    if u.hp > 0 then allAllies[#allAllies + 1] = u end
  end

  -- Update allied units
  for _, unit in ipairs(allAllies) do
    unit.hitFlash = math.max(0, (unit.hitFlash or 0) - dt)
    unit.attackAnim = math.max(0, (unit.attackAnim or 0) - dt)
    unit.overdriveTimer = math.max(0, (unit.overdriveTimer or 0) - dt)

    local speedBonus = (unit.overdriveTimer > 0) and 1.4 or 1.0
    local coreAspdBonus = (not unit.isSummon
      and (unit.attackType == "arrow" or unit.attackType == "multishot" or unit.attackType == "magic")
      and state:hasCore("wind_quiver")) and 1.22 or 1.0

    unit.cooldown = unit.cooldown - dt * speedBonus * coreAspdBonus

    local target = nil
    local bestD = math.huge
    for _, foe in ipairs(state.enemies) do
      if foe.hp > 0 then
        local d = dist(unit, foe)
        if d < bestD then
          bestD = d
          target = foe
        end
      end
    end

    if target then
      local effectiveRange = unit.range + (target.radius or 14) * 0.6
      if bestD > effectiveRange then
        local dx = target.x - unit.x
        local dy = target.y - unit.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len == 0 then len = 1 end
        local maxAdvanceX = (unit.role == "backline")
          and math.max(M.ARENA.castleX + 360, M.ARENA.rightBound - unit.range + 40)
          or (M.ARENA.rightBound - 6)
        local nx = unit.x + (dx / len) * unit.speed * dt
        local ny = unit.y + (dy / len) * unit.speed * dt
        unit.x = math.min(maxAdvanceX, math.max(M.ARENA.castleX + 26, nx))
        unit.y = math.max(M.ARENA.minY, math.min(M.ARENA.maxY, ny))
      elseif unit.cooldown <= 0 then
        performAllyAttack(state, unit, target)
      end
    else
      local dx = unit.homeX - unit.x
      local dy = unit.homeY - unit.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d > 4 then
        local step = math.min(d, unit.speed * dt)
        unit.x = unit.x + (dx / d) * step
        unit.y = unit.y + (dy / d) * step
      end
    end
  end

  -- Update enemies
  for _, foe in ipairs(state.enemies) do
    if foe.hp > 0 then
      foe.hitFlash = math.max(0, foe.hitFlash - dt)
      foe.attackAnim = math.max(0, foe.attackAnim - dt)
      foe.cooldown = foe.cooldown - dt

      local target = nil
      local bestScore = math.huge
      for _, ally in ipairs(allAllies) do
        if ally.hp > 0 then
          local d = dist(foe, ally)
          if foe.targetsBackline and d <= foe.range then
            if ally.x < bestScore then
              bestScore = ally.x
              target = ally
            end
          elseif not foe.targetsBackline then
            if d < bestScore then
              bestScore = d
              target = ally
            end
          end
        end
      end

      if not target and #allAllies > 0 then
        local minD = math.huge
        for _, ally in ipairs(allAllies) do
          if ally.hp > 0 then
            local d = dist(foe, ally)
            if d < minD then
              minD = d
              target = ally
            end
          end
        end
      end

      local dToTarget = target and dist(foe, target) or math.huge
      local enteredArena = foe.x <= (M.ARENA.rightBound - 18)

      if target and enteredArena and dToTarget <= foe.range then
        if foe.cooldown <= 0 then
          foe.cooldown = 1 / foe.aspd
          foe.attackAnim = 0.18
          if foe.projSpeed > 0 then
            local denom = (dToTarget == 0) and 1 or dToTarget
            state.projectiles[#state.projectiles + 1] = {
              fromEnemy = true,
              x = foe.x - 10,
              y = foe.y,
              vx = ((target.x - foe.x) / denom) * foe.projSpeed,
              vy = ((target.y - foe.y) / denom) * foe.projSpeed,
              damage = foe.atk,
              color = foe.accent,
              radius = foe.isBoss and 7 or 4,
              pierceLeft = 0,
              hitIds = {},
              life = 2.2,
            }
          else
            damageAlly(state, target, foe.atk, foe)
            spawnVfx(state, {
              kind = "slash",
              x = target.x,
              y = target.y,
              color = foe.accent,
              life = 0.16,
              maxLife = 0.16,
              radius = 18,
            })
          end
        end
      else
        local moveX = -foe.speed
        local moveY = 0
        if target and math.abs(target.x - foe.x) < 160 then
          local dx = target.x - foe.x
          local dy = target.y - foe.y
          local len = math.sqrt(dx * dx + dy * dy)
          if len == 0 then len = 1 end
          moveX = (dx / len) * foe.speed
          moveY = (dy / len) * foe.speed
        end
        foe.x = foe.x + moveX * dt
        foe.y = math.max(M.ARENA.minY, math.min(M.ARENA.maxY, foe.y + moveY * dt))
      end

      if foe.x <= M.ARENA.castleX then
        local heartLoss = foe.isBoss and 3 or 1
        state.hearts = math.max(0, state.hearts - heartLoss)
        state.screenShake = math.max(state.screenShake, 12)
        state.audio:playHurtBase()
        addFloatingText(state, M.ARENA.castleX + 18, foe.y, "-" .. tostring(heartLoss) .. " HP", Color.hex("#ff4d6d"), 1.35)
        foe.hp = 0
      end
    end
  end

  -- Update projectiles
  for _, p in ipairs(state.projectiles) do
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt

    if p.fromEnemy then
      for _, ally in ipairs(allAllies) do
        if ally.hp > 0 and not p.hitIds[ally.id] then
          if dist(p, ally) <= (ally.radius or 15) + p.radius then
            p.hitIds[ally.id] = true
            damageAlly(state, ally, p.damage, nil)
            p.life = 0
            break
          end
        end
      end
    else
      for _, foe in ipairs(state.enemies) do
        if foe.hp > 0 and not p.hitIds[foe.id] then
          if dist(p, foe) <= foe.radius + p.radius + 4 then
            p.hitIds[foe.id] = true
            if p.splash and p.splash > 0 then
              for _, near in ipairs(state.enemies) do
                if near.hp > 0 and dist(near, p) <= p.splash then
                  local mult = (near == foe) and 1 or 0.65
                  damageEnemy(state, near, p.damage * mult, p.attacker, p.isCrit, 0)
                end
              end
              spawnVfx(state, {
                kind = "ring",
                x = p.x,
                y = p.y,
                color = p.color,
                radius = p.splash,
                life = 0.22,
                maxLife = 0.22,
              })
            else
              damageEnemy(state, foe, p.damage, p.attacker, p.isCrit, 0)
            end

            if p.chainTargets and p.chainTargets > 0 then
              local chained = 0
              for _, near in ipairs(state.enemies) do
                if near ~= foe and near.hp > 0 and dist(near, foe) <= 130 then
                  damageEnemy(state, near, p.damage * 0.6, p.attacker, false, 0)
                  spawnVfx(state, {
                    kind = "beam",
                    x1 = foe.x,
                    y1 = foe.y,
                    x2 = near.x,
                    y2 = near.y,
                    color = Color.hex("#d9b8ff"),
                    life = 0.18,
                    maxLife = 0.18,
                  })
                  chained = chained + 1
                  if chained >= p.chainTargets then break end
                end
              end
            end

            if p.pierceLeft and p.pierceLeft > 0 then
              p.pierceLeft = p.pierceLeft - 1
            else
              p.life = 0
              break
            end
          end
        end
      end
    end
  end

  -- Update meteors
  for _, m in ipairs(state.meteors) do
    m.progress = m.progress + dt / m.duration
    if m.progress >= 1 then
      m.impacted = true
      state.screenShake = math.max(state.screenShake, 7)
      state.audio:playMeteor()
      for _, foe in ipairs(state.enemies) do
        if foe.hp > 0 and dist(foe, m) <= m.radius then
          damageEnemy(state, foe, m.damage, m.attacker, true, 16)
        end
      end
      spawnVfx(state, {
        kind = "ring",
        x = m.x,
        y = m.y,
        color = Color.hex("#ff7c43"),
        radius = m.radius,
        life = 0.32,
        maxLife = 0.32,
      })
      for i = 1, 12 do
        local ang = math.random() * math.pi * 2
        local spd = 60 + math.random() * 140
        spawnVfx(state, {
          kind = "particle",
          x = m.x,
          y = m.y,
          vx = math.cos(ang) * spd,
          vy = math.sin(ang) * spd,
          color = (i % 2 == 0) and Color.hex("#ffbe0b") or Color.hex("#fb5607"),
          size = 4,
          life = 0.42,
          maxLife = 0.42,
        })
      end
    end
  end

  -- Filter alive entities
  local function filterList(list, pred)
    local out = {}
    for _, item in ipairs(list) do
      if pred(item) then out[#out + 1] = item end
    end
    return out
  end

  state.enemies = filterList(state.enemies, function(e) return e.hp > 0 end)
  state.roster = filterList(state.roster, function(u) return u.hp > 0 end)
  state.summons = filterList(state.summons, function(u) return u.hp > 0 end)
  state.projectiles = filterList(state.projectiles, function(p)
    return p.life > 0 and p.x >= M.ARENA.x - 20 and p.x <= M.ARENA.spawnX + 60
  end)
  state.meteors = filterList(state.meteors, function(m) return not m.impacted end)
end

return M
