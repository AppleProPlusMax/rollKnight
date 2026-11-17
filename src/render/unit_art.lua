-- Slotbound-style chibi pixel characters with explicit internal K ink seams,
-- optional 2-layer rarity glow halo, and baked oval ground shadow.
local Color = require("src.utils.color")

local M = {}
local cache = {}

M.OUTLINE = "#2a1d24"
M.PAD = 3

-- ---------------------------------------------------------------------------
-- Templates (all allies face RIGHT; K = internal ink outline seam)
-- ---------------------------------------------------------------------------
local T = {}

-- Swordsman / Fighter: upright broadsword on left, rounded helm, blue tunic, separated boots
T.swordsman = {
  "......aAAAa.....",
  ".KWK.aAAAAAa....",
  "KWWKaLLLLLLLa...",
  "KWWKAKKKKKKKA...",
  "KWWKSSSESSEsK...",
  "KWWKSSSSSSSsK...",
  "KLKKKTTTTTTTKK..",
  "KYKKTYYTTTTTtK..",
  ".KK.KTTTTTTTTK..",
  "....KLLLLLLLtK..",
  "....KTTKKTTKK...",
  "....KddKKddK....",
  "....KllKKllK....",
}

-- Shield Knight / Paladin: upright broadsword on left + enclosed helm + distinct front shield
T.shield_knight = {
  "......aAAAa.....",
  ".KWK.aAAAAAa....",
  "KWWKaAAKKKAAa...",
  "KWWKAKSSSSSAK...",
  "KWWKAKSSESsAK...",
  "KWWKAAKKKKKAA...",
  "KLKKKTTTTKKKK...",
  "KYKKTTTTKXXXxK..",
  ".KK.KTTTKXYXxK..",
  "....KTTTKXXXxK..",
  "....KTTtKxxxKK..",
  "....KddK.KKdd...",
  "....KllK..Kll...",
}

-- Pirate / Berserker / Champion: curved cutlass upright on left, bandana/captain hat, coat
T.pirate = {
  ".....PPPPPP.....",
  "KWK.PPPPYYYYP...",
  "KWWKPKKKKKKKP...",
  "KWwKKSSESSEsK...",
  "KWWKSSssssssK...",
  "KYKKKTTTTTTTKK..",
  ".KK.KTTYYTTTYK..",
  "....KTTTTTTTYK..",
  "....KLLLLLLLtK..",
  "....KddKKddKK...",
  "....KllKKllK....",
}

-- Elf Bladedancer / Windrunner: pointy elf ear left, hood/helm, diagonal blade right
T.elf_blade = {
  "....hhhh........",
  "...hHHHHh.......",
  ".KshHHHHHh......",
  "KSShKKKKKh......",
  ".KKSSESSEsK..KWK",
  "...SSSSSSsK.KWWK",
  "..KTTTTTTKKKWWK.",
  ".KhTTTTTtKKYKK..",
  ".KhKTTTTK.......",
  "...KLLLLK.......",
  "...KTTKKTTK.....",
  "...KddKKddK.....",
  "...KllKKllK.....",
}

-- Hooded Ranger / Sniper: pointy ear left, green/emerald hood, bow held right with K seam
T.archer = {
  ".....hhhh.......",
  "....hHHHHh......",
  "..KshHHHHHh.KBK.",
  ".KSShKKKKKhKBBc.",
  "..KKSSESSEsK.Bc.",
  "....SSSSSSsK.Bc.",
  "..QKTTTTTTKK.Bc.",
  ".KQtTLLTTTSSKBc.",
  "..KKTTTTTTK.KBc.",
  "....KTTttK.KBBK.",
  "....KddKKddK.KK.",
  "....KllKKllK....",
}

-- Caster / Cleric / Mage: hat/helm with brim crease, striped robe, vertical orb/mace staff right
T.mage = {
  ".......aA.......",
  "......aAAAa.....",
  ".....aAAAAAa.KOK",
  "...KKYYYYYYKKOoO",
  "...hSSESSEsKKKOK",
  "...hFsSSssFK.KLK",
  "..KrRRRRRRrKKKLK",
  ".KrRRYRRRRYrSSK.",
  ".KrRRWRRRWWrKLK.",
  ".KrRRWRRRWWrKLK.",
  "..KrrrrrrrrK.KLK",
  "....KllKKllK.KlK",
}

