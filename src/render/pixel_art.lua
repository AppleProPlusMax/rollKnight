local Color = require("src.utils.color")
local UnitArt = require("src.render.unit_art")

local M = {}
local cache = {}

local function parseColorChar(ch, palette)
  local c = palette[ch]
  if not c then return nil end
  if type(c) == "string" then
    return Color.hex(c)
  end
  return c
end

function M.buildSprite(key, rows, palette)
  if cache[key] then return cache[key] end
  if not love or not love.image or not love.graphics then return nil end

  local h = #rows
  local w = 1
  for y = 1, h do
    if #rows[y] > w then w = #rows[y] end
  end

  local id = love.image.newImageData(w, h)
  for y = 1, h do
    local row = rows[y]
    local rlen = #row
    for x = 1, w do
      local ch = (x <= rlen) and row:sub(x, x) or "."
      local c = parseColorChar(ch, palette)
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

-- 18x18 Slotbound-style pixel-art slot symbols
local SYMBOL_MATRICES = {
  shield = {
    palette = {
      K = "#181425", W = "#f8fafc", S = "#cbd5e1", A = "#64748b",
      B = "#3b82f6", D = "#1d4ed8", L = "#93c5fd",
    },
    rows = {
      "..................",
      "....KKKKKKKKKK....",
      "...KWWWWLLWWWWK...",
      "..KWSSSBBBBSSSAK..",
      "..KWSSSBLLBSSSAK..",
      "..KWSSSBLLBSSSAK..",
      "..KBBBBDDDDDDDDK..",
      "..KLLLLDDDDDDDDK..",
      "..KWSSSBLLBSSSAK..",
      "..KWSSSBLLBSSSAK..",
      "...KWSSBDBSSSAK...",
      "...KWSSBDBSSSAK...",
      "....KSSBBBSSAK....",
      ".....KSSBSSAK.....",
      "......KAAAAK......",
      ".......KKKK.......",
      "..................",
      "..................",
    },
  },
  bow = {
    palette = {
      K = "#181425", B = "#78350f", M = "#b45309", L = "#d97706",
      S = "#e2e8f0", W = "#f8fafc",
    },
    rows = {
      "..................",
      "..KKKKK...........",
      ".KLLLLLK..........",
      "KMLKKKKMK.........",
      "KMK....KMK........",
      ".K.W....KMKK......",
      "....W....KSSK.....",
      ".....W....KMK.....",
      "......W....KMK....",
      ".......W...KMK....",
      "........W..KMK....",
      ".........W.KMK....",
      "..........KSSK....",
      "..........KLLK....",
      "...........KK.....",
      "..................",
      "..................",
      "..................",
    },
  },
  staff = {
    palette = {
      K = "#181425", B = "#1d4ed8", M = "#3b82f6", L = "#93c5fd",
      Y = "#f59e0b", G = "#fde047", D = "#b45309",
    },
    rows = {
      ".........KKKKK....",
      ".......KKBMMMMK...",
      "......KBMMLLMMBK..",
      ".....KBMMLLMMMBK..",
      ".....KBMMMMMMBBK..",
      "....KKBMMMMMMBK...",
      "...KBMMBMMMMMBK...",
      "..KKYBBBMMMMMBBK..",
      ".KYYGGGGYYBBBYGGK.",
      ".KDDYYYYYGGGGYYDK.",
      "..KKKKDDDYYYYDDK..",
      "......KKKKKKKK....",
      "..................",
      "..................",
      "..................",
      "..................",
      "..................",
      "..................",
    },
  },
  horse = {
    palette = {
      K = "#181425", B = "#9a6338", L = "#c68b59", M = "#5c3818",
      C = "#f3e5ab", S = "#d9c282", W = "#ffffff",
    },
    rows = {
      ".......KK..KK.....",
      "......KBKKKBMK....",
      ".....KLLLLBMMK....",
      "....KLLKELLBMMK...",
      "...KCLLLLLLBMMK...",
      "..KCCCLLLLLLBMK...",
      ".KCKCCLLLLLLBMMK..",
      ".KSSSSKLLLLLBMMK..",
      "..KKKK.KLLLLBMK...",
      ".......KLLLLBMK...",
      "......KLLLLBBMK...",
      "......KLLLLBBMK...",
      "......KLLLBBMK....",
      ".......KKKKKK.....",
      "..................",
      "..................",
      "..................",
      "..................",
    },
  },
  skull = {
    palette = {
      K = "#181425", W = "#f8fafc", S = "#cbd5e1", A = "#64748b",
      B = "#78350f", M = "#b45309", C = "#5eead4", T = "#0d9488",
    },
    rows = {
      "............KKKK..",
      "...........KWWWK..",
      "..........KWWWSK..",
      ".........KWWWSK...",
      "........KWWWSK....",
      ".......KWWWSK.....",
      "......KWWWSK......",
      ".....KWWWSK.......",
      "....KWWWSK........",
      "....KAAAK.........",
      "...KBBMKK.........",
      "..KCCKK...........",
      ".KCTCK............",
      "..KKK.............",
      "..................",
      "..................",
      "..................",
      "..................",
    },
  },
  coin = {
    palette = {
      K = "#181425", O = "#b45309", G = "#eab308", Y = "#fde047", W = "#fef9c3",
    },
    rows = {
      "....KKKKKKKKKK....",
      "..KKGGGGGGGGGGKK..",
      ".KGYYYYWWWWYYYYGK.",
      ".KGYWWGGGGGGWWYGK.",
      "KGYWGGYYYYYYGGWYGK",
      "KGYWGYOOOOOOGYGWYK",
      "KGYWGYOYYYYOGYGWYK",
      "KGYWGYOYWWYOGYGWYK",
      "KGYWGYOYWWYOGYGWYK",
      "KGYWGYOYYYYOGYGWYK",
      "KGYWGYOOOOOOGYGWYK",
      ".KGYWGGYYYYGGWYGK.",
      ".KGYOGGGGGGGGOYGK.",
      "..KGGOOOOOOOOGGK..",
      "....KKKKKKKKKK....",
      "..................",
      "..................",
      "..................",
    },
  },
  jester = {
    palette = {
      K = "#181425", P = "#ec4899", R = "#be185d", C = "#06b6d4", B = "#0e7490",
      Y = "#facc15", W = "#f8fafc",
    },
    rows = {
      ".KK............KK.",
      "KYYK..........KYYK",
      ".KPPK........KCCK.",
      ".KPPPK......KCCCK.",
      "..KPRPK....KCBCK..",
      "..KPRPPKKKKCCBCK..",
      "...KWWWWWWWWWWK...",
      "...KWWKKWWKKWWK...",
      "...KWWWWWWWWWWK...",
      "...KWWRRRRRRWWK...",
      "....KWWWWWWWWK....",
      "...KPPPYCCYCCCK...",
      "..KPRPPPCCCCCCK...",
      "...KKKKKKKKKKK....",
      "..................",
      "..................",
      "..................",
      "..................",
    },
  },
  crown = {
    palette = {
      K = "#181425", G = "#eab308", Y = "#fde047", W = "#fef9c3",
      O = "#b45309", R = "#ef4444", B = "#3b82f6", E = "#22c55e",
    },
    rows = {
      "........KK........",
      ".KK....KWWK....KK.",
      "KYYK...KYYK...KYYK",
      "KGYK..KGYGYK..KYGK",
      "KGYYKKGYYYYGKYYGGK",
      "KGYYYYWWYYWWYYYYGK",
      "KGYRYYBYYYYBYYEYGK",
      "KGYYYYYYYYYYYYYYGK",
      "KGGGGGGGGGGGGGGGGK",
      "KGOOOOOOOOOOOOOOGK",
      ".KKKKKKKKKKKKKKKK.",
      "..................",
      "..................",
      "..................",
      "..................",
      "..................",
      "..................",
      "..................",
    },
  },
}

