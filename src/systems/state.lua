local Units = require("src.data.units")
local CORES = require("src.data.cores")
local Upgrades = require("src.data.upgrades")
local Waves = require("src.data.waves")
local SlotMod = require("src.systems.slot_machine")
local Battle = require("src.systems.battle")
local Color = require("src.utils.color")

local M = {}
M.MAX_PITY = 4

M.DIFFICULTIES = {
  normal   = { id = "normal",   enemyScale = 1.0,  startGold = 42, hearts = 10 },
  hard     = { id = "hard",     enemyScale = 1.25, startGold = 46, hearts = 9 },
  judgment = { id = "judgment", enemyScale = 1.55, startGold = 52, hearts = 8 },
}

function M.createUnitInstance(baseId, tierOverride, rarityOverride, prismBonus)
  local tpl = Units.BASE_UNITS[baseId]
  local tier = tierOverride or tpl.startingTier or 1
  local tierMult = (tier == 2) and 1.55 or 1.0
  local rarity = rarityOverride or Units.rollRarity(prismBonus)
  local mult = tierMult * rarity.statMult

  local unit = {
    id = Battle.genId("unit"),
    baseId = tpl.id,
    family = tpl.family,
    classId = nil,
    rarity = rarity,
    bonusTrait = nil,
    name = tpl.name,
    role = tpl.role,
    laneX = tpl.laneX,
    tier = tier,
    xp = 0,
    hp = math.floor(tpl.hp * mult + 0.5),
    maxHp = math.floor(tpl.hp * mult + 0.5),
    shield = 0,
    atk = math.floor(tpl.atk * mult + 0.5),
    aspd = math.floor(tpl.aspd * (1 + (rarity.statMult - 1) * 0.3) * 100 + 0.5) / 100,
    range = tpl.range,
    speed = tpl.speed,
    color = tpl.color,
    accent = tpl.accent,
    attackType = tpl.attackType,
    projSpeed = tpl.projSpeed or 0,
    pierce = tpl.pierce or 0,
    splash = tpl.splash or 0,
    knockback = tpl.knockback or 0,
    cleaveRadius = tpl.cleaveRadius or 0,
    critChance = tpl.critChance or 0,
    summonOnKill = tpl.summonOnKill or false,
    summonCount = tpl.summonCount or 1,
    goldOnKill = tpl.goldOnKill or 0,
    thorns = 0,
    healOnHit = 0,
    lifesteal = 0,
    overdriveOnKill = false,
    multishot = 0,
    chainTargets = 0,
    meteorEvery = 0,
    sellGold = tpl.sellGold + rarity.xpBonus * 3,
    xpValue = tpl.xpValue + rarity.xpBonus,
    traits = tpl.traits,
    branches = tpl.branches,
    kills = 0,
    attackCount = 0,
    cooldown = 0.1,
    hitFlash = 0,
    attackAnim = 0,
    overdriveTimer = 0,
    radius = (tier >= 2) and 17 or 15,
    x = 500,
    y = 340,
    homeX = 500,
    homeY = 340,
    customPositioned = false,
    inBattlePosInitialized = false,
  }

  if rarity.id ~= "normal" then
    local tr = Units.BONUS_TRAITS[math.random(1, #Units.BONUS_TRAITS)]
    unit.bonusTrait = tr.name
    tr.apply(unit)
  end

  return unit
end

local GameState = {}
GameState.__index = GameState

function GameState.new(audio)
  return setmetatable({
    audio = audio,
    phase = "menu",
    difficulty = "normal",
    wave = 1,
    waveActive = false,
    fastForward = false,
    paused = false,

    gold = 42,
    hearts = 10,
    maxHearts = 10,
    nudges = 2,
    nudgesPerWave = 2,
    maxRoster = 8,
    prismBonus = 0,
    pityCharge = 0,
    spinMatchedThisTurn = false,

    baseSpinCost = 5,
    spinCostStep = 3,
    spinsThisWave = 0,
    freeFirstSpin = false,

    symbolWeights = {},
    slot = SlotMod.SlotMachine.new({}),

    roster = {},
    summons = {},
    enemies = {},
    projectiles = {},
    meteors = {},
    vfx = {},
    floatingTexts = {},

    cores = {},
    upgradeLevels = {},
    synergies = { counts = {} },
    coreModal = nil,
    classModal = nil,
    shopModal = false,
    guideModal = false,

    selectedUnitId = nil,
    feedMode = false,
    feedSacrificeId = nil,

    wavePlan = nil,
    waveElapsed = 0,
    spawnCursor = 1,
    totalKills = 0,

    screenShake = 0,
    jackpotFlash = 0,
    bossBannerTimer = 0,
    waveClearTimer = 0,
    waveClearGold = 0,
  }, GameState)
end

function GameState:hasCore(coreId)
  for _, c in ipairs(self.cores) do
    if c.id == coreId then return true end
  end
  return false
end

function GameState:refreshSynergies()
  self.synergies = Battle.computeSynergies(self.roster)
end

function GameState:rebuildReels()
  self.slot:rebuild(self.symbolWeights)
end

function GameState:isPitySpinReady()
  return self.pityCharge >= M.MAX_PITY
end

function GameState:currentSpinCost()
  if self:isPitySpinReady() then
    return 0
  end
  if self.freeFirstSpin and self.spinsThisWave == 0 then
    return 0
  end
  return self.baseSpinCost + self.spinsThisWave * self.spinCostStep
end

function GameState:setDifficulty(diffId)
  if M.DIFFICULTIES[diffId] then
    self.difficulty = diffId
  end
end

function GameState:startRun()
  local diff = M.DIFFICULTIES[self.difficulty] or M.DIFFICULTIES.normal
  self.phase = "spin"
  self.wave = 1
  self.waveActive = false
  self.paused = false
  self.gold = diff.startGold
  self.hearts = diff.hearts
  self.maxHearts = diff.hearts
  self.nudgesPerWave = 2
  self.nudges = 2
  self.maxRoster = 8
  self.prismBonus = 0
  self.pityCharge = 0
  self.spinMatchedThisTurn = false
  self.baseSpinCost = 5
  self.spinCostStep = 3
  self.spinsThisWave = 0
  self.freeFirstSpin = false
  self.symbolWeights = {}
  self.slot = SlotMod.SlotMachine.new(self.symbolWeights)

  self.roster = {
    M.createUnitInstance("warrior", 1, Units.RARITIES.normal, 0),
    M.createUnitInstance("ranger", 1, Units.RARITIES.normal, 0),
  }
  Battle.assignFormationPositions(self.roster)
  self:refreshSynergies()

  self.summons = {}
  self.enemies = {}
  self.projectiles = {}
  self.meteors = {}
  self.vfx = {}
  self.floatingTexts = {}
  self.cores = {}
  self.upgradeLevels = {}
  self.coreModal = nil
  self.classModal = nil
  self.shopModal = false
  self.guideModal = false
  self.selectedUnitId = self.roster[1].id
  self.feedMode = false
  self.feedSacrificeId = nil
  self.totalKills = 0
  self.wavePlan = Waves.buildWavePlan(1, diff.enemyScale)
  self.waveElapsed = 0
  self.spawnCursor = 1
  self.jackpotFlash = 0
  self.bossBannerTimer = 0
  self.waveClearTimer = 0
end

function GameState:canSpin()
  return (self.phase == "spin" or self.phase == "battle")
    and not self.coreModal
    and not self.classModal
    and not self.shopModal
    and not self.guideModal
    and not self.slot.spinning
    and self.gold >= self:currentSpinCost()
end

function GameState:spin()
  if not self:canSpin() then return false end
  local isPity = self:isPitySpinReady()
  local cost = self:currentSpinCost()
  self.gold = self.gold - cost
  if not isPity then
    self.spinsThisWave = self.spinsThisWave + 1
  else
    self.pityCharge = 0
  end
  self.spinMatchedThisTurn = false
  self.slot:startSpin({ forceCenterWild = isPity })
  self.audio:playLever()
  return true
end

function GameState:nudgeReel(col, dir)
  if (self.phase ~= "spin" and self.phase ~= "battle")
     or self.coreModal or self.classModal or self.shopModal or self.guideModal or self.slot.spinning or self.nudges <= 0 then
    return false
  end
  if self.slot:nudge(col, dir) then
    self.nudges = self.nudges - 1
    self.audio:playNudge()
    self:applySlotMatches(true)
    return true
  end
  return false
end

function GameState:applySlotMatches(fromNudge)
  local matches = self.slot:collectNewMatches()
  if #matches == 0 then
    if not fromNudge and not self.spinMatchedThisTurn then
      self.pityCharge = math.min(M.MAX_PITY, self.pityCharge + 1)
    end
    return {}
  end

  self.spinMatchedThisTurn = true
  local triggeredJackpot = false
  local jesterActive = self:hasCore("jester_trick")

  for _, m in ipairs(matches) do
    local mult = (jesterActive and m.isDiagonal) and 2 or 1
    if m.isPureJackpot then
      triggeredJackpot = true
      local goldGain = (m.symbol.payoutGold or 18) * mult
      self.gold = self.gold + goldGain
      for _ = 1, mult do
        self:summonUnit("champion")
      end
      self.floatingTexts[#self.floatingTexts + 1] = {
        x = 205, y = 255, vy = -28,
        text = "JACKPOT +" .. tostring(goldGain) .. "g!",
        color = Color.hex("#ffdf6b"), life = 1.3, maxLife = 1.3, scale = 1.35,
      }
    elseif m.symbol.unitId then
      for _ = 1, mult do
        self:summonUnit(m.symbol.unitId)
      end
      local wildBonus = (m.crownCount or 0) * 6 + (m.jesterCount or 0) * 4
      if wildBonus > 0 then
        self.gold = self.gold + wildBonus
      end
    elseif m.symbol.payoutGold > 0 then
      local gain = m.symbol.payoutGold * mult
      self.gold = self.gold + gain
      self.audio:playCoin()
      self.floatingTexts[#self.floatingTexts + 1] = {
        x = 205, y = 280, vy = -30,
        text = "+" .. tostring(gain) .. "g",
        color = Color.hex("#f6c945"), life = 1.0, maxLife = 1.0, scale = 1.25,
      }
    end
  end

  if triggeredJackpot then
    self.jackpotFlash = 1.0
    self.screenShake = math.max(self.screenShake, 10)
    self.audio:playJackpot()
  else
    self.audio:playMatch(#matches)
  end

  return matches
end

function GameState:summonUnit(baseId)
  if #self.roster < self.maxRoster then
    local unit = M.createUnitInstance(baseId, nil, nil, self.prismBonus)
    self.roster[#self.roster + 1] = unit
    Battle.assignFormationPositions(self.roster)
    self:refreshSynergies()
    self.selectedUnitId = unit.id

    local label = "+" .. unit.name.zh
    if unit.rarity.id == "prism" then
      label = "PRISM " .. label
      self.jackpotFlash = math.max(self.jackpotFlash, 0.45)
    elseif unit.rarity.id == "epic" then
      label = "EPIC " .. label
    end
    self.floatingTexts[#self.floatingTexts + 1] = {
      x = unit.x, y = unit.y - 26, vy = -28,
      text = label,
      color = unit.rarity.color, life = 1.0, maxLife = 1.0, scale = 1.1,
    }
    return unit
  end

  local target = nil
  for _, u in ipairs(self.roster) do
    if u.baseId == baseId and u.tier < 3 then target = u; break end
  end
  if not target then
    for _, u in ipairs(self.roster) do
      if u.tier < 3 then target = u; break end
    end
  end

  if target then
    self:grantUnitXp(target, 1)
    return target
  end

  local refund = Units.BASE_UNITS[baseId].sellGold or 6
  self.gold = self.gold + refund
  self.floatingTexts[#self.floatingTexts + 1] = {
    x = 210, y = 320, vy = -26,
    text = "+" .. tostring(refund) .. "g",
    color = Color.hex("#f6c945"), life = 0.9, maxLife = 0.9, scale = 1.05,
  }
  return nil
end

function GameState:setUnitPosition(unitId, x, y)
  for _, u in ipairs(self.roster) do
    if u.id == unitId then
      local clampedX = math.max(Battle.ARENA.castleX + 34, math.min(Battle.ARENA.rightBound - 80, x))
      local clampedY = math.max(Battle.ARENA.minY + 10, math.min(Battle.ARENA.maxY - 10, y))
      u.homeX = clampedX
      u.homeY = clampedY
      u.x = clampedX
      u.y = clampedY
      u.customPositioned = true
      return true
    end
  end
  return false
end

function GameState:grantUnitXp(target, amount)
  if not target or target.tier >= 3 then return end
  target.xp = target.xp + amount
  local needed = Units.xpNeededForTier(target.tier)
  if target.xp >= needed then
    target.xp = target.xp - needed
    target.tier = target.tier + 1
    target.radius = (target.tier >= 2) and 17 or 15
    self.audio:playEvolve()

    if target.tier == 2 then
      target.maxHp = math.floor(target.maxHp * 1.55 + 0.5)
      target.hp = target.maxHp
      target.atk = math.floor(target.atk * 1.48 + 0.5)
      target.aspd = math.floor(target.aspd * 1.12 * 100 + 0.5) / 100
      self.floatingTexts[#self.floatingTexts + 1] = {
        x = target.x, y = target.y - 32, vy = -32,
        text = "2-STAR!",
        color = Color.hex("#ffdf6b"), life = 1.15, maxLife = 1.15, scale = 1.25,
      }
      if target.xp >= Units.xpNeededForTier(2) then
        self:grantUnitXp(target, 0)
      end
    elseif target.tier == 3 then
      target.xp = 0
      local branchIds = target.branches or { "paladin", "berserker" }
      local choices = {}
      for _, id in ipairs(branchIds) do
        if Units.ADVANCED_CLASSES[id] then
          choices[#choices + 1] = Units.ADVANCED_CLASSES[id]
        end
      end
      self.classModal = { unitId = target.id, choices = choices }
    end
  end
end

function GameState:absorbUnit(sacrificeId, targetId)
  if not sacrificeId or not targetId or sacrificeId == targetId then return false end
  local sacIdx = nil
  local tgt = nil
  for i, u in ipairs(self.roster) do
    if u.id == sacrificeId then sacIdx = i end
    if u.id == targetId then tgt = u end
  end
  if not sacIdx or not tgt then return false end

  local sac = self.roster[sacIdx]
  local sameTypeBonus = (sac.baseId == tgt.baseId) and 1 or 0
  local bloodPact = self:hasCore("blood_pact")
  local xpGain = (sac.xpValue or 1) + (sac.tier - 1) * 2 + sameTypeBonus + (bloodPact and 1 or 0)

  if bloodPact then
    tgt.atk = math.floor(tgt.atk * 1.18 + 0.5)
  end
  if sac.rarity and sac.rarity.id == "prism" and tgt.rarity and tgt.rarity.id ~= "prism" then
    tgt.rarity = sac.rarity
    tgt.maxHp = math.floor(tgt.maxHp * 1.25 + 0.5)
    tgt.hp = tgt.maxHp
    tgt.atk = math.floor(tgt.atk * 1.2 + 0.5)
  end

  table.remove(self.roster, sacIdx)
  Battle.assignFormationPositions(self.roster)
  self:refreshSynergies()
  self.selectedUnitId = tgt.id
  self.feedSacrificeId = nil
  self.feedMode = false

  if tgt.tier >= 3 then
    -- Paragon Over-Absorb: surplus units permanently empower 3-star champions!
    local atkBoost = 1 + 0.12 * xpGain
    local hpBoost = 1 + 0.14 * xpGain
    tgt.atk = math.floor(tgt.atk * atkBoost + 0.5)
    tgt.maxHp = math.floor(tgt.maxHp * hpBoost + 0.5)
    tgt.hp = tgt.maxHp
    self.audio:playEvolve()
    self.floatingTexts[#self.floatingTexts + 1] = {
      x = tgt.x, y = tgt.y - 24, vy = -30,
      text = "PARAGON +" .. math.floor((atkBoost - 1) * 100) .. "%!",
      color = Color.hex("#ffdf6b"), life = 1.0, maxLife = 1.0, scale = 1.15,
    }
    return true
  end

  self:grantUnitXp(tgt, xpGain)
  self.floatingTexts[#self.floatingTexts + 1] = {
    x = tgt.x, y = tgt.y - 20, vy = -30,
    text = "+" .. tostring(xpGain) .. " EXP",
    color = Color.hex("#80ffdb"), life = 0.9, maxLife = 0.9, scale = 1.15,
  }
  return true
end

function GameState:dismissUnit(unitId)
  if #self.roster <= 1 then return false end
  for i, u in ipairs(self.roster) do
    if u.id == unitId then
      local gain = math.floor((u.sellGold or 6) * u.tier + 0.5)
      self.gold = self.gold + gain
      table.remove(self.roster, i)
      Battle.assignFormationPositions(self.roster)
      self:refreshSynergies()
      self.selectedUnitId = self.roster[1] and self.roster[1].id or nil
      self.audio:playCoin()
      return true
    end
  end
  return false
end

function GameState:chooseClass(classId)
  if not self.classModal then return false end
  local unit = nil
  for _, u in ipairs(self.roster) do
    if u.id == self.classModal.unitId then unit = u; break end
  end
  local cls = Units.ADVANCED_CLASSES[classId]
  if not unit or not cls then
    self.classModal = nil
    return false
  end

  unit.classId = cls.id
  unit.name = cls.name
  unit.color = cls.color
  unit.accent = cls.accent
  unit.maxHp = math.floor(unit.maxHp * cls.hpMult + 0.5)
  unit.hp = unit.maxHp
  unit.atk = math.floor(unit.atk * cls.atkMult + 0.5)
  unit.aspd = math.floor(unit.aspd * cls.aspdMult * 100 + 0.5) / 100
  if cls.role then unit.role = cls.role end
  if cls.laneX then unit.laneX = cls.laneX end
  if cls.range then unit.range = cls.range end
  if cls.rangeBonus then unit.range = unit.range + cls.rangeBonus end
  if cls.attackType then unit.attackType = cls.attackType end
  if cls.projSpeed then unit.projSpeed = cls.projSpeed end
  if cls.pierce then unit.pierce = (unit.pierce or 0) + cls.pierce end
  if cls.splash then unit.splash = cls.splash end
  if cls.knockback then unit.knockback = cls.knockback end
  if cls.cleaveRadius then unit.cleaveRadius = cls.cleaveRadius end
  if cls.critChance then unit.critChance = math.max(unit.critChance or 0, cls.critChance) end
  if cls.thorns then unit.thorns = cls.thorns end
  if cls.healOnHit then unit.healOnHit = cls.healOnHit end
  if cls.lifesteal then unit.lifesteal = cls.lifesteal end
  if cls.overdriveOnKill then unit.overdriveOnKill = true end
  if cls.summonOnKill then unit.summonOnKill = true end
  if cls.summonCount then unit.summonCount = cls.summonCount end
  if cls.goldOnKill then unit.goldOnKill = (unit.goldOnKill or 0) + cls.goldOnKill end
  if cls.multishot then unit.multishot = cls.multishot end
  if cls.chainTargets then unit.chainTargets = cls.chainTargets end
  if cls.meteorEvery then unit.meteorEvery = cls.meteorEvery end
  unit.traits = cls.desc
  unit.radius = 19

  Battle.assignFormationPositions(self.roster)
  self:refreshSynergies()
  self.classModal = nil
  self.audio:playJackpot()
  return true
end

function GameState:buyUpgrade(upgId)
  local upg = nil
  for _, u in ipairs(Upgrades.SHOP_UPGRADES) do
    if u.id == upgId then upg = u; break end
  end
  if not upg then return false end
  local lvl = self.upgradeLevels[upgId] or 0
  if lvl >= upg.maxLevel then return false end
  local cost = Upgrades.getCost(upg, lvl)
  if self.gold < cost then return false end

  self.gold = self.gold - cost
  self.upgradeLevels[upgId] = lvl + 1
  upg.apply(self)
  self.audio:playEvolve()
  return true
end

function GameState:openCoreDraft()
  local owned = {}
  for _, c in ipairs(self.cores) do owned[c.id] = true end
  local pool = {}
  for _, c in ipairs(CORES) do
    if not owned[c.id] then pool[#pool + 1] = c end
  end
  if #pool == 0 then return end

  for i = #pool, 2, -1 do
    local j = math.random(1, i)
    pool[i], pool[j] = pool[j], pool[i]
  end

  local choices = {}
  for i = 1, math.min(3, #pool) do
    choices[i] = pool[i]
  end
  self.coreModal = { choices = choices }
end

function GameState:chooseCore(coreId)
  if not self.coreModal then return false end
  local chosen = nil
  for _, c in ipairs(self.coreModal.choices) do
    if c.id == coreId then chosen = c; break end
  end
  if not chosen then return false end
  self.cores[#self.cores + 1] = chosen
  if chosen.onAcquire then chosen.onAcquire(self) end
  self.coreModal = nil
  self.audio:playEvolve()
  return true
end

function GameState:startWave()
  if self.phase ~= "spin" or self.coreModal or self.classModal or self.shopModal or self.guideModal then return false end
  local diff = M.DIFFICULTIES[self.difficulty] or M.DIFFICULTIES.normal
  self.phase = "battle"
  self.waveActive = true
  self.feedMode = false
  self.feedSacrificeId = nil
  self.wavePlan = self.wavePlan or Waves.buildWavePlan(self.wave, diff.enemyScale)
  self.waveElapsed = 0
  self.spawnCursor = 1
  self.summons = {}
  self.projectiles = {}
  self.meteors = {}
  Battle.assignFormationPositions(self.roster)
  self:refreshSynergies()

  -- Grant battle shields to Paladin / Phalanx Banner frontliners
  local hasPhalanx = self:hasCore("phalanx_banner")
  for _, u in ipairs(self.roster) do
    local shieldAmt = 0
    if u.classId == "paladin" then shieldAmt = shieldAmt + math.floor(u.maxHp * 0.25) end
    if hasPhalanx and (u.role == "frontline" or u.role == "vanguard") then
      shieldAmt = shieldAmt + math.floor(u.maxHp * 0.2)
    end
    u.shield = shieldAmt
  end
  return true
end

local CORE_MILESTONES = { [1] = true, [3] = true, [5] = true, [7] = true, [10] = true, [13] = true, [16] = true, [19] = true }

function GameState:completeWave()
  self.waveActive = false
  self.summons = {}
  self.projectiles = {}
  self.meteors = {}

  for _, u in ipairs(self.roster) do
    u.hp = u.maxHp
    u.shield = 0
    u.overdriveTimer = 0
    u.x = u.homeX
    u.y = u.homeY
  end

  if self.wave >= Waves.MAX_WAVES then
    self.phase = "victory"
    self.audio:playJackpot()
    return
  end

  local waveBonus = 14 + self.wave * 2 + (self:hasCore("castle_mason") and 12 or 0)
  self.gold = self.gold + waveBonus
  self.waveClearGold = waveBonus
  self.waveClearTimer = 2.2

  local diff = M.DIFFICULTIES[self.difficulty] or M.DIFFICULTIES.normal
  local clearedWave = self.wave
  self.wave = self.wave + 1
  self.spinsThisWave = 0
  self.nudges = self.nudgesPerWave
  self.wavePlan = Waves.buildWavePlan(self.wave, diff.enemyScale)
  self.phase = "spin"
  self:refreshSynergies()

  if CORE_MILESTONES[clearedWave] then
    self:openCoreDraft()
  end
end

function GameState:update(rawDt)
  local dt = math.min(0.05, rawDt)
  self.screenShake = math.max(0, self.screenShake - dt * 28)
  self.jackpotFlash = math.max(0, self.jackpotFlash - dt * 1.6)
  self.bossBannerTimer = math.max(0, self.bossBannerTimer - dt)
  self.waveClearTimer = math.max(0, self.waveClearTimer - dt)

  local keptTexts = {}
  for _, ft in ipairs(self.floatingTexts) do
    ft.y = ft.y + ft.vy * dt
    ft.life = ft.life - dt
    if ft.life > 0 then keptTexts[#keptTexts + 1] = ft end
  end
  self.floatingTexts = keptTexts

  local keptVfx = {}
  for _, v in ipairs(self.vfx) do
    v.life = v.life - dt
    if v.kind == "particle" then
      v.x = v.x + v.vx * dt
      v.y = v.y + v.vy * dt
      v.vx = v.vx * 0.94
      v.vy = v.vy * 0.94
    elseif v.kind == "coin_fly" then
      v.x = v.x + v.vx * dt
      v.y = v.y + v.vy * dt
      v.vy = v.vy + 220 * dt
    end
    if v.life > 0 then keptVfx[#keptVfx + 1] = v end
  end
  self.vfx = keptVfx

  if self.paused or self.coreModal or self.classModal or self.shopModal or self.guideModal then
    return
  end

  if self.slot.spinning or self.slot.leverPull > 0 or self.slot.reelBounce[1] > 0 or self.slot.reelBounce[2] > 0 or self.slot.reelBounce[3] > 0 then
    local res = self.slot:update(dt)
    if res.ticked then self.audio:playReelTick() end
    for _, col in ipairs(res.stoppedCols) do
      self.audio:playReelStop(col - 1)
    end
    if res.finished then
      self:applySlotMatches(false)
    end
  end

  if self.phase == "battle" and self.waveActive then
    local simDt = self.fastForward and (dt * 2.0) or dt
    Battle.updateBattle(self, simDt)

    if self.hearts <= 0 then
      self.phase = "gameover"
      self.waveActive = false
      return
    end

    local allSpawned = self.wavePlan and (self.spawnCursor > #self.wavePlan.spawns)
    if allSpawned and #self.enemies == 0 then
      self:completeWave()
    end
  end
end

M.GameState = GameState
return M
