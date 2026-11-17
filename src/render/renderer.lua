local Symbols = require("src.data.symbols")
local Waves = require("src.data.waves")
local Units = require("src.data.units")
local Items = require("src.data.items")
local Upgrades = require("src.data.upgrades")
local StateMod = require("src.systems.state")
local Battle = require("src.systems.battle")
local Sprites = require("src.render.sprites")
local PixelArt = require("src.render.pixel_art")
local Color = require("src.utils.color")

local Renderer = {}
Renderer.__index = Renderer

local SLOT_PANEL = { x = 14, y = 70, w = 374, h = 636 }
local REEL_BOX = { x = 28, y = 144, w = 312, h = 186 }
local CELL_W = 94
local CELL_H = 58
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
  local bg = opts.bg or Color.hex("#3b3145")
  local border = opts.border or Color.hex("#69587a")
  local textCol = opts.text or Color.hex("#f8fafc")
  local font = opts.font or self.fonts.f14

  if opts.disabled then
    bg = Color.hex("#211b26")
    border = Color.hex("#382f42")
    textCol = Color.hex("#6b6275")
  elseif opts.active then
    bg = opts.activeBg or Color.hex("#5b4682")
    border = opts.activeBorder or Color.hex("#facc15")
  elseif opts.hovered then
    bg = Color.hex("#4e405c")
    border = Color.hex("#fde047")
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
    lg.setColor(opts.disabled and Color.hex("#574f61") or Color.hex("#fde047"))
    lg.printf(opts.subLabel, rect.x, rect.y + rect.h * 0.5 + 3, rect.w, "center")
  else
    drawCenteredText(font, label, rect.x, rect.y, rect.w, rect.h, textCol)
  end
end

local function drawHealthBar(x, y, w, h, ratio, color, shieldRatio)
  local lg = love.graphics
  local r = math.max(0, math.min(1, ratio))
  lg.setColor(0.05, 0.04, 0.07, 0.9)
  lg.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
  lg.setColor(Color.hex("#2c2533"))
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

  -- Warm dark plum-slate Slotbound UI backdrop
  lg.setColor(Color.hex("#241d2b"))
  lg.rectangle("fill", 0, 0, 1280, 720)

  if state.phase == "menu" then
    self:renderMenu(state, i18n, time, registerHit, hoverPos)
    lg.pop()
    return hitboxes
  end

  self:renderHud(state, i18n, registerHit, hoverPos)
  self:renderSlotPanel(state, i18n, time, registerHit, hoverPos, viewportTransform, shakeX, shakeY)
  self:renderArena(state, i18n, time, registerHit, hoverPos, dragState)
  self:renderBottomBar(state, i18n, registerHit, hoverPos)

  if state.jackpotFlash > 0 then
    lg.setColor(1, 0.87, 0.42, state.jackpotFlash * 0.25)
    lg.rectangle("fill", 0, 0, 1280, 720)
  end

  for _, ft in ipairs(state.floatingTexts) do
    local alpha = math.max(0, math.min(1, ft.life / ft.maxLife))
    lg.setFont(self.fonts.f14)
    lg.setColor(0.05, 0.03, 0.07, alpha)
    lg.printf(ft.text, ft.x - 101, ft.y - 1, 200, "center")
    lg.printf(ft.text, ft.x - 99, ft.y + 1, 200, "center")
    lg.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
    lg.printf(ft.text, ft.x - 100, ft.y, 200, "center")
  end

  local hasModal = state.shopModal or state.guideModal or state.coreModal or state.classModal
    or state.phase == "gameover" or state.phase == "victory"

  if hasModal then
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
  local w = 274
  local h = 68
  local tx = math.min(1265 - w, math.max(15, pos.x + 14))
  local ty = math.min(705 - h, math.max(70, pos.y - 76))
  lg.setColor(0.11, 0.08, 0.14, 0.96)
  lg.rectangle("fill", tx, ty, w, h, 6, 6)
  lg.setColor(tip.color or Color.hex("#f6c945"))
  lg.setLineWidth(1.8)
  lg.rectangle("line", tx, ty, w, h, 6, 6)
  lg.setLineWidth(1)
  lg.setFont(self.fonts.f13)
  lg.print(tip.title, tx + 10, ty + 8)
  lg.setFont(self.fonts.f11)
  lg.setColor(Color.hex("#f1f5f9"))
  lg.printf(tip.body, tx + 10, ty + 28, w - 20, "left")
end