local DECOR_MATRICES = {
  winged_skull = {
    palette = {
      K = "#181425", D = "#2d2433", M = "#44364a", R = "#69202e", S = "#421822",
      H = "#854549", B = "#592c34", O = "#fb923c", Y = "#facc15", W = "#f8fafc",
      G = "#cbd5e1", F = "#fff1a8", E = "#ea580c",
    },
    rows = {
      "................KF................",
      "...............KOYK...............",
      "...........KK..KEYK..KK...........",
      "..........KHHK.KKKK.KHHK..........",
      "..........KHBKDDDDDDKBHK..........",
      "KKK.......KHKDDDDDDDDKHK.......KKK",
      "KRRKK.....KKDDDDMMDDDDKK.....KKRRK",
      "KRRRRKK...KDDDMMMMMMDDDKK..KKRRRRK",
      ".KSRRRRKKKKDDMMMMMMMMDDKKKKRRRRSK.",
      ".KSSRRRRRKDDDOKMMMMKODDDKRRRRRSSK.",
      "..KKSSRRRKDDDOOKMMKOODDDKRRRSSKK..",
      "....KKSSSKDDDDDDDDDDDDDDKSSSKK....",
      "......KKKKDDDWWWWWWWWDDDKKKK......",
      "..........KDDWGWGWGWGDDK..........",
      "...........KKDDDDDDDDKK...........",
      ".............KKKKKKKK.............",
    },
  },
  demon_skull = {
    palette = {
      K = "#181425", D = "#2a1624", M = "#521b36", R = "#991b1b", S = "#450a0a",
      H = "#dc2626", B = "#7f1d1d", O = "#f97316", Y = "#fde047", W = "#f8fafc",
      G = "#fca5a5", F = "#ffffff", E = "#dc2626",
    },
    rows = {
      "................KF................",
      "...............KFYK...............",
      "...........KK..KEYK..KK...........",
      "..........KHHK.KKKK.KHHK..........",
      "..........KHBKDDDDDDKBHK..........",
      "KKK.......KHKDDDDDDDDKHK.......KKK",
      "KRRKK.....KKDDDDMMDDDDKK.....KKRRK",
      "KRRRRKK...KDDDMMMMMMDDDKK..KKRRRRK",
      ".KSRRRRKKKKDDMMMMMMMMDDKKKKRRRRSK.",
      ".KSSRRRRRKDDDYKMMMMKYDDDKRRRRRSSK.",
      "..KKSSRRRKDDDYYKMMKYYDDDKRRRSSKK..",
      "....KKSSSKDDDDDDDDDDDDDDKSSSKK....",
      "......KKKKDDDWWWWWWWWDDDKKKK......",
      "..........KDDWGWGWGWGDDK..........",
      "...........KKDDDDDDDDKK...........",
      ".............KKKKKKKK.............",
    },
  },
  open_book = {
    palette = {
      K = "#181425", W = "#f8fafc", G = "#cbd5e1", T = "#475569",
    },
    rows = {
      "KKKKKKKKKKKKKKKKKK",
      "KWWWWWWK..KWWWWWWK",
      "KWTTTTWK..KWTTTTWK",
      "KWWWWWWK..KWWWWWWK",
      "KWTTWWWK..KWTTWWWK",
      "KWWWWWWK..KWWWWWWK",
      "KWTTTTWK..KWTTTTWK",
      "KWWWWWWK..KWWWWWWK",
      "KGGGGGGK..KGGGGGGK",
      "KKKKKKKK..KKKKKKKK",
    },
  },
  merchant = {
    palette = {
      K = "#181425", P = "#3b0764", M = "#6b21a8", W = "#f1f5f9", S = "#94a3b8", Y = "#facc15", C = "#38bdf8",
    },
    rows = {
      ".....KKKKKKKK.....",
      "....KPPPPPPPPK....",
      "...KPPPMMMMPPPK...",
      "..KPPKWWWWWWKPPK..",
      "..KPKWWKKKKWWKPK..",
      "..KPKWKCWWCKWKPK..",
      "..KPKWWWWWWWWKPK..",
      "...KKPWWWWWWPKK...",
      "..KKPPPPYYPPPPKK..",
      ".KPPPMMMYYMMMPPPK.",
      ".KPPMMMMMMMMMMPPK.",
      "..KKKKKKKKKKKKKK..",
    },
  },
  -- Pixel-art 2-story Watchtower Portal on left of battlefield (matching Slotbound!)
  watchtower = {
    palette = {
      K = "#181425",
      R = "#a8382b", -- warm shingled red roof
      O = "#d95b38", -- roof highlight
      B = "#6e4228", -- rich timber
      L = "#9c6239", -- light timber
      D = "#432818", -- dark wood shadow
      S = "#7e8699", -- stone base
      M = "#535869", -- stone shadow
      P = "#20172b", -- dark portal interior
      C = "#a855f7", -- summoning rune glow
      Y = "#fde047", -- torch highlight
    },
    rows = {
      "........KKKK........",
      "......KKORROKK......",
      ".....KOORRRROOK.....",
      "....KOORRRRRROOK....",
      "...KOOORRRRRROOOK...",
      "..KRRRRRRRRRRRRRRK..",
      ".KKKKKKKKKKKKKKKKKK.",
      "...KLLLLLLLLLLLLK...",
      "...KLKKBBYYBBKKLK...",
      "...KLKBPPPPPPBKLK...",
      "...KLLBPPPPPPBLLK...",
      "...KLLLLLLLLLLLLK...",
      "..KBBBBBBBBBBBBBBK..",
      "..KBDDDDDDDDDDDDBK..",
      "...KLLLLLLLLLLLLK...",
      "...KLBKKKKKKKKBLK...",
      "...KLBKPPPPPPKBLK...",
      "...KLBKPPCCPPKBLK...",
      "...KLBKPPCCPPKBLK...",
      "..KSSSKPPPPPPKSSSK..",
      "..KSMMKPPPPPPKMMSK..",
      ".KSSSSKPPPPPPKSSSSK.",
      ".KSMMMKKKKKKKKMMMSK.",
      ".KKKKKKKKKKKKKKKKKK.",
    },
  },
}

