# rollKnight (转运骑士)

A **Slotbound**-inspired roguelite **3×3 slot-machine auto-battler tower defense** game built with **LÖVE 11.5 (LuaJIT)**.

一款受《Slotbound》启发的 **3×3 拉霸机驱动 + 像素风自走棋塔防肉鸽**游戏，基于 **LÖVE 11.5 (LuaJIT)** 原生构建（零外部美术/音效素材依赖，全像素精灵与合成音效程序化生成）。

---

## 核心特色 / Key Features

### 1. 3×3 机械拉霸机与改命博弈 · 3×3 Mechanical Slot Machine
- **8 条赔付线 (8 Paylines)**：横排、竖列、对角线三连即可召唤对应兵种或赢取金币，包含 **弄臣 (`Jester`)** 与 **头奖王冠 (`Jackpot Crown`)** 百搭符号。
- **单列微调 (`Nudge`) 与保底槽 (`Luck Pity`)**：每波提供微调次数可上下拨动滚轮凑线（可凑线时高亮提示）；未中奖可积累 5 格幸运保底，满格下次免费必出中心百搭。
- **蓝水晶道具栏 (`0/8 Items Tray`)**：通过过波获得的 **蓝水晶 (`Crystals`)** 在骷髅商人店铺选购主动/被动改命遗物（如 `Trickster's Cube` 诡术魔方顺时针旋转左上角 2×2 格子、`Greedy Pearl` 贪婪珍珠、`Rewind Clock` 倒流怀表、`Gate Net` 城门捕网、`War Drum` 战鼓号角、`Frost Flask` 急冻魔药、`Golden Chalice` 圣金圣杯、`Lucky Clover` 四叶草徽记）。

### 2. 单位吞噬升星与分支转职 · Unit Absorption & Branching Class Evolution
- **7 大基础兵种与主动技能**：`Warrior`（铁盾卫士）、`Ranger`（翡翠游侠）、`Mage`（秘法学徒）、`Cavalry`（冲锋骑兵）、`Necro`（死灵术士）、`Jester`（弄臣）、`Champion`（王冠冠军），每个单位拥有独立冷却主动技、随机品质（`Normal` / `Rare` / `Epic` / `Prism`）与附加词条，并激活 **铁壁 / 翡翠 / 秘法 / 亡灵 / 王室** 五大羁绊。
- **吞噬升星与 12 种三阶转职**：拖拽单位到队友身上直接吞噬升星；升至 3 星触发分支转职（`Paladin`、`Berserker`、`Sniper`、`Windrunner`、`Archmage`、`Pyromancer`、`Vanguard`、`Dragon Knight`、`Necro Lord`、`Death Knight`、`Veil`、`Jester King`），满星后仍可继续吞噬强化面板。

### 3. 左半区战术布阵与四重像素生态 · Left-Half Deployment & 4 Pixel Biomes
- **战前左半区拖拽布阵**：开战前只允许在战场左半区调整站位，搭配右缘出兵的 20 波敌军与 4 位审判级 Boss（第 5/10/15/20 波），并设有 `1.0x / 1.3x / 1.6x` 三档难度。
- **4 套横版粗颗粒像素地形**：随着波次推进，羊皮纸卷轴战场自动切换 **草地 (`Meadow`) → 洞窟 (`Cave`) → 峡谷 (`Canyon`) → 古神庙遗迹 (`Ruins`)**，左侧配备两层像素瞭望塔传送门与召唤法阵。
- **翻页书图鉴 (`COLLECTION`) 与骷髅商人 (`Shop`)**：双页羊皮纸图鉴支持查看兵种立绘、属性、主动技能冷却与转职路线；核心遗物 (`Core Relics`) 三选一卷轴永久改变全局规则。

---

## 快速运行与打包 / Run, Test & Build

### 环境要求 / Requirements
- **Windows** 推荐直接使用仓库附带的 `tools\love-11.5-win64\`；或安装 [LÖVE 11.5](https://love2d.org/) (`64-bit`)。

### 运行游戏 / Run the Game
```powershell
.\tools\love-11.5-win64\lovec.exe .
```

### 运行单元测试与渲染冒烟测试 / Run Tests & Smoke Check
```powershell
# 运行全部 10 项核心逻辑单元测试
.\tools\love-11.5-win64\lovec.exe . --test

# 运行全界面渲染与交互冒烟测试（menu / spin / shopModal / guideModal / battle / coreModal / classModal / victory）
.\tools\love-11.5-win64\lovec.exe . --smoke
```

### 构建独立 Windows `.exe` / Package Standalone `.exe`
```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
# 输出文件 / Output: dist\rollKnight.exe
```

---

## 目录结构 / Project Structure
- `main.lua` — 游戏主循环、虚拟分辨率适配（1280×720）、拖拽/吞噬与左半区放置判定、`--test` / `--smoke` 入口
- `src/data/` — 符号赔付线 (`symbols.lua`)、兵种与转职 (`units.lua`)、核心遗物 (`cores.lua`)、水晶道具 (`items.lua`)、波次与敌军 (`waves.lua`)、商店升级 (`upgrades.lua`)
- `src/systems/` — 拉霸机滚轮 (`slot_machine.lua`)、战斗 AI/技能/状态异常 (`battle.lua`)、全局运行态与经济 (`state.lua`)
- `src/render/` — Q 版角色生成器 (`unit_art.lua`)、像素图标与 4 套地形生成 (`pixel_art.lua`)、精灵渲染 (`sprites.lua`)、主 UI 与弹窗渲染 (`renderer.lua`)
- `tests/run_tests.lua` — 10 项自动化单元测试
