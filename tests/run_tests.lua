local SlotMod = require("src.systems.slot_machine")
local Battle = require("src.systems.battle")
local StateMod = require("src.systems.state")

local function noop() end
local mockAudio = {
  playLever = noop,
  playReelTick = noop,
  playReelStop = noop,
  playNudge = noop,
  playMatch = noop,
  playJackpot = noop,
  playHit = noop,
  playBow = noop,
  playMagic = noop,
  playMeteor = noop,
  playCoin = noop,
  playEvolve = noop,
  playHurtBase = noop,
}

local tests = {}

local function addTest(name, fn)
  tests[#tests + 1] = { name = name, fn = fn }
end

addTest("resolveLineSymbols handles pure matches, wildcard crowns, and pure jackpots", function()
  local r1 = SlotMod.resolveLineSymbols("shield", "shield", "shield")
  assert(r1 and r1.matchedSymbolId == "shield" and not r1.isPureJackpot and r1.crownCount == 0)

  local r2 = SlotMod.resolveLineSymbols("bow", "crown", "bow")
  assert(r2 and r2.matchedSymbolId == "bow" and not r2.isPureJackpot and r2.crownCount == 1)

  local r3 = SlotMod.resolveLineSymbols("crown", "crown", "crown")
  assert(r3 and r3.matchedSymbolId == "crown" and r3.isPureJackpot and r3.crownCount == 3)

  assert(SlotMod.resolveLineSymbols("shield", "bow", "shield") == nil)
end)

addTest("evaluateGrid detects rows, columns, and diagonals across 3x3 grid", function()
  local grid = {
    { "shield", "bow", "coin" },
    { "shield", "shield", "staff" },
    { "shield", "horse", "crown" },
  }
  local matches = SlotMod.evaluateGrid(grid)
  local ids = {}
  for _, m in ipairs(matches) do ids[m.lineId] = true end
  assert(ids.row1 == true)
  assert(ids.diag1 == true)
  assert(#matches == 2)
end)

addTest("SlotMachine nudge shifts reel and collectNewMatches prevents double claiming", function()
  local slot = SlotMod.SlotMachine.new()
  slot.strips = {
    { "shield", "bow", "staff", "coin" },
    { "shield", "bow", "staff", "coin" },
    { "coin", "shield", "bow", "staff" },
  }
  slot.offsets = { 1, 1, 1 }

  local before = slot:getGrid()[3]
  assert(#slot:collectNewMatches() == 0)
  -- dir = 1 nudges symbols UP: row 2 -> row 1, row 3 -> row 2
  assert(slot:nudge(3, 1) == true)
  local afterUp = slot:getGrid()[3]
  assert(afterUp[1] == before[2] and afterUp[2] == before[3])
  assert(#slot:collectNewMatches() == 3)
  assert(#slot:collectNewMatches() == 0)
  -- dir = -1 nudges symbols DOWN: row 1 -> row 2, row 2 -> row 3
  assert(slot:nudge(3, -1) == true)
  local afterDown = slot:getGrid()[3]
  assert(afterDown[1] == before[1] and afterDown[2] == before[2] and afterDown[3] == before[3])
end)

addTest("GameState unit absorption evolves to 2-star and opens classModal at 3-star", function()
  local state = StateMod.GameState.new(mockAudio)
  state:startRun()
  assert(#state.roster == 2)

  local mainUnit = state.roster[1]
  local w1 = state:summonUnit("warrior")
  assert(state:absorbUnit(w1.id, mainUnit.id))
  assert(mainUnit.tier == 2)

  local w2 = state:summonUnit("warrior")
  local w3 = state:summonUnit("warrior")
  assert(state:absorbUnit(w2.id, mainUnit.id))
  assert(mainUnit.tier == 2)
  assert(state:absorbUnit(w3.id, mainUnit.id))
  assert(mainUnit.tier == 3)
  assert(state.classModal ~= nil)
  assert(#state.classModal.choices == 2)

  local chosenId = state.classModal.choices[1].id
  assert(state:chooseClass(chosenId) == true)
  assert(state.classModal == nil)
  assert(mainUnit.classId == chosenId)
end)

addTest("GameState battle simulation clears wave 1 and opens coreModal", function()
  local state = StateMod.GameState.new(mockAudio)
  state:startRun()
  state:summonUnit("champion")
  state:startWave()
  assert(state.phase == "battle")
  assert(state.waveActive == true)

  for _ = 1, 600 do
    state:update(0.05)
    if state.phase == "spin" then break end
  end

  assert(state.phase == "spin")
  assert(state.wave == 2)
  assert(state.coreModal ~= nil)
  assert(#state.coreModal.choices == 3)
end)

addTest("allies can reach and defeat ranged enemies positioned on far-right arena edge", function()
  for _, unitId in ipairs({ "warrior", "mage" }) do
    local state = StateMod.GameState.new(mockAudio)
    state:startRun()
    state.roster = { StateMod.createUnitInstance(unitId) }
    state.roster[1].x = 700
    state.roster[1].y = 340
    state.phase = "battle"
    state.waveActive = true
    state.wavePlan = { wave = 4, spawns = {} }

    local edgeArcher = Battle.spawnEnemyFromPlan({ type = "archer_foe", delay = 0, scale = 1 })
    edgeArcher.x = Battle.ARENA.rightBound
    edgeArcher.y = 340
    state.enemies[#state.enemies + 1] = edgeArcher

    for _ = 1, 400 do
      Battle.updateBattle(state, 0.05)
      if #state.enemies == 0 then break end
    end

    assert(#state.enemies == 0, unitId .. " should reach and defeat enemy at right edge")
  end
end)

addTest("reel locking, jester wildcards, upgrade shop, and custom repositioning work", function()
  local state = StateMod.GameState.new(mockAudio)
  state:startRun()
  local startGold = state.gold

  -- Lock reel 1 for 3g, spin, verify reel 1 offset stays unchanged
  local col1Before = state.slot.offsets[1]
  assert(state:toggleReelLock(1) == true)
  assert(state.gold == startGold - StateMod.LOCK_REEL_COST)
  assert(state:spin() == true)
  state:update(0.05)
  assert(state.slot.reelSpinning[1] == false)
  assert(state.slot.offsets[1] == col1Before)
  for _ = 1, 25 do
    state:update(0.05)
  end
  assert(state.slot.locked[1] == false)

  -- Jester wildcard matches line
  local jMatch = SlotMod.resolveLineSymbols("shield", "jester", "shield")
  assert(jMatch and jMatch.matchedSymbolId == "shield" and jMatch.jesterCount == 1)

  -- Upgrade shop: army_cap expands maxRoster
  state.gold = 100
  local prevCap = state.maxRoster
  assert(state:buyUpgrade("army_cap") == true)
  assert(state.maxRoster == prevCap + 1)

  -- Drag-reposition updates homeX/homeY
  local u = state.roster[1]
  assert(state:setUnitPosition(u.id, 620, 260) == true)
  assert(u.homeX == 620 and u.homeY == 260 and u.customPositioned == true)
end)

addTest("pity meter grants free wild spin, 3-star paragon absorb empowers, and burn/chill apply", function()
  local state = StateMod.GameState.new(mockAudio)
  state:setDifficulty("judgment")
  state:startRun()
  assert(state.hearts == 8 and state.gold == 52)

  -- Pity meter at MAX_PITY makes spin free and places a wild in center cell (2,2)
  state.pityCharge = StateMod.MAX_PITY
  assert(state:currentSpinCost() == 0)
  local goldBefore = state.gold
  assert(state:spin() == true)
  assert(state.gold == goldBefore)
  for _ = 1, 25 do
    state:update(0.05)
  end
  local centerSym = state.slot:getGrid()[2][2]
  assert(centerSym == "crown" or centerSym == "jester", "Center symbol should be a wild after pity spin")

  -- 3-star paragon over-absorb empowers ATK and MaxHP
  local mainUnit = state.roster[1]
  mainUnit.tier = 3
  local atkBefore = mainUnit.atk
  local hpBefore = mainUnit.maxHp
  local fodder = StateMod.createUnitInstance("warrior")
  state.roster[#state.roster + 1] = fodder
  assert(state:absorbUnit(fodder.id, mainUnit.id) == true)
  assert(mainUnit.atk > atkBefore and mainUnit.maxHp > hpBefore)

  -- Burn and Chill status effects work in battle
  local foe = Battle.spawnEnemyFromPlan({ type = "orc", delay = 0, scale = 1 })
  local foeHp = foe.hp
  state.enemies = { foe }
  state.phase = "battle"
  state.waveActive = true
  state.wavePlan = { wave = 3, spawns = {} }
  Battle.applyBurn(foe, 40, 2.0, mainUnit)
  Battle.applyChill(foe, 2.0)
  assert(foe.chillTimer == 2.0)
  Battle.updateBattle(state, 0.55)
  assert(foe.hp < foeHp)
end)

local function runAll()
  local passed = 0
  local failed = 0
  for _, t in ipairs(tests) do
    local ok, err = pcall(t.fn)
    if ok then
      passed = passed + 1
      print("[PASS] " .. t.name)
    else
      failed = failed + 1
      print("[FAIL] " .. t.name .. ": " .. tostring(err))
    end
  end
  print(string.format("Summary: %d passed, %d failed", passed, failed))
  return failed == 0
end

if not love then
  local ok = runAll()
  os.exit(ok and 0 or 1)
end

return runAll
