local Color = require("src.utils.color")

local M = {}

function M.drawSymbolIcon(symbolId, cx, cy, size)
  size = size or 38
  local s = size * 0.5
  local lg = love.graphics
  lg.push()
  lg.translate(cx, cy)

  if symbolId == "shield" then
    lg.setColor(Color.hex("#3a6ea5"))
    lg.polygon("fill", 0, -s * 0.85, s * 0.78, -s * 0.48, s * 0.65, s * 0.35, 0, s * 0.9, -s * 0.65, s * 0.35, -s * 0.78, -s * 0.48)
    lg.setLineWidth(2.5)
    lg.setColor(Color.hex("#cde4ff"))
    lg.polygon("line", 0, -s * 0.85, s * 0.78, -s * 0.48, s * 0.65, s * 0.35, 0, s * 0.9, -s * 0.65, s * 0.35, -s * 0.78, -s * 0.48)
    lg.setColor(Color.hex("#8cc4ff"))
    lg.rectangle("fill", -3, -s * 0.45, 6, s * 0.95)
    lg.rectangle("fill", -s * 0.38, -3, s * 0.76, 6)
  elseif symbolId == "bow" then
    lg.setColor(Color.hex("#d49b54"))
    lg.setLineWidth(4)
    lg.arc("line", "open", -s * 0.15, 0, s * 0.72, -math.pi * 0.42, math.pi * 0.42)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.setLineWidth(1.6)
    lg.line(s * 0.04, -s * 0.69, s * 0.04, s * 0.69)
    lg.setColor(Color.hex("#80ed99"))
    lg.setLineWidth(2.5)
    lg.line(-s * 0.55, 0, s * 0.72, 0)
    lg.setColor(Color.hex("#b5f0b8"))
    lg.polygon("fill", s * 0.82, 0, s * 0.52, -s * 0.22, s * 0.52, s * 0.22)
  elseif symbolId == "staff" then
    lg.setColor(Color.hex("#8f5c38"))
    lg.setLineWidth(4)
    lg.line(-s * 0.45, s * 0.78, s * 0.28, -s * 0.32)
    lg.setColor(Color.hex("#c77dff"))
    lg.circle("fill", s * 0.38, -s * 0.46, s * 0.34)
    lg.setColor(Color.hex("#f3d9ff"))
    lg.circle("fill", s * 0.3, -s * 0.54, s * 0.12)
  elseif symbolId == "horse" then
    lg.setColor(Color.hex("#e69d45"))
    lg.polygon("fill",
      -s * 0.45, s * 0.72,
      -s * 0.38, -s * 0.15,
      -s * 0.05, -s * 0.75,
      s * 0.2, -s * 0.5,
      s * 0.65, -s * 0.2,
      s * 0.52, s * 0.12,
      s * 0.1, s * 0.08,
      s * 0.28, s * 0.72
    )
    lg.setLineWidth(2)
    lg.setColor(Color.hex("#ffe5b4"))
    lg.polygon("line",
      -s * 0.45, s * 0.72,
      -s * 0.38, -s * 0.15,
      -s * 0.05, -s * 0.75,
      s * 0.2, -s * 0.5,
      s * 0.65, -s * 0.2,
      s * 0.52, s * 0.12,
      s * 0.1, s * 0.08,
      s * 0.28, s * 0.72
    )
    lg.setColor(Color.hex("#1b1d2b"))
    lg.rectangle("fill", s * 0.18, -s * 0.32, 4, 4)
  elseif symbolId == "skull" then
    lg.setColor(Color.hex("#d8f3dc"))
    lg.circle("fill", 0, -s * 0.14, s * 0.56)
    lg.rectangle("fill", -s * 0.32, s * 0.2, s * 0.64, s * 0.44)
    lg.setColor(Color.hex("#14213d"))
    lg.circle("fill", -s * 0.22, -s * 0.12, s * 0.15)
    lg.circle("fill", s * 0.22, -s * 0.12, s * 0.15)
    lg.setColor(Color.hex("#57d1c9"))
    lg.rectangle("fill", -s * 0.25, -s * 0.15, 4, 4)
    lg.rectangle("fill", s * 0.18, -s * 0.15, 4, 4)
  elseif symbolId == "coin" then
    lg.setColor(Color.hex("#f6c945"))
    lg.circle("fill", 0, 0, s * 0.68)
    lg.setLineWidth(3)
    lg.setColor(Color.hex("#fff1a8"))
    lg.circle("line", 0, 0, s * 0.68)
    lg.setColor(Color.hex("#c98a12"))
    lg.rectangle("fill", -3, -s * 0.34, 6, s * 0.68)
  elseif symbolId == "crown" then
    lg.setColor(Color.hex("#ffdf6b"))
    lg.polygon("fill", -s * 0.72, s * 0.5, -s * 0.8, -s * 0.45, -s * 0.35, 0, 0, -s * 0.7, s * 0.35, 0, s * 0.8, -s * 0.45, s * 0.72, s * 0.5)
    lg.setLineWidth(2)
    lg.setColor(Color.hex("#fff8d6"))
    lg.polygon("line", -s * 0.72, s * 0.5, -s * 0.8, -s * 0.45, -s * 0.35, 0, 0, -s * 0.7, s * 0.35, 0, s * 0.8, -s * 0.45, s * 0.72, s * 0.5)
    lg.setColor(Color.hex("#ef476f"))
    lg.rectangle("fill", -4, -s * 0.1, 8, 8)
  end

  lg.setLineWidth(1)
  lg.pop()
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
  lg.setColor(0, 0, 0, 0.38)
  lg.ellipse("fill", 0, r * 0.88 - bob, r * 0.85, r * 0.34)

  -- Overdrive aura
  if unit.overdriveTimer and unit.overdriveTimer > 0 then
    lg.setColor(1, 0.43, 0.31, 0.85)
    lg.setLineWidth(2.5)
    lg.circle("line", 0, 0, r + 6)
  end

  -- Body
  if unit.hitFlash and unit.hitFlash > 0 then
    lg.setColor(1, 1, 1, 1)
  else
    lg.setColor(unit.color)
  end
  lg.rectangle("fill", -r * 0.75, -r * 0.65, r * 1.5, r * 1.4, 5, 5)
  lg.setLineWidth(2)
  lg.setColor((unit.tier >= 3) and Color.hex("#ffdf6b") or (unit.tier == 2 and Color.hex("#cbd5e1") or Color.hex("#1e2235")))
  lg.rectangle("line", -r * 0.75, -r * 0.65, r * 1.5, r * 1.4, 5, 5)

  -- Class headwear / weapon
  if unit.hitFlash and unit.hitFlash > 0 then
    lg.setColor(1, 1, 1, 1)
  else
    lg.setColor(unit.accent)
  end

  if unit.baseId == "mage" or unit.classId == "archmage" or unit.classId == "pyromancer" then
    lg.polygon("fill", -r * 0.75, -r * 0.5, 0, -r * 1.35, r * 0.75, -r * 0.5)
  elseif unit.baseId == "ranger" or unit.classId == "sniper" or unit.classId == "windrunner" then
    lg.rectangle("fill", -r * 0.5, -r * 0.9, r, r * 0.45)
    lg.setColor(Color.hex("#f4d58d"))
    lg.setLineWidth(2.5)
    lg.arc("line", "open", r * 0.55, 0, r * 0.6, -1.1, 1.1)
  elseif unit.baseId == "cavalry" or unit.classId == "vanguard" or unit.classId == "dragonknight" then
    lg.setColor(Color.hex("#ff595e"))
    lg.rectangle("fill", -r * 0.2, -r * 1.15, r * 0.4, r * 0.45)
    lg.setColor(Color.hex("#fff1a8"))
    lg.setLineWidth(3)
    lg.line(-r * 0.2, 2, r * 1.35, -3)
  elseif unit.baseId == "skeleton" then
    lg.setColor(Color.hex("#f1f5f9"))
    lg.circle("fill", 0, -r * 0.35, r * 0.45)
  else
    lg.rectangle("fill", -r * 0.55, -r * 0.95, r * 1.1, r * 0.42)
    lg.setColor(Color.hex("#161925"))
    lg.rectangle("fill", -r * 0.15, -r * 0.78, r * 0.55, 3)
    lg.setColor(Color.hex("#e2e8f0"))
    lg.rectangle("fill", r * 0.65, -r * 0.5, 4, r * 1.1)
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

  lg.setColor(0, 0, 0, 0.42)
  lg.ellipse("fill", 0, r * 0.85 - bob, r * 0.9, r * 0.35)

  if foe.typeId == "boss_beholder" or foe.typeId == "boss_abyss" then
    lg.setColor(foe.accent)
    lg.setLineWidth(2.5)
    for i = 0, 5 do
      local ang = (i / 6) * math.pi * 2 + time * 1.2
      lg.line(math.cos(ang) * r * 0.7, math.sin(ang) * r * 0.7, math.cos(ang) * r * 1.25, math.sin(ang) * r * 1.25)
    end
    lg.setColor((foe.hitFlash > 0) and { 1, 1, 1, 1 } or foe.color)
    lg.circle("fill", 0, 0, r)
    lg.setColor(foe.accent)
    lg.circle("line", 0, 0, r)
    lg.setColor(1, 1, 1, 1)
    lg.circle("fill", -4, -2, r * 0.42)
    lg.setColor(Color.hex("#ff0054"))
    lg.circle("fill", -6, -2, r * 0.2)
  elseif foe.typeId == "slime" then
    lg.setColor((foe.hitFlash > 0) and { 1, 1, 1, 1 } or foe.color)
    lg.arc("fill", 0, 2, r, math.pi, 0)
    lg.rectangle("fill", -r, 2, r * 2, r * 0.55)
    lg.setColor(Color.hex("#0b132b"))
    lg.rectangle("fill", -5, -2, 3, 4)
    lg.rectangle("fill", 1, -2, 3, 4)
  else
    lg.setColor((foe.hitFlash > 0) and { 1, 1, 1, 1 } or foe.color)
    local rad = foe.isBoss and 8 or 5
    lg.rectangle("fill", -r * 0.78, -r * 0.7, r * 1.56, r * 1.45, rad, rad)
    lg.setLineWidth(foe.isBoss and 3 or 1.8)
    lg.setColor(foe.isBoss and Color.hex("#ffbe0b") or Color.hex("#181a24"))
    lg.rectangle("line", -r * 0.78, -r * 0.7, r * 1.56, r * 1.45, rad, rad)

    if foe.isBoss or foe.typeId == "orc" or foe.typeId == "dark_knight" then
      lg.setColor(foe.accent)
      lg.polygon("fill", -r * 0.6, -r * 0.65, -r * 0.9, -r * 1.15, -r * 0.25, -r * 0.65)
      lg.polygon("fill", r * 0.6, -r * 0.65, r * 0.9, -r * 1.15, r * 0.25, -r * 0.65)
    end

    lg.setColor(Color.hex("#ff4d6d"))
    lg.rectangle("fill", -r * 0.45, -r * 0.25, 4, 4)
    lg.rectangle("fill", -r * 0.1, -r * 0.25, 4, 4)
  end

  lg.setLineWidth(1)
  lg.pop()
end

return M
