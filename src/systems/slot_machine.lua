local Symbols = require("src.data.symbols")

local M = {}

function M.resolveLineSymbols(a, b, c)
  local arr = { a, b, c }
  local crowns = 0
  local jesters = 0
  local nonWilds = {}

  for _, s in ipairs(arr) do
    if s == "crown" then
      crowns = crowns + 1
    elseif s == "jester" then
      jesters = jesters + 1
    else
      nonWilds[#nonWilds + 1] = s
    end
  end

  if #nonWilds == 0 then
    if crowns == 3 then
      return { matchedSymbolId = "crown", isPureJackpot = true, crownCount = 3, jesterCount = 0 }
    elseif jesters == 3 then
      return { matchedSymbolId = "jester", isPureJackpot = false, crownCount = 0, jesterCount = 3 }
    else
      return { matchedSymbolId = "crown", isPureJackpot = true, crownCount = crowns, jesterCount = jesters }
    end
  end

  local first = nonWilds[1]
  for i = 2, #nonWilds do
    if nonWilds[i] ~= first then
      return nil
    end
  end

  return {
    matchedSymbolId = first,
    isPureJackpot = false,
    crownCount = crowns,
    jesterCount = jesters,
  }
end

function M.evaluateGrid(grid)
  local matches = {}
  for _, line in ipairs(Symbols.PAYLINES) do
    local c1, r1 = line.cells[1][1], line.cells[1][2]
    local c2, r2 = line.cells[2][1], line.cells[2][2]
    local c3, r3 = line.cells[3][1], line.cells[3][2]
    local resolved = M.resolveLineSymbols(grid[c1][r1], grid[c2][r2], grid[c3][r3])
    if resolved then
      matches[#matches + 1] = {
        lineId = line.id,
        lineName = line.name,
        isDiagonal = line.isDiagonal,
        cells = line.cells,
        symbolId = resolved.matchedSymbolId,
        isPureJackpot = resolved.isPureJackpot,
        crownCount = resolved.crownCount,
        jesterCount = resolved.jesterCount,
        symbol = Symbols.SYMBOLS[resolved.matchedSymbolId],
      }
    end
  end
  return matches
end

local SlotMachine = {}
SlotMachine.__index = SlotMachine

function SlotMachine.new(weights)
  weights = weights or {}
  local self = setmetatable({
    strips = {
      Symbols.buildReelStrip(weights),
      Symbols.buildReelStrip(weights),
      Symbols.buildReelStrip(weights),
    },
    offsets = { 1, 1, 1 },
    locked = { false, false, false },
    spinning = false,
    forceCenterWild = false,
    leverPull = 0,
    reelSpinning = { false, false, false },
    reelTimers = { 0, 0, 0 },
    reelVisualShift = { 0, 0, 0 },
    reelBounce = { 0, 0, 0 },
    tickAccum = { 0, 0, 0 },
    claimedLines = {},
    activeMatches = {},
  }, SlotMachine)
  return self
end

function SlotMachine:rebuild(weights)
  weights = weights or {}
  self.strips = {
    Symbols.buildReelStrip(weights),
    Symbols.buildReelStrip(weights),
    Symbols.buildReelStrip(weights),
  }
  for col = 1, 3 do
    local len = #self.strips[col]
    self.offsets[col] = ((self.offsets[col] - 1) % len) + 1
  end
end

function SlotMachine:getSymbolAt(col, relOffset)
  local strip = self.strips[col]
  local len = #strip
  local idx = ((self.offsets[col] + relOffset - 1) % len) + 1
  return strip[idx]
end

function SlotMachine:getGrid()
  local grid = { {}, {}, {} }
  for col = 1, 3 do
    for row = 1, 3 do
      grid[col][row] = self:getSymbolAt(col, row - 1)
    end
  end
  return grid
end

local function findWildOffset(strip)
  local len = #strip
  local candidates = {}
  for i = 1, len do
    local sym = strip[i]
    if sym == "crown" or sym == "jester" then
      -- To appear in row 2 (center), base offset is i - 1 wrapped
      local base = ((i - 2) % len) + 1
      candidates[#candidates + 1] = base
    end
  end
  if #candidates > 0 then
    return candidates[math.random(1, #candidates)]
  end
  return nil
end

function SlotMachine:startSpin(opts)
  opts = opts or {}
  self.spinning = true
  self.forceCenterWild = opts.forceCenterWild or false
  self.leverPull = 1.0
  self.claimedLines = {}
  self.activeMatches = {}
  self.reelVisualShift = { 0, 0, 0 }
  self.reelBounce = { 0, 0, 0 }
  self.tickAccum = { 0, 0, 0 }

  local baseDurs = { 0.36, 0.56, 0.78 }
  local anySpinning = false
  for col = 1, 3 do
    if self.locked[col] then
      self.reelSpinning[col] = false
      self.reelTimers[col] = 0
    else
      anySpinning = true
      self.reelSpinning[col] = true
      self.reelTimers[col] = baseDurs[col]
      self.offsets[col] = math.random(1, #self.strips[col])
    end
  end

  if not anySpinning then
    self.reelSpinning[3] = true
    self.reelTimers[3] = 0.36
  end
end

function SlotMachine:update(dt)
  self.leverPull = math.max(0, self.leverPull - dt * 3.4)
  for col = 1, 3 do
    self.reelBounce[col] = math.max(0, self.reelBounce[col] - dt * 5)
  end

  if not self.spinning then
    return { finished = false, stoppedCols = {}, ticked = false }
  end

  local stoppedCols = {}
  local ticked = false

  for col = 1, 3 do
    if self.reelSpinning[col] then
      self.reelTimers[col] = self.reelTimers[col] - dt
      self.tickAccum[col] = self.tickAccum[col] + dt
      self.reelVisualShift[col] = (self.reelVisualShift[col] + dt * 18) % 1

      if self.tickAccum[col] >= 0.055 then
        self.tickAccum[col] = 0
        local len = #self.strips[col]
        self.offsets[col] = (self.offsets[col] % len) + 1
        ticked = true
      end

      if self.reelTimers[col] <= 0 then
        self.reelSpinning[col] = false
        self.reelVisualShift[col] = 0
        self.reelBounce[col] = 1.0
        if col == 2 and self.forceCenterWild then
          local wildOff = findWildOffset(self.strips[2])
          self.offsets[2] = wildOff or math.random(1, #self.strips[2])
        else
          self.offsets[col] = math.random(1, #self.strips[col])
        end
        stoppedCols[#stoppedCols + 1] = col
      end
    end
  end

  if not self.reelSpinning[1] and not self.reelSpinning[2] and not self.reelSpinning[3] then
    self.spinning = false
    self.forceCenterWild = false
    self.locked = { false, false, false }
    return { finished = true, stoppedCols = stoppedCols, ticked = ticked }
  end

  return { finished = false, stoppedCols = stoppedCols, ticked = ticked }
end

function SlotMachine:nudge(col, dir)
  if self.spinning or col < 1 or col > 3 then
    return false
  end
  local len = #self.strips[col]
  self.offsets[col] = ((self.offsets[col] - 1 + dir) % len) + 1
  self.reelBounce[col] = 0.55
  return true
end

function SlotMachine:collectNewMatches()
  local allMatches = M.evaluateGrid(self:getGrid())
  self.activeMatches = allMatches
  local newlyMatched = {}
  for _, m in ipairs(allMatches) do
    if not self.claimedLines[m.lineId] then
      self.claimedLines[m.lineId] = true
      newlyMatched[#newlyMatched + 1] = m
    end
  end
  return newlyMatched
end

M.SlotMachine = SlotMachine
return M