-- Druid / Necromancer: horned dark hood, shadow face with glowing eyes, crescent scythe right
T.hood = {
  "..Y......Y......",
  "..hhHHHHhh..KKK.",
  "..hHHHHHHh.KWWOK",
  "..hKKKKKKhKWOKKK",
  "..hFGFFGFh.KLK..",
  "..hFFFFFFh.KLK..",
  "..KRRRRRRKKKLK..",
  ".KrRRYRRRRYSSK..",
  ".KrRRRRRRRRKLK..",
  ".KrRRYYYYRRKLK..",
  "..KrrrrrrrrKLK..",
  "....KrrKKrrKlK..",
}

-- Mounted Lancer: plumed knight atop armored steed, couched lance right
T.rider = {
  ".....PPP............",
  "....aAAAa...........",
  "...aAAAAAa.......KWK",
  "...aKKKKKa......KWW.",
  "....SSESsK....KWW...",
  "..KKTTTTTKK.KWW.....",
  ".KTTTYTTTSSWW..KNN..",
  "KMMNNNNlNNNNNNKNEEN.",
  "KMNNNNnnnnNNNNNNNNK.",
  ".K.KNNNNNNNNNNNNKK..",
  "...KNNK.....KNNK....",
  "...KllK.....KllK....",
}

-- Two-pronged Jester with bell wand
T.jester = {
  ".KY.......YK....",
  ".KPP.....CCK....",
  "..KPPP.CCCK.....",
  "...KWWWWWKK.....",
  "...KWEWWEWK.....",
  "...KWWRRWWK.KYK.",
  "..KPPPCCCCKKSSK.",
  ".KPPPPCCCCKKLK..",
  "..KPPYCCYCK.KLK.",
  "...KPPKKCCK.....",
  "...KYYKKYYK.....",
}

-- Summoned Skeleton soldier
T.skeleton = {
  "....WWWWW.......",
  "...WWWWWWW......",
  "...WEEWEEW..KM..",
  "...WWWwWWW..KMK.",
  "....WwWwW...KMK.",
  "..KwWWWWWWK.KMK.",
  ".KwKWwWwWWK.KLK.",
  "...KWWWWWWK..K..",
  "....KWKKWK......",
  "....KWKKWK......",
  "....KwKKwK......",
}

T.goblin = {
  "....gGGGg.....",
  "Gg.gGGGGGg.gG.",
  ".gGGGEGGEGGg..",
  "...gKKKKKKg...",
  "....gWgWgg....",
  "..KLLLLLLK.KM.",
  ".KGLLlLLLGKMK.",
  "..KLLLLLlK.K..",
  "....KggKKggK..",
  "....KllKKllK..",
}

T.orc = {
  "....nnnnnn......",
  "...nmmmmmmn.....",
  "...OOEOOOEO.....",
  "...OOOOOOOO..AA.",
  "...OWKKKKWO.AAA.",
  "..KLLLLLLLLKKOK.",
  ".KOLLLYLLLLK.LK.",
  ".KOLLLLLLLLK.LK.",
  "..KLLLLLLLLK.LK.",
  "...KOOOKKOOOKlK.",
  "...KllKKllK.....",
}

T.slime = {
  ".....CCCC.....",
  "...CCLLCCCC...",
  "..CLLWCCCCCC..",
  ".CCLCCCCCCCCC.",
  ".CCCCECCCECCC.",
  "CCCCCCCCCCCCcc",
  "cCCCCCCCCCCCcc",
  ".cccccccccccc.",
}

