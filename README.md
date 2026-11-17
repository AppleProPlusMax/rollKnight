# rollKnight (LÖVE 2D)

A roguelite slot-machine auto-battler defense game built with **LÖVE 11.5 (Lua)**.

## Features
- **3x3 Fate Reels & Nudges**: Match 8 paylines (rows, columns, diagonals) to summon units or earn gold, with Crown wildcards & Jackpots. Use limited per-wave Nudges to shift reels into winning lines.
- **Unit Absorption & Branching Class Evolution**: Sacrifice extra units to level up core fighters and evolve 3-Star units into specialized classes (Paladin, Berserker, Sniper, Windrunner, Archmage, Pyromancer, Vanguard, Dragon Knight, Necro Lord, Death Knight).
- **Core Relics**: Draft run-altering Cores after milestone waves.
- **20 Waves & Judgment Bosses**: Defend your castle across 20 waves including elite boss encounters.
- **Procedural Graphics & Retro Synth Audio**: All sprites and SFX are generated natively via `love.graphics` and `love.sound.newSoundData`, with `中文 / EN` toggle.

## Requirements
- [LÖVE 11.5](https://love2d.org/) (`love.exe` 64-bit)

## Run the Game

```powershell
love .
```

## Run Tests

```powershell
love . --test
```

## Package Standalone Windows `.exe` (Optional)

```powershell
# 1. Create rollKnight.love (excluding .git and dist)
Compress-Archive -Path conf.lua, main.lua, src, tests -DestinationPath rollKnight.zip -Force
Move-Item rollKnight.zip rollKnight.love -Force

# 2. Fuse with love.exe
cmd /c copy /b "C:\Program Files\LOVE\love.exe"+rollKnight.love rollKnight.exe
```