function M.getWingedSkullImage(isBoss)
  local key = isBoss and "demon_skull" or "winged_skull"
  local spec = DECOR_MATRICES[key]
  return M.buildSprite("decor_" .. key, spec.rows, spec.palette)
end

function M.getMerchantImage()
  local spec = DECOR_MATRICES.merchant
  return M.buildSprite("decor_merchant", spec.rows, spec.palette)
end

function M.getWatchtowerImage()
  local spec = DECOR_MATRICES.watchtower
  return M.buildSprite("decor_watchtower", spec.rows, spec.palette)
end

function M.getOpenBookImage()
  local spec = DECOR_MATRICES.open_book
  return M.buildSprite("decor_open_book", spec.rows, spec.palette)
end

function M.getSymbolImage(symbolId)
  local spec = SYMBOL_MATRICES[symbolId]
  if not spec then return nil end
  return M.buildSprite("sym_" .. symbolId, spec.rows, spec.palette)
end

function M.getUnitImage(unit, rarityId)
  return UnitArt.getUnitImage(unit, rarityId)
end

function M.getEnemyImage(foe)
  return UnitArt.getEnemyImage(foe)
end

local biomeCache = {}

function M.getBiomeForWave(wave)
  if wave <= 5 then return "meadow" end
  if wave <= 10 then return "cave" end
  if wave <= 15 then return "canyon" end
  return "ruins"