T.beholder = {
  "...Y....Y....Y....",
  "...p....p....p....",
  "....p...p...p.....",
  ".....PPPPPPPP.....",
  "...PPPPPPPPPPPP...",
  "..PPPWWWWWWPPPPP..",
  ".PPPWWWRRWWWPPPPp.",
  ".PPPWWRKKRWWPPPPp.",
  ".PPPWWWRRWWWPPPPp.",
  "..PPPWWWWWWPPPPp..",
  "..PPPMMMMMMMPPpp..",
  "...PPMWMWMWMPpp...",
  "....pPPPPPPPpp....",
  ".....pp.pp.pp.....",
}

-- ---------------------------------------------------------------------------
-- Shared warm, muted Slotbound-like color sets
-- ---------------------------------------------------------------------------
local SKIN = { S = "#eab896", s = "#c98d6d", E = "#2a1d24" }
local STEEL = { A = "#b8cadb", a = "#8197ae", d = "#526278", L = "#dfeaf2" }

local function merge(...)
  local out = {}
  for _, t in ipairs({ ... }) do
    for k, v in pairs(t) do out[k] = v end
  end
  return out
end

-- ---------------------------------------------------------------------------
-- Unit & Enemy mappings
-- ---------------------------------------------------------------------------
local UNITS = {
  warrior = { tpl = "swordsman", pal = merge(SKIN, STEEL, {
    T = "#5579b0", t = "#3a5582", Y = "#e2b553",
    W = "#f3f0e6", L = "#7a4b31", d = "#5c3927", l = "#4a2e22",
  }) },
  paladin = { tpl = "shield_knight", pal = merge(SKIN, STEEL, {
    A = "#d8e3ee", a = "#9db1c7",
    T = "#6d88a8", t = "#4c6380", Y = "#e2b553",
    W = "#f7f3e6", L = "#7a4b31", d = "#5b3b28", l = "#4a2e22",
    X = "#6a7384", x = "#c5cfd9",
  }) },
  berserker = { tpl = "pirate", pal = merge(SKIN, {
    P = "#b83b35", Y = "#8a2926", T = "#efe8d6", t = "#c9c0aa",
    W = "#f4f1ea", w = "#b5bec9", L = "#6b432b", d = "#523322", l = "#40271b",
  }) },
  deathknight = { tpl = "shield_knight", pal = {
    A = "#565a96", a = "#393c6e", S = "#1d1930", s = "#141124", E = "#5ef2e0",
    T = "#3a3466", t = "#27234a", Y = "#5ef2e0",
    W = "#b8fff5", L = "#393c6e", d = "#27234a", l = "#1d1930",
    X = "#2b274d", x = "#7d82c0",
  } },
  champion = { tpl = "pirate", pal = merge(SKIN, {
    P = "#362b38", Y = "#eab84e", s = "#6e462d",
    T = "#3a303c", t = "#261f29", W = "#f4f1ea", w = "#b5bec9",
    L = "#785134", d = "#563825", l = "#40271b",
  }) },

  ranger = { tpl = "archer", pal = merge(SKIN, {
    H = "#5e9c4c", h = "#3f7034",
    T = "#6ea659", t = "#4a7a3a", B = "#8c5c34", c = "#efe8d6", Q = "#7a4b31",
    d = "#5c3927", l = "#4a2e22", L = "#e2b553",
  }) },
  sniper = { tpl = "archer", pal = merge(SKIN, {
    H = "#2f6b5c", h = "#1f4a40",
    T = "#3c7d6b", t = "#285a4c", B = "#5b3b28", c = "#d84a4a", Q = "#5b3b28",
    d = "#462e20", l = "#332118", L = "#c8473b",
  }) },
  windrunner = { tpl = "elf_blade", pal = merge(SKIN, {
    H = "#e2e9df", h = "#9db5a3",
    T = "#f3f6f0", t = "#5ea36e", W = "#e8f0f5", Y = "#e2b553",
    L = "#7a4b31", d = "#5c3927", l = "#4a2e22",
  }) },

  mage = { tpl = "mage", pal = merge(SKIN, {
    A = "#5a7fc4", a = "#3e5c96", Y = "#e2b553", h = "#4f74ad", F = "#d8d2c4",
    R = "#5a82c4", r = "#3b588e", W = "#f3efe4", O = "#7fe3f0", o = "#3fa6c4",
    L = "#7a4b31", l = "#4e3125",
  }) },
  archmage = { tpl = "mage", pal = merge(SKIN, {
    A = "#b4c8dc", a = "#7c94ad", Y = "#dfe8f0", h = "#7c94ad", F = "#f1ede2",
    R = "#63a372", r = "#41734d", W = "#f5f2ea", O = "#a6ecff", o = "#59b2d4",
    L = "#6e869c", l = "#495d6e",
  }) },
  pyromancer = { tpl = "mage", pal = merge(SKIN, {
    A = "#c8473b", a = "#8f2f28", Y = "#f39a3b", h = "#8f2f28", F = "#5b2f22",
    R = "#c8473b", r = "#8f2f28", W = "#ffd36b", O = "#ffd36b", o = "#f2762e",
    L = "#5b3b28", l = "#3a261b",
  }) },

  necro = { tpl = "hood", pal = {
    Y = "#a6c4d8", H = "#4e4652", h = "#322c36", F = "#2d2630", G = "#5ef2e0",
    R = "#5a7049", r = "#3c4d30", W = "#c8dce6", O = "#7ea3b5", S = "#5a7049",
    L = "#7a4b31", l = "#4e3125",
  } },
  necrolord = { tpl = "hood", pal = {
    Y = "#f2cf5b", H = "#2f2850", h = "#1e1a36", F = "#141022", G = "#7ef5e6",
    R = "#3a3066", r = "#261f46", W = "#d9f7f2", O = "#5ef2e0", S = "#e8e2d2",
    L = "#a9a294", l = "#6d675c",
  } },
  veil = { tpl = "hood", pal = {
    Y = "#ffb3f0", H = "#8a42ad", h = "#5d2978", F = "#251733", G = "#ffb3f0",
    R = "#6e3290", r = "#4a2064", W = "#ffd4f7", O = "#d86ee0", S = "#eab896",
    L = "#6c2f88", l = "#46205a",
  } },

  cavalry = { tpl = "rider", pal = merge(SKIN, STEEL, {
    P = "#c8473b", T = "#b8443a", Y = "#e2b553",
    W = "#e9e4d6", N = "#9a6a3c", n = "#6b4527", M = "#4e3125", l = "#4e3125",
  }) },
  vanguard = { tpl = "rider", pal = merge(SKIN, {
    A = "#ffe7a1", a = "#e0b04a",
    P = "#4f74ad", T = "#4f74ad", Y = "#ffe7a1",
    W = "#ffffff", N = "#ece6d8", n = "#b9b1a0", M = "#e0b04a", l = "#6b5a46",
  }) },
  dragonknight = { tpl = "rider", pal = merge(SKIN, {
    A = "#e66a4a", a = "#a83b2c",
    P = "#ffd36b", T = "#7a2622", Y = "#ffd36b",
    W = "#ffd36b", N = "#a83b2c", n = "#6e2420", M = "#f2762e", l = "#3a1512",
  }) },

  jester = { tpl = "jester", pal = {
    Y = "#f2cf5b", P = "#d24f8a", C = "#3fb6c9", W = "#f4efe4",
    E = "#2a1d24", R = "#c8473b", S = "#eab896", L = "#7a4b31",
  } },
  jesterking = { tpl = "jester", pal = {
    Y = "#ffe7a1", P = "#c8473b", C = "#e0b04a", W = "#f4efe4",
    E = "#2a1d24", R = "#8f2f28", S = "#eab896", L = "#e0b04a",
  } },

  skeleton = { tpl = "skeleton", pal = {
    W = "#ece6d8", w = "#b9b1a0", E = "#2a1d24", M = "#a9b2bf", L = "#7a4b31",
  } },
}

