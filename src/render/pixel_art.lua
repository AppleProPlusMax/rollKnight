local Color = require("src.utils.color")

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
  local w = #rows[1]
  local id = love.image.newImageData(w, h)
  for y = 1, h do
    local row = rows[y]
    for x = 1, w do
      local ch = row:sub(x, x)
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

local SYMBOL_MATRICES = {
  shield = {
    palette = { B = "#2f5d96", L = "#70b5ff", W = "#e6f2ff", D = "#182c47" },
    rows = {
      "....DDDD....",
      "..DDBBBBDD..",
      ".DBBWWWWBBD.",
      ".DBBWLLWBBD.",
      ".DBLLWWLLBD.",
      ".DBLLWWLLBD.",
      ".DBBWLLWBBD.",
      "..DBWWWWBD..",
      "..DBBBBBBD..",
      "...DBBBBD...",
      "....DBBD....",
      ".....DD.....",
    },
  },
  bow = {
    palette = { W = "#9c6644", L = "#ddb892", S = "#e2e8f0", G = "#80ed99", D = "#1d2d24" },
    rows = {
      "...DDD......",
      "..DWWLD.....",
      ".DWWL.SD....",
      ".DWL..SD.DD.",
      "DWL...SGGGD.",
      "DWLGGGGGGGD.",
      "DWL...SGGGD.",
      ".DWL..SD.DD.",
      ".DWWL.SD....",
      "..DWWLD.....",
      "...DDD......",
      "............",
    },
  },
  staff = {
    palette = { P = "#c77dff", L = "#f3d9ff", G = "#7b2cbf", W = "#7f4f24", D = "#1b1429" },
    rows = {
      "......DDDD..",
      ".....DPPLPD.",
      "....DPLLLPGD",
      "....DPPPPGD.",
      ".....DGGGD..",
      "....DWDDDD..",
      "...DWD......",
      "..DWD.......",
      ".DWD........",
      "DWD.........",
      "DD..........",
      "............",
    },
  },
  horse = {
    palette = { O = "#e69d45", L = "#ffd596", B = "#9c5221", E = "#11131e", R = "#ef476f" },
    rows = {
      ".....RRR....",
      "....ROOLR...",
      "...ROOLLOO..",
      "..ROOLELOOO.",
      "..ROOOOOOO..",
      "..ROOBBBO...",
      "...ROOOO....",
      "..ROOOOOO...",
      "..ROO..OO...",
      "..OBO..OBO..",
      "..BB....BB..",
      "............",
    },
  },
  skull = {
    palette = { W = "#e2ece9", S = "#a8dadc", C = "#48cae4", D = "#14213d" },
    rows = {
      "...DDDDDD...",
      "..DWWWWWWWD.",
      ".DWWWWWWWWWD",
      ".DWDDWWDDWWD",
      ".DWDCDWDCDWD",
      ".DWWWWWWWWWD",
      "..DWWDDWWWD.",
      "..DWWWWWWWD.",
      "...DWDWDWD..",
      "...DWDWDWD..",
      "....DDDDD...",
      "............",
    },
  },
  coin = {
    palette = { Y = "#f6c945", L = "#fff3b0", O = "#d48c00", D = "#4a2c00" },
    rows = {
      "...DDDDDD...",
      "..DYYYYYYD..",
      ".DYLLLLLLYD.",
      ".DYLODDOLYD.",
      "DYLLODDOLLYD",
      "DYLLODDOLLYD",
      "DYLLODDOLLYD",
      ".DYLODDOLYD.",
      ".DYOOOOOOYD.",
      "..DYYYYYYD..",
      "...DDDDDD...",
      "............",
    },
  },
  crown = {
    palette = { Y = "#ffdf6b", L = "#fff8d6", O = "#e09f1f", R = "#ef476f", B = "#3a86ff", D = "#3d2800" },
    rows = {
      ".....DD.....",
      ".DD..YL..DD.",
      "DYLD.YY.DYLD",
      "DYYDDYYDDYYD",
      "DYLYYYYYYLYD",
      "DYYRYYYYBYYD",
      "DYYYYYYYYYYD",
      "DOOOOOOOOOOD",
      "DDDDDDDDDDDD",
      "............",
      "............",
      "............",
    },
  },
  jester = {
    palette = { P = "#ff4d6d", C = "#4cc9f0", Y = "#ffbe0b", W = "#f8f9fa", D = "#1d1e2c" },
    rows = {
      ".YY......YY.",
      "DPPD....DCCD",
      "DPPPD..DCCCD",
      ".DPPPDDCCCD.",
      "..DWWWWWWWD.",
      "..DWDDWDDWD.",
      "..DWWWWWWWD.",
      "..DWWRRRWWD.",
      "...DWWWWWD..",
      "..DPPYCCCPD.",
      "..DDDDDDDDD.",
      "............",
    },
  },
}

