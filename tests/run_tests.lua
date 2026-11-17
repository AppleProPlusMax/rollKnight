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

  assert(#slot:collectNewMatches() == 0)
  assert(slot:nudge(3, 1) == true)
  assert(#slot:collectNewMatches() == 3)
  assert(#slot:collectNewMatches() == 0)
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