local ENEMIES = {
  goblin = { tpl = "goblin", pal = {
    G = "#7fae4a", g = "#557a32", E = "#d84a4a", W = "#f3f0e6",
    L = "#8a5a3a", l = "#5e3b28", M = "#c3ccd6",
  } },
  slime = { tpl = "slime", pal = {
    C = "#4fc3d4", c = "#2f8aa0", L = "#a6ecf2", W = "#ffffff", E = "#1e3a4a",
  } },
  orc = { tpl = "orc", pal = {
    O = "#d0743c", E = "#2a1d24", W = "#f3f0e6", n = "#4b4f5c", m = "#6f7381",
    L = "#7a4b31", l = "#4e3125", Y = "#c3ccd6", A = "#c3ccd6",
  } },
  archer_foe = { tpl = "archer", pal = {
    H = "#6b4aa8", h = "#48307a", S = "#b9a6d6", s = "#8a76a8", E = "#ff5470",
    T = "#5a3e8f", t = "#3e2a66", L = "#e2b553", d = "#2a1d44", l = "#221636",
    B = "#5e3b28", c = "#d8d0e6", Q = "#3e2a66",
  } },
  dark_knight = { tpl = "shield_knight", pal = {
    A = "#5f6a7d", a = "#434b5a", S = "#1c1c26", s = "#14141c", E = "#ff4d4d",
    T = "#3b4250", t = "#272c36", Y = "#d9a441",
    W = "#c3ccd6", L = "#434b5a", d = "#2c323d", l = "#1e222b",
    X = "#3b4250", x = "#7a8494",
  } },
  boss_warlord = { tpl = "shield_knight", pal = {
    A = "#c8473b", a = "#8f2f28", S = "#d0743c", s = "#a8582c", E = "#ffe066",
    T = "#6e2420", t = "#4a1714", Y = "#ffe066",
    W = "#f3f0e6", L = "#4b4f5c", d = "#33363f", l = "#24262e",
    X = "#4b4f5c", x = "#ffe066",
  } },
  boss_beholder = { tpl = "beholder", pal = {
    P = "#8a4ab8", p = "#5e2f85", W = "#f4efe4", R = "#e04a6a",
    Y = "#ffd36b", M = "#3a1838",
  } },
}

