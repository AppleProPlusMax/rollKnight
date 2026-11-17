local Audio = require("src.audio")
local I18n = require("src.i18n")
local StateMod = require("src.systems.state")
local Battle = require("src.systems.battle")
local Renderer = require("src.render.renderer")

local VIRTUAL_W = 1280
local VIRTUAL_H = 720

local audio = nil
local i18n = nil
local state = nil
local renderer = nil
local hitboxes = {}
local hoverPos = nil
local dragState = nil
local totalTime = 0
local smokeFrames = nil

local function dist2D(dx, dy)
  return math.sqrt(dx * dx + dy * dy)
end

local function getViewportTransform()
  local w, h = love.graphics.getDimensions()
  local scale = math.min(w / VIRTUAL_W, h / VIRTUAL_H)
  local ox = (w - VIRTUAL_W * scale) * 0.5
  local oy = (h - VIRTUAL_H * scale) * 0.5
  return { scale = scale, ox = ox, oy = oy }
end

local function screenToVirtual(sx, sy)
  local vp = getViewportTransform()
  return {
    x = (sx - vp.ox) / vp.scale,
    y = (sy - vp.oy) / vp.scale,
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
  elseif id == "set_diff" then
    state:setDifficulty(hit.payload.diff)
  elseif id == "back_menu" then
    state.phase = "menu"
  elseif id == "toggle_lang" then
    i18n:toggle()
  elseif id == "toggle_shop" then
    state.guideModal = false
    state.shopModal = not state.shopModal
  elseif id == "toggle_guide" then
    state.shopModal = false
    state.guideModal = not state.guideModal
  elseif id == "close_modals" then
    state.shopModal = false
    state.guideModal = false
  elseif id == "modal_blocker" then
    -- Swallow click on modal body/backdrop
  elseif id == "buy_upgrade" then
    state:buyUpgrade(hit.payload.upgId)
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
      -- Exercise drag-and-drop input handlers
      local u = state.roster[1]
      dragState = { unitId = u.id, startX = u.x, startY = u.y, curX = u.x, curY = u.y, active = false }
      love.mousemoved(u.x + 25, u.y + 10)
      love.mousereleased(u.x + 25, u.y + 10, 1)
      state.shopModal = true
    elseif smokeFrames == 4 then
      state.shopModal = false
      state.guideModal = true
    elseif smokeFrames == 5 then
      state.guideModal = false
      state:startWave()
      state:update(0.2)
    elseif smokeFrames == 6 then
      state:openCoreDraft()
    elseif smokeFrames == 7 then
      state.coreModal = nil
      state.classModal = {
        unitId = state.roster[1].id,
        choices = { require("src.data.units").ADVANCED_CLASSES.paladin, require("src.data.units").ADVANCED_CLASSES.berserker },
      }
    elseif smokeFrames == 8 then
      state.classModal = nil
      state.phase = "victory"
    elseif smokeFrames >= 9 then
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
  local vp = getViewportTransform()
  love.graphics.push()
  love.graphics.translate(vp.ox, vp.oy)
  love.graphics.scale(vp.scale, vp.scale)
  hitboxes = renderer:render(state, i18n, totalTime, hoverPos, dragState, vp)
  love.graphics.pop()
end

function love.mousemoved(x, y)
  local pos = screenToVirtual(x, y)
  hoverPos = pos
  if dragState then
    dragState.curX = pos.x
    dragState.curY = pos.y
    if dist2D(pos.x - dragState.startX, pos.y - dragState.startY) > 7 then
      dragState.active = true
    end
  end
end

function love.mousepressed(x, y, button)
  if not state then return end
  if button == 2 then
    if state.feedMode then
      state.feedMode = false
      state.feedSacrificeId = nil
    end
    dragState = nil
    return
  end
  if button ~= 1 then return end

  local pos = screenToVirtual(x, y)
  for i = #hitboxes, 1, -1 do
    local h = hitboxes[i]
    local r = h.rect
    if pos.x >= r.x and pos.x <= r.x + r.w and pos.y >= r.y and pos.y <= r.y + r.h then
      if h.id == "unit_arena" and not state.waveActive and not state.feedMode and not state.coreModal and not state.classModal and not state.shopModal and not state.guideModal then
        dragState = {
          unitId = h.payload.unitId,
          startX = pos.x,
          startY = pos.y,
          curX = pos.x,
          curY = pos.y,
          active = false,
        }
        state.selectedUnitId = h.payload.unitId
      else
        dispatchAction(h)
      end
      break
    end
  end
end

function love.mousereleased(x, y, button)
  if button ~= 1 or not dragState then return end
  local pos = screenToVirtual(x, y)
  local dragged = dragState
  dragState = nil

  if not dragged.active then
    handleUnitClick(dragged.unitId)
    return
  end

  -- Check if dropped onto another allied unit -> Absorb!
  local dropTarget = nil
  for _, u in ipairs(state.roster) do
    if u.id ~= dragged.unitId and dist2D(pos.x - u.x, pos.y - u.y) <= 28 then
      dropTarget = u
      break
    end
  end

  if dropTarget then
    state:absorbUnit(dragged.unitId, dropTarget.id)
    return
  end

  -- Check if dropped inside Arena -> Reposition!
  local A = Battle.ARENA
  if pos.x >= A.x and pos.x <= A.x + A.w and pos.y >= A.y and pos.y <= A.y + A.h then
    state:setUnitPosition(dragged.unitId, pos.x, pos.y)
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
  elseif key == "u" and state.phase ~= "menu" then
    state.guideModal = false
    state.shopModal = not state.shopModal
  elseif key == "g" and state.phase ~= "menu" then
    state.shopModal = false
    state.guideModal = not state.guideModal
  elseif key == "escape" then
    if state.shopModal then
      state.shopModal = false
    elseif state.guideModal then
      state.guideModal = false
    elseif state.feedMode then
      state.feedMode = false
      state.feedSacrificeId = nil
    end
  end
end
