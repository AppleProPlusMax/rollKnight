local Symbols = require("src.data.symbols")
local Waves = require("src.data.waves")
local Units = require("src.data.units")
local Upgrades = require("src.data.upgrades")
local StateMod = require("src.systems.state")
local Battle = require("src.systems.battle")
local Sprites = require("src.render.sprites")
local Color = require("src.utils.color")

local Renderer = {}
Renderer.__index = Renderer

local SLOT_PANEL = { x = 16, y = 74, w = 364, h = 632 }
local REEL_BOX = { x = 28, y = 134, w = 312, h = 204 }
local CELL_W = 94
local CELL_H = 62
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
  return setmetatable({ fonts = {}, tooltip = nil }, Renderer)
end

function Renderer:initFonts()
  local cjkPaths = {
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/msyh.ttf",
    "C:/Windows/Fonts/simhei.ttf",
    "C:/Windows/Fonts/simsun.ttc",
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
    bg = opts.activeBg or Color.hex("#4f46e5")
    border = opts.activeBorder or Color.hex("#a5b4fc")
  elseif opts.hovered then
    bg = Color.hex("#384266")
    border = Color.hex("#8da2fb")
  end

  lg.setColor(bg)
  lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
  lg.setLineWidth(2)
  lg.setColor(border)
  lg.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)
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

local function drawHealthBar(x, y, w, h, ratio, color, shieldRatio)
  local lg = love.graphics
  local r = math.max(0, math.min(1, ratio))
  lg.setColor(0.04, 0.05, 0.08, 0.88)
  lg.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("fill", x, y, w, h)
  lg.setColor(color or Color.hex("#4ade80"))
  lg.rectangle("fill", x, y, w * r, h)
  if shieldRatio and shieldRatio > 0 then
    local sr = math.max(0, math.min(1, shieldRatio))
    lg.setColor(Color.hex("#38bdf8"))
    lg.rectangle("fill", x, y - 2, w * sr, 2)
  end
end

