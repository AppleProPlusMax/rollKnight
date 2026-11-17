local Symbols = require("src.data.symbols")
local Waves = require("src.data.waves")
local Units = require("src.data.units")
local StateMod = require("src.systems.state")
local Battle = require("src.systems.battle")
local Sprites = require("src.render.sprites")
local Color = require("src.utils.color")

local Renderer = {}
Renderer.__index = Renderer

local SLOT_PANEL = { x = 16, y = 78, w = 364, h = 626 }
local REEL_BOX = { x = 34, y = 152, w = 328, h = 222 }
local CELL_W = 100
local CELL_H = 68
local CELL_GAP = 8

local function loadFontFromPaths(paths, size)
  for _, p in ipairs(paths) do
    local f = io.open(p, "rb")
    if f then
      local data = f:read("*a")
      f:close()
      if data and #data > 0 then
        local ok, fd = pcall(love.filesystem.newFileData, data, "font_" .. tostring(size) .. ".ttf")
        if ok and fd then
          local okFont, font = pcall(love.graphics.newFont, fd, size)
          if okFont and font then
            return font
          end
        end
      end
    end
  end
  return love.graphics.newFont(size)
end

function Renderer.new()
  local self = setmetatable({
    fonts = {},
  }, Renderer)
  return self
end

function Renderer:initFonts()
  local cjkPaths = {
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/msyh.ttf",
    "C:/Windows/Fonts/simhei.ttf",
    "C:/Windows/Fonts/simsun.ttc",
    "C:/Windows/Fonts/seguisym.ttf",
    "/System/Library/Fonts/PingFang.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
  }
  self.fonts = {
    f11 = loadFontFromPaths(cjkPaths, 11),
    f12 = loadFontFromPaths(cjkPaths, 12),
    f13 = loadFontFromPaths(cjkPaths, 13),
    f14 = loadFontFromPaths(cjkPaths, 14),
    f15 = loadFontFromPaths(cjkPaths, 15),
    f16 = loadFontFromPaths(cjkPaths, 16),
    f18 = loadFontFromPaths(cjkPaths, 18),
    f22 = loadFontFromPaths(cjkPaths, 22),
    f28 = loadFontFromPaths(cjkPaths, 28),
    f36 = loadFontFromPaths(cjkPaths, 36),
    f54 = loadFontFromPaths(cjkPaths, 54),
  }
end

local function isHover(hoverPos, rect)
  return hoverPos
    and hoverPos.x >= rect.x
    and hoverPos.x <= rect.x + rect.w
    and hoverPos.y >= rect.y
    and hoverPos.y <= rect.y + rect.h
end

local function drawCenteredText(font, text, x, y, w, h, color)
  local lg = love.graphics
  lg.setFont(font)
  lg.setColor(color)
  local fh = font:getHeight()
  lg.printf(text, x, y + (h - fh) / 2, w, "center")
end

function Renderer:drawButton(rect, label, opts)
  opts = opts or {}
  local lg = love.graphics
  local bg = opts.bg or Color.hex("#2a314d")
  local border = opts.border or Color.hex("#4b5682")
  local textCol = opts.text or Color.hex("#f1f5f9")
  local font = opts.font or self.fonts.f14

  if opts.disabled then
    bg = Color.hex("#1c2030")
    border = Color.hex("#2d3348")
    textCol = Color.hex("#64748b")
  elseif opts.active then
    bg = Color.hex("#4f46e5")
    border = Color.hex("#a5b4fc")
  elseif opts.hovered then
    bg = Color.hex("#384266")
    border = Color.hex("#8da2fb")
  end

  lg.setColor(bg)
  lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 7, 7)
  lg.setLineWidth(2)
  lg.setColor(border)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h, 7, 7)
  lg.setLineWidth(1)

  if opts.subLabel then
    lg.setFont(font)
    lg.setColor(textCol)
    lg.printf(label, rect.x, rect.y + rect.h * 0.5 - font:getHeight() * 0.85, rect.w, "center")
    lg.setFont(self.fonts.f12)
    lg.setColor(opts.disabled and Color.hex("#475569") or Color.hex("#fde047"))
    lg.printf(opts.subLabel, rect.x, rect.y + rect.h * 0.5 + 3, rect.w, "center")
  else
    drawCenteredText(font, label, rect.x, rect.y, rect.w, rect.h, textCol)
  end
