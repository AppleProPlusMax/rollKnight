local TRANSLATIONS = {
  zh = {
    title = "rollKnight",
    subtitle = "转盘抽兵 · 吞噬进化 · 肉鸽塔防",
    startRun = "开始远征",
    continueHint = "支持 20 波挑战 · 含 Boss 审判波次",
    rulesTitle = "核心玩法",
    rule1 = "1. 拉动左侧 3x3 老虎机，连成横/竖/斜线即可召唤士兵或获得金币",
    rule2 = "2. 每波拥有微调 (Nudge) 次数，上下推动滚轮把差一格的符号推成连线",
    rule3 = "3. 点击“吞噬模式”将弱小单位喂给主力，满经验即可晋升或选择转职分支",
    rule4 = "4. 击败敌人赚取金币，战斗中也能随时继续拉杆补兵，守住左侧城堡！",
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
    feedModeHint = "先选祭品兵种 -> 再选目标主将吸收升级 (右键取消)",
    cancelFeed = "取消吞噬",
    selectTarget = "选择要强化的目标单位",
    selectSacrifice = "选择要献祭吞噬的单位",
    dismissUnit = "遣散",
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
    jackpot = "JACKPOT! 黄金头奖!",
    bossWarning = "! 审判波次来袭 !",
    slotTitle = "命运转盘",
    nudgeUp = "上推",
    nudgeDown = "下推",
    coresBar = "已激活核心",
    noCores = "暂无核心遗物",
    clickUnitTip = "提示：点击己方单位查看属性或选中吞噬；战斗中也可随时拉杆召唤援军",
    langToggle = "EN",
    xpLabel = "吸收进度",
    hp = "生命",
    atk = "攻击",
    aspd = "攻速",
    kills = "击杀",
  },
  en = {
    title = "rollKnight",
    subtitle = "Slot-Machine Roguelite Auto-Battler Defense",
    startRun = "START RUN",
    continueHint = "20 Waves · Includes Boss Judgment Waves",
    rulesTitle = "HOW TO PLAY",
    rule1 = "1. Pull the 3x3 slot machine to match lines (rows, cols, diagonals) & summon units",
    rule2 = "2. Spend Nudges each wave to shift reels up/down into winning lines",
    rule3 = "3. Use Absorb Mode to sacrifice weak units into stronger ones and branch-evolve",
    rule4 = "4. Earn gold from kills & spin mid-battle to reinforce your frontline!",
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
    feedModeHint = "Select sacrifice -> Select target unit to evolve (Right-click cancel)",
    cancelFeed = "CANCEL",
    selectTarget = "Select target unit to empower",
    selectSacrifice = "Select unit to sacrifice",
    dismissUnit = "Dismiss",
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
    jackpot = "JACKPOT!",
    bossWarning = "! JUDGMENT WAVE !",
    slotTitle = "FATE REELS",
    nudgeUp = "UP",
    nudgeDown = "DN",
    coresBar = "ACTIVE CORES",
    noCores = "No Cores yet",
    clickUnitTip = "Tip: Click units to inspect or absorb; you can also spin mid-battle!",
    langToggle = "中文",
    xpLabel = "Essence",
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
