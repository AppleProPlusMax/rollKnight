import { SYMBOLS } from "../data/symbols.js";
import { MAX_WAVES } from "../data/waves.js";
import { xpNeededForTier } from "../data/units.js";
import { MAX_ROSTER } from "../systems/state.js";
import { ARENA } from "../systems/battle.js";
import { drawAllySprite, drawEnemySprite, drawSymbolIcon } from "./sprites.js";

const SLOT_PANEL = { x: 16, y: 78, w: 364, h: 626 };
const REEL_BOX = { x: 34, y: 152, w: 328, h: 222 };
const CELL_W = 100;
const CELL_H = 68;
const CELL_GAP = 8;

function drawButton(ctx, rect, label, opts = {}) {
  const {
    bg = "#2a314d",
    border = "#4b5682",
    text = "#f1f5f9",
    disabled = false,
    active = false,
    font = "bold 14px sans-serif",
    subLabel = null,
    hovered = false,
  } = opts;

  ctx.save();
  ctx.fillStyle = disabled ? "#1c2030" : active ? "#4f46e5" : hovered ? "#384266" : bg;
  ctx.strokeStyle = disabled ? "#2d3348" : active ? "#a5b4fc" : hovered ? "#8da2fb" : border;
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(rect.x, rect.y, rect.w, rect.h, 7);
  ctx.fill();
  ctx.stroke();

  ctx.fillStyle = disabled ? "#64748b" : text;
  ctx.font = font;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";
  if (subLabel) {
    ctx.fillText(label, rect.x + rect.w / 2, rect.y + rect.h / 2 - 9);
    ctx.font = "12px sans-serif";
    ctx.fillStyle = disabled ? "#475569" : "#fde047";
    ctx.fillText(subLabel, rect.x + rect.w / 2, rect.y + rect.h / 2 + 11);
  } else {
    ctx.fillText(label, rect.x + rect.w / 2, rect.y + rect.h / 2);
  }
  ctx.restore();
}

function drawHealthBar(ctx, x, y, w, h, ratio, color = "#4ade80") {
  ctx.fillStyle = "rgba(10, 12, 20, 0.85)";
  ctx.fillRect(x - 1, y - 1, w + 2, h + 2);
  ctx.fillStyle = "#334155";
  ctx.fillRect(x, y, w, h);
  ctx.fillStyle = color;
  ctx.fillRect(x, y, Math.max(0, Math.min(1, ratio)) * w, h);
}

export function renderGame(ctx, state, i18n, time, hoverPos) {
  const t = (k) => i18n.t(k);
  const hitboxes = [];
  const registerHit = (id, rect, payload = null) => {
    hitboxes.push({ id, rect, payload });
  };
  const isHover = (rect) =>
    hoverPos &&
    hoverPos.x >= rect.x &&
    hoverPos.x <= rect.x + rect.w &&
    hoverPos.y >= rect.y &&
    hoverPos.y <= rect.y + rect.h;

  ctx.save();
  if (state.screenShake > 0.2) {
    const sx = (Math.random() - 0.5) * state.screenShake;
    const sy = (Math.random() - 0.5) * state.screenShake;
    ctx.translate(sx, sy);
  }

  // Background
  ctx.fillStyle = "#11131e";
  ctx.fillRect(0, 0, 1280, 720);

  if (state.phase === "menu") {
    renderMenu(ctx, state, i18n, time, hitboxes, isHover);
    ctx.restore();
    return hitboxes;
  }

  // Top HUD Bar
  renderHud(ctx, state, i18n, registerHit, isHover);

  // Left Panel: 3x3 Slot Machine + Controls + Unit Inspector
  renderSlotPanel(ctx, state, i18n, registerHit, isHover);

  // Right Panel: Tactical Arena
  renderArena(ctx, state, i18n, time, registerHit, isHover);

  // Bottom Roster Strip
  renderRosterStrip(ctx, state, i18n, registerHit, isHover);

  // Jackpot Screen Flash
  if (state.jackpotFlash > 0) {
    ctx.fillStyle = `rgba(255, 223, 107, ${state.jackpotFlash * 0.25})`;
    ctx.fillRect(0, 0, 1280, 720);
  }

  // Floating texts across screen
  for (const ft of state.floatingTexts) {
    const alpha = Math.max(0, Math.min(1, ft.life / ft.maxLife));
    ctx.save();
    ctx.globalAlpha = alpha;
    ctx.font = `bold ${Math.round(14 * (ft.scale || 1))}px sans-serif`;
    ctx.textAlign = "center";
    ctx.strokeStyle = "#090a10";
    ctx.lineWidth = 3;
    ctx.strokeText(ft.text, ft.x, ft.y);
    ctx.fillStyle = ft.color;
    ctx.fillText(ft.text, ft.x, ft.y);
    ctx.restore();
  }

  // Modals (highest priority)
  if (state.coreModal) {
    renderCoreModal(ctx, state, i18n, registerHit, isHover);
  } else if (state.classModal) {
    renderClassModal(ctx, state, i18n, registerHit, isHover);
  } else if (state.phase === "gameover" || state.phase === "victory") {
    renderEndOverlay(ctx, state, i18n, registerHit, isHover);
  }

  ctx.restore();
  return hitboxes;
}