function Renderer:render(state, i18n, time, hoverPos, dragState, viewportTransform)
  local lg = love.graphics
  local hitboxes = {}
  self.tooltip = nil
  local function registerHit(id, rect, payload)
    hitboxes[#hitboxes + 1] = { id = id, rect = rect, payload = payload }
  end

  local shakeX, shakeY = 0, 0
  if state.screenShake > 0.2 then
    shakeX = (math.random() - 0.5) * state.screenShake
    shakeY = (math.random() - 0.5) * state.screenShake
  end

  lg.push()
  lg.translate(shakeX, shakeY)

  lg.setColor(Color.hex("#10121c"))
  lg.rectangle("fill", 0, 0, 1280, 720)

  if state.phase == "menu" then
    self:renderMenu(state, i18n, time, registerHit, hoverPos)
    lg.pop()
    return hitboxes
  end

  self:renderHud(state, i18n, registerHit, hoverPos)
  self:renderSlotPanel(state, i18n, time, registerHit, hoverPos, viewportTransform, shakeX, shakeY)
  self:renderArena(state, i18n, time, registerHit, hoverPos, dragState)
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

  local hasModal = state.shopModal or state.guideModal or state.coreModal or state.classModal
    or state.phase == "gameover" or state.phase == "victory"

  if hasModal then
    -- Isolate modal clicks so clicks never fall through onto background controls
    hitboxes = {}
    if state.shopModal or state.guideModal then
      registerHit("close_modals", { x = 0, y = 0, w = 1280, h = 720 })
    else
      registerHit("modal_blocker", { x = 0, y = 0, w = 1280, h = 720 })
    end
  end

  if state.shopModal then
    self:renderShopModal(state, i18n, registerHit, hoverPos)
  elseif state.guideModal then
    self:renderGuideModal(state, i18n, registerHit, hoverPos)
  elseif state.coreModal then
    self:renderCoreModal(state, i18n, registerHit, hoverPos)
  elseif state.classModal then
    self:renderClassModal(state, i18n, registerHit, hoverPos)
  elseif state.phase == "gameover" or state.phase == "victory" then
    self:renderEndOverlay(state, i18n, registerHit, hoverPos)
  elseif self.tooltip and hoverPos then
    self:renderTooltip(self.tooltip, hoverPos)
  end

  lg.pop()
  return hitboxes
end

function Renderer:renderTooltip(tip, pos)
  local lg = love.graphics
  local w = 270
  local h = 64
  local tx = math.min(1265 - w, math.max(15, pos.x + 14))
  local ty = math.min(705 - h, math.max(70, pos.y + 14))
  lg.setColor(0.06, 0.08, 0.14, 0.96)
  lg.rectangle("fill", tx, ty, w, h, 6, 6)
  lg.setColor(tip.color or Color.hex("#f6c945"))
  lg.setLineWidth(1.5)
  lg.rectangle("line", tx, ty, w, h, 6, 6)
  lg.setLineWidth(1)
  lg.setFont(self.fonts.f13)
  lg.print(tip.title, tx + 10, ty + 8)
  lg.setFont(self.fonts.f11)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.printf(tip.body, tx + 10, ty + 28, w - 20, "left")
end

function Renderer:renderMenu(state, i18n, time, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.39, 0.40, 0.95, 0.08)
  for x = 0, 1280, 40 do lg.line(x, 0, x, 720) end
  for y = 0, 720, 40 do lg.line(0, y, 1280, y) end

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 190, 62, 900, 596, 16, 16)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#f6c945"))
  lg.rectangle("line", 190, 62, 900, 596, 16, 16)
  lg.setLineWidth(1)

  local demoSymbols = { "shield", "bow", "staff", "horse", "skull", "coin", "jester", "crown" }
  for i, sym in ipairs(demoSymbols) do
    local sx = 310 + (i - 1) * 94
    local sy = 136 + math.sin(time * 3 + i) * 5
    Sprites.drawSymbolIcon(sym, sx, sy, 38)
  end

  lg.setFont(self.fonts.f54)
  lg.setColor(Color.hex("#ffdf6b"))
  lg.printf(t("title"), 190, 174, 900, "center")

  lg.setFont(self.fonts.f16)
  lg.setColor(Color.hex("#cbd5e1"))
  lg.printf(t("subtitle"), 190, 234, 900, "center")

  lg.setColor(Color.hex("#111422"))
  lg.rectangle("fill", 240, 274, 800, 176, 10, 10)
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("line", 240, 274, 800, 176, 10, 10)

  lg.setFont(self.fonts.f15)
  lg.setColor(Color.hex("#93c5fd"))
  lg.print(t("rulesTitle"), 264, 288)

  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.print(t("rule1"), 264, 318)
  lg.print(t("rule2"), 264, 348)
  lg.print(t("rule3"), 264, 378)
  lg.print(t("rule4"), 264, 408)

  -- Difficulty selector
  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#94a3b8"))
  lg.printf(t("diffLabel"), 190, 466, 900, "center")
  local diffs = {
    { id = "normal",   label = t("diffNormal"),   color = Color.hex("#4ade80") },
    { id = "hard",     label = t("diffHard"),     color = Color.hex("#f59e0b") },
    { id = "judgment", label = t("diffJudgment"), color = Color.hex("#fb7185") },
  }
  for idx, d in ipairs(diffs) do
    local dBtn = { x = 385 + (idx - 1) * 176, y = 490, w = 160, h = 36 }
    self:drawButton(dBtn, d.label, {
      active = (state.difficulty == d.id),
      activeBg = Color.hex("#262d47"),
      activeBorder = d.color,
      border = Color.hex("#334155"),
      text = d.color,
      font = self.fonts.f13,
      hovered = isHover(hoverPos, dBtn),
    })
    registerHit("set_diff", dBtn, { diff = d.id })
  end

  local startBtn = { x = 490, y = 542, w = 300, h = 60 }
  self:drawButton(startBtn, t("startRun"), {
    bg = Color.hex("#d97706"),
    border = Color.hex("#fde047"),
    text = Color.hex("#ffffff"),
    font = self.fonts.f22,
    hovered = isHover(hoverPos, startBtn),
  })
  registerHit("start_run", startBtn)

  lg.setFont(self.fonts.f12)
  lg.setColor(Color.hex("#94a3b8"))
  lg.printf(t("continueHint"), 190, 618, 900, "center")

  local langBtn = { x = 990, y = 84, w = 74, h = 32 }
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
  lg.print("rollKnight", 16, 18)

  local pills = {
    { label = t("wave") .. ": " .. state.wave .. "/" .. Waves.MAX_WAVES, color = Color.hex("#93c5fd"), x = 148, w = 114 },
    { label = t("hearts") .. ": " .. state.hearts .. "/" .. state.maxHearts, color = Color.hex("#fb7185"), x = 270, w = 104 },
    { label = t("gold") .. ": " .. state.gold .. "g", color = Color.hex("#facc15"), x = 382, w = 104 },
    { label = t("nudges") .. ": " .. state.nudges, color = Color.hex("#4ade80"), x = 494, w = 102 },
    { label = t("roster") .. ": " .. #state.roster .. "/" .. state.maxRoster, color = Color.hex("#c084fc"), x = 604, w = 110 },
  }

  for _, p in ipairs(pills) do
    lg.setColor(Color.hex("#0f1220"))
    lg.rectangle("fill", p.x, 14, p.w, 34, 7, 7)
    lg.setColor(Color.hex("#2e3654"))
    lg.rectangle("line", p.x, 14, p.w, 34, 7, 7)
    drawCenteredText(self.fonts.f13, p.label, p.x, 14, p.w, 34, p.color)
  end

  local guideBtn = { x = 724, y = 14, w = 68, h = 34 }
  self:drawButton(guideBtn, t("guideBtn"), {
    active = state.guideModal,
    font = self.fonts.f13,
    hovered = isHover(hoverPos, guideBtn),
  })
  registerHit("toggle_guide", guideBtn)

  local shopBtn = { x = 800, y = 14, w = 92, h = 34 }
  self:drawButton(shopBtn, t("shopBtn"), {
    active = state.shopModal,
    bg = Color.hex("#3b2e16"),
    border = Color.hex("#facc15"),
    font = self.fonts.f13,
    hovered = isHover(hoverPos, shopBtn),
  })
  registerHit("toggle_shop", shopBtn)

  local speedBtn = { x = 900, y = 14, w = 84, h = 34 }
  self:drawButton(speedBtn, state.fastForward and t("speed2x") or t("speed1x"), {
    active = state.fastForward,
    font = self.fonts.f13,
    hovered = isHover(hoverPos, speedBtn),
  })
  registerHit("toggle_speed", speedBtn)

  local pauseBtn = { x = 992, y = 14, w = 74, h = 34 }
  self:drawButton(pauseBtn, state.paused and t("resume") or t("pause"), {
    active = state.paused,
    font = self.fonts.f13,
    hovered = isHover(hoverPos, pauseBtn),
  })
  registerHit("toggle_pause", pauseBtn)

  local muteBtn = { x = 1074, y = 14, w = 74, h = 34 }
  self:drawButton(muteBtn, state.audio.muted and t("unmute") or t("mute"), {
    active = state.audio.muted,
    font = self.fonts.f13,
    hovered = isHover(hoverPos, muteBtn),
  })
  registerHit("toggle_mute", muteBtn)

  local langBtn = { x = 1156, y = 14, w = 106, h = 34 }
  self:drawButton(langBtn, t("langToggle"), { font = self.fonts.f13, hovered = isHover(hoverPos, langBtn) })
  registerHit("toggle_lang", langBtn)
end

function Renderer:renderSlotPanel(state, i18n, time, registerHit, hoverPos, vp, shakeX, shakeY)
  shakeX = shakeX or 0
  shakeY = shakeY or 0
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(Color.hex("#191d30"))
  lg.rectangle("fill", SLOT_PANEL.x, SLOT_PANEL.y, SLOT_PANEL.w, SLOT_PANEL.h, 10, 10)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#333c5c"))
  lg.rectangle("line", SLOT_PANEL.x, SLOT_PANEL.y, SLOT_PANEL.w, SLOT_PANEL.h, 10, 10)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#f6c945"))
  lg.printf(t("slotTitle"), SLOT_PANEL.x, SLOT_PANEL.y + 6, SLOT_PANEL.w, "center")

  local modalBlocked = state.coreModal or state.classModal or state.shopModal or state.guideModal
  local canNudge = (not state.slot.spinning) and (state.nudges > 0) and (not modalBlocked)

  for col = 1, 3 do
    local cx = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
    local upRect = { x = cx, y = 102, w = CELL_W, h = 26 }
    local hintUp = canNudge and state.slot:wouldNudgeMatch(col, 1)
    self:drawButton(upRect, (hintUp and "* ^ " or "^ ") .. t("nudgeUp"), {
      disabled = not canNudge,
      bg = hintUp and Color.hex("#2b4a26") or Color.hex("#21322b"),
      border = hintUp and Color.hex("#facc15") or Color.hex("#4ade80"),
      text = hintUp and Color.hex("#fef08a") or Color.hex("#f1f5f9"),
      font = self.fonts.f11,
      hovered = isHover(hoverPos, upRect),
    })
    registerHit("nudge", upRect, { col = col, dir = 1 })
  end

  -- Reel Window Frame
  lg.setColor(Color.hex("#0e101a"))
  lg.rectangle("fill", REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 8, 8)
  lg.setLineWidth(3)
  lg.setColor(state:isPitySpinReady() and Color.hex("#ffdf6b") or Color.hex("#b48a3e"))
  lg.rectangle("line", REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 8, 8)
  lg.setLineWidth(1)

  -- Physical Lever on the right edge of the Reel Box
  local leverRect = { x = REEL_BOX.x + REEL_BOX.w + 4, y = REEL_BOX.y + 18, w = 26, h = 160 }
  local pull = state.slot.leverPull or 0
  local knobY = leverRect.y + 14 + pull * 116
  local baseY = leverRect.y + 132
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("fill", leverRect.x + 3, leverRect.y + 44, 8, 96, 3, 3)
  lg.setColor(Color.hex("#94a3b8"))
  lg.setLineWidth(4)
  lg.line(leverRect.x + 7, baseY, leverRect.x + 15, knobY)
  lg.setLineWidth(1)
  local knobHover = isHover(hoverPos, leverRect) and state:canSpin()
  lg.setColor(state:canSpin() and (knobHover and Color.hex("#fde047") or Color.hex("#ef4444")) or Color.hex("#475569"))
  lg.circle("fill", leverRect.x + 15, knobY, 10)
  lg.setColor(Color.hex("#fff1f2"))
  lg.circle("fill", leverRect.x + 12, knobY - 3, 3)
  registerHit("spin", leverRect)

  local matchedSet = {}
  for _, m in ipairs(state.slot.activeMatches) do
    for _, cell in ipairs(m.cells) do
      matchedSet[cell[1] .. "," .. cell[2]] = true
    end
  end

  local sx = vp.ox + (REEL_BOX.x + 4 + shakeX) * vp.scale
  local sy = vp.oy + (REEL_BOX.y + 4 + shakeY) * vp.scale
  local sw = (REEL_BOX.w - 8) * vp.scale
  local sh = (REEL_BOX.h - 8) * vp.scale
  lg.setScissor(sx, sy, sw, sh)

  for col = 1, 3 do
    local isSpinning = state.slot.reelSpinning[col]
    local isLocked = state.slot.locked[col]
    local shiftPx = isSpinning and (state.slot.reelVisualShift[col] * (CELL_H + 3)) or 0
    local bouncePx = (not isSpinning) and (math.sin(state.slot.reelBounce[col] * math.pi) * 6) or 0
    local startRow = isSpinning and 0 or 1

    for row = startRow, 3 do
      local cellX = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
      local cellY = REEL_BOX.y + 6 + (row - 1) * (CELL_H + 3) + shiftPx + bouncePx
      local isMatch = (not state.slot.spinning) and (row >= 1) and matchedSet[col .. "," .. row]

      lg.setColor(isLocked and Color.hex("#23203d") or (isMatch and Color.hex("#2d2614") or Color.hex("#161a29")))
      lg.rectangle("fill", cellX, cellY, CELL_W, CELL_H, 6, 6)
      lg.setLineWidth(isMatch and 2.5 or (isLocked and 2 or 1))
      lg.setColor(isLocked and Color.hex("#818cf8") or (isMatch and Color.hex("#ffdf6b") or Color.hex("#272d45")))
      lg.rectangle("line", cellX, cellY, CELL_W, CELL_H, 6, 6)
      lg.setLineWidth(1)

      local symId = state.slot:getSymbolAt(col, row - 1)
      Sprites.drawSymbolIcon(symId, cellX + CELL_W / 2, cellY + CELL_H / 2 - 6, 32)

      lg.setFont(self.fonts.f11)
      lg.setColor(Symbols.SYMBOLS[symId].color)
      lg.printf(i18n:pick(Symbols.SYMBOLS[symId].name), cellX, cellY + CELL_H - 16, CELL_W, "center")
    end
  end

  lg.setScissor()

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

  -- Nudge DOWN + Reel LOCK row
  for col = 1, 3 do
    local cx = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
    local dnRect = { x = cx, y = 342, w = 52, h = 24 }
    local hintDn = canNudge and state.slot:wouldNudgeMatch(col, -1)
    self:drawButton(dnRect, (hintDn and "* " or "v ") .. t("nudgeDown"), {
      disabled = not canNudge,
      bg = hintDn and Color.hex("#2b4a26") or Color.hex("#21322b"),
      border = hintDn and Color.hex("#facc15") or Color.hex("#4ade80"),
      text = hintDn and Color.hex("#fef08a") or Color.hex("#f1f5f9"),
      font = self.fonts.f11,
      hovered = isHover(hoverPos, dnRect),
    })
    registerHit("nudge", dnRect, { col = col, dir = -1 })

    local isLocked = state.slot.locked[col]
    local lockRect = { x = cx + 55, y = 342, w = 39, h = 24 }
    self:drawButton(lockRect, isLocked and t("lockedReel") or (t("lockReel") .. StateMod.LOCK_REEL_COST), {
      active = isLocked,
      disabled = state.slot.spinning or modalBlocked or (not isLocked and state.gold < StateMod.LOCK_REEL_COST),
      bg = Color.hex("#1e2438"),
      border = Color.hex("#64748b"),
      font = self.fonts.f11,
      hovered = isHover(hoverPos, lockRect),
    })
    registerHit("lock_reel", lockRect, { col = col })
  end

  -- Luck / Pity Meter Bar
  local pityReady = state:isPitySpinReady()
  local pityRect = { x = 28, y = 370, w = 340, h = 18 }
  lg.setColor(Color.hex("#0e101a"))
  lg.rectangle("fill", pityRect.x, pityRect.y, pityRect.w, pityRect.h, 4, 4)
  local frac = state.pityCharge / StateMod.MAX_PITY
  lg.setColor(pityReady and Color.hex("#eab308") or Color.hex("#6366f1"))
  lg.rectangle("fill", pityRect.x + 2, pityRect.y + 2, (pityRect.w - 4) * frac, pityRect.h - 4, 3, 3)
  lg.setColor(pityReady and Color.hex("#fde047") or Color.hex("#334155"))
  lg.rectangle("line", pityRect.x, pityRect.y, pityRect.w, pityRect.h, 4, 4)
  local pityTxt = pityReady and t("pityReady") or (t("pityLabel") .. ": " .. state.pityCharge .. "/" .. StateMod.MAX_PITY)
  drawCenteredText(self.fonts.f11, pityTxt, pityRect.x, pityRect.y, pityRect.w, pityRect.h, Color.hex("#f8fafc"))

  local spinCost = state:currentSpinCost()
  local spinRect = { x = 28, y = 394, w = 166, h = 48 }
  self:drawButton(spinRect, state.slot.spinning and t("spinning") or t("spin"), {
    disabled = not state:canSpin(),
    bg = pityReady and Color.hex("#ca8a04") or Color.hex("#b45309"),
    border = Color.hex("#fbbf24"),
    subLabel = pityReady and t("guaranteedWild") or ((spinCost == 0) and t("free") or (tostring(spinCost) .. "g")),
    font = self.fonts.f15,
    hovered = isHover(hoverPos, spinRect),
  })
  registerHit("spin", spinRect)

  local fightRect = { x = 202, y = 394, w = 166, h = 48 }
  local inBattle = (state.phase == "battle")
  self:drawButton(fightRect, inBattle and t("inBattle") or t("startWave"), {
    disabled = inBattle or (modalBlocked ~= nil),
    bg = Color.hex("#15803d"),
    border = Color.hex("#4ade80"),
    font = self.fonts.f15,
    hovered = isHover(hoverPos, fightRect),
  })
  registerHit("start_wave", fightRect)

  -- Selected Unit Inspector
  local sel = nil
  for _, u in ipairs(state.roster) do
    if u.id == state.selectedUnitId then sel = u; break end
  end
  if not sel then sel = state.roster[1] end

  local card = { x = 28, y = 448, w = 340, h = 166 }
  lg.setColor(Color.hex("#121524"))
  lg.rectangle("fill", card.x, card.y, card.w, card.h, 8, 8)
  lg.setColor(sel and sel.rarity and sel.rarity.color or Color.hex("#2d3554"))
  lg.rectangle("line", card.x, card.y, card.w, card.h, 8, 8)

  if sel then
    local rarName = sel.rarity and i18n:pick(sel.rarity.name) or ""
    local famName = (sel.family and Units.FAMILIES[sel.family]) and i18n:pick(Units.FAMILIES[sel.family].name) or ""
    lg.setFont(self.fonts.f13)
    lg.setColor(sel.accent)
    lg.printf("[" .. rarName .. "] " .. i18n:pick(sel.name) .. " (" .. sel.tier .. "*)", card.x + 10, card.y + 8, 210, "left")

    local needed = Units.xpNeededForTier(sel.tier)
    local xpTxt = (sel.tier >= 3) and t("paragonLabel") or (t("xpLabel") .. " " .. sel.xp .. "/" .. needed)
    lg.setFont(self.fonts.f11)
    lg.setColor(sel.tier >= 3 and Color.hex("#fde047") or Color.hex("#94a3b8"))
    lg.printf(xpTxt, card.x + 212, card.y + 10, card.w - 222, "right")

    lg.setFont(self.fonts.f12)
    lg.setColor(Color.hex("#cbd5e1"))
    local bonusTxt = sel.bonusTrait and (" | " .. i18n:pick(sel.bonusTrait)) or ""
    lg.print(famName .. bonusTxt .. " | " .. t("kills") .. ": " .. (sel.kills or 0), card.x + 10, card.y + 30)

    lg.setColor(Color.hex("#e2e8f0"))
    lg.print(
      t("hp") .. ":" .. math.floor(sel.hp + 0.5) .. "/" .. sel.maxHp .. "  " .. t("atk") .. ":" .. sel.atk .. "  " .. t("aspd") .. ":" .. sel.aspd,
      card.x + 10,
      card.y + 50
    )

    lg.setColor(Color.hex("#a5b4fc"))
    lg.printf(i18n:pick(sel.traits), card.x + 10, card.y + 70, card.w - 20, "left")

    local feedBtn = { x = card.x + 10, y = card.y + 120, w = 172, h = 34 }
    self:drawButton(feedBtn, state.feedMode and t("cancelFeed") or t("feedMode"), {
      active = state.feedMode,
      disabled = (#state.roster < 2) or (modalBlocked ~= nil),
      bg = Color.hex("#312e81"),
      border = Color.hex("#818cf8"),
      font = self.fonts.f13,
      hovered = isHover(hoverPos, feedBtn),
    })
    registerHit("toggle_feed", feedBtn)

    local sellGain = math.floor((sel.sellGold or 6) * sel.tier + 0.5)
    local dismissBtn = { x = card.x + 190, y = card.y + 120, w = 140, h = 34 }
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
  lg.rectangle("fill", 28, 622, 340, 70, 8, 8)
  lg.setColor(Color.hex("#2d3554"))
  lg.rectangle("line", 28, 622, 340, 70, 8, 8)

  lg.setFont(self.fonts.f11)
  lg.setColor(Color.hex("#94a3b8"))
  lg.print(t("coresBar") .. " (" .. #state.cores .. ")", 38, 628)

  if #state.cores == 0 then
    lg.setFont(self.fonts.f12)
    lg.setColor(Color.hex("#475569"))
    lg.print(t("noCores"), 38, 654)
  else
    for idx = 1, math.min(6, #state.cores) do
      local core = state.cores[idx]
      local bx = 38 + (idx - 1) * 53
      local by = 648
      local cRect = { x = bx, y = by, w = 47, h = 32 }
      local hov = isHover(hoverPos, cRect)
      lg.setColor(hov and Color.hex("#2c3454") or Color.hex("#1e2438"))
      lg.rectangle("fill", bx, by, 47, 32, 5, 5)
      lg.setColor(core.color)
      lg.rectangle("line", bx, by, 47, 32, 5, 5)
      drawCenteredText(self.fonts.f11, core.badge, bx, by, 47, 32, core.color)
      if hov then
        self.tooltip = { title = i18n:pick(core.name), body = i18n:pick(core.desc), color = core.color }
      end
    end
  end
end

function Renderer:renderArena(state, i18n, time, registerHit, hoverPos, dragState)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local A = Battle.ARENA

  lg.setColor(Color.hex("#141c23"))
  lg.rectangle("fill", A.x, A.y, A.w, A.h, 10, 10)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#333c5c"))
  lg.rectangle("line", A.x, A.y, A.w, A.h, 10, 10)
  lg.setLineWidth(1)

  -- Subtle tactical stone grid
  lg.setColor(1, 1, 1, 0.025)
  local laneH = (A.h - 60) / 6
  for i = 0, 5, 2 do
    lg.rectangle("fill", A.x + 42, A.y + 40 + i * laneH, A.w - 50, laneH)
  end

  -- Top Synergy Bar inside Arena
  local synX = A.x + 48
  local synY = A.y + 6
  local famOrder = { "ironbound", "sylvan", "arcane", "undead", "royal" }
  for _, famId in ipairs(famOrder) do
    local fam = Units.FAMILIES[famId]
    local cnt = (state.synergies and state.synergies.counts and state.synergies.counts[famId]) or 0
    local active = cnt >= fam.threshold
    local sRect = { x = synX, y = synY, w = 104, h = 22 }
    local hov = isHover(hoverPos, sRect)
    lg.setColor(active and Color.hex("#1e293b") or Color.hex("#0f172a"))
    lg.rectangle("fill", synX, synY, 104, 22, 4, 4)
    lg.setColor(active and fam.color or Color.hex("#334155"))
    lg.rectangle("line", synX, synY, 104, 22, 4, 4)
    drawCenteredText(self.fonts.f11, i18n:pick(fam.name) .. " " .. cnt .. "/" .. fam.threshold, synX, synY, 104, 22, active and fam.color or Color.hex("#64748b"))
    if hov then
      self.tooltip = { title = i18n:pick(fam.name), body = i18n:pick(fam.bonusDesc), color = fam.color }
    end
    synX = synX + 110
  end

  -- Next Wave Preview OR Live Wave Progress Bar
  local pw = 248
  local px = A.x + A.w - pw - 10
  if state.phase == "spin" and state.wavePlan then
    local isBoss = state.wavePlan.isBossWave
    lg.setColor(isBoss and Color.hex("#4c0519") or Color.hex("#172554"))
    lg.rectangle("fill", px, synY, pw, 22, 4, 4)
    lg.setColor(isBoss and Color.hex("#fb7185") or Color.hex("#60a5fa"))
    lg.rectangle("line", px, synY, pw, 22, 4, 4)
    local txt = t("nextWave") .. ": " .. #state.wavePlan.spawns .. (isBoss and (" [" .. t("bossTag") .. "]") or "")
    drawCenteredText(self.fonts.f11, txt, px, synY, pw, 22, isBoss and Color.hex("#fde047") or Color.hex("#bfdbfe"))
  elseif state.phase == "battle" and state.wavePlan then
    local total = #state.wavePlan.spawns
    local remaining = math.max(0, total - (state.spawnCursor - 1)) + #state.enemies
    local clearedFrac = math.max(0, math.min(1, (total - remaining) / math.max(1, total)))
    lg.setColor(Color.hex("#0f172a"))
    lg.rectangle("fill", px, synY, pw, 22, 4, 4)
    lg.setColor(Color.hex("#dc2626"))
    lg.rectangle("fill", px + 2, synY + 2, (pw - 4) * clearedFrac, 18, 3, 3)
    lg.setColor(Color.hex("#475569"))
    lg.rectangle("line", px, synY, pw, 22, 4, 4)
    drawCenteredText(self.fonts.f11, t("waveProg") .. " " .. (total - remaining) .. "/" .. total, px, synY, pw, 22, Color.hex("#f8fafc"))
  end

  -- Castle Wall + Battlements + Banner
  lg.setColor(Color.hex("#334155"))
  lg.rectangle("fill", A.x + 2, A.y + 8, 36, A.h - 16)
  lg.setColor(Color.hex("#475569"))
  for y = A.y + 18, A.y + A.h - 24, 36 do
    lg.rectangle("fill", A.x + 32, y, 10, 20)
  end
  local waveOff = math.sin(time * 4) * 3
  lg.setColor(Color.hex("#b91c1c"))
  lg.polygon("fill", A.x + 12, A.y + 40, A.x + 30 + waveOff, A.y + 46, A.x + 12, A.y + 58)
  lg.setColor(Color.hex("#64748b"))
  lg.setLineWidth(2)
  lg.line(A.castleX, A.y + 6, A.castleX, A.y + A.h - 6)
  lg.setLineWidth(1)

  -- Ground Craters
  for _, v in ipairs(state.vfx) do
    if v.kind == "crater" then
      local alpha = math.max(0, (v.life / v.maxLife) * 0.55)
      lg.setColor(v.color[1], v.color[2], v.color[3], alpha)
      lg.ellipse("fill", v.x, v.y, v.radius, v.radius * 0.45)
    end
  end

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
      if isSel or isSac or (state.feedMode and not u.isSummon) then
        lg.setColor(isSac and Color.hex("#f43f5e") or ((state.feedMode and state.feedSacrificeId) and Color.hex("#4ade80") or Color.hex("#ffdf6b")))
        lg.setLineWidth(2.2)
        lg.circle("line", u.x, u.y, (u.radius or 15) + 7)
        lg.setLineWidth(1)
      end

      Sprites.drawAllySprite(u, time)
      local shieldRatio = (u.shield and u.shield > 0) and (u.shield / u.maxHp) or 0
      drawHealthBar(u.x - 16, u.y - (u.radius or 15) - 9, 32, 4, u.hp / u.maxHp, Color.hex("#4ade80"), shieldRatio)

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
        lg.printf(i18n:pick(e.name), e.x - 100, e.y - e.radius - 28, 200, "center")
      end
    end
  end

  if dragState and dragState.active then
    local srcUnit = nil
    local hoverTarget = nil
    for _, u in ipairs(state.roster) do
      if u.id == dragState.unitId then
        srcUnit = u
      elseif math.sqrt((dragState.curX - u.x)^2 + (dragState.curY - u.y)^2) <= 28 then
        hoverTarget = u
      end
    end
    if srcUnit then
      lg.setColor(hoverTarget and Color.hex("#4ade80") or { 1, 0.87, 0.42, 0.78 })
      lg.setLineWidth(2.2)
      lg.line(srcUnit.x, srcUnit.y, dragState.curX, dragState.curY)
      lg.circle("line", hoverTarget and hoverTarget.x or dragState.curX, hoverTarget and hoverTarget.y or dragState.curY, hoverTarget and 24 or 18)
      if hoverTarget then
        lg.setFont(self.fonts.f12)
        lg.printf(t("feedMode"), hoverTarget.x - 50, hoverTarget.y - 42, 100, "center")
      end
      lg.setLineWidth(1)
    end
  end

  for _, p in ipairs(state.projectiles) do
    lg.setColor(p.color)
    if p.kind == "arrow" then
      lg.push()
      lg.translate(p.x, p.y)
      lg.rotate(p.angle or 0)
      lg.setLineWidth(2.5)
      lg.line(-7, 0, 7, 0)
      lg.polygon("fill", 9, 0, 3, -3, 3, 3)
      lg.pop()
      lg.setLineWidth(1)
    else
      lg.circle("fill", p.x, p.y, p.radius)
    end
  end

  for _, v in ipairs(state.vfx) do
    if v.kind ~= "crater" then
      local alpha = math.max(0, v.life / v.maxLife)
      lg.setColor(v.color[1], v.color[2], v.color[3], alpha)
      if v.kind == "particle" then
        lg.rectangle("fill", v.x - v.size / 2, v.y - v.size / 2, v.size, v.size)
      elseif v.kind == "coin_fly" then
        lg.circle("fill", v.x, v.y, 4.5)
        lg.setColor(1, 0.98, 0.8, alpha)
        lg.circle("line", v.x, v.y, 4.5)
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
  end
  lg.setLineWidth(1)

  if state.feedMode then
    local msg = state.feedSacrificeId and t("selectTarget") or t("selectSacrifice")
    lg.setColor(0.12, 0.11, 0.29, 0.92)
    lg.rectangle("fill", A.x + 140, A.y + 34, 580, 32, 8, 8)
    lg.setColor(Color.hex("#818cf8"))
    lg.setLineWidth(2)
    lg.rectangle("line", A.x + 140, A.y + 34, 580, 32, 8, 8)
    lg.setLineWidth(1)
    drawCenteredText(self.fonts.f12, msg .. " - " .. t("feedModeHint"), A.x + 140, A.y + 34, 580, 32, Color.hex("#e0e7ff"))
  end

  if state.bossBannerTimer > 0 then
    lg.setColor(0.62, 0.07, 0.22, 0.9)
    lg.rectangle("fill", A.x + 250, A.y + 72, 360, 36, 8, 8)
    drawCenteredText(self.fonts.f16, t("bossWarning"), A.x + 250, A.y + 72, 360, 36, Color.hex("#fde047"))
  elseif state.waveClearTimer > 0 then
    lg.setColor(0.08, 0.32, 0.20, 0.92)
    lg.rectangle("fill", A.x + 250, A.y + 72, 360, 36, 8, 8)
    drawCenteredText(self.fonts.f15, t("waveCleared") .. tostring(state.waveClearGold) .. "g", A.x + 250, A.y + 72, 360, 36, Color.hex("#fde047"))
  end
end

function Renderer:renderRosterStrip(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local A = Battle.ARENA
  local strip = { x = A.x, y = 638, w = A.w, h = 68 }

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

  local count = #state.roster
  local slotW = math.min(82, math.floor((strip.w - 20 - (count - 1) * 4) / math.max(1, count)))
  for idx, u in ipairs(state.roster) do
    local rx = strip.x + 10 + (idx - 1) * (slotW + 4)
    local ry = strip.y + 8
    local rect = { x = rx, y = ry, w = slotW, h = 52 }
    local isSel = (u.id == state.selectedUnitId)
    local isSac = (u.id == state.feedSacrificeId)

    lg.setColor(isSac and Color.hex("#4c1d24") or (isSel and Color.hex("#2a3457") or (isHover(hoverPos, rect) and Color.hex("#222944") or Color.hex("#121524"))))
    lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
    lg.setLineWidth((isSel or isSac) and 2 or 1)
    lg.setColor(isSac and Color.hex("#fb7185") or (isSel and Color.hex("#ffdf6b") or (u.rarity and u.rarity.color or Color.hex("#334155"))))
    lg.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)
    lg.setLineWidth(1)

    lg.setFont(self.fonts.f11)
    lg.setColor(u.accent)
    lg.printf(i18n:pick(u.name), rx + 2, ry + 5, slotW - 4, "center")

    Sprites.drawTierPips(rx + slotW / 2, ry + 28, u.tier)
    drawHealthBar(rx + 6, ry + 41, slotW - 12, 4, u.hp / u.maxHp, Color.hex("#4ade80"))
    registerHit("unit_card", rect, { unitId = u.id })
  end
end

function Renderer:renderGuideModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.03, 0.04, 0.07, 0.84)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 160, 96, 960, 528, 14, 14)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#60a5fa"))
  lg.rectangle("line", 160, 96, 960, 528, 14, 14)
  lg.setLineWidth(1)
  registerHit("modal_blocker", { x = 160, y = 96, w = 960, h = 528 })

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#93c5fd"))
  lg.printf(t("guideTitle"), 160, 122, 960, "center")
  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#cbd5e1"))
  lg.printf(t("guideSub"), 180, 162, 920, "center")

  for idx, key in ipairs(Symbols.SYMBOL_KEYS) do
    local sym = Symbols.SYMBOLS[key]
    local col = (idx - 1) % 4
    local row = math.floor((idx - 1) / 4)
    local card = { x = 192 + col * 226, y = 204 + row * 172, w = 212, h = 156 }
    lg.setColor(Color.hex("#121524"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 8, 8)
    lg.setColor(sym.color)
    lg.rectangle("line", card.x, card.y, card.w, card.h, 8, 8)

    Sprites.drawSymbolIcon(key, card.x + card.w / 2, card.y + 40, 40)
    lg.setFont(self.fonts.f15)
    lg.setColor(sym.color)
    lg.printf(i18n:pick(sym.name), card.x + 8, card.y + 70, card.w - 16, "center")

    local info = ""
    if sym.unitId and Units.BASE_UNITS[sym.unitId] then
      info = i18n:pick(Units.BASE_UNITS[sym.unitId].traits)
    elseif sym.payoutGold > 0 then
      info = "+" .. sym.payoutGold .. "g"
    end
    lg.setFont(self.fonts.f11)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.printf(info, card.x + 12, card.y + 98, card.w - 24, "center")
  end

  local closeBtn = { x = 540, y = 562, w = 200, h = 44 }
  self:drawButton(closeBtn, t("close"), { hovered = isHover(hoverPos, closeBtn) })
  registerHit("toggle_guide", closeBtn)
end

function Renderer:renderShopModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.03, 0.04, 0.07, 0.84)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#181c2e"))
  lg.rectangle("fill", 160, 100, 960, 520, 14, 14)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#facc15"))
  lg.rectangle("line", 160, 100, 960, 520, 14, 14)
  lg.setLineWidth(1)
  registerHit("modal_blocker", { x = 160, y = 100, w = 960, h = 520 })

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#fde047"))
  lg.printf(t("shopTitle"), 160, 126, 960, "center")

  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#cbd5e1"))
  lg.printf(t("shopSub") .. "  (" .. t("gold") .. ": " .. state.gold .. "g)", 160, 166, 960, "center")

  for idx, upg in ipairs(Upgrades.SHOP_UPGRADES) do
    local col = (idx - 1) % 3
    local row = math.floor((idx - 1) / 3)
    local card = { x = 196 + col * 304, y = 210 + row * 170, w = 284, h = 152 }
    local lvl = state.upgradeLevels[upg.id] or 0
    local maxed = lvl >= upg.maxLevel
    local cost = Upgrades.getCost(upg, lvl)
    local canBuy = (not maxed) and (state.gold >= cost)
    local hov = canBuy and isHover(hoverPos, card)

    lg.setColor(hov and Color.hex("#262d47") or Color.hex("#121524"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(hov and 2.5 or 1.5)
    lg.setColor(maxed and Color.hex("#475569") or (canBuy and upg.color or Color.hex("#334155")))
    lg.rectangle("line", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(1)

    lg.setFont(self.fonts.f15)
    lg.setColor(upg.color)
    lg.print(i18n:pick(upg.name), card.x + 14, card.y + 14)

    lg.setFont(self.fonts.f12)
    lg.setColor(Color.hex("#94a3b8"))
    lg.printf("Lv." .. lvl .. "/" .. upg.maxLevel, card.x, card.y + 16, card.w - 14, "right")

    lg.setFont(self.fonts.f13)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.printf(i18n:pick(upg.desc), card.x + 14, card.y + 48, card.w - 28, "left")

    local priceBtn = { x = card.x + 14, y = card.y + 106, w = card.w - 28, h = 34 }
    self:drawButton(priceBtn, maxed and t("maxed") or (tostring(cost) .. "g"), {
      disabled = not canBuy,
      bg = Color.hex("#1e3a2f"),
      border = upg.color,
      font = self.fonts.f14,
      hovered = hov,
    })
    registerHit("buy_upgrade", card, { upgId = upg.id })
  end

  local closeBtn = { x = 540, y = 558, w = 200, h = 44 }
  self:drawButton(closeBtn, t("close"), {
    bg = Color.hex("#334155"),
    border = Color.hex("#94a3b8"),
    hovered = isHover(hoverPos, closeBtn),
  })
  registerHit("toggle_shop", closeBtn)
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