local UNIT_MATRICES = {
  warrior = {
    palette = { H = "#94a3b8", L = "#e2e8f0", B = "#3b82f6", S = "#60a5fa", W = "#cbd5e1", D = "#0f172a" },
    rows = {
      "....DDDD....",
      "...DHHHHHD..",
      "..DHHLLLHD..",
      "..DHDDDDHD..",
      "..DHHHHHHD..",
      ".DDSBBBBSDD.",
      "DSSDDBBBSDWD",
      "DSSDDLLLSDWD",
      "DSSDDBBBSDWD",
      ".DDDDDDDDDD.",
      "...DBB..BB..",
      "...DDD..DDD.",
    },
  },
  ranger = {
    palette = { G = "#22c55e", L = "#86efac", F = "#fde68a", W = "#92400e", S = "#e2e8f0", D = "#0f172a" },
    rows = {
      "....DDDD....",
      "...DGGGGGD..",
      "..DGLLLLGGD.",
      "..DGFDDFFGD.",
      "...DGGGGGD..",
      "..DDGGGGDW..",
      ".DGGGGGGDWS.",
      ".DGGLLGGDWS.",
      "..DGGGGGDWS.",
      "...DGGGDDW..",
      "...DGG..GG..",
      "...DDD..DDD.",
    },
  },
  mage = {
    palette = { P = "#7e22ce", L = "#d8b4fe", Y = "#fde047", F = "#fde68a", C = "#c084fc", D = "#0f172a" },
    rows = {
      ".....DD.....",
      "....DPPD....",
      "...DPPPPD...",
      "..DPPLLLPD..",
      ".DDDDDDDDDD.",
      "...DFDDFD...",
      "..DPPPPPPD.Y",
      "..DPCCCCPD.L",
      "..DPPPPPPDW.",
      "...DPPPPDW..",
      "...DPP..PW..",
      "...DDD..DD..",
    },
  },
  cavalry = {
    palette = { R = "#ef4444", A = "#f59e0b", L = "#fde68a", H = "#b45309", W = "#e2e8f0", D = "#0f172a" },
    rows = {
      "....RRR.....",
      "...DAAAD....",
      "...DALAD....",
      "..DDAAADD.W.",
      ".DAAAAAAW...",
      "DHHHHHHHWW..",
      "DHHHHHHHD...",
      ".DHHHHHHD...",
      ".DHH..HHD...",
      ".DHH..HHD...",
      ".DDD..DDD...",
      "............",
    },
  },
  necro = {
    palette = { T = "#14b8a6", L = "#99f6e4", P = "#1e293b", W = "#e2e8f0", D = "#090d16" },
    rows = {
      "...DDDDDD...",
      "..DPPPPPPD..",
      "..DPDDDDPD..",
      "..DPTWWTPD..",
      "...DPPPPD...",
      "..DPTTTTPD.L",
      "..DPTTTTPD.T",
      "..DPPPPPPDW.",
      "...DPPPPDW..",
      "...DPP..PW..",
      "...DDD..DD..",
      "............",
    },
  },
  champion = {
    palette = { Y = "#facc15", L = "#fef08a", W = "#f8fafc", R = "#ef4444", B = "#1e293b", D = "#1a1400" },
    rows = {
      "..DD.DD.DD..",
      "..YYDYYDYY..",
      "..DYYYYYYD..",
      "..DYDDDDYD..",
      "..DYYYYYYD..",
      ".DDWWYYWWDD.",
      "DWWDDYYDDWWD",
      "DWWDDLLDDWWD",
      ".DDYYYYYYDD.",
      "...DYY..YY..",
      "...DDD..DDD.",
      "............",
    },
  },
  jester = {
    palette = { P = "#ec4899", C = "#06b6d4", Y = "#facc15", W = "#f8fafc", D = "#111827" },
    rows = {
      ".YY......YY.",
      "DPPD....DCCD",
      ".DPPD..DCCD.",
      "..DWWWWWWWD.",
      "..DWDWWWDWD.",
      "..DWWWWWWWD.",
      "..DPYCCYPPD.",
      "..DPCCCCPPD.",
      "...DP..CPD..",
      "...DD..DDD..",
      "............",
      "............",
    },
  },
  skeleton = {
    palette = { W = "#e2e8f0", S = "#94a3b8", C = "#38bdf8", D = "#0f172a" },
    rows = {
      "....DDDD....",
      "...DWWWWD...",
      "..DWDWWDWD..",
      "..DWCWWCWD..",
      "...DWWWWD...",
      "...DDDDDD...",
      "..DWWWWWW...",
      "...DWSWSD...",
      "...DW..WD...",
      "...DW..WD...",
      "...DD..DD...",
      "............",
    },
  },
}