function renderMenu(ctx, state, i18n, time, hitboxes, isHover) {
  const t = (k) => i18n.t(k);

  // Subtle decorative grid
  ctx.strokeStyle = "rgba(99, 102, 241, 0.08)";
  ctx.lineWidth = 1;
  for (let x = 0; x < 1280; x += 40) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, 720);
    ctx.stroke();
  }
  for (let y = 0; y < 720; y += 40) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(1280, y);
    ctx.stroke();
  }

  // Title Card
  ctx.fillStyle = "#181c2e";
  ctx.strokeStyle = "#f6c945";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.roundRect(220, 74, 840, 572, 16);
  ctx.fill();
  ctx.stroke();

  // Animated symbol showcase
  const demoSymbols = ["shield", "bow", "staff", "horse", "skull", "coin", "crown"];
  demoSymbols.forEach((sym, i) => {
    const sx = 355 + i * 95;
    const sy = 152 + Math.sin(time * 3 + i) * 5;
    drawSymbolIcon(ctx, sym, sx, sy, 40);
  });

  ctx.fillStyle = "#ffdf6b";
  ctx.font = "bold 54px sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(t("title"), 640, 232);

  ctx.fillStyle = "#cbd5e1";
  ctx.font = "18px sans-serif";
  ctx.fillText(t("subtitle"), 640, 268);

  // Rules box
  ctx.fillStyle = "#111422";
  ctx.strokeStyle = "#334155";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.roundRect(290, 296, 700, 178, 10);
  ctx.fill();
  ctx.stroke();

  ctx.textAlign = "left";
  ctx.fillStyle = "#93c5fd";
  ctx.font = "bold 15px sans-serif";
  ctx.fillText(t("rulesTitle"), 316, 324);

  ctx.fillStyle = "#e2e8f0";
  ctx.font = "14px sans-serif";
  ctx.fillText(t("rule1"), 316, 356);
  ctx.fillText(t("rule2"), 316, 386);
  ctx.fillText(t("rule3"), 316, 416);
  ctx.fillText(t("rule4"), 316, 446);

  const startBtn = { x: 490, y: 500, w: 300, h: 64 };
  drawButton(ctx, startBtn, t("startRun"), {
    bg: "#d97706",
    border: "#fde047",
    text: "#ffffff",
    font: "bold 22px sans-serif",
    hovered: isHover(startBtn),
  });
  hitboxes.push({ id: "start_run", rect: startBtn });

  ctx.textAlign = "center";
  ctx.fillStyle = "#94a3b8";
  ctx.font = "13px sans-serif";
  ctx.fillText(t("continueHint"), 640, 594);

  const langBtn = { x: 960, y: 92, w: 74, h: 32 };
  drawButton(ctx, langBtn, t("langToggle"), { hovered: isHover(langBtn) });
  hitboxes.push({ id: "toggle_lang", rect: langBtn });
}