-- ---------------------------------------------------------------------------
-- Builder: explicit K seams + auto outer ink + 2-layer soft glow + oval shadow
-- ---------------------------------------------------------------------------
local function toColor(c)
  if type(c) == "string" then return Color.hex(c) end
  return { c[1], c[2], c[3], c[4] or 1 }
end

local function buildSprite(key, rows, palette, opts)
  if cache[key] then return cache[key] end
  if not love or not love.image or not love.graphics then return nil end
  opts = opts or {}

  local srcH = #rows
  local srcW = 0
  for _, r in ipairs(rows) do if #r > srcW then srcW = #r end end
  local pad = M.PAD
  local W, H = srcW + pad * 2, srcH + pad * 2

  -- grid[y][x] = {r,g,b,a}; kinds: 0 empty, 1 body, 2 ink, 3 inner glow, 4 outer glow
  local grid, kind = {}, {}
  for y = 1, H do
    grid[y], kind[y] = {}, {}
    for x = 1, W do grid[y][x] = false; kind[y][x] = 0 end
  end

  local ink = toColor(opts.outline or M.OUTLINE)
  local minFootX, maxFootX = W, 1

  for sy = 1, srcH do
    local row = rows[sy]
    for sx = 1, srcW do
      local srcX = opts.flip and (srcW - sx + 1) or sx
      local ch = row:sub(srcX, srcX)
      if ch == "K" then
        grid[sy + pad][sx + pad] = ink
        kind[sy + pad][sx + pad] = 2
      elseif ch ~= "" and ch ~= "." then
        local c = palette[ch]
        if c then
          grid[sy + pad][sx + pad] = toColor(c)
          kind[sy + pad][sx + pad] = 1
          if sy >= srcH - 1 then
            local px = sx + pad
            if px < minFootX then minFootX = px end
            if px > maxFootX then maxFootX = px end
          end
        end
      end
    end
  end

  if maxFootX < minFootX then
    minFootX = math.floor(W * 0.3)
    maxFootX = math.ceil(W * 0.7)
  end

  local function hasNeighbor(x, y, k)
    return (x > 1 and kind[y][x - 1] == k)
      or (x < W and kind[y][x + 1] == k)
      or (y > 1 and kind[y - 1][x] == k)
      or (y < H and kind[y + 1][x] == k)
  end

  -- Layer 1: auto outer 1px ink outline around body pixels
  local marks = {}
  for y = 1, H do
    for x = 1, W do
      if kind[y][x] == 0 and hasNeighbor(x, y, 1) then
        marks[#marks + 1] = { x, y }
      end
    end
  end
  for _, m in ipairs(marks) do
    grid[m[2]][m[1]] = ink
    kind[m[2]][m[1]] = 2
  end

  -- Layer 2 & 3: 2-step soft outer glow halo (matches Slotbound emerald rarity halo)
  if opts.glow then
    local gCol = toColor(opts.glow)
    local innerGlow = { gCol[1], gCol[2], gCol[3], 0.82 }
    local outerGlow = { gCol[1], gCol[2], gCol[3], 0.34 }

    marks = {}
    for y = 1, H do
      for x = 1, W do
        if kind[y][x] == 0 and hasNeighbor(x, y, 2) then
          marks[#marks + 1] = { x, y }
        end
      end
    end
    for _, m in ipairs(marks) do
      grid[m[2]][m[1]] = innerGlow
      kind[m[2]][m[1]] = 3
    end

    marks = {}
    for y = 1, H do
      for x = 1, W do
        if kind[y][x] == 0 and hasNeighbor(x, y, 3) then
          marks[#marks + 1] = { x, y }
        end
      end
    end
    for _, m in ipairs(marks) do
      grid[m[2]][m[1]] = outerGlow
      kind[m[2]][m[1]] = 4
    end
  end

  -- Baked oval pixel shadow right under the boots (Slotbound card & ground look)
  if opts.shadow ~= false then
    local shadowY1 = math.min(H - 1, srcH + pad + 1)
    local shadowY2 = math.min(H, shadowY1 + 1)
    local sx1 = math.max(1, minFootX - 2)
    local sx2 = math.min(W, maxFootX + 2)
    local sh = { ink[1], ink[2], ink[3], 0.28 }
    for y = shadowY1, shadowY2 do
      local inset = (y == shadowY2) and 1 or 0
      for x = sx1 + inset, sx2 - inset do
        if kind[y][x] == 0 then
          grid[y][x] = sh
        end
      end
    end
  end

  local id = love.image.newImageData(W, H)
  for y = 1, H do
    for x = 1, W do
      local c = grid[y][x]
      if c then
        id:setPixel(x - 1, y - 1, c[1], c[2], c[3], c[4] or 1)
      else
        id:setPixel(x - 1, y - 1, 0, 0, 0, 0)
      end
    end
  end
  local img = love.graphics.newImage(id)
  img:setFilter("nearest", "nearest")
  cache[key] = img
  return img
end

local RARITY_GLOW = {
  rare = "#7fd17a",
  epic = "#b98ae6",
  prism = "#ff8fc0",
}

function M.getUnitImage(unit, rarityId)
  local key = unit.classId or unit.baseId or "warrior"
  local def = UNITS[key] or UNITS[unit.baseId] or UNITS.warrior
  if not UNITS[key] then key = UNITS[unit.baseId] and unit.baseId or "warrior" end
  rarityId = rarityId or (unit.rarity and unit.rarity.id) or "normal"
  local glow = RARITY_GLOW[rarityId]
  return buildSprite("u_" .. key .. "_" .. (glow and rarityId or "n"), T[def.tpl], def.pal, { glow = glow })
end

function M.getEnemyImage(foe)
  local key = foe.typeId
  if key == "boss_abyss" then key = "boss_beholder" end
  if key == "boss_dread" then key = "boss_warlord" end
  local def = ENEMIES[key] or ENEMIES.goblin
  if not ENEMIES[key] then key = "goblin" end
  local glow = foe.isBoss and "#e04a4a" or nil
  return buildSprite("e_" .. key, T[def.tpl], def.pal, { flip = true, glow = glow })
end

M.UNITS = UNITS
M.ENEMIES = ENEMIES
M.TEMPLATES = T
return M