function Renderer:renderMenu(state, i18n, time, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(Color.hex("#32293b"))
  for x = 0, 1280, 48 do lg.line(x, 0, x, 720) end
  for y = 0, 720, 48 do lg.line(0, y, 1280, y) end

  lg.setColor(Color.hex("#e8d8b9"))
  lg.rectangle("fill", 190, 58, 900, 604, 14, 14)
  lg.setLineWidth(4)
  lg.setColor(Color.hex("#6e5332"))
  lg.rectangle("line", 190, 58, 900, 604, 14, 14)
  lg.setLineWidth(1)

  local skull = PixelArt.getWingedSkullImage(false)
  if skull then
    local iw, ih = skull:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(skull, 640, 102, 0, 3.2, 3.2, iw * 0.5, ih * 0.5)
  end

  local demoSymbols = { "shield", "bow", "staff", "horse", "skull", "coin", "jester", "crown" }
  for i, sym in ipairs(demoSymbols) do
    local sx = 310 + (i - 1) * 94
    local sy = 154 + math.sin(time * 3 + i) * 4
    Sprites.drawSymbolIcon(sym, sx, sy, 36)
  end

  lg.setFont(self.fonts.f54)
  lg.setColor(Color.hex("#3b2314"))
  lg.printf(t("title"), 190, 184, 900, "center")

  lg.setFont(self.fonts.f16)
  lg.setColor(Color.hex("#6b4423"))
  lg.printf(t("subtitle"), 190, 242, 900, "center")

  lg.setColor(Color.hex("#2c2333"))
  lg.rectangle("fill", 240, 280, 800, 172, 10, 10)
  lg.setColor(Color.hex("#6e5332"))
  lg.rectangle("line", 240, 280, 800, 172, 10, 10)

  lg.setFont(self.fonts.f15)
  lg.setColor(Color.hex("#fde047"))
  lg.print(t("rulesTitle"), 264, 294)

  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#f1e9da"))
  lg.print(t("rule1"), 264, 322)
  lg.print(t("rule2"), 264, 352)
  lg.print(t("rule3"), 264, 382)
  lg.print(t("rule4"), 264, 412)

  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#5c3d22"))
  lg.printf(t("diffLabel"), 190, 466, 900, "center")
  local diffs = {
    { id = "normal",   label = t("diffNormal"),   color = Color.hex("#22c55e") },
    { id = "hard",     label = t("diffHard"),     color = Color.hex("#d97706") },
    { id = "judgment", label = t("diffJudgment"), color = Color.hex("#e11d48") },
  }
  for idx, d in ipairs(diffs) do
    local dBtn = { x = 385 + (idx - 1) * 176, y = 490, w = 160, h = 36 }
    self:drawButton(dBtn, d.label, {
      active = (state.difficulty == d.id),
      activeBg = Color.hex("#2c2333"),
      activeBorder = d.color,
      bg = Color.hex("#3d3147"),
      border = Color.hex("#69587a"),
      text = d.color,
      font = self.fonts.f13,
      hovered = isHover(hoverPos, dBtn),
    })
    registerHit("set_diff", dBtn, { diff = d.id })
  end

  local startBtn = { x = 490, y = 542, w = 300, h = 60 }
  self:drawButton(startBtn, t("startRun"), {
    bg = Color.hex("#b45309"),
    border = Color.hex("#fde047"),
    text = Color.hex("#ffffff"),
    font = self.fonts.f22,
    hovered = isHover(hoverPos, startBtn),
  })
  registerHit("start_run", startBtn)

  lg.setFont(self.fonts.f12)
  lg.setColor(Color.hex("#6b4423"))
  lg.printf(t("continueHint"), 190, 618, 900, "center")

  local langBtn = { x = 990, y = 80, w = 74, h = 32 }
  self:drawButton(langBtn, t("langToggle"), { hovered = isHover(hoverPos, langBtn) })
  registerHit("toggle_lang", langBtn)
end

function Renderer:renderHud(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(Color.hex("#1d1724"))
  lg.rectangle("fill", 0, 0, 1280, 60)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#453852"))
  lg.line(0, 60, 1280, 60)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f22)
  lg.setColor(Color.hex("#fde047"))
  lg.print("rollKnight", 14, 17)

  local nextBossWave = math.ceil(state.wave / 5) * 5
  local bossDelta = nextBossWave - state.wave
  local bossText = (bossDelta == 0) and (t("bossIn") .. t("bossNow")) or (t("bossIn") .. bossDelta .. t("bossInWaves"))

  local pills = {
    { label = t("gold") .. ": " .. state.gold .. "g", color = Color.hex("#facc15"), x = 138, w = 96 },
    { label = t("hearts") .. ": " .. state.hearts .. "/" .. state.maxHearts, color = Color.hex("#fb7185"), x = 240, w = 96 },
    { label = t("roster") .. ": " .. #state.roster .. "/" .. state.maxRoster, color = Color.hex("#c084fc"), x = 342, w = 92 },
    { label = t("crystals") .. ": " .. state.crystals, color = Color.hex("#38bdf8"), x = 440, w = 88 },
    { label = t("nudges") .. ": " .. state.nudges, color = Color.hex("#4ade80"), x = 534, w = 88 },
    { label = t("wave") .. " " .. state.wave .. "/" .. Waves.MAX_WAVES, color = Color.hex("#e2e8f0"), x = 628, w = 96 },
    { label = bossText, color = (bossDelta == 0) and Color.hex("#fb7185") or Color.hex("#fca5a5"), x = 730, w = 104 },
  }

  for _, p in ipairs(pills) do
    lg.setColor(Color.hex("#2c2334"))
    lg.rectangle("fill", p.x, 13, p.w, 34, 6, 6)
    lg.setColor(Color.hex("#4e405c"))
    lg.rectangle("line", p.x, 13, p.w, 34, 6, 6)
    drawCenteredText(self.fonts.f12, p.label, p.x, 13, p.w, 34, p.color)
  end

  local guideBtn = { x = 844, y = 13, w = 68, h = 34 }
  self:drawButton(guideBtn, t("guideBtn"), {
    active = state.guideModal,
    font = self.fonts.f12,
    hovered = isHover(hoverPos, guideBtn),
  })
  registerHit("toggle_guide", guideBtn)

  local shopBtn = { x = 918, y = 13, w = 82, h = 34 }
  self:drawButton(shopBtn, t("shopBtn"), {
    active = state.shopModal,
    bg = Color.hex("#4a3319"),
    border = Color.hex("#facc15"),
    font = self.fonts.f12,
    hovered = isHover(hoverPos, shopBtn),
  })
  registerHit("toggle_shop", shopBtn)

  local speedBtn = { x = 1006, y = 13, w = 74, h = 34 }
  self:drawButton(speedBtn, state.fastForward and "2x" or "1x", {
    active = state.fastForward,
    font = self.fonts.f12,
    hovered = isHover(hoverPos, speedBtn),
  })
  registerHit("toggle_speed", speedBtn)

  local pauseBtn = { x = 1086, y = 13, w = 62, h = 34 }
  self:drawButton(pauseBtn, state.paused and t("resume") or t("pause"), {
    active = state.paused,
    font = self.fonts.f12,
    hovered = isHover(hoverPos, pauseBtn),
  })
  registerHit("toggle_pause", pauseBtn)

  local muteBtn = { x = 1154, y = 13, w = 54, h = 34 }
  self:drawButton(muteBtn, state.audio.muted and t("unmute") or t("mute"), {
    active = state.audio.muted,
    font = self.fonts.f11,
    hovered = isHover(hoverPos, muteBtn),
  })
  registerHit("toggle_mute", muteBtn)

  local langBtn = { x = 1214, y = 13, w = 52, h = 34 }
  self:drawButton(langBtn, t("langToggle"), { font = self.fonts.f12, hovered = isHover(hoverPos, langBtn) })
  registerHit("toggle_lang", langBtn)
end

function Renderer:renderSlotPanel(state, i18n, time, registerHit, hoverPos, vp, shakeX, shakeY)
  shakeX = shakeX or 0
  shakeY = shakeY or 0
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local isBoss = state.wavePlan and state.wavePlan.isBossWave
  local pityReady = state:isPitySpinReady()

  local skullCenterX = REEL_BOX.x + REEL_BOX.w * 0.5
  local modalBlocked = (state.coreModal ~= nil) or (state.classModal ~= nil) or (state.shopModal == true) or (state.guideModal == true)
  local canNudge = (not state.slot.spinning) and (state.nudges > 0) and (not modalBlocked)

  -- Vertical silver chain links behind top crest
  for cy = SLOT_PANEL.y - 6, SLOT_PANEL.y + 22, 6 do
    for _, lx in ipairs({ skullCenterX - 58, skullCenterX + 52 }) do
      lg.setColor(Color.hex("#1c1321"))
      lg.rectangle("fill", lx - 1, cy - 1, 7, 6)
      lg.setColor(((cy / 6) % 2 == 0) and Color.hex("#cbd5e1") or Color.hex("#64748b"))
      lg.rectangle("fill", lx, cy, 5, 4)
    end
  end

  -- Dark plum-brown mechanical Slot Machine housing (matching Slotbound!)
  lg.setColor(Color.hex("#3a2b3d"))
  lg.rectangle("fill", SLOT_PANEL.x, SLOT_PANEL.y + 22, SLOT_PANEL.w, SLOT_PANEL.h - 22, 8, 8)
  lg.setLineWidth(3)
  lg.setColor(pityReady and Color.hex("#facc15") or Color.hex("#1c1321"))
  lg.rectangle("line", SLOT_PANEL.x, SLOT_PANEL.y + 22, SLOT_PANEL.w, SLOT_PANEL.h - 22, 8, 8)
  lg.setLineWidth(1.5)
  lg.setColor(Color.hex("#523e57"))
  lg.rectangle("line", SLOT_PANEL.x + 3, SLOT_PANEL.y + 25, SLOT_PANEL.w - 6, SLOT_PANEL.h - 28, 6, 6)
  lg.setLineWidth(1)

  -- Horizontal dark-crimson top roller beam with iron straps under crest
  local beamX, beamY, beamW = REEL_BOX.x - 4, SLOT_PANEL.y + 20, REEL_BOX.w + 8
  lg.setColor(Color.hex("#1c1321"))
  lg.rectangle("fill", beamX - 2, beamY - 2, beamW + 4, 14, 3, 3)
  lg.setColor(Color.hex("#6b1d2f"))
  lg.rectangle("fill", beamX, beamY, beamW, 10, 2, 2)
  lg.setColor(Color.hex("#8c2d42"))
  lg.rectangle("fill", beamX + 2, beamY + 1, beamW - 4, 3)
  for _, sxStrap in ipairs({ beamX + 18, beamX + beamW - 26 }) do
    lg.setColor(Color.hex("#3b3245"))
    lg.rectangle("fill", sxStrap, beamY - 2, 8, 14)
    lg.setColor(Color.hex("#64748b"))
    lg.rectangle("fill", sxStrap + 2, beamY, 4, 3)
  end

  -- Small diagonal rope lashings on left & right frame edges
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#cbd5e1"))
  for _, ryLash in ipairs({ 178, 266 }) do
    lg.line(REEL_BOX.x - 10, ryLash, REEL_BOX.x - 2, ryLash + 6)
    lg.line(REEL_BOX.x - 10, ryLash + 7, REEL_BOX.x - 2, ryLash + 13)
    lg.line(REEL_BOX.x + REEL_BOX.w + 2, ryLash, REEL_BOX.x + REEL_BOX.w + 10, ryLash + 6)
  end
  lg.setLineWidth(1)

  -- Winged Horned Demon Skull Crest centered at top
  local skull = PixelArt.getWingedSkullImage(isBoss)
  if skull then
    local iw, ih = skull:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(skull, math.floor(skullCenterX), SLOT_PANEL.y + 18, 0, 3, 3, math.floor(iw * 0.5), math.floor(ih * 0.5))
  end

  -- Slot Header Row: Keyhole/Nudge Pill | Center Spin Cost Tab | Open-Book Collection Button
  local keyPill = { x = REEL_BOX.x + 4, y = 98, w = 64, h = 24 }
  lg.setColor(Color.hex("#2b1e30"))
  lg.rectangle("fill", keyPill.x, keyPill.y, keyPill.w, keyPill.h, 5, 5)
  lg.setColor(Color.hex("#57415d"))
  lg.rectangle("line", keyPill.x, keyPill.y, keyPill.w, keyPill.h, 5, 5)
  -- Pixel keyhole icon on left
  lg.setColor(Color.hex("#94a3b8"))
  lg.circle("fill", keyPill.x + 15, keyPill.y + 9, 4)
  lg.rectangle("fill", keyPill.x + 13, keyPill.y + 11, 4, 7)
  drawCenteredText(self.fonts.f13, tostring(state.nudges), keyPill.x + 24, keyPill.y, keyPill.w - 28, keyPill.h, Color.hex("#f8fafc"))

  local spinCost = state:currentSpinCost()
  local costTab = { x = skullCenterX - 38, y = 104, w = 76, h = 24 }
  lg.setColor(Color.hex("#1d1422"))
  lg.rectangle("fill", costTab.x, costTab.y, costTab.w, costTab.h, 4, 4)
  lg.setColor(Color.hex("#57415d"))
  lg.rectangle("line", costTab.x, costTab.y, costTab.w, costTab.h, 4, 4)
  local costStr = pityReady and "WILD" or ((spinCost == 0) and t("free") or tostring(spinCost))
  drawCenteredText(self.fonts.f14, costStr, costTab.x, costTab.y, costTab.w, costTab.h, Color.hex("#fde047"))

  local bookBtn = { x = REEL_BOX.x + REEL_BOX.w - 46, y = 96, w = 42, h = 28 }
  local bookHov = isHover(hoverPos, bookBtn)
  lg.setColor(bookHov and Color.hex("#4e405c") or Color.hex("#2b1e30"))
  lg.rectangle("fill", bookBtn.x, bookBtn.y, bookBtn.w, bookBtn.h, 5, 5)
  lg.setColor(bookHov and Color.hex("#fde047") or Color.hex("#57415d"))
  lg.rectangle("line", bookBtn.x, bookBtn.y, bookBtn.w, bookBtn.h, 5, 5)
  local bookImg = PixelArt.getOpenBookImage()
  if bookImg then
    local bw, bh = bookImg:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(bookImg, math.floor(bookBtn.x + bookBtn.w * 0.5), math.floor(bookBtn.y + bookBtn.h * 0.5), 0, 2, 2, math.floor(bw * 0.5), math.floor(bh * 0.5))
  end
  registerHit("toggle_guide", bookBtn)

  -- Nudge UP strip (compact pixel arrow buttons)
  for col = 1, 3 do
    local cx = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
    local upRect = { x = cx, y = 128, w = CELL_W, h = 16 }
    local hintUp = canNudge and state.slot:wouldNudgeMatch(col, 1)
    self:drawButton(upRect, hintUp and "* ^ *" or "^", {
      disabled = not canNudge,
      bg = hintUp and Color.hex("#2b4a26") or Color.hex("#2b1e30"),
      border = hintUp and Color.hex("#facc15") or Color.hex("#57415d"),
      text = hintUp and Color.hex("#fef08a") or Color.hex("#cbd5e1"),
      font = self.fonts.f11,
      hovered = isHover(hoverPos, upRect),
    })
    registerHit("nudge", upRect, { col = col, dir = 1 })
  end

  -- Dark ink Reel Housing Window
  lg.setColor(Color.hex("#1b1320"))
  lg.rectangle("fill", REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 6, 6)
  lg.setLineWidth(3)
  lg.setColor(pityReady and Color.hex("#fde047") or Color.hex("#1c1321"))
  lg.rectangle("line", REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 6, 6)
  lg.setLineWidth(1)

  -- L-Shaped Silver Pipe Lever with Large Dark-Crimson Sphere Knob
  local leverRect = { x = REEL_BOX.x + REEL_BOX.w + 4, y = REEL_BOX.y + 4, w = 32, h = 176 }
  local pull = state.slot.leverPull or 0
  local knobY = leverRect.y + 34 + pull * 108
  local baseY = REEL_BOX.y + REEL_BOX.h - 32
  local pipeX = leverRect.x + 15
  -- Socket housing on right wall of Reel Box
  lg.setColor(Color.hex("#1b1320"))
  lg.rectangle("fill", REEL_BOX.x + REEL_BOX.w - 1, baseY - 12, 12, 24, 3, 3)
  lg.setColor(Color.hex("#473b54"))
  lg.rectangle("fill", REEL_BOX.x + REEL_BOX.w + 1, baseY - 9, 8, 18, 2, 2)
  -- Silver L-pipe (horizontal stem + vertical arm)
  lg.setColor(Color.hex("#1b1320"))
  lg.rectangle("fill", REEL_BOX.x + REEL_BOX.w + 3, baseY - 5, (pipeX - (REEL_BOX.x + REEL_BOX.w + 3)) + 5, 10)
  lg.rectangle("fill", pipeX - 5, math.min(baseY, knobY), 10, math.abs(baseY - knobY) + 5)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.rectangle("fill", REEL_BOX.x + REEL_BOX.w + 4, baseY - 3, (pipeX - (REEL_BOX.x + REEL_BOX.w + 4)) + 3, 4)
  lg.rectangle("fill", pipeX - 3, math.min(baseY, knobY), 4, math.abs(baseY - knobY) + 3)
  lg.setColor(Color.hex("#94a3b8"))
  lg.rectangle("fill", REEL_BOX.x + REEL_BOX.w + 4, baseY + 1, (pipeX - (REEL_BOX.x + REEL_BOX.w + 4)) + 3, 2)
  lg.rectangle("fill", pipeX + 1, math.min(baseY, knobY), 2, math.abs(baseY - knobY) + 3)
  -- Large dark-crimson sphere knob
  local knobHover = isHover(hoverPos, leverRect) and state:canSpin()
  lg.setColor(Color.hex("#1b1320"))
  lg.circle("fill", pipeX, knobY, 14)
  lg.setColor(state:canSpin() and Color.hex("#881337") or Color.hex("#473b54"))
  lg.circle("fill", pipeX, knobY, 12)
  lg.setColor(state:canSpin() and (knobHover and Color.hex("#f43f5e") or Color.hex("#be123c")) or Color.hex("#5c4f69"))
  lg.circle("fill", pipeX - 1, knobY - 1, 9)
  lg.setColor(state:canSpin() and Color.hex("#fda4af") or Color.hex("#94a3b8"))
  lg.circle("fill", pipeX - 4, knobY - 4, 3)
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
    local shiftPx = isSpinning and (state.slot.reelVisualShift[col] * (CELL_H + 3)) or 0
    local bouncePx = (not isSpinning) and (math.sin(state.slot.reelBounce[col] * math.pi) * 6) or 0
    local startRow = isSpinning and 0 or 1
    local stripX = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)

    -- Continuous vertical parchment-gray paper drum strip
    lg.setColor(Color.hex("#d5d0c8"))
    lg.rectangle("fill", stripX, REEL_BOX.y + 4, CELL_W, REEL_BOX.h - 8)

    for row = startRow, 3 do
      local cellY = REEL_BOX.y + 6 + (row - 1) * (CELL_H + 3) + shiftPx + bouncePx
      local isMatch = (not state.slot.spinning) and (row >= 1) and matchedSet[col .. "," .. row]

      if isMatch then
        lg.setColor(Color.hex("#fef08a", 0.78))
        lg.rectangle("fill", stripX + 4, cellY + 2, CELL_W - 8, CELL_H - 4, 6, 6)
      end

      local symId = state.slot:getSymbolAt(col, row - 1)
      Sprites.drawSymbolIcon(symId, stripX + CELL_W / 2, cellY + CELL_H / 2, 44)
    end

    -- Multi-step top & bottom curved cylinder shading + horizontal seam lines
    lg.setColor(Color.hex("#857f78"))
    lg.rectangle("fill", stripX, REEL_BOX.y + 4, CELL_W, 5)
    lg.rectangle("fill", stripX, REEL_BOX.y + REEL_BOX.h - 9, CELL_W, 5)
    lg.setColor(Color.hex("#aba59d"))
    lg.rectangle("fill", stripX, REEL_BOX.y + 9, CELL_W, 6)
    lg.rectangle("fill", stripX, REEL_BOX.y + REEL_BOX.h - 15, CELL_W, 6)
    lg.setColor(0, 0, 0, 0.28)
    lg.rectangle("fill", stripX, REEL_BOX.y + 4, CELL_W, 4)
    lg.rectangle("fill", stripX, REEL_BOX.y + REEL_BOX.h - 8, CELL_W, 4)
    lg.setColor(Color.hex("#59432d", 0.55))
    lg.line(stripX, REEL_BOX.y + 15, stripX + CELL_W, REEL_BOX.y + 15)
    lg.line(stripX, REEL_BOX.y + REEL_BOX.h - 16, stripX + CELL_W, REEL_BOX.y + REEL_BOX.h - 16)
  end

  -- Crisp 3px dark #1b1320 column dividers between the 3 paper drums
  lg.setColor(Color.hex("#1b1320"))
  for c = 1, 2 do
    local divX = REEL_BOX.x + 6 + c * CELL_W + (c - 0.5) * CELL_GAP - 2
    lg.rectangle("fill", divX, REEL_BOX.y + 4, 4, REEL_BOX.h - 8)
  end

  lg.setScissor()

  if not state.slot.spinning and #state.slot.activeMatches > 0 then
    lg.setLineWidth(3.5)
    for _, m in ipairs(state.slot.activeMatches) do
      local pts = {}
      for _, cell in ipairs(m.cells) do
        pts[#pts + 1] = REEL_BOX.x + 6 + (cell[1] - 1) * (CELL_W + CELL_GAP) + CELL_W / 2
        pts[#pts + 1] = REEL_BOX.y + 6 + (cell[2] - 1) * (CELL_H + 3) + CELL_H / 2
      end
      lg.setColor(m.isPureJackpot and Color.hex("#f59e0b") or Color.hex("#d97706", 0.85))
      lg.line(pts)
    end
    lg.setLineWidth(1)
  end

  -- Nudge DOWN strip + dark crimson bottom beam & skull lockbox plate
  lg.setColor(Color.hex("#6b1d2f"))
  lg.rectangle("fill", beamX, 344, beamW, 12, 3, 3)
  for col = 1, 3 do
    local cx = REEL_BOX.x + 6 + (col - 1) * (CELL_W + CELL_GAP)
    local dnRect = { x = cx, y = 330, w = CELL_W, h = 14 }
    local hintDn = canNudge and state.slot:wouldNudgeMatch(col, -1)
    self:drawButton(dnRect, hintDn and "* v *" or "v", {
      disabled = not canNudge,
      bg = hintDn and Color.hex("#2b4a26") or Color.hex("#2b1e30"),
      border = hintDn and Color.hex("#facc15") or Color.hex("#57415d"),
      text = hintDn and Color.hex("#fef08a") or Color.hex("#cbd5e1"),
      font = self.fonts.f11,
      hovered = isHover(hoverPos, dnRect),
    })
    registerHit("nudge", dnRect, { col = col, dir = -1 })
  end
  -- Small iron skull-plate lockbox ornament below middle column
  local lockBox = { x = skullCenterX - 24, y = 344, w = 48, h = 16 }
  lg.setColor(Color.hex("#1c1321"))
  lg.rectangle("fill", lockBox.x - 2, lockBox.y - 2, lockBox.w + 4, lockBox.h + 4, 3, 3)
  lg.setColor(Color.hex("#473b54"))
  lg.rectangle("fill", lockBox.x, lockBox.y, lockBox.w, lockBox.h, 2, 2)
  lg.setColor(Color.hex("#1b1320"))
  lg.circle("fill", skullCenterX, lockBox.y + 7, 4.5)
  lg.rectangle("fill", skullCenterX - 3, lockBox.y + 10, 6, 4)
  lg.setColor(Color.hex("#64748b"))
  lg.rectangle("fill", skullCenterX - 2, lockBox.y + 6, 1, 2)
  lg.rectangle("fill", skullCenterX + 1, lockBox.y + 6, 1, 2)

  -- Luck / Pity Meter Bar
  local pityRect = { x = 28, y = 364, w = 346, h = 18 }
  lg.setColor(Color.hex("#1b1521"))
  lg.rectangle("fill", pityRect.x, pityRect.y, pityRect.w, pityRect.h, 4, 4)
  local frac = state.pityCharge / StateMod.MAX_PITY
  lg.setColor(pityReady and Color.hex("#eab308") or Color.hex("#7c3aed"))
  lg.rectangle("fill", pityRect.x + 2, pityRect.y + 2, (pityRect.w - 4) * frac, pityRect.h - 4, 3, 3)
  lg.setColor(pityReady and Color.hex("#fde047") or Color.hex("#4e405c"))
  lg.rectangle("line", pityRect.x, pityRect.y, pityRect.w, pityRect.h, 4, 4)
  local pityTxt = pityReady and t("pityReady") or (t("pityLabel") .. ": " .. state.pityCharge .. "/" .. StateMod.MAX_PITY)
  drawCenteredText(self.fonts.f11, pityTxt, pityRect.x, pityRect.y, pityRect.w, pityRect.h, Color.hex("#f8fafc"))

  local spinCost = state:currentSpinCost()
  local spinRect = { x = 28, y = 388, w = 168, h = 46 }
  self:drawButton(spinRect, state.slot.spinning and t("spinning") or t("spin"), {
    disabled = not state:canSpin(),
    bg = pityReady and Color.hex("#ca8a04") or Color.hex("#b45309"),
    border = Color.hex("#fbbf24"),
    subLabel = pityReady and t("guaranteedWild") or ((spinCost == 0) and t("free") or (tostring(spinCost) .. "g")),
    font = self.fonts.f15,
    hovered = isHover(hoverPos, spinRect),
  })
  registerHit("spin", spinRect)

  local fightRect = { x = 204, y = 388, w = 170, h = 46 }
  local inBattle = (state.phase == "battle")
  local fightDisabled = inBattle or modalBlocked
  local fightPulse = (not fightDisabled) and (0.5 + 0.5 * math.sin(time * 4.5)) or 0
  self:drawButton(fightRect, inBattle and t("inBattle") or t("startWave"), {
    disabled = fightDisabled,
    bg = Color.hex("#16a34a"),
    border = (fightPulse > 0.5) and Color.hex("#bbf7d0") or Color.hex("#86efac"),
    font = self.fonts.f15,
    hovered = isHover(hoverPos, fightRect),
  })
  if not fightDisabled then
    lg.setColor(0.53, 0.94, 0.67, 0.25 + fightPulse * 0.35)
    lg.setLineWidth(2)
    lg.rectangle("line", fightRect.x - 2, fightRect.y - 2, fightRect.w + 4, fightRect.h + 4, 8, 8)
    lg.setLineWidth(1)
  end
  registerHit("start_wave", fightRect)

  -- Selected Unit Inspector (Compact with Unit Portrait)
  local sel = nil
  for _, u in ipairs(state.roster) do
    if u.id == state.selectedUnitId then sel = u; break end
  end
  if not sel then sel = state.roster[1] end

  local card = { x = 28, y = 442, w = 346, h = 148 }
  lg.setColor(Color.hex("#1d1724"))
  lg.rectangle("fill", card.x, card.y, card.w, card.h, 8, 8)
  lg.setColor(sel and sel.rarity and sel.rarity.color or Color.hex("#4e405c"))
  lg.rectangle("line", card.x, card.y, card.w, card.h, 8, 8)

  if sel then
    -- 48x48 Recessed Portrait Box
    local pBox = { x = card.x + 10, y = card.y + 10, w = 48, h = 48 }
    lg.setColor(Color.hex("#140f19"))
    lg.rectangle("fill", pBox.x, pBox.y, pBox.w, pBox.h, 6, 6)
    lg.setColor(sel.rarity and sel.rarity.color or Color.hex("#594969"))
    lg.rectangle("line", pBox.x, pBox.y, pBox.w, pBox.h, 6, 6)
    local pImg = PixelArt.getUnitImage(sel)
    if pImg then
      local iw, ih = pImg:getDimensions()
      lg.setColor(1, 1, 1, 1)
      lg.draw(pImg, math.floor(pBox.x + pBox.w * 0.5), math.floor(pBox.y + pBox.h * 0.52), 0, 2, 2, math.floor(iw * 0.5), math.floor(ih * 0.5))
    end
    Sprites.drawTierPips(pBox.x + pBox.w * 0.5, pBox.y + 6, sel.tier or 1)

    local infoX = card.x + 66
    local rarName = sel.rarity and i18n:pick(sel.rarity.name) or ""
    local famName = (sel.family and Units.FAMILIES[sel.family]) and i18n:pick(Units.FAMILIES[sel.family].name) or ""
    lg.setFont(self.fonts.f13)
    lg.setColor(sel.accent)
    lg.printf("[" .. rarName .. "] " .. i18n:pick(sel.name) .. " (" .. sel.tier .. "*)", infoX, card.y + 8, 198, "left")

    local needed = Units.xpNeededForTier(sel.tier)
    local xpTxt = (sel.tier >= 3) and t("paragonLabel") or (t("xpLabel") .. " " .. sel.xp .. "/" .. needed)
    lg.setFont(self.fonts.f11)
    lg.setColor(sel.tier >= 3 and Color.hex("#fde047") or Color.hex("#cbd5e1"))
    lg.printf(xpTxt, infoX + 186, card.y + 10, card.w - 262, "right")

    lg.setFont(self.fonts.f12)
    lg.setColor(Color.hex("#cbd5e1"))
    local bonusTxt = sel.bonusTrait and (" | " .. i18n:pick(sel.bonusTrait)) or ""
    lg.print(famName .. bonusTxt .. " | " .. t("kills") .. ": " .. (sel.kills or 0), infoX, card.y + 27)

    lg.setColor(Color.hex("#f8fafc"))
    lg.print(
      t("hp") .. ":" .. math.floor(sel.hp + 0.5) .. "/" .. sel.maxHp .. "  " .. t("atk") .. ":" .. sel.atk .. "  " .. t("aspd") .. ":" .. sel.aspd,
      infoX,
      card.y + 44
    )

    local skillTxt = sel.activeSkill and (i18n:pick(sel.activeSkill.name) .. " (" .. sel.activeSkill.cooldown .. "s): " .. i18n:pick(sel.activeSkill.desc)) or i18n:pick(sel.traits)
    lg.setFont(self.fonts.f11)
    lg.setColor(Color.hex("#fde68a"))
    lg.printf(skillTxt, card.x + 10, card.y + 66, card.w - 20, "left")

    local feedBtn = { x = card.x + 10, y = card.y + 108, w = 176, h = 32 }
    self:drawButton(feedBtn, state.feedMode and t("cancelFeed") or t("feedMode"), {
      active = state.feedMode,
      disabled = (#state.roster < 2) or modalBlocked,
      bg = Color.hex("#4c1d95"),
      border = Color.hex("#a78bfa"),
      font = self.fonts.f12,
      hovered = isHover(hoverPos, feedBtn),
    })
    registerHit("toggle_feed", feedBtn)

    local sellGain = math.floor((sel.sellGold or 6) * sel.tier + 0.5)
    local dismissBtn = { x = card.x + 194, y = card.y + 108, w = 142, h = 32 }
    self:drawButton(dismissBtn, t("dismissUnit") .. " +" .. sellGain .. "g", {
      disabled = (#state.roster <= 1) or state.waveActive,
      bg = Color.hex("#4c1d24"),
      border = Color.hex("#fb7185"),
      font = self.fonts.f12,
      hovered = isHover(hoverPos, dismissBtn),
    })
    registerHit("dismiss_unit", dismissBtn, { unitId = sel.id })
  end

  -- Items Tray (Bottom-Left under Slot Machine, always renders all 8 sockets!)
  local tray = { x = 28, y = 598, w = 346, h = 98 }
  lg.setColor(Color.hex("#1d1724"))
  lg.rectangle("fill", tray.x, tray.y, tray.w, tray.h, 8, 8)
  lg.setColor(Color.hex("#4e405c"))
  lg.rectangle("line", tray.x, tray.y, tray.w, tray.h, 8, 8)

  lg.setFont(self.fonts.f11)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.print(t("itemsTray") .. " (" .. #state.items .. "/" .. state.maxItems .. ")", tray.x + 10, tray.y + 6)
  if #state.items == 0 then
    lg.setColor(Color.hex("#857a94"))
    lg.printf(t("noItems"), tray.x + 105, tray.y + 6, tray.w - 115, "right")
  end

  for idx = 1, state.maxItems do
    local col = (idx - 1) % 4
    local row = math.floor((idx - 1) / 4)
    local ix = tray.x + 10 + col * 83
    local iy = tray.y + 24 + row * 34
    local iRect = { x = ix, y = iy, w = 77, h = 30 }
    local item = state.items[idx]
    if item then
      local isActive = (item.kind == "active_slot" or item.kind == "active_battle")
      local canUse = isActive and (item.usesLeft > 0)
      local hov = isHover(hoverPos, iRect)
      lg.setColor(hov and Color.hex("#3f334d") or Color.hex("#2b2236"))
      lg.rectangle("fill", ix, iy, 77, 30, 5, 5)
      lg.setLineWidth(canUse and 2 or 1.2)
      lg.setColor(canUse and Color.hex("#fde047") or item.color)
      lg.rectangle("line", ix, iy, 77, 30, 5, 5)
      lg.setLineWidth(1)
      local lbl = item.badge .. (isActive and (" " .. item.usesLeft) or "")
      drawCenteredText(self.fonts.f11, lbl, ix, iy, 77, 30, item.color)
      if isActive then
        registerHit("use_item", iRect, { index = idx })
      end
      if hov then
        local extra = isActive and (" [" .. (canUse and t("useNow") or t("usedUp")) .. "]") or ""
        self.tooltip = { title = i18n:pick(item.name) .. extra, body = i18n:pick(item.desc), color = item.color }
      end
    else
      lg.setColor(Color.hex("#140f19"))
      lg.rectangle("fill", ix, iy, 77, 30, 5, 5)
      lg.setColor(Color.hex("#362c42"))
      lg.rectangle("line", ix, iy, 77, 30, 5, 5)
    end
  end
end

function Renderer:renderArena(state, i18n, time, registerHit, hoverPos, dragState)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local A = Battle.ARENA

  -- Outer Warm Torn-Edge Parchment Scroll Frame
  lg.setColor(Color.hex("#e6d5b8"))
  lg.rectangle("fill", A.x - 10, A.y - 10, A.w + 20, A.h + 20, 8, 8)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#6e5332"))
  lg.rectangle("line", A.x - 10, A.y - 10, A.w + 20, A.h + 20, 8, 8)
  lg.setLineWidth(1)

  -- Dynamic Side-View Chunky Pixel-Art Biome (Meadow -> Cave -> Canyon -> Ruins)
  local biomeId = PixelArt.getBiomeForWave(state.wave)
  local biomeImg = PixelArt.getBiomeCanvas(biomeId, A.w, A.h)
  if biomeImg then
    local bw, bh = biomeImg:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(biomeImg, A.x, A.y, 0, A.w / bw, A.h / bh)
  else
    lg.setColor(Color.hex("#2d6a4f"))
    lg.rectangle("fill", A.x, A.y, A.w, A.h)
  end
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#5c4428"))
  lg.rectangle("line", A.x, A.y, A.w, A.h)
  lg.setLineWidth(1)

  -- Top Synergy Pills inside top-left of parchment
  local synX = A.x + 8
  local synY = A.y + 8
  local famOrder = { "ironbound", "sylvan", "arcane", "undead", "royal" }
  for _, famId in ipairs(famOrder) do
    local fam = Units.FAMILIES[famId]
    local cnt = (state.synergies and state.synergies.counts and state.synergies.counts[famId]) or 0
    local active = cnt >= fam.threshold
    local sRect = { x = synX, y = synY, w = 88, h = 22 }
    local hov = isHover(hoverPos, sRect)
    lg.setColor(active and Color.hex("#241d2b", 0.92) or Color.hex("#1b1521", 0.72))
    lg.rectangle("fill", synX, synY, 88, 22, 4, 4)
    lg.setColor(active and fam.color or Color.hex("#574b63"))
    lg.rectangle("line", synX, synY, 88, 22, 4, 4)
    drawCenteredText(self.fonts.f11, i18n:pick(fam.name) .. " " .. cnt .. "/" .. fam.threshold, synX, synY, 88, 22, active and fam.color or Color.hex("#cbd5e1"))
    if hov then
      self.tooltip = { title = i18n:pick(fam.name), body = i18n:pick(fam.bonusDesc), color = fam.color }
    end
    synX = synX + 92
  end

  -- Wave Progress Ribbon (Top-Right inside biome)
  local rw = 260
  local rx = A.x + A.w - rw - 10
  lg.setColor(Color.hex("#2b2135", 0.92))
  lg.rectangle("fill", rx, synY, rw, 24, 5, 5)
  lg.setColor(Color.hex("#a48253"))
  lg.rectangle("line", rx, synY, rw, 24, 5, 5)
  for offset = -1, 2 do
    local wNum = state.wave + offset
    if wNum >= 1 and wNum <= Waves.MAX_WAVES then
      local bx = rx + 8 + (offset + 1) * 62
      local isCur = (offset == 0)
      local isBossW = (wNum % 5 == 0)
      lg.setColor(isCur and Color.hex("#b45309") or (isBossW and Color.hex("#7f1d1d") or Color.hex("#3b3047")))
      lg.rectangle("fill", bx, synY + 3, 56, 18, 4, 4)
      local lbl = isBossW and ("B" .. wNum) or ("W" .. wNum)
      drawCenteredText(self.fonts.f11, lbl, bx, synY + 3, 56, 18, isCur and Color.hex("#fef08a") or Color.hex("#e2e8f0"))
    end
  end

  -- Pixel-Art Two-Story Watchtower Portal on left edge (matching Slotbound!)
  local towerImg = PixelArt.getWatchtowerImage()
  if towerImg then
    local tw, th = towerImg:getDimensions()
    lg.setColor(0, 0, 0, 0.35)
    lg.ellipse("fill", A.x + 48, A.minY + 124, 42, 11)
    lg.setColor(1, 1, 1, 1)
    lg.draw(towerImg, A.x + 8, A.minY + 124 - th * 4, 0, 4, 4)
  end
  -- Glowing summoning rune circle at the tower gate
  lg.setColor(0.55, 0.36, 0.96, 0.28 + math.sin(time * 3) * 0.1)
  lg.ellipse("fill", A.castleX + 40, A.minY + 132, 26, 10)
  lg.setColor(Color.hex("#a855f7"))
  lg.ellipse("line", A.castleX + 40, A.minY + 132, 26, 10)

  -- Subtle left-half deployment divider before wave starts (matching Slotbound)
  if not state.waveActive then
    local midX = A.deployMaxX
    for dy = A.minY, A.maxY - 12, 18 do
      lg.setColor(1, 0.96, 0.78, (dragState and dragState.active) and 0.78 or 0.32)
      lg.rectangle("fill", midX - 1, dy, 2, 10)
    end
  end

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
    lg.setColor(1, 0.31, 0.12, 0.2)
    lg.circle("fill", m.x, m.y, m.radius * m.progress)
    lg.setColor(1, 0.39, 0.20, 0.9)
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
  local activeBoss = nil
  for _, e in ipairs(state.enemies) do
    renderList[#renderList + 1] = { kind = "enemy", y = e.y, obj = e }
    if e.isBoss and e.hp > 0 then activeBoss = e end
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
      drawHealthBar(u.x - 14, u.y + (u.spriteTop or -24) - 5, 28, 4, u.hp / u.maxHp, Color.hex("#4ade80"), shieldRatio)

      if not u.isSummon then
        registerHit("unit_arena", { x = u.x - 20, y = u.y - 20, w = 40, h = 40 }, { unitId = u.id })
      end
    else
      local e = item.obj
      Sprites.drawEnemySprite(e, time)
      local bw = e.isBoss and 56 or 28
      drawHealthBar(e.x - bw / 2, e.y + (e.spriteTop or -(e.radius + 10)) - 6, bw, e.isBoss and 6 or 4, e.hp / e.maxHp, Color.hex("#fb7185"))
    end
  end

  -- Centered Crimson Boss HP Bar (matching Slotbound screenshot #1/#2!)
  if activeBoss then
    local bw, bh = 380, 18
    local bx, by = A.x + (A.w - bw) / 2, A.y + 42
    lg.setColor(Color.hex("#1b1521", 0.92))
    lg.rectangle("fill", bx - 2, by - 2, bw + 4, bh + 4, 4, 4)
    lg.setColor(Color.hex("#dc2626"))
    lg.rectangle("fill", bx, by, bw * math.max(0, activeBoss.hp / activeBoss.maxHp), bh, 3, 3)
    lg.setColor(Color.hex("#facc15"))
    lg.rectangle("line", bx - 2, by - 2, bw + 4, bh + 4, 4, 4)
    drawCenteredText(self.fonts.f12, i18n:pick(activeBoss.name) .. "  " .. math.floor(activeBoss.hp) .. "/" .. activeBoss.maxHp, bx, by, bw, bh, Color.hex("#ffffff"))
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
      -- Highlight Left-Half Deploy Zone & dim non-deployable Right Half
      local rightX = A.deployMaxX
      lg.setColor(0.08, 0.05, 0.10, 0.32)
      lg.rectangle("fill", rightX, A.minY - 6, (A.x + A.w) - rightX, A.maxY - A.minY + 12)
      lg.setColor(0.28, 0.87, 0.50, 0.10)
      lg.rectangle("fill", A.castleX + 34, A.minY + 6, A.deployMaxX - (A.castleX + 34), A.maxY - A.minY - 12)
      lg.setColor(Color.hex("#4ade80", 0.72))
      lg.rectangle("line", A.castleX + 34, A.minY + 6, A.deployMaxX - (A.castleX + 34), A.maxY - A.minY - 12)
      lg.setFont(self.fonts.f11)
      lg.setColor(Color.hex("#dcfce7"))
      lg.print(t("deployZone"), A.castleX + 42, A.minY - 16)

      local outOfLeftZone = (dragState.curX > A.deployMaxX)
      local clampX = math.max(A.castleX + 34, math.min(A.deployMaxX, dragState.curX))
      local clampY = math.max(A.minY + 10, math.min(A.maxY - 10, dragState.curY))
      local destX = hoverTarget and hoverTarget.x or clampX
      local destY = hoverTarget and hoverTarget.y or clampY

      lg.setColor(hoverTarget and Color.hex("#4ade80") or (outOfLeftZone and Color.hex("#fb7185") or { 1, 0.87, 0.42, 0.88 }))
      lg.setLineWidth(2.2)
      lg.line(srcUnit.x, srcUnit.y, destX, destY)
      lg.circle("line", destX, destY, hoverTarget and 24 or 18)
      if hoverTarget then
        lg.setFont(self.fonts.f12)
        lg.printf(t("feedMode"), hoverTarget.x - 50, hoverTarget.y - 42, 100, "center")
      elseif outOfLeftZone then
        lg.setFont(self.fonts.f12)
        lg.setColor(Color.hex("#fda4af"))
        lg.printf(t("deployLeftOnly"), destX - 64, destY - 40, 128, "center")
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
    lg.setColor(0.18, 0.12, 0.25, 0.92)
    lg.rectangle("fill", A.x + 110, A.y + 38, 580, 30, 8, 8)
    lg.setColor(Color.hex("#a78bfa"))
    lg.setLineWidth(2)
    lg.rectangle("line", A.x + 110, A.y + 38, 580, 30, 8, 8)
    lg.setLineWidth(1)
    drawCenteredText(self.fonts.f12, msg .. " - " .. t("feedModeHint"), A.x + 110, A.y + 38, 580, 30, Color.hex("#f3e8ff"))
  end

  if state.bossBannerTimer > 0 then
    lg.setColor(0.62, 0.07, 0.22, 0.9)
    lg.rectangle("fill", A.x + 220, A.y + 74, 360, 36, 8, 8)
    drawCenteredText(self.fonts.f16, t("bossWarning"), A.x + 220, A.y + 74, 360, 36, Color.hex("#fde047"))
  elseif state.waveClearTimer > 0 then
    lg.setColor(0.08, 0.32, 0.20, 0.92)
    lg.rectangle("fill", A.x + 220, A.y + 74, 360, 36, 8, 8)
    drawCenteredText(self.fonts.f15, t("waveCleared") .. tostring(state.waveClearGold) .. "g", A.x + 220, A.y + 74, 360, 36, Color.hex("#fde047"))
  end

  -- Right-Edge Vertical Bookmark Tabs (matching Slotbound's outer right tabs!)
  local modalBlocked = (state.coreModal ~= nil) or (state.classModal ~= nil) or (state.shopModal == true) or (state.guideModal == true)
  local tabX = A.x + A.w + 14
  local sideButtons = {
    { id = "toggle_guide", label = t("guideBtn"), y = A.y + 20,  bg = Color.hex("#3b3047"), border = Color.hex("#93c5fd") },
    { id = "toggle_shop",  label = t("shopBtn"),  y = A.y + 82,  bg = Color.hex("#4a3319"), border = Color.hex("#facc15") },
    { id = "toggle_speed", label = state.fastForward and "2x" or "1x", y = A.y + 144, bg = Color.hex("#2c2334"), border = Color.hex("#a78bfa") },
    { id = "start_wave",   label = (state.phase == "battle") and "..." or t("startWave"), y = A.y + 206, bg = Color.hex("#16a34a"), border = Color.hex("#86efac"), disabled = (state.phase == "battle") or modalBlocked },
  }
  for _, sb in ipairs(sideButtons) do
    local rect = { x = tabX, y = sb.y, w = 48, h = 50 }
    self:drawButton(rect, sb.label, {
      disabled = sb.disabled,
      bg = sb.bg,
      border = sb.border,
      font = self.fonts.f11,
      hovered = isHover(hoverPos, rect),
    })
    registerHit(sb.id, rect)
  end
end

function Renderer:renderBottomBar(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local barX = 400
  local barY = 562

  -- Left section: Large Beveled Stone Core Slots (6 slots, matching Slotbound bottom-center bar!)
  local coreBox = { x = barX, y = barY, w = 368, h = 144 }
  lg.setColor(Color.hex("#2c2333"))
  lg.rectangle("fill", coreBox.x, coreBox.y, coreBox.w, coreBox.h, 8, 8)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#594969"))
  lg.rectangle("line", coreBox.x, coreBox.y, coreBox.w, coreBox.h, 8, 8)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f12)
  lg.setColor(Color.hex("#fde047"))
  lg.print(t("coresBar") .. " (" .. #state.cores .. "/6)", coreBox.x + 12, coreBox.y + 8)

  for idx = 1, 6 do
    local col = (idx - 1) % 3
    local row = math.floor((idx - 1) / 3)
    local sx = coreBox.x + 14 + col * 116
    local sy = coreBox.y + 30 + row * 54
    local sRect = { x = sx, y = sy, w = 108, h = 46 }
    local core = state.cores[idx]
    local hov = core and isHover(hoverPos, sRect)
    lg.setColor(core and (hov and Color.hex("#3f334d") or Color.hex("#1f1926")) or Color.hex("#19141f"))
    lg.rectangle("fill", sx, sy, 108, 46, 6, 6)
    lg.setLineWidth(core and 2 or 1)
    lg.setColor(core and core.color or Color.hex("#3b3047"))
    lg.rectangle("line", sx, sy, 108, 46, 6, 6)
    lg.setLineWidth(1)

    if core then
      drawCenteredText(self.fonts.f12, core.badge .. " · " .. i18n:pick(core.name), sx + 4, sy, 100, 46, core.color)
      if hov then
        self.tooltip = { title = i18n:pick(core.name), body = i18n:pick(core.desc), color = core.color }
      end
    end
  end

  -- Right section: Active Army Roster Strip
  local armyBox = { x = 776, y = barY, w = 490, h = 144 }
  lg.setColor(Color.hex("#2c2333"))
  lg.rectangle("fill", armyBox.x, armyBox.y, armyBox.w, armyBox.h, 8, 8)
  lg.setLineWidth(2)
  lg.setColor(Color.hex("#594969"))
  lg.rectangle("line", armyBox.x, armyBox.y, armyBox.w, armyBox.h, 8, 8)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f12)
  lg.setColor(Color.hex("#c084fc"))
  lg.print(t("roster") .. " (" .. #state.roster .. "/" .. state.maxRoster .. ") — " .. t("clickUnitTip"), armyBox.x + 12, armyBox.y + 8)

  local cols = 6
  local slotW = 74
  for idx, u in ipairs(state.roster) do
    local c = (idx - 1) % cols
    local r = math.floor((idx - 1) / cols)
    local rx = armyBox.x + 12 + c * (slotW + 5)
    local ry = armyBox.y + 30 + r * 54
    local rect = { x = rx, y = ry, w = slotW, h = 48 }
    local isSel = (u.id == state.selectedUnitId)
    local isSac = (u.id == state.feedSacrificeId)

    lg.setColor(isSac and Color.hex("#4c1d24") or (isSel and Color.hex("#3f334d") or (isHover(hoverPos, rect) and Color.hex("#32283d") or Color.hex("#1b1521"))))
    lg.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 5, 5)
    lg.setLineWidth((isSel or isSac) and 2 or 1.2)
    lg.setColor(isSac and Color.hex("#fb7185") or (isSel and Color.hex("#ffdf6b") or (u.rarity and u.rarity.color or Color.hex("#4e405c"))))
    lg.rectangle("line", rect.x, rect.y, rect.w, rect.h, 5, 5)
    lg.setLineWidth(1)

    lg.setFont(self.fonts.f11)
    lg.setColor(u.accent)
    lg.printf(i18n:pick(u.name), rx + 2, ry + 4, slotW - 4, "center")
    Sprites.drawTierPips(rx + slotW / 2, ry + 26, u.tier)
    drawHealthBar(rx + 6, ry + 38, slotW - 12, 4, u.hp / u.maxHp, Color.hex("#4ade80"))
    registerHit("unit_card", rect, { unitId = u.id })
  end
end

function Renderer:renderGuideModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.05, 0.04, 0.08, 0.85)
  lg.rectangle("fill", 0, 0, 1280, 720)

  -- Open Two-Page Parchment Book (matching Slotbound COLLECTION modal!)
  local book = { x = 140, y = 76, w = 1000, h = 568 }
  lg.setColor(Color.hex("#e8d8b9"))
  lg.rectangle("fill", book.x, book.y, book.w, book.h, 12, 12)
  lg.setLineWidth(4)
  lg.setColor(Color.hex("#5c4024"))
  lg.rectangle("line", book.x, book.y, book.w, book.h, 12, 12)
  lg.setLineWidth(3)
  lg.line(book.x + book.w / 2, book.y + 8, book.x + book.w / 2, book.y + book.h - 8)
  lg.setLineWidth(1)
  registerHit("modal_blocker", book)

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#fde047"))
  lg.printf(t("guideTitle"), 140, 32, 1000, "center")

  -- Helper: draw pixel-art corner-knot selection frame (matching Slotbound Collection book)
  local function drawCodexCornerKnot(x, y, sx, sy)
    local p = 3
    -- 5x5 interlocking Greek-key corner motif
    local pts = {
      {0,0},{1,0},{2,0},{3,0},{4,0},
      {0,1},{4,1},
      {0,2},{2,2},{3,2},{4,2},
      {0,3},{2,3},
      {0,4},{1,4},{2,4},
    }
    for _, pt in ipairs(pts) do
      local rxPos = (sx > 0) and (x + pt[1] * p) or (x - (pt[1] + 1) * p)
      local ryPos = (sy > 0) and (y + pt[2] * p) or (y - (pt[2] + 1) * p)
      lg.rectangle("fill", rxPos, ryPos, p, p)
    end
  end

  local function resolveCodexUnit(uId)
    local base = Units.BASE_UNITS[uId]
    if base then
      return {
        id = base.id,
        name = base.name,
        family = base.family,
        hp = base.hp,
        atk = base.atk,
        aspd = base.aspd,
        range = base.range,
        activeSkill = base.activeSkill,
        traitDesc = base.desc,
        branches = base.branches,
        isAdv = false,
      }
    end
    local adv = Units.ADVANCED_CLASSES[uId]
    if adv then
      local parent = Units.BASE_UNITS.warrior
      for _, b in pairs(Units.BASE_UNITS) do
        for _, br in ipairs(b.branches or {}) do
          if br == uId then
            parent = b
            break
          end
        end
      end
      return {
        id = adv.id,
        parentId = parent.id,
        parentName = parent.name,
        name = adv.name,
        family = parent.family,
        hp = math.floor(parent.hp * (adv.hpMult or 1) + 0.5),
        atk = math.floor(parent.atk * (adv.atkMult or 1) + 0.5),
        aspd = math.floor(parent.aspd * (adv.aspdMult or 1) * 100 + 0.5) / 100,
        range = adv.range or (parent.range + (adv.rangeBonus or 0)),
        activeSkill = parent.activeSkill,
        traitDesc = adv.desc,
        isAdv = true,
      }
    end
    return resolveCodexUnit("warrior")
  end

  -- Left Page: 3x3 Sage-Parchment Grid of Units & Advanced Classes (matching Slotbound!)
  local unitKeys = {
    "warrior", "paladin", "berserker",
    "champion", "mage", "archmage",
    "ranger", "windrunner", "necro",
  }
  for idx, uId in ipairs(unitKeys) do
    local col = (idx - 1) % 3
    local row = math.floor((idx - 1) / 3)
    local cx = book.x + 42 + col * 142
    local cy = book.y + 42 + row * 144
    local cell = { x = cx, y = cy, w = 132, h = 136 }
    local isSel = (state.codexUnitId == uId)
    local hov = isHover(hoverPos, cell)
    lg.setColor(isSel and Color.hex("#e8dfc2") or (hov and Color.hex("#e2d9b8") or Color.hex("#d8cfa9")))
    lg.rectangle("fill", cell.x, cell.y, cell.w, cell.h)

    if isSel then
      lg.setLineWidth(2)
      lg.setColor(Color.hex("#6e553e"))
      lg.rectangle("line", cell.x, cell.y, cell.w, cell.h)
      drawCodexCornerKnot(cell.x, cell.y, 1, 1)
      drawCodexCornerKnot(cell.x + cell.w, cell.y, -1, 1)
      drawCodexCornerKnot(cell.x, cell.y + cell.h, 1, -1)
      drawCodexCornerKnot(cell.x + cell.w, cell.y + cell.h, -1, -1)
      lg.setLineWidth(1)
    else
      lg.setColor(Color.hex("#b5a882"))
      lg.rectangle("line", cell.x, cell.y, cell.w, cell.h)
      local pip = 4
      lg.rectangle("fill", cell.x, cell.y, pip, pip)
      lg.rectangle("fill", cell.x + cell.w - pip, cell.y, pip, pip)
      lg.rectangle("fill", cell.x, cell.y + cell.h - pip, pip, pip)
      lg.rectangle("fill", cell.x + cell.w - pip, cell.y + cell.h - pip, pip, pip)
    end

    local info = resolveCodexUnit(uId)
    local rarGlow = info.isAdv and "rare" or "normal"
    local img = PixelArt.getUnitImage({ baseId = uId, classId = uId }, rarGlow)
    if img then
      local iw, ih = img:getDimensions()
      lg.setColor(1, 1, 1, 1)
      lg.draw(img, math.floor(cell.x + cell.w / 2), cell.y + 56, 0, 4, 4, math.floor(iw * 0.5), math.floor(ih * 0.5))
    end
    lg.setFont(self.fonts.f13)
    lg.setColor(Color.hex("#3b2314"))
    lg.printf(i18n:pick(info.name), cell.x + 4, cell.y + 106, cell.w - 8, "center")
    registerHit("pick_codex_unit", cell, { unitId = uId })
  end

  -- Right Page: Detailed Unit Card (Stats, Active Skill + Cooldown, Promotions)
  local rx = book.x + book.w / 2 + 34
  local rw = book.w / 2 - 68
  local tpl = resolveCodexUnit(state.codexUnitId or "warrior")

  lg.setColor(Color.hex("#dcc8a4"))
  lg.rectangle("fill", rx, book.y + 34, rw, 50, 6, 6)
  lg.setColor(Color.hex("#8c704c"))
  lg.rectangle("line", rx, book.y + 34, rw, 50, 6, 6)
  drawCenteredText(self.fonts.f22, i18n:pick(tpl.name), rx, book.y + 34, rw, 50, Color.hex("#3b2314"))

  local img = PixelArt.getUnitImage({ baseId = tpl.id, classId = tpl.id }, tpl.isAdv and "rare" or "normal")
  if img then
    local iw, ih = img:getDimensions()
    lg.setColor(Color.hex("#f3e6cb"))
    lg.rectangle("fill", rx, book.y + 100, 110, 110, 8, 8)
    lg.setColor(Color.hex("#8c704c"))
    lg.rectangle("line", rx, book.y + 100, 110, 110, 8, 8)
    lg.setColor(1, 1, 1, 1)
    local sc = math.max(1, math.floor(math.min(4, 86 / math.max(iw, ih))))
    lg.draw(img, math.floor(rx + 55), book.y + 155, 0, sc, sc, math.floor(iw * 0.5), math.floor(ih * 0.5))
  end

  local fam = Units.FAMILIES[tpl.family]
  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#5c4024"))
  lg.print(i18n:pick(fam.name), rx + 128, book.y + 106)
  lg.print(t("hp") .. ": " .. tpl.hp .. "   " .. t("atk") .. ": " .. tpl.atk, rx + 128, book.y + 136)
  lg.print(t("aspd") .. ": " .. tpl.aspd .. "   RNG: " .. tpl.range, rx + 128, book.y + 166)

  -- Active Skill / Class Trait Box
  lg.setColor(Color.hex("#f3e6cb"))
  lg.rectangle("fill", rx, book.y + 228, rw, 130, 8, 8)
  lg.setColor(Color.hex("#8c704c"))
  lg.rectangle("line", rx, book.y + 228, rw, 130, 8, 8)
  if tpl.activeSkill then
    lg.setFont(self.fonts.f16)
    lg.setColor(Color.hex("#b45309"))
    lg.print(t("activeSkill") .. ": " .. i18n:pick(tpl.activeSkill.name), rx + 14, book.y + 242)
    lg.setFont(self.fonts.f13)
    lg.setColor(Color.hex("#78350f"))
    lg.print(t("cooldownLabel") .. ": " .. tpl.activeSkill.cooldown .. "s", rx + 14, book.y + 268)
    lg.setColor(Color.hex("#3b2314"))
    local bodyTxt = tpl.isAdv and tpl.traitDesc and i18n:pick(tpl.traitDesc) or i18n:pick(tpl.activeSkill.desc)
    lg.printf(bodyTxt, rx + 14, book.y + 296, rw - 28, "left")
  end

  -- Promotions Chain
  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#5c4024"))
  lg.print(t("promotions") .. ":", rx, book.y + 378)
  lg.setFont(self.fonts.f15)
  lg.setColor(Color.hex("#1d4ed8"))
  if tpl.isAdv then
    lg.printf(i18n:pick(tpl.parentName) .. "  >  " .. i18n:pick(tpl.name), rx, book.y + 406, rw, "left")
  else
    local bNames = {}
    for _, bId in ipairs(tpl.branches or {}) do
      local cls = Units.ADVANCED_CLASSES[bId]
      if cls then bNames[#bNames + 1] = i18n:pick(cls.name) end
    end
    lg.printf(i18n:pick(tpl.name) .. "  >  (" .. table.concat(bNames, " / ") .. ")", rx, book.y + 406, rw, "left")
  end

  local closeBtn = { x = 540, y = book.y + book.h - 62, w = 200, h = 42 }
  self:drawButton(closeBtn, t("close"), {
    bg = Color.hex("#78350f"),
    border = Color.hex("#fde047"),
    hovered = isHover(hoverPos, closeBtn),
  })
  registerHit("toggle_guide", closeBtn)
end

function Renderer:renderShopModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.05, 0.04, 0.08, 0.85)
  lg.rectangle("fill", 0, 0, 1280, 720)

  local box = { x = 130, y = 76, w = 1020, h = 568 }
  lg.setColor(Color.hex("#231b2b"))
  lg.rectangle("fill", box.x, box.y, box.w, box.h, 12, 12)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#d4a348"))
  lg.rectangle("line", box.x, box.y, box.w, box.h, 12, 12)
  lg.setLineWidth(1)
  registerHit("modal_blocker", box)

  -- Skeleton Merchant behind Wooden Counter
  local merch = PixelArt.getMerchantImage()
  if merch then
    local iw, ih = merch:getDimensions()
    lg.setColor(1, 1, 1, 1)
    lg.draw(merch, box.x + 86, box.y + 62, 0, 4.0, 4.0, iw * 0.5, ih * 0.5)
  end
  lg.setColor(Color.hex("#78350f"))
  lg.rectangle("fill", box.x + 24, box.y + 92, 130, 16, 4, 4)

  lg.setFont(self.fonts.f22)
  lg.setColor(Color.hex("#fde047"))
  lg.print(t("shopTitle"), box.x + 174, box.y + 24)
  lg.setFont(self.fonts.f13)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.print(t("shopSub"), box.x + 174, box.y + 56)
  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#38bdf8"))
  lg.print(t("crystalsLabel") .. ": " .. state.crystals .. "   |   " .. t("gold") .. ": " .. state.gold .. "g", box.x + 174, box.y + 80)

  -- Left Half: Crystal Items (4x2)
  for idx, itemKey in ipairs(Items.ITEM_KEYS) do
    local tpl = Items.ITEMS[itemKey]
    local col = (idx - 1) % 2
    local row = math.floor((idx - 1) / 2)
    local card = { x = box.x + 24 + col * 244, y = box.y + 120 + row * 98, w = 234, h = 88 }
    local owned = state:hasItem(tpl.id)
    local canBuy = (not owned) and (#state.items < state.maxItems) and (state.crystals >= tpl.cost)
    local hov = canBuy and isHover(hoverPos, card)

    lg.setColor(owned and Color.hex("#1a2421") or (hov and Color.hex("#3b304a") or Color.hex("#191320")))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 8, 8)
    lg.setColor(owned and Color.hex("#4ade80") or (canBuy and tpl.color or Color.hex("#3f334d")))
    lg.rectangle("line", card.x, card.y, card.w, card.h, 8, 8)

    lg.setFont(self.fonts.f13)
    lg.setColor(tpl.color)
    lg.print(i18n:pick(tpl.name), card.x + 10, card.y + 8)
    lg.setFont(self.fonts.f12)
    lg.setColor(owned and Color.hex("#4ade80") or Color.hex("#38bdf8"))
    lg.printf(owned and t("inBag") or (tpl.cost .. " " .. t("crystals")), card.x, card.y + 8, card.w - 10, "right")

    lg.setFont(self.fonts.f11)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.printf(i18n:pick(tpl.desc), card.x + 10, card.y + 30, card.w - 20, "left")

    registerHit("buy_item", card, { itemId = tpl.id })
  end

  -- Right Half: Gold Slot/Army Upgrades (2x3)
  for idx, upg in ipairs(Upgrades.SHOP_UPGRADES) do
    local col = (idx - 1) % 2
    local row = math.floor((idx - 1) / 2)
    local card = { x = box.x + 528 + col * 238, y = box.y + 120 + row * 126, w = 228, h = 116 }
    local lvl = state.upgradeLevels[upg.id] or 0
    local maxed = lvl >= upg.maxLevel
    local cost = Upgrades.getCost(upg, lvl)
    local canBuy = (not maxed) and (state.gold >= cost)
    local hov = canBuy and isHover(hoverPos, card)

    lg.setColor(hov and Color.hex("#3b304a") or Color.hex("#191320"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 8, 8)
    lg.setColor(maxed and Color.hex("#475569") or (canBuy and upg.color or Color.hex("#3f334d")))
    lg.rectangle("line", card.x, card.y, card.w, card.h, 8, 8)

    lg.setFont(self.fonts.f13)
    lg.setColor(upg.color)
    lg.print(i18n:pick(upg.name), card.x + 10, card.y + 10)
    lg.setFont(self.fonts.f11)
    lg.setColor(Color.hex("#94a3b8"))
    lg.printf("Lv." .. lvl .. "/" .. upg.maxLevel, card.x, card.y + 12, card.w - 10, "right")

    lg.setFont(self.fonts.f11)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.printf(i18n:pick(upg.desc), card.x + 10, card.y + 36, card.w - 20, "left")

    local priceBtn = { x = card.x + 10, y = card.y + 78, w = card.w - 20, h = 28 }
    self:drawButton(priceBtn, maxed and t("maxed") or (tostring(cost) .. "g"), {
      disabled = not canBuy,
      bg = Color.hex("#3b2e16"),
      border = upg.color,
      font = self.fonts.f12,
      hovered = hov,
    })
    registerHit("buy_upgrade", card, { upgId = upg.id })
  end

  local closeBtn = { x = 540, y = box.y + box.h - 54, w = 200, h = 40 }
  self:drawButton(closeBtn, t("close"), { hovered = isHover(hoverPos, closeBtn) })
  registerHit("toggle_shop", closeBtn)
end

function Renderer:renderCoreModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.05, 0.04, 0.08, 0.84)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#fde047"))
  lg.printf(t("coreModalTitle"), 180, 118, 920, "center")
  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.printf(t("coreModalSub"), 180, 158, 920, "center")

  -- Three vertical Parchment Scrolls (matching Slotbound screenshot #4!)
  for idx, core in ipairs(state.coreModal.choices) do
    local card = { x = 216 + (idx - 1) * 288, y = 204, w = 268, h = 340 }
    local hov = isHover(hoverPos, card)
    lg.setColor(hov and Color.hex("#f3e6cb") or Color.hex("#e8d8b9"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(hov and 4 or 2.5)
    lg.setColor(hov and Color.hex("#d97706") or Color.hex("#6e5332"))
    lg.rectangle("line", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(1)

    lg.setColor(Color.hex("#2c2333"))
    lg.circle("fill", card.x + card.w / 2, card.y + 68, 30)
    lg.setLineWidth(2)
    lg.setColor(core.color)
    lg.circle("line", card.x + card.w / 2, card.y + 68, 30)
    lg.setLineWidth(1)
    drawCenteredText(self.fonts.f14, core.badge, card.x + card.w / 2 - 30, card.y + 38, 60, 60, core.color)

    lg.setFont(self.fonts.f18)
    lg.setColor(Color.hex("#3b2314"))
    lg.printf(i18n:pick(core.name), card.x + 12, card.y + 118, card.w - 24, "center")

    lg.setFont(self.fonts.f14)
    lg.setColor(Color.hex("#5c4024"))
    lg.printf(i18n:pick(core.desc), card.x + 20, card.y + 168, card.w - 40, "center")

    registerHit("pick_core", card, { coreId = core.id })
  end
end

function Renderer:renderClassModal(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end

  lg.setColor(0.05, 0.04, 0.08, 0.85)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#241d2b"))
  lg.rectangle("fill", 260, 145, 760, 430, 14, 14)
  lg.setLineWidth(3)
  lg.setColor(Color.hex("#facc15"))
  lg.rectangle("line", 260, 145, 760, 430, 14, 14)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f28)
  lg.setColor(Color.hex("#fde047"))
  lg.printf(t("classModalTitle"), 260, 174, 760, "center")

  lg.setFont(self.fonts.f14)
  lg.setColor(Color.hex("#e2e8f0"))
  lg.printf(t("classModalSub"), 260, 216, 760, "center")

  for idx, cls in ipairs(state.classModal.choices) do
    local card = { x = 310 + (idx - 1) * 340, y = 268, w = 320, h = 256 }
    local hov = isHover(hoverPos, card)
    lg.setColor(hov and Color.hex("#f3e6cb") or Color.hex("#e8d8b9"))
    lg.rectangle("fill", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(hov and 4 or 2.5)
    lg.setColor(hov and Color.hex("#d97706") or Color.hex("#6e5332"))
    lg.rectangle("line", card.x, card.y, card.w, card.h, 10, 10)
    lg.setLineWidth(1)

    lg.setFont(self.fonts.f22)
    lg.setColor(Color.hex("#3b2314"))
    lg.printf("[3*] " .. i18n:pick(cls.name), card.x + 10, card.y + 34, card.w - 20, "center")

    lg.setFont(self.fonts.f13)
    lg.setColor(Color.hex("#b45309"))
    lg.printf(
      "HP x" .. cls.hpMult .. "  |  ATK x" .. cls.atkMult .. "  |  ASPD x" .. cls.aspdMult,
      card.x + 10,
      card.y + 82,
      card.w - 20,
      "center"
    )

    lg.setFont(self.fonts.f14)
    lg.setColor(Color.hex("#5c4024"))
    lg.printf(i18n:pick(cls.desc), card.x + 18, card.y + 128, card.w - 36, "center")

    registerHit("pick_class", card, { classId = cls.id })
  end
end

function Renderer:renderEndOverlay(state, i18n, registerHit, hoverPos)
  local lg = love.graphics
  local function t(k) return i18n:t(k) end
  local isWin = (state.phase == "victory")

  lg.setColor(0.05, 0.04, 0.08, 0.85)
  lg.rectangle("fill", 0, 0, 1280, 720)

  lg.setColor(Color.hex("#e8d8b9"))
  lg.rectangle("fill", 360, 180, 560, 360, 14, 14)
  lg.setLineWidth(3.5)
  lg.setColor(isWin and Color.hex("#d97706") or Color.hex("#be123c"))
  lg.rectangle("line", 360, 180, 560, 360, 14, 14)
  lg.setLineWidth(1)

  lg.setFont(self.fonts.f36)
  lg.setColor(isWin and Color.hex("#b45309") or Color.hex("#be123c"))
  lg.printf(isWin and t("victoryTitle") or t("gameOverTitle"), 360, 218, 560, "center")

  lg.setFont(self.fonts.f16)
  lg.setColor(Color.hex("#3b2314"))
  lg.printf(isWin and t("victorySub") or t("gameOverSub"), 380, 276, 520, "center")

  lg.setFont(self.fonts.f15)
  lg.setColor(Color.hex("#5c4024"))
  lg.printf(
    t("wave") .. ": " .. state.wave .. "/" .. Waves.MAX_WAVES .. "   |   " .. t("kills") .. ": " .. state.totalKills,
    360,
    328,
    560,
    "center"
  )

  local retryBtn = { x = 430, y = 410, w = 200, h = 52 }
  self:drawButton(retryBtn, t("restart"), {
    bg = Color.hex("#b45309"),
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