function renderHud(ctx, state, i18n, registerHit, isHover) {
  const t = (k) => i18n.t(k);

  ctx.fillStyle = "#171a2b";
  ctx.fillRect(0, 0, 1280, 62);
  ctx.strokeStyle = "#2b314d";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(0, 62);
  ctx.lineTo(1280, 62);
  ctx.stroke();

  // Brand
  ctx.fillStyle = "#ffdf6b";
  ctx.font = "bold 22px sans-serif";
  ctx.textAlign = "left";
  ctx.fillText("rollKnight", 20, 38);

  const pills = [
    { label: `${t("wave")}: ${state.wave}/${MAX_WAVES}`, color: "#93c5fd", x: 165, w: 128 },
    { label: `♥ ${state.hearts}/${state.maxHearts}`, color: "#fb7185", x: 305, w: 108 },
    { label: `🪙 ${state.gold}g`, color: "#facc15", x: 425, w: 112 },
    { label: `🎲 ${t("nudges")}: ${state.nudges}`, color: "#4ade80", x: 549, w: 128 },
    { label: `⚔ ${t("roster")}: ${state.roster.length}/${MAX_ROSTER}`, color: "#c084fc", x: 689, w: 130 },
  ];

  for (const p of pills) {
    ctx.fillStyle = "#0f1220";
    ctx.strokeStyle = "#2e3654";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.roundRect(p.x, 14, p.w, 34, 7);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = p.color;
    ctx.font = "bold 14px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(p.label, p.x + p.w / 2, 36);
  }

  // Controls on top right
  const speedBtn = { x: 868, y: 14, w: 94, h: 34 };
  drawButton(ctx, speedBtn, state.fastForward ? t("speed2x") : t("speed1x"), {
    active: state.fastForward,
    hovered: isHover(speedBtn),
  });
  registerHit("toggle_speed", speedBtn);

  const pauseBtn = { x: 970, y: 14, w: 86, h: 34 };
  drawButton(ctx, pauseBtn, state.paused ? t("resume") : t("pause"), {
    active: state.paused,
    hovered: isHover(pauseBtn),
  });
  registerHit("toggle_pause", pauseBtn);

  const muteBtn = { x: 1064, y: 14, w: 92, h: 34 };
  drawButton(ctx, muteBtn, state.audio.muted ? t("unmute") : t("mute"), {
    active: state.audio.muted,
    hovered: isHover(muteBtn),
  });
  registerHit("toggle_mute", muteBtn);

  const langBtn = { x: 1164, y: 14, w: 96, h: 34 };
  drawButton(ctx, langBtn, t("langToggle"), { hovered: isHover(langBtn) });
  registerHit("toggle_lang", langBtn);
}

