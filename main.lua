local Audio = require("src.audio")
local I18n = require("src.i18n")
local StateMod = require("src.systems.state")
local Renderer = require("src.render.renderer")

local VIRTUAL_W = 1280
local VIRTUAL_H = 720

local audio = nil
local i18n = nil
local state = nil
local renderer = nil
local hitboxes = {}
local hoverPos = nil
local totalTime = 0
local smokeFrames = nil

local function getViewportTransform()
  local w, h = love.graphics.getDimensions()
  local scale = math.min(w / VIRTUAL_W, h / VIRTUAL_H)
  local ox = (w - VIRTUAL_W * scale) * 0.5
  local oy = (h - VIRTUAL_H * scale) * 0.5
  return scale, ox, oy
end

local function screenToVirtual(sx, sy)
  local scale, ox, oy = getViewportTransform()
  return {
    x = (sx - ox) / scale,
    y = (sy - oy) / scale,
  }
end

local function handleUnitClick(unitId)
  if state.feedMode then
    if not state.feedSacrificeId then
      state.feedSacrificeId = unitId
      state.selectedUnitId = unitId
    elseif state.feedSacrificeId == unitId then
      state.feedSacrificeId = nil
    else
      state:absorbUnit(state.feedSacrificeId, unitId)
    end
    return
  end
  state.selectedUnitId = unitId
end

local function dispatchAction(hit)
  local id = hit.id
  if id == "start_run" then
    state:startRun()
  elseif id == "back_menu" then
    state.phase = "menu"
  elseif id == "toggle_lang" then
    i18n:toggle()
  elseif id == "toggle_speed" then
    state.fastForward = not state.fastForward
  elseif id == "toggle_pause" then
    state.paused = not state.paused
  elseif id == "toggle_mute" then
    audio:toggleMute()
  elseif id == "spin" then
    state:spin()
  elseif id == "nudge" then
    state:nudgeReel(hit.payload.col, hit.payload.dir)
  elseif id == "start_wave" then
    state:startWave()
  elseif id == "toggle_feed" then
    if #state.roster >= 2 then
      state.feedMode = not state.feedMode
      state.feedSacrificeId = state.feedMode and state.selectedUnitId or nil
    end
  elseif id == "dismiss_unit" then
    if not state.waveActive then
      state:dismissUnit(hit.payload.unitId)
    end
  elseif id == "unit_arena" or id == "unit_card" then
    handleUnitClick(hit.payload.unitId)
  elseif id == "pick_core" then
    state:chooseCore(hit.payload.coreId)
  elseif id == "pick_class" then
    state:chooseClass(hit.payload.classId)
  end
end

function love.load(args)
  if args then
    for _, a in ipairs(args) do
      if a == "--test" then
        local runTests = require("tests.run_tests")
        local ok = runTests()
        love.event.quit(ok and 0 or 1)
        return
      elseif a == "--smoke" then
        smokeFrames = 0
      end
    end
  end

  math.randomseed(os.time())
  audio = Audio.new()
  audio:init()
  i18n = I18n.new("zh")
  state = StateMod.GameState.new(audio)
  renderer = Renderer.new()
  renderer:initFonts()
end

function love.update(dt)
  if not state then return end
  totalTime = totalTime + dt
  if smokeFrames ~= nil then
    smokeFrames = smokeFrames + 1
    if smokeFrames == 1 then
      -- menu
    elseif smokeFrames == 2 then
      state:startRun()
      state:spin()
    elseif smokeFrames == 3 then
      state:update(1.0)
      state:startWave()
    elseif smokeFrames == 4 then
      state:update(0.2)
      state:openCoreDraft()
    elseif smokeFrames == 5 then
      state.coreModal = nil
      state.classModal = { unitId = state.roster[1].id, choices = { require("src.data.units").ADVANCED_CLASSES.paladin, require("src.data.units").ADVANCED_CLASSES.berserker } }
    elseif smokeFrames == 6 then
      state.classModal = nil
      state.phase = "victory"
    elseif smokeFrames >= 7 then
      print("SMOKE_OK")
      love.event.quit(0)
      return
    end
    return
  end
  state:update(dt)
end

function love.draw()
  if not state or not renderer then return end
  love.graphics.clear(0.05, 0.055, 0.08, 1)
  local scale, ox, oy = getViewportTransform()
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(scale, scale)
  hitboxes = renderer:render(state, i18n, totalTime, hoverPos)
  love.graphics.pop()
end

function love.mousemoved(x, y)
  hoverPos = screenToVirtual(x, y)
end

function love.mousepressed(x, y, button)
  if not state then return end
  if button == 2 then
    if state.feedMode then
      state.feedMode = false
      state.feedSacrificeId = nil
    end
    return
  end
  if button ~= 1 then return end

  local pos = screenToVirtual(x, y)
  for i = #hitboxes, 1, -1 do
    local h = hitboxes[i]
    local r = h.rect
    if pos.x >= r.x and pos.x <= r.x + r.w and pos.y >= r.y and pos.y <= r.y + r.h then
      dispatchAction(h)
      break
    end
  end
end

function love.keypressed(key)
  if not state then return end
  if key == "space" then
    if state.phase == "menu" then
      state:startRun()
    elseif state:canSpin() then
      state:spin()
    end
  elseif key == "f" then
    state.fastForward = not state.fastForward
  elseif key == "p" then
    state.paused = not state.paused
  elseif key == "escape" and state.feedMode then
    state.feedMode = false
    state.feedSacrificeId = nil
  end
end