end

-- Chunky pixel-art biome builder on low-res ImageData (3x crisp texels matching Slotbound!)
local function createPixelPainter(bw, bh)
  local id = love.image.newImageData(bw, bh)
  local function setPx(x, y, c)
    local ix, iy = math.floor(x), math.floor(y)
    if ix >= 0 and ix < bw and iy >= 0 and iy < bh then
      id:setPixel(ix, iy, c[1], c[2], c[3], c[4] or 1)
    end
  end
  local function rect(x, y, rw, rh, c)
    for yy = math.floor(y), math.floor(y + rh - 1) do
      for xx = math.floor(x), math.floor(x + rw - 1) do
        setPx(xx, yy, c)
      end
    end
  end
  local function disc(cx, cy, r, c)
    local r2 = r * r
    for dy = -math.ceil(r), math.ceil(r) do
      for dx = -math.ceil(r), math.ceil(r) do
        if dx * dx + dy * dy <= r2 then
          setPx(cx + dx, cy + dy, c)
        end
      end
    end
  end
  return { id = id, w = bw, h = bh, px = setPx, rect = rect, disc = disc }
end

local function drawPixelTree(p, x, groundY, scale)
  local barkDark = Color.hex("#3f2718")
  local barkMid  = Color.hex("#613c24")
  local barkHi   = Color.hex("#855534")
  local leafDeep = Color.hex("#1b4332")
  local leafDark = Color.hex("#2d6a4f")
  local leafMid  = Color.hex("#52b788")
  local leafHi   = Color.hex("#95d5b2")

  local th = math.floor(28 * scale)
  local tw = math.floor(7 * scale)
  -- Roots & trunk
  p.rect(x - tw / 2, groundY - th, tw, th, barkMid)
  p.rect(x - tw / 2, groundY - th, 2, th, barkDark)
  p.rect(x + tw / 2 - 2, groundY - th, 2, th, barkHi)
  p.rect(x - tw / 2 - 3, groundY - 3, tw + 6, 3, barkDark)

  -- Crown blobs (Slotbound lush rounded leaf clusters)
  local cy = groundY - th - 6
  local blobs = {
    { dx = -10 * scale, dy = 2 * scale, r = 10 * scale },
    { dx = 10 * scale,  dy = 2 * scale, r = 10 * scale },
    { dx = -6 * scale,  dy = -7 * scale, r = 11 * scale },
    { dx = 6 * scale,   dy = -7 * scale, r = 11 * scale },
    { dx = 0,           dy = -13 * scale, r = 12 * scale },
  }
  for _, b in ipairs(blobs) do p.disc(x + b.dx, cy + b.dy + 2, b.r + 1, leafDeep) end
  for _, b in ipairs(blobs) do p.disc(x + b.dx, cy + b.dy, b.r, leafDark) end
  for _, b in ipairs(blobs) do p.disc(x + b.dx - 1, cy + b.dy - 2, math.max(3, b.r - 3), leafMid) end
  for _, b in ipairs(blobs) do p.disc(x + b.dx - 2, cy + b.dy - 4, math.max(2, b.r - 7), leafHi) end
