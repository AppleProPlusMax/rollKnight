local Color = require("src.utils.color")
local PixelArt = require("src.render.pixel_art")

local M = {}

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
  lg.setColor(color)
  local spacing = 8
  local startX = cx - ((tier - 1) * spacing) / 2
  for i = 0, tier - 1 do
    local x = startX + i * spacing
    lg.polygon("fill", x, cy - 4, x + 3, cy, x, cy + 4, x - 3, cy)
  end
end

function M.drawAllySprite(unit, time)
  local lg = love.graphics
  local r = unit.radius or 15
  local bob = (unit.attackAnim and unit.attackAnim > 0) and -3 or (math.sin(time * 5 + unit.x * 0.05) * 1.5)

  lg.push()
  lg.translate(unit.x, unit.y + bob)

  -- Shadow
  lg.setColor(0, 0, 0, 0.42)
  lg.ellipse("fill", 0, r * 0.9 - bob, r * 0.9, r * 0.36)

  -- Rarity halo
  if unit.rarity and unit.rarity.id ~= "normal" then
    local col = (unit.rarity.id == "prism") and prismColor(time) or unit.rarity.color
    lg.setColor(col[1], col[2], col[3], 0.78)
    lg.setLineWidth(unit.rarity.id == "prism" and 2.5 or 1.6)
    lg.circle("line", 0, 2, r + 3)
  end

  -- Overdrive aura
  if unit.overdriveTimer and unit.overdriveTimer > 0 then
    lg.setColor(1, 0.43, 0.31, 0.9)
    lg.setLineWidth(2.5)
    lg.circle("line", 0, 0, r + 7)
  end

  local img = PixelArt.getUnitImage(unit)
  if img then
    local iw, ih = img:getDimensions()
    local targetSize = (r * 2.25)
    local scale = targetSize / iw
    if unit.hitFlash and unit.hitFlash > 0 then
      lg.setColor(1, 0.65, 0.65, 1)
    else
      lg.setColor(1, 1, 1, 1)
    end
    lg.draw(img, 0, 0, 0, scale, scale, iw * 0.5, ih * 0.5)
  else
    lg.setColor(unit.color)
    lg.rectangle("fill", -r * 0.75, -r * 0.65, r * 1.5, r * 1.4, 5, 5)
  end

  if not unit.isSummon then
    M.drawTierPips(0, -r - 15, unit.tier or 1)
  end

  lg.setLineWidth(1)
  lg.pop()
end

function M.drawEnemySprite(foe, time)
  local lg = love.graphics
  local r = foe.radius or 14
  local bob = math.sin(time * 6 + foe.x * 0.04) * 1.8

  lg.push()
  lg.translate(foe.x, foe.y + bob)

  lg.setColor(0, 0, 0, 0.45)
  lg.ellipse("fill", 0, r * 0.85 - bob, r * 0.95, r * 0.36)

  if foe.isBoss then
    lg.setColor(foe.accent[1], foe.accent[2], foe.accent[3], 0.45)
    lg.setLineWidth(2)
    lg.circle("line", 0, 0, r + 4 + math.sin(time * 4) * 2)
  end

  local img = PixelArt.getEnemyImage(foe)
  if img then
    local iw, ih = img:getDimensions()
    local targetSize = r * 2.3
    local scale = targetSize / iw
    if foe.hitFlash and foe.hitFlash > 0 then
      lg.setColor(1, 0.55, 0.55, 1)
    else
      lg.setColor(1, 1, 1, 1)
    end
    lg.draw(img, 0, 0, 0, scale, scale, iw * 0.5, ih * 0.5)
  else
    lg.setColor(foe.color)
    lg.circle("fill", 0, 0, r)
  end

  lg.setLineWidth(1)
  lg.pop()
end

return M