end

local function drawHealthBar(x, y, w, h, ratio, color)
  local lg = love.graphics
  local r = math.max(0, math.min(1, ratio))
  lg.setColor(0.04, 0.05, 0.08, 0.85)
  lg.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(color or Color.hex("#4ade80"))
  lg.rectangle("fill", x, y, w * r, h)
end

function Renderer:render(state, i18n, time, hoverPos)
  local lg = love.graphics
  local hitboxes = {}
  local function registerHit(id, rect, payload)
    hitboxes[#hitboxes + 1] = { id = id, rect = rect, payload = payload }
  end

  lg.push()
  if state.screenShake > 0.2 then
    local sx = (math.random() - 0.5) * state.screenShake
    local sy = (math.random() - 0.5) * state.screenShake
    lg.translate(sx, sy)
  end

  lg.setColor(Color.hex("#11131e"))
  lg.rectangle("fill", 0, 0, 1280, 720)

  if state.phase == "menu" then
    self:renderMenu(state, i18n, time, registerHit, hoverPos)
    lg.pop()
    return hitboxes
  end

  self:renderHud(state, i18n, registerHit, hoverPos)
  self:renderSlotPanel(state, i18n, registerHit, hoverPos)
  self:renderArena(state, i18n, time, registerHit, hoverPos)
  self:renderRosterStrip(state, i18n, registerHit, hoverPos)

  if state.jackpotFlash > 0 then
    lg.setColor(1, 0.87, 0.42, state.jackpotFlash * 0.25)
    lg.rectangle("fill", 0, 0, 1280, 720)
  end

  for _, ft in ipairs(state.floatingTexts) do
    local alpha = math.max(0, math.min(1, ft.life / ft.maxLife))
    lg.setFont(self.fonts.f14)
    lg.setColor(0.04, 0.04, 0.07, alpha)
    lg.printf(ft.text, ft.x - 101, ft.y - 1, 200, "center")
    lg.printf(ft.text, ft.x - 99, ft.y + 1, 200, "center")
    lg.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
    lg.printf(ft.text, ft.x - 100, ft.y, 200, "center")
  end

  if state.coreModal then
    self:renderCoreModal(state, i18n, registerHit, hoverPos)
  elseif state.classModal then
    self:renderClassModal(state, i18n, registerHit, hoverPos)
  elseif state.phase == "gameover" or state.phase == "victory" then
    self:renderEndOverlay(state, i18n, registerHit, hoverPos)
  end

  lg.pop()
  return hitboxes
end

function Renderer:renderMenu(state, i18n, time, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.39, 0.40, 0.95, 0.08)
  for x = 0, 1280, 40 do lg.line(x, 0, x, 720) end
  for y = 0, 720, 40 do lg.line(0, y, 1280, y) end

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 220, 74, 840, 572, 16, 16)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#f6c945"))
  lg.rectangle("line", 220, 74, 840, 572, 16, 16)
  lg.setLineWidth(1)

  local demoSymbols = { "shield", "bow", "staff", "horse", "skull", "coin", "crown" }
  for i, sym in ipairs(demoSymbols) do
    local sx = 355 + (i - 1) * 95
    local sy = 152 + math.sin(time * 3 + i) * 5
    Sprites.drawSymbolIcon(sym, sx, sy, 40)
  end

  lg.setFont(self.fonts.f54)
  lg.setColor(Color.hex("#ffdf6b"))
  lg.printf(t("title"), 220, 192, 840, "center")

  lg.setFont(self.fonts.f18)
  lg.setColor(Color.hex("#cbd5e1"))
  lg.printf(t("subtitle"), 220, 254, 840, "center")

  lg.setColor(Color.hex("#111422"))
  lg.rectangle("fill", 290, 296, 700, 178, 10, 10)
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("line", 290, 296, 700, 178, 10, 10)

  lg.setFont(self.fonts.f15)
  lg.setColor(Color.hex("#93c5fd"))
  lg.print(t("rulesTitle"), 316, 312)

  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.print(t("rule1"), 316, 344)
  lg.print(t("rule2"), 316, 374)
  lg.print(t("rule3"), 316, 404)
  lg.print(t("rule4"), 316, 434)

  local startBtn = { x = 490, y = 500, w = 300, h = 64 }
  self:drawButton(startBtn, t("startRun"), {
    bg = Color.hex("#d97706"),
    border = Color.hex("#fde047"),
    text = Color.hex("#ffffff"),
    font = self.fonts.f22,
    hovered = isHover(hoverPos, startBtn),
  })
  registerHit("start_run", startBtn)

  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#94a3b8"))
  lg.printf(t("continueHint"), 220, 584, 840, "center")

  local langBtn = { x = 960, y = 92, w = 74, h = 32 }
  self:drawButton(langBtn, t("langToggle"), { hovered = isHover(hoverPos, langBtn) })
  registerHit("toggle_lang", langBtn)