end

local function drawPixelCloud(p, cx, cy, cw)
  local white = Color.hex("#ffffff")
  local shade = Color.hex("#dceef8")
  p.disc(cx - cw * 0.28, cy + 2, cw * 0.22, shade)
  p.disc(cx, cy - 3, cw * 0.30, shade)
  p.disc(cx + cw * 0.28, cy + 2, cw * 0.22, shade)
  p.rect(cx - cw * 0.34, cy, cw * 0.68, 8, shade)

  p.disc(cx - cw * 0.28, cy, cw * 0.21, white)
  p.disc(cx, cy - 5, cw * 0.28, white)
  p.disc(cx + cw * 0.28, cy, cw * 0.20, white)
  p.rect(cx - cw * 0.32, cy - 2, cw * 0.64, 7, white)
end

--- Builds a cached Slotbound-style chunky pixel-art biome image at 3x texel resolution.
function M.getBiomeCanvas(biomeId, w, h)
  local cacheKey = biomeId .. "_" .. tostring(w) .. "x" .. tostring(h)
  if biomeCache[cacheKey] then return biomeCache[cacheKey] end
  if not love or not love.image or not love.graphics then return nil end

  local bw = math.max(120, math.floor(w / 3))
  local bh = math.max(80, math.floor(h / 3))
  local p = createPixelPainter(bw, bh)
  local horizonY = math.floor(bh * 0.48)

  if biomeId == "meadow" then
    -- Crisp 3-band Slotbound sky (contiguous integer bands, zero seams!)
    local sky1 = Color.hex("#59b2e6")
    local sky2 = Color.hex("#79c7f0")
    local sky3 = Color.hex("#a4def9")
    local sy1 = math.floor(horizonY * 0.40)
    local sy2 = math.floor(horizonY * 0.74)
    p.rect(0, 0, bw, sy1, sky1)
    p.rect(0, sy1, bw, sy2 - sy1, sky2)
    p.rect(0, sy2, bw, horizonY - sy2, sky3)

    -- Giant glowing cream-gold sun on center horizon (classic Slotbound Meadow look!)
    local sunX, sunY = math.floor(bw * 0.56), horizonY - 12
    p.disc(sunX, sunY, 27, Color.hex("#fde68a"))
    p.disc(sunX, sunY, 22, Color.hex("#fef3c7"))
    p.disc(sunX, sunY, 17, Color.hex("#fffbeb"))

    -- Fluffy layered clouds
    drawPixelCloud(p, 58, horizonY - 10, 48)
    drawPixelCloud(p, 118, horizonY - 4, 52)
    drawPixelCloud(p, 186, horizonY - 8, 56)
    drawPixelCloud(p, 238, horizonY - 14, 42)

    -- Distant rolling green treeline ridge
    local hillDark = Color.hex("#2d6a4f")
    local hillMid = Color.hex("#40916c")
    for hx = 0, bw - 1 do
      local ridgeH = 9 + math.floor(math.sin(hx * 0.08) * 3 + math.cos(hx * 0.19) * 2)
      p.rect(hx, horizonY - ridgeH, 1, ridgeH, hillDark)
      if ridgeH > 8 then
        p.rect(hx, horizonY - ridgeH, 1, 3, hillMid)
      end
    end

    -- Lush meadow ground with natural pixel grass edge + battle dirt lane
    local gTop = Color.hex("#6bbf59")
    local gMid = Color.hex("#4f9d4b")
    local gDark = Color.hex("#3b7d3b")
    local pathLight = Color.hex("#96b368")
    p.rect(0, horizonY, bw, 4, gTop)
    p.rect(0, horizonY + 4, bw, bh - horizonY - 4, gMid)
    p.rect(0, bh - 12, bw, 12, gDark)

    -- Soft worn footpath along center-bottom battle corridor
    local pathY = horizonY + math.floor((bh - horizonY) * 0.42)
    for px = 18, bw - 14 do
      local waveOff = math.floor(math.sin(px * 0.05) * 2)
      p.rect(px, pathY + waveOff, 1, 14, pathLight)
      if ((px * 13) % 19) == 0 then
        p.px(px, pathY + waveOff + 5, Color.hex("#b7c985"))
      end
    end

    -- Scattered grass blades, dark turf shadows & wildflowers
    for gx = 4, bw - 5, 7 do
      for gy = horizonY + 3, bh - 5, 9 do
        local hVal = (gx * 31 + gy * 17) % 23
        if hVal < 5 then
          p.px(gx, gy, gDark)
          p.px(gx + 1, gy - 1, gTop)
          p.px(gx + 2, gy, gDark)
        elseif hVal == 9 then
          -- Tiny daisy/wildflower
          p.px(gx, gy, gDark)
          p.px(gx, gy - 1, Color.hex("#fef08a"))
        end
      end
    end

    -- Iconic left & right framing pixel trees (like Slotbound Steam screenshot #1!)
    drawPixelTree(p, 48, horizonY + 6, 1.05)
    drawPixelTree(p, bw - 28, horizonY + 8, 1.15)
    drawPixelTree(p, bw - 70, horizonY + 2, 0.72)

  elseif biomeId == "cave" then
    -- Deep obsidian cavern sky + jagged rock roof
    p.rect(0, 0, bw, horizonY, Color.hex("#15121f"))
    p.rect(0, horizonY - 18, bw, 18, Color.hex("#211c30"))

    -- Stalactites hanging from ceiling
    for sx = 0, bw - 1 do
      local stalH = 10 + ((sx * 7 + math.floor(sx / 9) * 19) % 24)
      if sx % 14 > 5 then stalH = math.floor(stalH * 0.55) end
      p.rect(sx, 0, 1, stalH, Color.hex("#2b253d"))
      if sx % 3 == 0 and stalH > 8 then
        p.rect(sx, 0, 1, stalH - 3, Color.hex("#3b3352"))
      end
    end

    -- Back rock pillars & glowing crystal veins
    for _, px in ipairs({ 54, 128, 198, 246 }) do
      p.rect(px - 8, 0, 16, horizonY, Color.hex("#231e33"))
      p.rect(px - 4, 0, 7, horizonY, Color.hex("#342d4a"))
      -- Glowing cyan/purple crystal cluster
      p.rect(px - 3, horizonY - 12, 3, 12, Color.hex("#6366f1"))
      p.rect(px, horizonY - 16, 3, 16, Color.hex("#38bdf8"))
      p.px(px + 1, horizonY - 14, Color.hex("#e0f2fe"))
    end

    -- Cavern slate stone floor
    p.rect(0, horizonY, bw, 4, Color.hex("#473f5e"))
    p.rect(0, horizonY + 4, bw, bh - horizonY - 4, Color.hex("#2e293d"))
    p.rect(0, bh - 10, bw, 10, Color.hex("#211d2b"))
    for tx = 4, bw - 6, 12 do
      for ty = horizonY + 8, bh - 6, 10 do
        if ((tx + ty) % 20) == 0 then
          p.rect(tx, ty, 6, 2, Color.hex("#1d1926"))
          p.rect(tx + 1, ty - 1, 3, 1, Color.hex("#4b4363"))
        end
      end
    end

  elseif biomeId == "canyon" then
    -- Warm sunset desert sky (contiguous bands)
    local cy1 = math.floor(horizonY * 0.38)
    local cy2 = math.floor(horizonY * 0.72)
    p.rect(0, 0, bw, cy1, Color.hex("#c97a53"))
    p.rect(0, cy1, bw, cy2 - cy1, Color.hex("#de9b6f"))
    p.rect(0, cy2, bw, horizonY - cy2, Color.hex("#eec395"))

    -- Distant stepped mesas (left, center-right, far right)
    local mesaBack = Color.hex("#9e583b")
    local mesaMid  = Color.hex("#87442d")
    local mesaLit  = Color.hex("#be714d")
    local mesas = {
      { x = 18, w = 52, h = 34 },
      { x = 84, w = 36, h = 24 },
      { x = 148, w = 68, h = 42 },
      { x = 224, w = 44, h = 36 },
    }
    for _, m in ipairs(mesas) do
      p.rect(m.x, horizonY - m.h, m.w, m.h, mesaBack)
      p.rect(m.x + 4, horizonY - m.h - 6, m.w - 10, 6, mesaBack)
      p.rect(m.x + m.w - 8, horizonY - m.h, 8, m.h, mesaMid)
      p.rect(m.x, horizonY - m.h, 4, m.h, mesaLit)
    end
    p.rect(0, horizonY - 8, bw, 8, Color.hex("#7a3c27"))

    -- Sandy desert canyon floor
    p.rect(0, horizonY, bw, 4, Color.hex("#d9a86c"))
    p.rect(0, horizonY + 4, bw, bh - horizonY - 4, Color.hex("#c28e56"))
    p.rect(0, bh - 10, bw, 10, Color.hex("#a3703f"))

    -- Desert pebbles & withered dead tree on right (matching Slotbound screenshot #4!)
    for px = 10, bw - 8, 13 do
      for py = horizonY + 8, bh - 8, 11 do
        if ((px * 7 + py) % 17) < 4 then
          p.rect(px, py, 3, 2, Color.hex("#946033"))
          p.px(px, py - 1, Color.hex("#e6ba83"))
        end
      end
    end
    -- Dead canyon tree right
    local tx = bw - 34
    p.rect(tx, horizonY - 26, 4, 28, Color.hex("#4a2c1d"))
    p.rect(tx - 8, horizonY - 22, 8, 2, Color.hex("#4a2c1d"))
    p.rect(tx + 4, horizonY - 19, 7, 2, Color.hex("#4a2c1d"))
    p.rect(tx - 10, horizonY - 26, 2, 4, Color.hex("#6b422d"))
    p.rect(tx + 10, horizonY - 24, 2, 5, Color.hex("#6b422d"))

  else
    -- Ancient overgrown twilight ruins (Slotbound screenshot #5!)
    local ry1 = math.floor(horizonY * 0.5)
    p.rect(0, 0, bw, ry1, Color.hex("#1b2124"))
    p.rect(0, ry1, bw, horizonY - ry1, Color.hex("#293335"))

    -- Broken stone temple pillars & carved guardian statue on right
    local stDark = Color.hex("#3b4445")
    local stMid  = Color.hex("#535e5e")
    local stMoss = Color.hex("#4e7844")
    for _, px in ipairs({ 58, 118, 174 }) do
      local ph = 28 + (px % 16)
      p.rect(px, horizonY - ph, 10, ph, stDark)
      p.rect(px + 1, horizonY - ph, 4, ph, stMid)
      p.rect(px - 2, horizonY - ph, 14, 4, stMid)
      p.rect(px + 2, horizonY - 8, 6, 4, stMoss)
    end
    -- Guardian dragon-head statue on right
    local sx = bw - 48
    p.rect(sx, horizonY - 38, 18, 38, stDark)
    p.rect(sx - 6, horizonY - 36, 22, 12, stMid)
    p.px(sx - 3, horizonY - 32, Color.hex("#facc15"))
    p.rect(sx + 2, horizonY - 16, 12, 6, stMoss)

    -- Mossy temple tile floor
    p.rect(0, horizonY, bw, 4, Color.hex("#4e5957"))
    p.rect(0, horizonY + 4, bw, bh - horizonY - 4, Color.hex("#323a3a"))
    p.rect(0, bh - 10, bw, 10, Color.hex("#23292a"))
    for tx = 6, bw - 8, 14 do
      p.rect(tx, horizonY + 10, 10, 1, Color.hex("#222829"))
      if tx % 28 == 6 then
        p.rect(tx + 2, horizonY + 3, 4, 2, stMoss)
      end
    end
  end

  local img = love.graphics.newImage(p.id)
  img:setFilter("nearest", "nearest")
  biomeCache[cacheKey] = img
  return img
end

return M
