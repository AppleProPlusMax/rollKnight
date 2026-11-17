local Symbols = require("src.data.symbols")

local M = {}

function M.resolveLineSymbols(a, b, c)
  local arr = { a, b, c }
  local crowns = 0
  local nonCrowns = {}
  for _, s in ipairs(arr) do
    if s == "crown" then
      crowns = crowns + 1
    else
      nonCrowns[#nonCrowns + 1] = s
    end
  end

  if #nonCrowns == 0 then
    return { matchedSymbolId = "crown", isPureJackpot = true, crownCount = 3 }
  end

  local first = nonCrowns[1]
  for i = 2, #nonCrowns do
    if nonCrowns[i] ~= first then
      return nil
    end
  end

  return { matchedSymbolId = first, isPureJackpot = false, crownCount = crowns }
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
    spinning = false,
    reelSpinning = { false, false, false },
    reelTimers = { 0, 0, 0 },
    reelVisualShift = { 0, 0, 0 },
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

function SlotMachine:getGrid()
  local grid = { {}, {}, {} }
  for col = 1, 3 do
    local strip = self.strips[col]
    local len = #strip
    local base = self.offsets[col]
    for row = 1, 3 do
      local idx = ((base + row - 2) % len) + 1
      grid[col][row] = strip[idx]
    end
  end
  return grid
end

function SlotMachine:startSpin()
  self.spinning = true
  self.reelSpinning = { true, true, true }
  self.reelTimers = { 0.36, 0.56, 0.78 }
  self.reelVisualShift = { 0, 0, 0 }
  self.tickAccum = { 0, 0, 0 }
  self.claimedLines = {}
  self.activeMatches = {}

  for col = 1, 3 do
    self.offsets[col] = math.random(1, #self.strips[col])
  end
end

function SlotMachine:update(dt)
  if not self.spinning then
    return { finished = false, stoppedCols = {}, ticked = false }
  end

  local stoppedCols = {}
  local ticked = false

  for col = 1, 3 do
    if self.reelSpinning[col] then
      self.reelTimers[col] = self.reelTimers[col] - dt
      self.tickAccum[col] = self.tickAccum[col] + dt
      self.reelVisualShift[col] = (self.reelVisualShift[col] + dt * 16) % 1

      if self.tickAccum[col] >= 0.06 then
        self.tickAccum[col] = 0
        local len = #self.strips[col]
        self.offsets[col] = (self.offsets[col] % len) + 1
        ticked = true
      end

      if self.reelTimers[col] <= 0 then
        self.reelSpinning[col] = false
        self.reelVisualShift[col] = 0
        self.offsets[col] = math.random(1, #self.strips[col])
        stoppedCols[#stoppedCols + 1] = col
      end
    end
  end

  if not self.reelSpinning[1] and not self.reelSpinning[2] and not self.reelSpinning[3] then
    self.spinning = false
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