end

function Renderer:renderHud(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(Color.hex("#171a2b"))
  lg.rectangle("fill", 0, 0, 1280, 62)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#2b314d"))
  lg.line(0, 62, 1280, 62)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f22)
  lg.setColor(Color.hex("#ffdf6b"))
  lg.print("rollKnight", 20, 18)

  local pills = {
    { label = t("wave") .. ": " .. state.wave .. "/" .. Waves.MAX_WAVES, color = Color.hex("#93c5fd"), x = 165, w = 128 },
    { label = t("hearts") .. ": " .. state.hearts .. "/" .. state.maxHearts, color = Color.hex("#fb7185"), x = 305, w = 114 },
    { label = t("gold") .. ": " .. state.gold .. "g", color = Color.hex("#facc15"), x = 431, w = 116 },
    { label = t("nudges") .. ": " .. state.nudges, color = Color.hex("#4ade80"), x = 559, w = 118 },
    { label = t("roster") .. ": " .. #state.roster .. "/" .. StateMod.MAX_ROSTER, color = Color.hex("#c084fc"), x = 689, w = 128 },
  }

  for _, p in ipairs(pills) do
    lg.setColor(Color.hex("#0f1220"))
    lg.rectangle("fill", p.x, 14, p.w, 34, 7, 7)
    lg.setColor(Color.hex("#2e3654"))
    lg.rectangle("line", p.x, 14, p.w, 34, 7, 7)
    drawCenteredText(self.fonts.f14, p.label, p.x, 14, p.w, 34, p.color)
  end

  local speedBtn = { x = 868, y = 14, w = 94, h = 34 }
  self:drawButton(speedBtn, state.fastForward and t("speed2x") or t("speed1x"), {
    active = state.fastForward,
    hovered = isHover(hoverPos, speedBtn),
  })
  registerHit("toggle_speed", speedBtn)

  local pauseBtn = { x = 970, y = 14, w = 86, h = 34 }
  self:drawButton(pauseBtn, state.paused and t("resume") or t("pause"), {
    active = state.paused,
    hovered = isHover(hoverPos, pauseBtn),
  })
  registerHit("toggle_pause", pauseBtn)

  local muteBtn = { x = 1064, y = 14, w = 92, h = 34 }
  self:drawButton(muteBtn, state.audio.muted and t("unmute") or t("mute"), {
    active = state.audio.muted,
    hovered = isHover(hoverPos, muteBtn),
  })
  registerHit("toggle_mute", muteBtn)

  local langBtn = { x = 1164, y = 14, w = 96, h = 34 }
  self:drawButton(langBtn, t("langToggle"), { hovered = isHover(hoverPos, langBtn) })
  registerHit("toggle_lang", langBtn)
end

function Renderer:renderSlotPanel(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(Color.hex("#191d30"))
  lg.rectangle("fill", SLOT_PANEL.x, SLOT_PANEL.y, SLOT_PANEL.w, SLOT_PANEL.h, 10, 10)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#333c5c"))
  lg.rectangle("line", SLOT_PANEL.x, SLOT_PANEL.y, SLOT_PANEL.w, SLOT_PANEL.h, 10, 10)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f16)
  lg.setColor(Color.hex("#f6c945"))
  lg.printf(t("slotTitle"), SLOT_PANEL.x, SLOT_PANEL.y + 10, SLOT_PANEL.w, "center")

  local canNudge = (not state.slot.spinning) and (state.nudges > 0) and (not state.coreModal) and (not state.classModal)

  for col = 1, 3 do
    local cx = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
    local upRect = { x = cx, y = 116, w = CELL_W, h = 28 }
    self:drawButton(upRect, "^ " .. t("nudgeUp"), {
      disabled = not canNudge,
      bg = Color.hex("#21322b"),
      border = Color.hex("#4ade80"),
      font = self.fonts.f12,
      hovered = isHover(hoverPos, upRect),
    })
    registerHit("nudge", upRect, { col = col, dir = 1 })
  end

  lg.setColor(Color.hex("#0e101a"))
  lg.rectangle("fill", REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 8, 8)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#b48a3e"))
  lg.rectangle("line", REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 8, 8)
  lg.setLineWidth(1)

  local grid = state.slot:getGrid()
  local matchedSet = {}
  for _, m in ipairs(state.slot.activeMatches) do
    for _, cell in ipairs(m.cells) do
      matchedSet[cell[1] .. "," .. cell[2]] = true
    end
  end

  for col = 1, 3 do
    for row = 1, 3 do
      local cellX = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
      local cellY = REEL_BOX.y + 6 + (row - 1) * (CELL_H + 3)
      local isMatch = (not state.slot.spinning) and matchedSet[col .. "," .. row]

      lg.setColor(isMatch and Color.hex("#2d2614") or Color.hex("#161a29"))
      lg.rectangle("fill", cellX, cellY, CELL_W, CELL_H, 6, 6)
      lg.setLineWidth(isMatch and 2.5 or 1)
      lg.setColor(isMatch and Color.hex("#ffdf6b") or Color.hex("#272d45"))
      lg.rectangle("line", cellX, cellY, CELL_W, CELL_H, 6, 6)
      lg.setLineWidth(1)

      local symId = grid[col][row]
      local shiftY = state.slot.reelSpinning[col] and ((state.slot.reelVisualShift[col] - 0.5) * 18) or 0
      Sprites.drawSymbolIcon(symId, cellX + CELL_W / 2, cellY + CELL_H / 2 - 5 + shiftY, 36)

      lg.setFont(self.fonts.f11)
      lg.setColor(Symbols.SYMBOLS[symId].color)
      lg.printf(i18n:pick(Symbols.SYMBOLS[symId].name), cellX, cellY + CELL_H - 18, CELL_W, "center")
    end
  end

  if not state.slot.spinning and #state.slot.activeMatches > 0 then
    lg.setLineWidth(3.5)
    for _, m in ipairs(state.slot.activeMatches) do
      local pts = {}
      for _, cell in ipairs(m.cells) do
        pts[#pts + 1] = REEL_BOX.x + 6 + (cell[1] - 1) * (CELL_W + CELL_GAP) + CELL_W / 2
        pts[#pts + 1] = REEL_BOX.y + 6 + (cell[2] - 1) * (CELL_H + 3) + CELL_H / 2 - 4
      end
      lg.setColor(m.isPureJackpot and Color.hex("#ffdf6b") or Color.hex("#ffdf6b", 0.72))
      lg.line(pts)
    end
    lg.setLineWidth(1)
  end

  for col = 1, 3 do
    local cx = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
    local dnRect = { x = cx, y = 382, w = CELL_W, h = 28 }
    self:drawButton(dnRect, "v " .. t("nudgeDown"), {
      disabled = not canNudge,
      bg = Color.hex("#21322b"),
      border = Color.hex("#4ade80"),
      font = self.fonts.f12,
      hovered = isHover(hoverPos, dnRect),
    })
    registerHit("nudge", dnRect, { col = col, dir = -1 })
  end

  local spinCost = state:currentSpinCost()
  local spinRect = { x = 34, y = 422, w = 160, h = 54 }
  self:drawButton(spinRect, state.slot.spinning and t("spinning") or t("spin"), {
    disabled = not state:canSpin(),
    bg = Color.hex("#b45309"),
    border = Color.hex("#fbbf24"),
    subLabel = (spinCost == 0) and t("free") or (tostring(spinCost) .. "g"),
    font = self.fonts.f16,
    hovered = isHover(hoverPos, spinRect),
  })
  registerHit("spin", spinRect)

  local fightRect = { x = 202, y = 422, w = 160, h = 54 }
  local inBattle = (state.phase == "battle")
  self:drawButton(fightRect, inBattle and t("inBattle") or t("startWave"), {
    disabled = inBattle or (state.coreModal ~= nil) or (state.classModal ~= nil),
    bg = Color.hex("#15803d"),
    border = Color.hex("#4ade80"),
    font = self.fonts.f16,
    hovered = isHover(hoverPos, fightRect),
  })
  registerHit("start_wave", fightRect)

  -- Selected Unit Inspector
  local sel = nil
  for _, u in ipairs(state.roster) do
    if u.id == state.selectedUnitId then sel = u; break end
  end
  if not sel then sel = state.roster[1] end

  local card = { x = 34, y = 486, w = 328, h = 126 }
  lg.setColor(Color.hex("#121524"))
  lg.rectangle("fill", card.x, card.y, card.w, card.h, 8, 8)
  lg.setColor(Color.hex("#2d3554"))
  lg.rectangle("line", card.x, card.y, card.w, card.h, 8, 8)

  if sel then
    lg.setFont(self.fonts.f14)
    lg.setColor(sel.accent)
    lg.print(i18n:pick(sel.name) .. "  [" .. tostring(sel.tier) .. "*]", card.x + 12, card.y + 10)

    local needed = Units.xpNeededForTier(sel.tier)
    local xpTxt = (sel.tier >= 3) and "MAX" or (t("xpLabel") .. ": " .. sel.xp .. "/" .. needed)
    lg.setFont(self.fonts.f12)
    lg.setColor(Color.hex("#94a3b8"))
    lg.printf(xpTxt, card.x, card.y + 12, card.w - 12, "right")

    lg.setColor(Color.hex("#e2e8f0"))
    lg.print(
      t("hp") .. ": " .. math.floor(sel.hp + 0.5) .. "/" .. sel.maxHp .. "  " .. t("atk") .. ": " .. sel.atk .. "  " .. t("aspd") .. ": " .. sel.aspd,
      card.x + 12,
      card.y + 34
    )
    lg.setColor(Color.hex("#a5b4fc"))
    lg.printf(i18n:pick(sel.traits), card.x + 12, card.y + 54, card.w - 24, "left")

    local feedBtn = { x = card.x + 10, y = card.y + 82, w = 162, h = 34 }
    self:drawButton(feedBtn, state.feedMode and t("cancelFeed") or t("feedMode"), {
      active = state.feedMode,
      disabled = (#state.roster < 2) or (state.coreModal ~= nil) or (state.classModal ~= nil),
      bg = Color.hex("#312e81"),
      border = Color.hex("#818cf8"),
      font = self.fonts.f13,
      hovered = isHover(hoverPos, feedBtn),
    })
    registerHit("toggle_feed", feedBtn)

    local sellGain = math.floor((sel.sellGold or 6) * sel.tier + 0.5)
    local dismissBtn = { x = card.x + 180, y = card.y + 82, w = 138, h = 34 }
    self:drawButton(dismissBtn, t("dismissUnit") .. " +" .. sellGain .. "g", {
      disabled = (#state.roster <= 1) or state.waveActive,
      bg = Color.hex("#4c1d24"),
      border = Color.hex("#fb7185"),
      font = self.fonts.f12,
      hovered = isHover(hoverPos, dismissBtn),
    })
    registerHit("dismiss_unit", dismissBtn, { unitId = sel.id })
  end

  -- Active Cores Summary Bar
  lg.setColor(Color.hex("#121524"))
  lg.rectangle("fill", 34, 622, 328, 68, 8, 8)
  lg.setColor(Color.hex("#2d3554"))
  lg.rectangle("line", 34, 622, 328, 68, 8, 8)

  lg.setFont(self.fonts.f11)
  lg.setColor(Color.hex("#94a3b8"))
  lg.print(t("coresBar") .. " (" .. #state.cores .. ")", 46, 630)

  if #state.cores == 0 then
    lg.setFont(self.fonts.f12)
    lg.setColor(Color.hex("#475569"))
    lg.print(t("noCores"), 46, 654)
  else
    for idx = 1, math.min(6, #state.cores) do
      local core = state.cores[idx]
      local bx = 46 + (idx - 1) * 51
      local by = 650
      lg.setColor(Color.hex("#1e2438"))
      lg.rectangle("fill", bx, by, 45, 28, 5, 5)
      lg.setColor(core.color)
      lg.rectangle("line", bx, by, 45, 28, 5, 5)
      drawCenteredText(self.fonts.f11, core.badge, bx, by, 45, 28, core.color)
    end
  end
end

function Renderer:renderArena(state, i18n, time, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local A = Battle.ARENA

  lg.setColor(Color.hex("#151d24"))
  lg.rectangle("fill", A.x, A.y, A.w, A.h, 10, 10)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#333c5c"))
  lg.rectangle("line", A.x, A.y, A.w, A.h, 10, 10)
  lg.setLineWidth(1)

  -- Subtle tactical lanes
  lg.setColor(1, 1, 1, 0.025)
  local laneH = (A.h - 40) / 6
  for i = 0, 5, 2 do
    lg.rectangle("fill", A.x + 42, A.y + 20 + i * laneH, A.w - 50, laneH)
  end

  -- Castle wall
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("fill", A.x + 2, A.y + 8, 36, A.h - 16)
  lg.setColor(Color.hex("#475569"))
  for y = A.y + 18, A.y + A.h - 24, 36 do
    lg.rectangle("fill", A.x + 32, y, 10, 20)
  end
  lg.setColor(Color.hex("#64748b"))
  lg.setLineWidth(2)
  lg.line(A.castleX, A.y + 6, A.castleX, A.y + A.h - 6)
  lg.setLineWidth(1)

  -- Meteors
  for _, m in ipairs(state.meteors) do
    lg.setColor(1, 0.31, 0.12, 0.16)
    lg.circle("fill", m.x, m.y, m.radius * m.progress)
    lg.setColor(1, 0.39, 0.20, 0.85)
    lg.setLineWidth(2)
    lg.circle("line", m.x, m.y, m.radius)
    local curX = m.startX + (m.x - m.startX) * m.progress
    local curY = m.startY + (m.y - m.startY) * m.progress
    lg.setColor(Color.hex("#ffbe0b"))
    lg.circle("fill", curX, curY, 12)
  end
  lg.setLineWidth(1)

  -- Sort allies + enemies by Y
  local renderList = {}
  for _, u in ipairs(state.roster) do
    renderList[#renderList + 1] = { kind = "ally", y = u.y, obj = u }
  end
  for _, u in ipairs(state.summons) do
    renderList[#renderList + 1] = { kind = "ally", y = u.y, obj = u }
  end
  for _, e in ipairs(state.enemies) do
    renderList[#renderList + 1] = { kind = "enemy", y = e.y, obj = e }
  end
  table.sort(renderList, function(a, b) return a.y < b.y end)

  for _, item in ipairs(renderList) do
    if item.kind == "ally" then
      local u = item.obj
      local isSel = (u.id == state.selectedUnitId)
      local isSac = (u.id == state.feedSacrificeId)
      if isSel or isSac or (state.feedMode and not u.isSummon and u.tier < 3) then
        lg.setColor(isSac and Color.hex("#f43f5e") or ((state.feedMode and state.feedSacrificeId) and Color.hex("#4ade80") or Color.hex("#ffdf6b")))
        lg.setLineWidth(2.5)
        lg.circle("line", u.x, u.y, (u.radius or 15) + 6)
        lg.setLineWidth(1)
      end

      Sprites.drawAllySprite(u, time)
      drawHealthBar(u.x - 16, u.y - (u.radius or 15) - 9, 32, 4, u.hp / u.maxHp, Color.hex("#4ade80"))

      if not u.isSummon then
        registerHit("unit_arena", { x = u.x - 20, y = u.y - 20, w = 40, h = 40 }, { unitId = u.id })
      end
    else
      local e = item.obj
      Sprites.drawEnemySprite(e, time)
      local bw = e.isBoss and 56 or 30
      drawHealthBar(e.x - bw / 2, e.y - e.radius - 10, bw, e.isBoss and 6 or 4, e.hp / e.maxHp, Color.hex("#fb7185"))
      if e.isBoss then
        lg.setFont(self.fonts.f12)
        lg.setColor(Color.hex("#ffbe0b"))
        lg.printf(i18n:pick(e.name), e.x - 100, e.y - e.radius - 26, 200, "center")
      end
    end
  end

  -- Projectiles
  for _, p in ipairs(state.projectiles) do
    lg.setColor(p.color)
    lg.circle("fill", p.x, p.y, p.radius)
  end

  -- VFX
  for _, v in ipairs(state.vfx) do
    local alpha = math.max(0, v.life / v.maxLife)
    lg.setColor(v.color[1], v.color[2], v.color[3], alpha)
    if v.kind == "particle" then
      lg.rectangle("fill", v.x - v.size / 2, v.y - v.size / 2, v.size, v.size)
    elseif v.kind == "ring" then
      lg.setLineWidth(3)
      lg.circle("line", v.x, v.y, v.radius * (1 - alpha * 0.4))
    elseif v.kind == "slash" then
      lg.setLineWidth(3)
      lg.arc("line", "open", v.x, v.y, v.radius, -0.9, 0.9)
    elseif v.kind == "beam" then
      lg.setLineWidth(2.5)
      lg.line(v.x1, v.y1, v.x2, v.y2)
    end
  end
  lg.setLineWidth(1)

  if state.feedMode then
    local msg = state.feedSacrificeId and t("selectTarget") or t("selectSacrifice")
    lg.setColor(0.12, 0.11, 0.29, 0.9)
    lg.rectangle("fill", A.x + 170, A.y + 12, 520, 34, 8, 8)
    lg.setColor(Color.hex("#818cf8"))
    lg.setLineWidth(2)
    lg.rectangle("line", A.x + 170, A.y + 12, 520, 34, 8, 8)
    lg.setLineWidth(1)
    drawCenteredText(self.fonts.f13, msg .. " - " .. t("feedModeHint"), A.x + 170, A.y + 12, 520, 34, Color.hex("#e0e7ff"))
  end

  if state.bossBannerTimer > 0 then
    lg.setColor(0.62, 0.07, 0.22, 0.9)
    lg.rectangle("fill", A.x + 250, A.y + 56, 360, 36, 8, 8)
    drawCenteredText(self.fonts.f16, t("bossWarning"), A.x + 250, A.y + 56, 360, 36, Color.hex("#fde047"))
  end
end

function Renderer:renderRosterStrip(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local A = Battle.ARENA
  local strip = { x = A.x, y = 638, w = A.w, h = 66 }

  lg.setColor(Color.hex("#191d30"))
  lg.rectangle("fill", strip.x, strip.y, strip.w, strip.h, 8, 8)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#333c5c"))
  lg.rectangle("line", strip.x, strip.y, strip.w, strip.h, 8, 8)
  lg.setLineWidth(1)

  if #state.roster == 0 then
    drawCenteredText(self.fonts.f13, i18n:t("clickUnitTip"), strip.x, strip.y, strip.w, strip.h, Color.hex("#64748b"))
    return
  end

  local slotW = 82
  for idx, u in ipairs(state.roster) do
    local rx = strip.x + 10 + (idx - 1) * (slotW + 4)
    local ry = strip.y + 8
    local rect = { x = rx, y = ry, w = slotW, h = 50 }
    local isSel = (u.id == state.selectedUnitId)
    local isSac = (u.id == state.feedSacrificeId)

    lg.setColor(isSac and Color.hex("#4c1d24") or (isSel and Color.hex("#2a3457") or (isHover(hoverPos, rect) and Color.hex("#222944") or Color.hex("#121524"))))
    lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
    lg.setLineWidth((isSel or isSac) and 2 or 1)
    lg.setColor(isSac and Color.hex("#fb7185") or (isSel and Color.hex("#ffdf6b") or Color.hex("#334155")))
    lg.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)
    lg.setLineWidth(1)

    lg.setFont(self.fonts.f11)
    lg.setColor(u.accent)
    lg.printf(i18n:pick(u.name), rx + 2, ry + 5, slotW - 4, "center")

    Sprites.drawTierPips(rx + slotW / 2, ry + 27, u.tier)
    drawHealthBar(rx + 8, ry + 39, slotW - 16, 4, u.hp / u.maxHp, Color.hex("#4ade80"))
    registerHit("unit_card", rect, { unitId = u.id })
  end
end

function Renderer:renderCoreModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.03, 0.04, 0.07, 0.84)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 180, 140, 920, 440, 14, 14)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#f6c945"))
  lg.rectangle("line", 180, 140, 920, 440, 14, 14)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#ffdf6b"))
  lg.printf(t("coreModalTitle"), 180, 168, 920, "center")

  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#cbd5e1"))
  lg.printf(t("coreModalSub"), 180, 210, 920, "center")

  for idx, core in ipairs(state.coreModal.choices) do
    local card = { x = 224 + (idx - 1) * 284, y = 262, w = 264, h = 270 }
    local hov = isHover(hoverPos, card)
    lg.setColor(hov and Color.hex("#262d47") or Color.hex("#121524"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(hov and 3 or 2)
    lg.setColor(hov and Color.hex("#ffdf6b") or core.color)
    lg.rectangle("line", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(1)

    -- Emblem badge
    lg.setColor(Color.hex("#1e2438"))
    lg.circle("fill", card.x + card.w / 2, card.y + 56, 28)
    lg.setLineWidth(2)
    lg.setColor(core.color)
    lg.circle("line", card.x + card.w / 2, card.y + 56, 28)
    lg.setLineWidth(1)
    drawCenteredText(self.fonts.f13, core.badge, card.x + card.w / 2 - 28, card.y + 28, 56, 56, core.color)

    lg.setFont(self.fonts.f18)
    lg.setColor(core.color)
    lg.printf(i18n:pick(core.name), card.x + 10, card.y + 102, card.w - 20, "center")

    lg.setFont(self.fonts.f13)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.printf(i18n:pick(core.desc), card.x + 18, card.y + 144, card.w - 36, "center")

    registerHit("pick_core", card, { coreId = core.id })
  end
end

function Renderer:renderClassModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.03, 0.04, 0.07, 0.85)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 260, 145, 760, 430, 14, 14)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#818cf8"))
  lg.rectangle("line", 260, 145, 760, 430, 14, 14)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#a5b4fc"))
  lg.printf(t("classModalTitle"), 260, 174, 760, "center")

  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#cbd5e1"))
  lg.printf(t("classModalSub"), 260, 216, 760, "center")

  for idx, cls in ipairs(state.classModal.choices) do
    local card = { x = 310 + (idx - 1) * 340, y = 268, w = 320, h = 256 }
    local hov = isHover(hoverPos, card)
    lg.setColor(hov and Color.hex("#262d47") or Color.hex("#121524"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(hov and 3 or 2)
    lg.setColor(hov and Color.hex("#ffdf6b") or cls.color)
    lg.rectangle("line", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(1)

    lg.setFont(self.fonts.f22)
    lg.setColor(cls.color)
    lg.printf("[3*] " .. i18n:pick(cls.name), card.x + 10, card.y + 34, card.w - 20, "center")

    lg.setFont(self.fonts.f13)
    lg.setColor(Color.hex("#fde047"))
    lg.printf(
      "HP x" .. cls.hpMult .. "  |  ATK x" .. cls.atkMult .. "  |  ASPD x" .. cls.aspdMult,
      card.x + 10,
      card.y + 82,
      card.w - 20,
      "center"
    )

    lg.setFont(self.fonts.f14)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.printf(i18n:pick(cls.desc), card.x + 18, card.y + 128, card.w - 36, "center")

    registerHit("pick_class", card, { classId = cls.id })
  end
end

function Renderer:renderEndOverlay(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local isWin = (state.phase == "victory")

  lg.setColor(0.03, 0.04, 0.07, 0.85)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 360, 180, 560, 360, 14, 14)
  lg.setLineWidth(3)
  lg.setColor(isWin and Color.hex("#f6c945") or Color.hex("#fb7185"))
  lg.rectangle("line", 360, 180, 560, 360, 14, 14)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f36)
  lg.setColor(isWin and Color.hex("#ffdf6b") or Color.hex("#fb7185"))
  lg.printf(isWin and t("victoryTitle") or t("gameOverTitle"), 360, 218, 560, "center")

  lg.setFont(self.fonts.f16)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.printf(isWin and t("victorySub") or t("gameOverSub"), 380, 276, 520, "center")

  lg.setFont(self.fonts.f15)
  lg.setColor(Color.hex("#94a3b8"))
  lg.printf(
    t("wave") .. ": " .. state.wave .. "/" .. Waves.MAX_WAVES .. "   |   " .. t("kills") .. ": " .. state.totalKills,
    360,
    328,
    560,
    "center"
  )

  local retryBtn = { x = 430, y = 410, w = 200, h = 52 }
  self:drawButton(retryBtn, t("restart"), {
    bg = Color.hex("#d97706"),
    border = Color.hex("#fde047"),
    font = self.fonts.f16,
    hovered = isHover(hoverPos, retryBtn),
  })
  registerHit("start_run", retryBtn)

  local menuBtn = { x = 650, y = 410, w = 200, h = 52 }
  self:drawButton(menuBtn, t("backMenu"), { hovered = isHover(hoverPos, menuBtn) })
  registerHit("back_menu", menuBtn)
end

return Renderer