function renderSlotPanel(ctx, state, i18n, registerHit, isHover) {
  const t = (k) => i18n.t(k);

  // Cabinet Panel
  ctx.fillStyle = "#191d30";
  ctx.strokeStyle = "#333c5c";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(SLOT_PANEL.x, SLOT_PANEL.y, SLOT_PANEL.w, SLOT_PANEL.h, 10);
  ctx.fill();
  ctx.stroke();

  ctx.fillStyle = "#f6c945";
  ctx.font = "bold 16px sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(t("slotTitle"), SLOT_PANEL.x + SLOT_PANEL.w / 2, SLOT_PANEL.y + 26);

  // Nudge UP buttons (above each column)
  for (let col = 0; col < 3; col++) {
    const cx = REEL_BOX.x + 6 + col * (CELL_W + CELL_GAP);
    const upRect = { x: cx, y: 116, w: CELL_W, h: 28 };
    const canNudge = !state.slot.spinning && state.nudges > 0 && !state.coreModal && !state.classModal;
    drawButton(ctx, upRect, `▲ ${t("nudgeUp")}`, {
      disabled: !canNudge,
      bg: "#21322b",
      border: "#4ade80",
      font: "bold 12px sans-serif",
      hovered: isHover(upRect),
    });
    registerHit("nudge", upRect, { col, dir: -1 });
  }

  // Reel Frame
  ctx.fillStyle = "#0e101a";
  ctx.strokeStyle = "#b48a3e";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.roundRect(REEL_BOX.x, REEL_BOX.y, REEL_BOX.w, REEL_BOX.h, 8);
  ctx.fill();
  ctx.stroke();

  const grid = state.slot.getGrid();
  const matchedCellSet = new Set();
  for (const m of state.slot.activeMatches) {
    for (const [c, r] of m.cells) {
      matchedCellSet.add(`${c},${r}`);
    }
  }

  // Draw 3x3 cells
  for (let col = 0; col < 3; col++) {
    for (let row = 0; row < 3; row++) {
      const cellX = REEL_BOX.x + 6 + col * (CELL_W + CELL_GAP);
      const cellY = REEL_BOX.y + 6 + row * (CELL_H + 3);
      const isMatch = !state.slot.spinning && matchedCellSet.has(`${col},${row}`);

      ctx.fillStyle = isMatch ? "#2d2614" : "#161a29";
      ctx.strokeStyle = isMatch ? "#ffdf6b" : "#272d45";
      ctx.lineWidth = isMatch ? 2.5 : 1;
      ctx.beginPath();
      ctx.roundRect(cellX, cellY, CELL_W, CELL_H, 6);
      ctx.fill();
      ctx.stroke();

      const symId = grid[col][row];
      const shiftY = state.slot.reelSpinning[col] ? (state.slot.reelVisualShift[col] - 0.5) * 18 : 0;
      drawSymbolIcon(ctx, symId, cellX + CELL_W / 2, cellY + CELL_H / 2 - 5 + shiftY, 36);

      ctx.font = "bold 11px sans-serif";
      ctx.textAlign = "center";
      ctx.fillStyle = SYMBOLS[symId]?.color || "#cbd5e1";
      ctx.fillText(i18n.pick(SYMBOLS[symId]?.name), cellX + CELL_W / 2, cellY + CELL_H - 7);
    }
  }

  // Draw payline connectors for active matches
  if (!state.slot.spinning && state.slot.activeMatches.length > 0) {
    for (const m of state.slot.activeMatches) {
      const pts = m.cells.map(([c, r]) => ({
        x: REEL_BOX.x + 6 + c * (CELL_W + CELL_GAP) + CELL_W / 2,
        y: REEL_BOX.y + 6 + r * (CELL_H + 3) + CELL_H / 2 - 4,
      }));
      ctx.strokeStyle = m.isPureJackpot ? "#ffdf6b" : "rgba(255, 223, 107, 0.72)";
      ctx.lineWidth = 3.5;
      ctx.beginPath();
      ctx.moveTo(pts[0].x, pts[0].y);
      ctx.lineTo(pts[1].x, pts[1].y);
      ctx.lineTo(pts[2].x, pts[2].y);
      ctx.stroke();
    }
  }

  // Nudge DOWN buttons (below each column)
  for (let col = 0; col < 3; col++) {
    const cx = REEL_BOX.x + 6 + col * (CELL_W + CELL_GAP);
    const dnRect = { x: cx, y: 382, w: CELL_W, h: 28 };
    const canNudge = !state.slot.spinning && state.nudges > 0 && !state.coreModal && !state.classModal;
    drawButton(ctx, dnRect, `▼ ${t("nudgeDown")}`, {
      disabled: !canNudge,
      bg: "#21322b",
      border: "#4ade80",
      font: "bold 12px sans-serif",
      hovered: isHover(dnRect),
    });
    registerHit("nudge", dnRect, { col, dir: 1 });
  }

  // Spin & Fight Buttons
  const spinCost = state.currentSpinCost();
  const spinRect = { x: 34, y: 422, w: 160, h: 54 };
  drawButton(ctx, spinRect, state.slot.spinning ? t("spinning") : t("spin"), {
    disabled: !state.canSpin(),
    bg: "#b45309",
    border: "#fbbf24",
    subLabel: spinCost === 0 ? t("free") : `${spinCost}g`,
    font: "bold 16px sans-serif",
    hovered: isHover(spinRect),
  });
  registerHit("spin", spinRect);

  const fightRect = { x: 202, y: 422, w: 160, h: 54 };
  const inBattle = state.phase === "battle";
  drawButton(ctx, fightRect, inBattle ? t("inBattle") : t("startWave"), {
    disabled: inBattle || !!state.coreModal || !!state.classModal,
    bg: "#15803d",
    border: "#4ade80",
    font: "bold 16px sans-serif",
    hovered: isHover(fightRect),
  });
  registerHit("start_wave", fightRect);

  // Selected Unit Inspector + Absorb / Dismiss Controls
  const sel = state.roster.find((u) => u.id === state.selectedUnitId) || state.roster[0];
  const card = { x: 34, y: 486, w: 328, h: 126 };
  ctx.fillStyle = "#121524";
  ctx.strokeStyle = "#2d3554";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.roundRect(card.x, card.y, card.w, card.h, 8);
  ctx.fill();
  ctx.stroke();

  if (sel) {
    const unitTitle = `${i18n.pick(sel.name)}  ${"★".repeat(sel.tier)}`;
    ctx.fillStyle = sel.accent;
    ctx.font = "bold 14px sans-serif";
    ctx.textAlign = "left";
    ctx.fillText(unitTitle, card.x + 12, card.y + 22);

    const needed = xpNeededForTier(sel.tier);
    const xpTxt = sel.tier >= 3 ? "MAX" : `${t("xpLabel")}: ${sel.xp}/${needed}`;
    ctx.fillStyle = "#94a3b8";
    ctx.font = "12px sans-serif";
    ctx.textAlign = "right";
    ctx.fillText(xpTxt, card.x + card.w - 12, card.y + 22);

    ctx.textAlign = "left";
    ctx.fillStyle = "#e2e8f0";
    ctx.font = "12px sans-serif";
    ctx.fillText(
      `${t("hp")}: ${Math.round(sel.hp)}/${sel.maxHp}   ${t("atk")}: ${sel.atk}   ${t("aspd")}: ${sel.aspd}`,
      card.x + 12,
      card.y + 44
    );
    ctx.fillStyle = "#a5b4fc";
    ctx.fillText(i18n.pick(sel.traits), card.x + 12, card.y + 64, card.w - 24);

    // Feed / Absorb Button & Dismiss Button
    const feedBtn = { x: card.x + 10, y: card.y + 82, w: 162, h: 34 };
    drawButton(ctx, feedBtn, state.feedMode ? t("cancelFeed") : t("feedMode"), {
      active: state.feedMode,
      disabled: state.roster.length < 2 || !!state.coreModal || !!state.classModal,
      bg: "#312e81",
      border: "#818cf8",
      font: "bold 13px sans-serif",
      hovered: isHover(feedBtn),
    });
    registerHit("toggle_feed", feedBtn);

    const sellGain = Math.round((sel.sellGold || 6) * sel.tier);
    const dismissBtn = { x: card.x + 180, y: card.y + 82, w: 138, h: 34 };
    drawButton(ctx, dismissBtn, `${t("dismissUnit").split(" ")[0]} +${sellGain}g`, {
      disabled: state.roster.length <= 1 || state.waveActive,
      bg: "#4c1d24",
      border: "#fb7185",
      font: "bold 12px sans-serif",
      hovered: isHover(dismissBtn),
    });
    registerHit("dismiss_unit", dismissBtn, { unitId: sel.id });
  }

  // Active Cores Summary Bar at bottom of slot panel
  ctx.fillStyle = "#121524";
  ctx.strokeStyle = "#2d3554";
  ctx.beginPath();
  ctx.roundRect(34, 622, 328, 68, 8);
  ctx.fill();
  ctx.stroke();

  ctx.fillStyle = "#94a3b8";
  ctx.font = "bold 11px sans-serif";
  ctx.textAlign = "left";
  ctx.fillText(`${t("coresBar")} (${state.cores.length})`, 46, 639);

  if (state.cores.length === 0) {
    ctx.fillStyle = "#475569";
    ctx.font = "12px sans-serif";
    ctx.fillText(t("noCores"), 46, 666);
  } else {
    state.cores.slice(0, 7).forEach((core, idx) => {
      const cx = 56 + idx * 43;
      const cy = 665;
      ctx.fillStyle = "#1e2438";
      ctx.strokeStyle = core.color;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.arc(cx, cy, 16, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.font = "16px sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(core.icon, cx, cy + 5);
    });
  }
}

function renderArena(ctx, state, i18n, time, registerHit, isHover) {
  const t = (k) => i18n.t(k);

  // Ground
  const grad = ctx.createLinearGradient(ARENA.x, ARENA.y, ARENA.x, ARENA.y + ARENA.h);
  grad.addColorStop(0, "#192228");
  grad.addColorStop(1, "#131922");
  ctx.fillStyle = grad;
  ctx.strokeStyle = "#333c5c";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(ARENA.x, ARENA.y, ARENA.w, ARENA.h, 10);
  ctx.fill();
  ctx.stroke();

  // Subtle tactical lane stripes
  ctx.fillStyle = "rgba(255,255,255,0.02)";
  for (let i = 0; i < 6; i += 2) {
    const laneH = (ARENA.h - 40) / 6;
    ctx.fillRect(ARENA.x + 42, ARENA.y + 20 + i * laneH, ARENA.w - 50, laneH);
  }

  // Castle Wall on left side of arena
  ctx.fillStyle = "#334155";
  ctx.fillRect(ARENA.x + 2, ARENA.y + 8, 36, ARENA.h - 16);
  ctx.fillStyle = "#475569";
  for (let y = ARENA.y + 18; y < ARENA.y + ARENA.h - 24; y += 36) {
    ctx.fillRect(ARENA.x + 32, y, 10, 20);
  }
  ctx.strokeStyle = "#64748b";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(ARENA.castleX, ARENA.y + 6);
  ctx.lineTo(ARENA.castleX, ARENA.y + ARENA.h - 6);
  ctx.stroke();

  // Meteor ground warnings & falling streaks
  for (const m of state.meteors) {
    ctx.save();
    ctx.strokeStyle = "rgba(255, 100, 50, 0.85)";
    ctx.fillStyle = "rgba(255, 80, 30, 0.16)";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(m.x, m.y, m.radius * m.progress, 0, Math.PI * 2);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(m.x, m.y, m.radius, 0, Math.PI * 2);
    ctx.stroke();

    const curX = m.startX + (m.x - m.startX) * m.progress;
    const curY = m.startY + (m.y - m.startY) * m.progress;
    ctx.fillStyle = "#ffbe0b";
    ctx.beginPath();
    ctx.arc(curX, curY, 12, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  // Draw all allies & enemies sorted by Y for depth
  const renderList = [
    ...state.roster.map((u) => ({ kind: "ally", y: u.y, obj: u })),
    ...state.summons.map((u) => ({ kind: "ally", y: u.y, obj: u })),
    ...state.enemies.map((e) => ({ kind: "enemy", y: e.y, obj: e })),
  ].sort((a, b) => a.y - b.y);

  for (const item of renderList) {
    if (item.kind === "ally") {
      const u = item.obj;
      const isSelected = u.id === state.selectedUnitId;
      const isSacrifice = u.id === state.feedSacrificeId;

      if (isSelected || isSacrifice || (state.feedMode && !u.isSummon && u.tier < 3)) {
        ctx.save();
        ctx.strokeStyle = isSacrifice ? "#f43f5e" : state.feedMode && state.feedSacrificeId ? "#4ade80" : "#ffdf6b";
        ctx.lineWidth = 2.5;
        ctx.beginPath();
        ctx.arc(u.x, u.y, (u.radius || 15) + 6, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
      }

      drawAllySprite(ctx, u, time);
      drawHealthBar(ctx, u.x - 16, u.y - (u.radius || 15) - 9, 32, 4, u.hp / u.maxHp, "#4ade80");

      if (!u.isSummon) {
        const hitR = { x: u.x - 20, y: u.y - 20, w: 40, h: 40 };
        registerHit("unit_arena", hitR, { unitId: u.id });
      }
    } else {
      const e = item.obj;
      drawEnemySprite(ctx, e, time);
      const bw = e.isBoss ? 56 : 30;
      drawHealthBar(ctx, e.x - bw / 2, e.y - e.radius - 10, bw, e.isBoss ? 6 : 4, e.hp / e.maxHp, "#fb7185");
      if (e.isBoss) {
        ctx.font = "bold 12px sans-serif";
        ctx.textAlign = "center";
        ctx.fillStyle = "#ffbe0b";
        ctx.fillText(i18n.pick(e.name), e.x, e.y - e.radius - 16);
      }
    }
  }

  // Projectiles
  for (const p of state.projectiles) {
    ctx.save();
    ctx.fillStyle = p.color;
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  // VFX
  for (const v of state.vfx) {
    const alpha = Math.max(0, v.life / v.maxLife);
    ctx.save();
    ctx.globalAlpha = alpha;
    if (v.kind === "particle") {
      ctx.fillStyle = v.color;
      ctx.fillRect(v.x - v.size / 2, v.y - v.size / 2, v.size, v.size);
    } else if (v.kind === "ring") {
      ctx.strokeStyle = v.color;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(v.x, v.y, v.radius * (1 - alpha * 0.4), 0, Math.PI * 2);
      ctx.stroke();
    } else if (v.kind === "slash") {
      ctx.strokeStyle = v.color;
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(v.x, v.y, v.radius, -0.9, 0.9);
      ctx.stroke();
    } else if (v.kind === "beam") {
      ctx.strokeStyle = v.color;
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.moveTo(v.x1, v.y1);
      ctx.lineTo(v.x2, v.y2);
      ctx.stroke();
    }
    ctx.restore();
  }

  // Feed Mode Banner inside Arena
  if (state.feedMode) {
    const msg = state.feedSacrificeId ? t("selectTarget") : t("selectSacrifice");
    ctx.fillStyle = "rgba(30, 27, 75, 0.9)";
    ctx.strokeStyle = "#818cf8";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.roundRect(ARENA.x + 170, ARENA.y + 12, 520, 34, 8);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#e0e7ff";
    ctx.font = "bold 13px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(`${msg}  —  ${t("feedModeHint")}`, ARENA.x + 430, ARENA.y + 33);
  }

  // Boss Warning Banner
  if (state.bossBannerTimer > 0) {
    ctx.fillStyle = "rgba(159, 18, 57, 0.88)";
    ctx.beginPath();
    ctx.roundRect(ARENA.x + 250, ARENA.y + 56, 360, 36, 8);
    ctx.fill();
    ctx.fillStyle = "#fde047";
    ctx.font = "bold 16px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(t("bossWarning"), ARENA.x + 430, ARENA.y + 79);
  }
}

function renderRosterStrip(ctx, state, i18n, registerHit, isHover) {
  const t = (k) => i18n.t(k);
  const strip = { x: ARENA.x, y: 638, w: ARENA.w, h: 66 };
  ctx.fillStyle = "#191d30";
  ctx.strokeStyle = "#333c5c";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.roundRect(strip.x, strip.y, strip.w, strip.h, 8);
  ctx.fill();
  ctx.stroke();

  if (state.roster.length === 0) {
    ctx.fillStyle = "#64748b";
    ctx.font = "13px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(t("clickUnitTip"), strip.x + strip.w / 2, strip.y + 37);
    return;
  }

  const slotW = 82;
  state.roster.forEach((u, idx) => {
    const rx = strip.x + 10 + idx * (slotW + 4);
    const ry = strip.y + 8;
    const rect = { x: rx, y: ry, w: slotW, h: 50 };
    const isSel = u.id === state.selectedUnitId;
    const isSac = u.id === state.feedSacrificeId;

    ctx.fillStyle = isSac ? "#4c1d24" : isSel ? "#2a3457" : isHover(rect) ? "#222944" : "#121524";
    ctx.strokeStyle = isSac ? "#fb7185" : isSel ? "#ffdf6b" : "#334155";
    ctx.lineWidth = isSel || isSac ? 2 : 1;
    ctx.beginPath();
    ctx.roundRect(rect.x, rect.y, rect.w, rect.h, 6);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = u.accent;
    ctx.font = "bold 11px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(i18n.pick(u.name), rx + slotW / 2, ry + 17, slotW - 6);

    ctx.fillStyle = u.tier >= 3 ? "#ffdf6b" : "#93c5fd";
    ctx.font = "11px sans-serif";
    ctx.fillText("★".repeat(u.tier), rx + slotW / 2, ry + 32);

    drawHealthBar(ctx, rx + 8, ry + 39, slotW - 16, 4, u.hp / u.maxHp, "#4ade80");
    registerHit("unit_card", rect, { unitId: u.id });
  });
}

function renderCoreModal(ctx, state, i18n, registerHit, isHover) {
  const t = (k) => i18n.t(k);
  ctx.fillStyle = "rgba(8, 10, 18, 0.82)";
  ctx.fillRect(0, 0, 1280, 720);

  ctx.fillStyle = "#181c2e";
  ctx.strokeStyle = "#f6c945";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.roundRect(180, 140, 920, 440, 14);
  ctx.fill();
  ctx.stroke();

  ctx.textAlign = "center";
  ctx.fillStyle = "#ffdf6b";
  ctx.font = "bold 28px sans-serif";
  ctx.fillText(t("coreModalTitle"), 640, 195);
  ctx.fillStyle = "#cbd5e1";
  ctx.font = "14px sans-serif";
  ctx.fillText(t("coreModalSub"), 640, 226);

  const choices = state.coreModal.choices;
  choices.forEach((core, idx) => {
    const card = { x: 224 + idx * 284, y: 262, w: 264, h: 270 };
    const hov = isHover(card);
    ctx.fillStyle = hov ? "#262d47" : "#121524";
    ctx.strokeStyle = hov ? "#ffdf6b" : core.color;
    ctx.lineWidth = hov ? 3 : 2;
    ctx.beginPath();
    ctx.roundRect(card.x, card.y, card.w, card.h, 10);
    ctx.fill();
    ctx.stroke();

    ctx.font = "44px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(core.icon, card.x + card.w / 2, card.y + 72);

    ctx.fillStyle = core.color;
    ctx.font = "bold 18px sans-serif";
    ctx.fillText(i18n.pick(core.name), card.x + card.w / 2, card.y + 118);

    ctx.fillStyle = "#e2e8f0";
    ctx.font = "13px sans-serif";
    wrapText(ctx, i18n.pick(core.desc), card.x + card.w / 2, card.y + 156, card.w - 32, 20);

    registerHit("pick_core", card, { coreId: core.id });
  });
}

function renderClassModal(ctx, state, i18n, registerHit, isHover) {
  const t = (k) => i18n.t(k);
  ctx.fillStyle = "rgba(8, 10, 18, 0.84)";
  ctx.fillRect(0, 0, 1280, 720);

  ctx.fillStyle = "#181c2e";
  ctx.strokeStyle = "#818cf8";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.roundRect(260, 145, 760, 430, 14);
  ctx.fill();
  ctx.stroke();

  ctx.textAlign = "center";
  ctx.fillStyle = "#a5b4fc";
  ctx.font = "bold 28px sans-serif";
  ctx.fillText(t("classModalTitle"), 640, 200);
  ctx.fillStyle = "#cbd5e1";
  ctx.font = "14px sans-serif";
  ctx.fillText(t("classModalSub"), 640, 232);

  const choices = state.classModal.choices;
  choices.forEach((cls, idx) => {
    const card = { x: 310 + idx * 340, y: 268, w: 320, h: 256 };
    const hov = isHover(card);
    ctx.fillStyle = hov ? "#262d47" : "#121524";
    ctx.strokeStyle = hov ? "#ffdf6b" : cls.color;
    ctx.lineWidth = hov ? 3 : 2;
    ctx.beginPath();
    ctx.roundRect(card.x, card.y, card.w, card.h, 10);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = cls.color;
    ctx.font = "bold 22px sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(`★★★ ${i18n.pick(cls.name)}`, card.x + card.w / 2, card.y + 56);

    ctx.fillStyle = "#fde047";
    ctx.font = "bold 13px sans-serif";
    ctx.fillText(
      `HP x${cls.hpMult}  ·  ATK x${cls.atkMult}  ·  ASPD x${cls.aspdMult}`,
      card.x + card.w / 2,
      card.y + 96
    );

    ctx.fillStyle = "#e2e8f0";
    ctx.font = "14px sans-serif";
    wrapText(ctx, i18n.pick(cls.desc), card.x + card.w / 2, card.y + 144, card.w - 36, 22);

    registerHit("pick_class", card, { classId: cls.id });
  });
}

function renderEndOverlay(ctx, state, i18n, registerHit, isHover) {
  const t = (k) => i18n.t(k);
  const isWin = state.phase === "victory";
  ctx.fillStyle = "rgba(8, 10, 18, 0.85)";
  ctx.fillRect(0, 0, 1280, 720);

  ctx.fillStyle = "#181c2e";
  ctx.strokeStyle = isWin ? "#f6c945" : "#fb7185";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.roundRect(360, 180, 560, 360, 14);
  ctx.fill();
  ctx.stroke();

  ctx.textAlign = "center";
  ctx.fillStyle = isWin ? "#ffdf6b" : "#fb7185";
  ctx.font = "bold 36px sans-serif";
  ctx.fillText(isWin ? t("victoryTitle") : t("gameOverTitle"), 640, 250);

  ctx.fillStyle = "#e2e8f0";
  ctx.font = "16px sans-serif";
  ctx.fillText(isWin ? t("victorySub") : t("gameOverSub"), 640, 294);

  ctx.fillStyle = "#94a3b8";
  ctx.font = "15px sans-serif";
  ctx.fillText(`${t("wave")}: ${state.wave}/${MAX_WAVES}   ·   ${t("kills")}: ${state.totalKills}`, 640, 342);

  const retryBtn = { x: 430, y: 410, w: 200, h: 52 };
  drawButton(ctx, retryBtn, t("restart"), {
    bg: "#d97706",
    border: "#fde047",
    font: "bold 16px sans-serif",
    hovered: isHover(retryBtn),
  });
  registerHit("start_run", retryBtn);

  const menuBtn = { x: 650, y: 410, w: 200, h: 52 };
  drawButton(ctx, menuBtn, t("backMenu"), { hovered: isHover(menuBtn) });
  registerHit("back_menu", menuBtn);
}

function wrapText(ctx, text, cx, y, maxWidth, lineHeight) {
  const words = text.includes(" ") ? text.split(" ") : [...text];
  const sep = text.includes(" ") ? " " : "";
  let line = "";
  let curY = y;
  for (let i = 0; i < words.length; i++) {
    const test = line + words[i] + sep;
    if (ctx.measureText(test).width > maxWidth && line !== "") {
      ctx.fillText(line.trim(), cx, curY);
      line = words[i] + sep;
      curY += lineHeight;
    } else {
      line = test;
    }
  }
  if (line) ctx.fillText(line.trim(), cx, curY);
}
