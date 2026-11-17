import { audio } from "./audio.js";
import { createTranslator } from "./i18n.js";
import { GameState } from "./systems/state.js";
import { renderGame } from "./render/renderer.js";

const canvas = document.getElementById("game-canvas");
const ctx = canvas.getContext("2d");

const i18n = createTranslator("zh");
const state = new GameState(audio);

let hitboxes = [];
let hoverPos = null;
let lastTime = performance.now();
let totalTime = 0;

function toCanvasCoords(evt) {
  const rect = canvas.getBoundingClientRect();
  return {
    x: ((evt.clientX - rect.left) / rect.width) * canvas.width,
    y: ((evt.clientY - rect.top) / rect.height) * canvas.height,
  };
}

function handleUnitClick(unitId) {
  if (state.feedMode) {
    if (!state.feedSacrificeId) {
      state.feedSacrificeId = unitId;
      state.selectedUnitId = unitId;
    } else if (state.feedSacrificeId === unitId) {
      state.feedSacrificeId = null;
    } else {
      state.absorbUnit(state.feedSacrificeId, unitId);
    }
    return;
  }
  state.selectedUnitId = unitId;
}

function dispatchAction(hit) {
  switch (hit.id) {
    case "start_run":
      state.startRun();
      break;
    case "back_menu":
      state.phase = "menu";
      break;
    case "toggle_lang":
      i18n.toggle();
      break;
    case "toggle_speed":
      state.fastForward = !state.fastForward;
      break;
    case "toggle_pause":
      state.paused = !state.paused;
      break;
    case "toggle_mute":
      audio.toggleMute();
      break;
    case "spin":
      state.spin();
      break;
    case "nudge":
      state.nudgeReel(hit.payload.col, hit.payload.dir);
      break;
    case "start_wave":
      state.startWave();
      break;
    case "toggle_feed":
      if (state.roster.length >= 2) {
        state.feedMode = !state.feedMode;
        state.feedSacrificeId = state.feedMode ? state.selectedUnitId : null;
      }
      break;
    case "dismiss_unit":
      if (!state.waveActive) {
        state.dismissUnit(hit.payload.unitId);
      }
      break;
    case "unit_arena":
    case "unit_card":
      handleUnitClick(hit.payload.unitId);
      break;
    case "pick_core":
      state.chooseCore(hit.payload.coreId);
      break;
    case "pick_class":
      state.chooseClass(hit.payload.classId);
      break;
  }
}

canvas.addEventListener("mousemove", (evt) => {
  hoverPos = toCanvasCoords(evt);
});

canvas.addEventListener("mouseleave", () => {
  hoverPos = null;
});

canvas.addEventListener("contextmenu", (evt) => {
  evt.preventDefault();
  if (state.feedMode) {
    state.feedMode = false;
    state.feedSacrificeId = null;
  }
});

canvas.addEventListener("mousedown", (evt) => {
  if (evt.button !== 0) return;
  audio.ensureContext();
  const pos = toCanvasCoords(evt);
  // Check top-most hitboxes in reverse order (modals register last)
  for (let i = hitboxes.length - 1; i >= 0; i--) {
    const h = hitboxes[i];
    const r = h.rect;
    if (pos.x >= r.x && pos.x <= r.x + r.w && pos.y >= r.y && pos.y <= r.y + r.h) {
      dispatchAction(h);
      break;
    }
  }
});

window.addEventListener("keydown", (evt) => {
  if (evt.code === "Space") {
    evt.preventDefault();
    if (state.phase === "menu") {
      state.startRun();
    } else if (state.canSpin()) {
      state.spin();
    }
  } else if (evt.key === "f" || evt.key === "F") {
    state.fastForward = !state.fastForward;
  } else if (evt.key === "p" || evt.key === "P") {
    state.paused = !state.paused;
  } else if (evt.key === "Escape" && state.feedMode) {
    state.feedMode = false;
    state.feedSacrificeId = null;
  }
});

function frame(now) {
  const dt = (now - lastTime) / 1000;
  lastTime = now;
  totalTime += dt;

  state.update(dt);
  hitboxes = renderGame(ctx, state, i18n, totalTime, hoverPos);

  requestAnimationFrame(frame);
}

requestAnimationFrame(frame);
