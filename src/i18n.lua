local TRANSLATIONS = {
  zh = {
    title = "rollKnight",
    subtitle = "转盘抽兵 · 拖拽布阵 · 吞噬进化 · 肉鸽塔防",
    startRun = "开始远征",
    continueHint = "20 波次挑战 · 含审判定向 Boss · 局内老虎机升级商店",
    rulesTitle = "核心玩法",
    rule1 = "1. 拉动左侧 3x3 老虎机连线招兵，可花 3g 锁定单列滚轮或用微调 (Nudge) 改命",
    rule2 = "2. 直接在战场拖拽己方单位调整站位，或拖到另一名己方单位身上直接【吞噬升星】",
    rule3 = "3. 单位自带稀有度 (普通/稀有/史诗/棱镜) 与词条，3星可选择进阶分支职业",
    rule4 = "4. 点击【改造商店】强化转盘与扩编上限，战斗中也能随时拉杆召唤援军！",
    wave = "波次",
    gold = "金币",
    hearts = "生命",
    nudges = "微调",
    roster = "兵力",
    spin = "拉杆抽奖",
    spinning = "转动中...",
    free = "免费",
    startWave = "开始战斗",
    inBattle = "战斗进行中",
    speed1x = "1x 速度",
    speed2x = "2x 加速",
    pause = "暂停",
    resume = "继续",
    mute = "静音",
    unmute = "音效",
    feedMode = "吞噬模式",
    feedModeHint = "选祭品再点主将吸收（也可在战场上直接拖拽单位叠放吞噬！）",
    cancelFeed = "取消吞噬",
    selectTarget = "选择目标单位",
    selectSacrifice = "选择祭品单位",
    dismissUnit = "遣散",
    shopBtn = "改造商店",
    shopTitle = "转盘与军备改造商店",
    shopSub = "花费金币永久强化命运转盘、兵力上限或修复城堡",
    close = "关闭",
    maxed = "已满级",
    lockReel = "锁",
    lockedReel = "已锁",
    coreModalTitle = "选择核心遗物 (Core)",
    coreModalSub = "核心效果将永久改变本局的转盘或战斗规则",
    classModalTitle = "选择转职分支",
    classModalSub = "该单位已达到 3 星进化门槛，选择一项进阶职业：",
    gameOverTitle = "防线失守",
    victoryTitle = "凯旋归来！",
    victorySub = "你成功击退了全部 20 波敌军与审判领主！",
    gameOverSub = "城堡被敌军攻破，再接再厉！",
    restart = "重新开始",
    backMenu = "返回主菜单",
    bossWarning = "! 审判波次来袭 !",
    slotTitle = "命运转盘",
    nudgeUp = "上推",
    nudgeDown = "下推",
    coresBar = "核心",
    noCores = "暂无",
    synergyBar = "羁绊",
    nextWave = "下波预告",
    bossTag = "BOSS 审判",
    clickUnitTip = "提示：战场中可直接拖拽单位调整站位，拖到队友身上直接吞噬升星",
    langToggle = "EN",
    xpLabel = "经验",
    hp = "生命",
    atk = "攻击",
    aspd = "攻速",
    kills = "击杀",
  },
  en = {
    title = "rollKnight",
    subtitle = "Slot-Machine Roguelite Auto-Battler Defense",
    startRun = "START RUN",
    continueHint = "20 Waves · Boss Judgment Waves · Slot & Army Upgrades",
    rulesTitle = "HOW TO PLAY",
    rule1 = "1. Spin the 3x3 reels to summon units. Lock reels (3g) or spend Nudges to bend odds",
    rule2 = "2. Drag units on the battlefield to reposition, or drop onto an ally to ABSORB & evolve!",
    rule3 = "3. Units roll Rarities (Normal/Rare/Epic/Prism) & traits; 3-Star unlocks branching classes",
    rule4 = "4. Visit the Upgrade Shop between waves & spin mid-battle to reinforce!",
    wave = "WAVE",
    gold = "GOLD",
    hearts = "HP",
    nudges = "NUDGE",
    roster = "ARMY",
    spin = "SPIN",
    spinning = "SPINNING...",
    free = "FREE",
    startWave = "FIGHT!",
    inBattle = "IN BATTLE",
    speed1x = "1x SPD",
    speed2x = "2x SPD",
    pause = "PAUSE",
    resume = "RESUME",
    mute = "MUTE",
    unmute = "SFX",
    feedMode = "ABSORB",
    feedModeHint = "Click sacrifice then target (or simply drag a unit onto an ally!)",
    cancelFeed = "CANCEL",
    selectTarget = "Select target unit",
    selectSacrifice = "Select sacrifice unit",
    dismissUnit = "Dismiss",
    shopBtn = "UPGRADES",
    shopTitle = "SLOT & ARMY UPGRADE SHOP",
    shopSub = "Spend Gold to permanently upgrade your slot machine, army cap, or bastion",
    close = "CLOSE",
    maxed = "MAXED",
    lockReel = "LOCK",
    lockedReel = "LOCKED",
    coreModalTitle = "CHOOSE A CORE RELIC",
    coreModalSub = "Cores permanently alter slot odds or combat rules for this run",
    classModalTitle = "CLASS EVOLUTION",
    classModalSub = "This unit reached 3-Star! Choose an advanced class specialization:",
    gameOverTitle = "CASTLE FALLEN",
    victoryTitle = "VICTORY!",
    victorySub = "You defeated all 20 waves and the Judgment Bosses!",
    gameOverSub = "Your defenses were breached. Spin again!",
    restart = "NEW RUN",
    backMenu = "MAIN MENU",
    bossWarning = "! JUDGMENT WAVE !",
    slotTitle = "FATE REELS",
    nudgeUp = "UP",
    nudgeDown = "DN",
    coresBar = "CORES",
    noCores = "None",
    synergyBar = "SYNERGY",
    nextWave = "NEXT WAVE",
    bossTag = "BOSS",
    clickUnitTip = "Tip: Drag units on the field to reposition, or drop onto an ally to absorb!",
    langToggle = "中文",
    xpLabel = "EXP",
    hp = "HP",
    atk = "ATK",
    aspd = "ASPD",
    kills = "Kills",
  },
}

local I18n = {}
I18n.__index = I18n

function I18n.new(lang)
  return setmetatable({ lang = lang or "zh" }, I18n)
end

function I18n:setLang(nextLang)
  self.lang = (nextLang == "en") and "en" or "zh"
end

function I18n:toggle()
  self.lang = (self.lang == "zh") and "en" or "zh"
  return self.lang
end

function I18n:t(key)
  local dict = TRANSLATIONS[self.lang] or TRANSLATIONS.en
  return dict[key] or key
end

function I18n:pick(obj)
  if not obj then return "" end
  if type(obj) == "string" then return obj end
  return obj[self.lang] or obj.zh or obj.en or ""
end

return I18n
