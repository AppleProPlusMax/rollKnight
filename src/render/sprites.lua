local Color = require("src.utils.color")
local PixelArt = require("src.render.pixel_art")

local M = {}

-- Integer pixel scales keep the chibi sprites perfectly crisp (Slotbound look)
M.UNIT_SCALE = 2
M.BOSS_SCALE = 3

local function prismColor(time)
  local r = 0.65 + 0.35 * math.sin(time * 5.0)
  local g = 0.65 + 0.35 * math.sin(time * 5.0 + 2.09)
  local b = 0.65 + 0.35 * math.sin(time * 5.0 + 4.18)
  return { r, g, b, 1 }
end

function M.drawSymbolIcon(symbolId, cx, cy, size)
  size = size or 36
  local lg = love.graphics
  local img = PixelArt.getSymbolImage(symbolId)
  if img then
    local iw, ih = img:getDimensions()
    local scale = size / iw
    lg.setColor(1, 1, 1, 1)
    lg.draw(img, cx, cy, 0, scale, scale, iw * 0.5, ih * 0.5)
    return
  end

  lg.setColor(Color.hex("#cbd5e1"))
  lg.circle("fill", cx, cy, size * 0.35)
end

function M.drawTierPips(cx, cy, tier)
  local lg = love.graphics
  local color = (tier >= 3) and Color.hex("#ffdf6b") or (tier == 2 and Color.hex("#7dd3fc") or Color.hex("#cbd5e1"))
  local spacing = 7
  local startX = cx - ((tier - 1) * spacing) / 2
  for i = 0, tier - 1 do
    local x = math.floor(startX + i * spacing + 0.5)
    lg.setColor(Color.hex("#2a1d24"))
    lg.rectangle("fill", x - 3, cy - 3, 6, 6)
    lg.setColor(color)
    lg.rectangle("fill", x - 2, cy - 2, 4, 4)
  end
end

--- Draws a feet-anchored pixel sprite and returns the sprite's top Y (relative to origin).
local function drawFeetAnchored(img, feetY, scale, offsetX)
  local iw, ih = img:getDimensions()
  love.graphics.draw(img, math.floor(offsetX + 0.5), feetY, 0, scale, scale, math.floor(iw / 2), ih - 2)
  return feetY - (ih - 5) * scale
end

function M.drawAllySprite(unit, time)
  local lg = love.graphics
  local r = unit.radius or 15
  local attacking = unit.attackAnim and unit.attackAnim > 0
  local bob = attacking and 0 or ((math.floor(time * 3 + unit.x * 0.03) % 2 == 0) and 0 or -1)
  local lunge = attacking and 3 or 0
  local feetY = math.floor(r * 0.8 + 0.5)

  lg.push()
  lg.translate(math.floor(unit.x + 0.5), math.floor(unit.y + 0.5))

  if unit.overdriveTimer and unit.overdriveTimer > 0 then
    lg.setColor(1, 0.43, 0.31, 0.92)
    lg.setLineWidth(2)
    lg.ellipse("line", 0, feetY, 16, 6)
  end
  if unit.rarity and unit.rarity.id == "prism" then
    local col = prismColor(time)
    lg.setColor(col[1], col[2], col[3], 0.75)
    lg.setLineWidth(1.5)
    lg.ellipse("line", 0, feetY, 14, 5)
  end

  local img = PixelArt.getUnitImage(unit)
  local top = -r - 10
  if img then
    if unit.hitFlash and unit.hitFlash > 0 then
      lg.setColor(1, 0.55, 0.55, 1)
    else
      lg.setColor(1, 1, 1, 1)
    end
    top = drawFeetAnchored(img, feetY + bob, M.UNIT_SCALE, lunge)
  else
    lg.setColor(0.10, 0.07, 0.09, 0.32)
    lg.ellipse("fill", 0, feetY, 11, 4)
    lg.setColor(unit.color)
    lg.rectangle("fill", -r * 0.75, -r * 0.65, r * 1.5, r * 1.4, 5, 5)
  end
  unit.spriteTop = top - bob

  if not unit.isSummon then
    M.drawTierPips(0, unit.spriteTop - 11, unit.tier or 1)
  end

  lg.setLineWidth(1)
  lg.pop()
end

function M.drawEnemySprite(foe, time)
  local lg = love.graphics
  local r = foe.radius or 14
  local attacking = foe.attackAnim and foe.attackAnim > 0
  local bob = attacking and 0 or ((math.floor(time * 3.4 + foe.x * 0.03) % 2 == 0) and 0 or -1)
  local lunge = attacking and -3 or 0
  local scale = foe.isBoss and M.BOSS_SCALE or M.UNIT_SCALE
  local feetY = math.floor(r * 0.8 + 0.5)

  lg.push()
  lg.translate(math.floor(foe.x + 0.5), math.floor(foe.y + 0.5))

  local img = PixelArt.getEnemyImage(foe)
  local top = -r - 10
  if img then
    if foe.hitFlash and foe.hitFlash > 0 then
      lg.setColor(1, 0.55, 0.55, 1)
    elseif foe.chillTimer and foe.chillTimer > 0 then
      lg.setColor(0.55, 0.88, 1.0, 1)
    elseif foe.burnTimer and foe.burnTimer > 0 then
      lg.setColor(1.0, 0.72, 0.45, 1)
    elseif foe.rootTimer and foe.rootTimer > 0 then
      lg.setColor(0.76, 1.0, 0.55, 1)
    else
      lg.setColor(1, 1, 1, 1)
    end
    top = drawFeetAnchored(img, feetY + bob, scale, lunge)
  else
    lg.setColor(0.10, 0.07, 0.09, 0.34)
    lg.ellipse("fill", 0, feetY, foe.isBoss and 22 or 11, foe.isBoss and 7 or 4)
    lg.setColor(foe.color)
    lg.circle("fill", 0, 0, r)
  end
  foe.spriteTop = top - bob

  if foe.burnTimer and foe.burnTimer > 0 then
    lg.setColor(1, 0.52, 0.12, 0.85)
    lg.rectangle("fill", 8, foe.spriteTop + 6 + math.floor(math.sin(time * 12) * 2), 3, 3)
  end
  if foe.chillTimer and foe.chillTimer > 0 then
    lg.setColor(0.35, 0.85, 1, 0.9)
    lg.rectangle("fill", -11, foe.spriteTop + 8, 3, 3)
  end

  lg.setLineWidth(1)
  lg.pop()
end

return M