local ENEMY_MATRICES = {
  goblin = {
    palette = { G = "#65a30d", L = "#bef264", R = "#ef4444", B = "#78350f", D = "#0f172a" },
    rows = {
      ".DD......DD.",
      ".DGD....DGD.",
      "..DGGGGGGD..",
      "..DGRGGRGD..",
      "...DGGGGD...",
      "..DBBBBBBD..",
      ".DBBGGGGBBD.",
      "...DBBBBD...",
      "...DG..GD...",
      "...DD..DD...",
      "............",
      "............",
    },
  },
  slime = {
    palette = { C = "#06b6d4", L = "#a5f3fc", B = "#0e7490", D = "#082f49" },
    rows = {
      "............",
      "....DDDD....",
      "..DDLLLLDD..",
      ".DLLCCCCCCD.",
      ".DLCDCCDCCD.",
      "DLCCCCCCCCCD",
      "DCCCCCCCCCCD",
      "DBBBBBBBBBBD",
      ".DDDDDDDDDD.",
      "............",
      "............",
      "............",
    },
  },
  orc = {
    palette = { R = "#ea580c", L = "#fdba74", S = "#64748b", W = "#f8fafc", D = "#18181b" },
    rows = {
      "..DDDDDDDD..",
      ".DRRRRRRRRD.",
      ".DRRDRRDRRD.",
      ".DRWWRRWWLD.",
      "..DSSSSSSD..",
      "DDSSSSSSSSDD",
      "DSSRRRRRRSSD",
      "DSSRRRRRRSSD",
      ".DDSSSSSSDD.",
      "..DRR..RRD..",
      "..DDD..DDD..",
      "............",
    },
  },
  archer_foe = {
    palette = { P = "#7c3aed", L = "#c4b5fd", R = "#f43f5e", W = "#4c1d95", D = "#09090b" },
    rows = {
      "....DDDD....",
      "...DPPPPD...",
      "..DPPLLLPD..",
      "..DPRDDRPD..",
      "...DPPPPD...",
      "..WDPPPPD...",
      ".W.DPWWPD...",
      ".W.DPPPPD...",
      "..W.DP.PD...",
      "....DD.DD...",
      "............",
      "............",
    },
  },
  dark_knight = {
    palette = { A = "#475569", L = "#94a3b8", R = "#ef4444", Y = "#f59e0b", D = "#020617" },
    rows = {
      ".DD......DD.",
      ".DYD....DYD.",
      "..DAAAAAAD..",
      "..DADRRDAD..",
      "..DAAAAAAD..",
      ".DDAAAAAAADD",
      "DLLAAAAAAALD",
      ".DDAAAAAADD.",
      "..DAA..AAD..",
      "..DAA..AAD..",
      "..DDD..DDD..",
      "............",
    },
  },
  boss_beholder = {
    palette = { P = "#7e22ce", M = "#db2777", W = "#ffffff", R = "#ff0054", Y = "#ffbe0b", D = "#140021" },
    rows = {
      ".Y...YY...Y.",
      "..D..PP..D..",
      "..DPPPPPPD..",
      ".DPWWWWWWPD.",
      "DPWWWRRWWWPD",
      "DPWWWRRWWWPD",
      "DPWWWWWWWWPD",
      ".DPPPPPPPPD.",
      "..DPPMMPPD..",
      ".DY.DPPD.YD.",
      "D...D..D...D",
      "............",
    },
  },
}

function M.getSymbolImage(symbolId)
  local spec = SYMBOL_MATRICES[symbolId]
  if not spec then return nil end
  return M.buildSprite("sym_" .. symbolId, spec.rows, spec.palette)
end

function M.getUnitImage(unit)
  local key = unit.baseId or "warrior"
  local spec = UNIT_MATRICES[key] or UNIT_MATRICES.warrior
  return M.buildSprite("unit_" .. key, spec.rows, spec.palette)
end

function M.getEnemyImage(foe)
  local key = foe.typeId
  if key == "boss_abyss" then key = "boss_beholder" end
  if key == "boss_warlord" then key = "orc" end
  if key == "boss_dread" then key = "dark_knight" end
  local spec = ENEMY_MATRICES[key] or ENEMY_MATRICES.goblin
  return M.buildSprite("foe_" .. key, spec.rows, spec.palette)
end

return M
