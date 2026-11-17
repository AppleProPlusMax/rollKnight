/**
 * Procedural pixel-art style sprites drawn onto 2D Canvas.
 */

export function drawSymbolIcon(ctx, symbolId, cx, cy, size = 38) {
  const s = size / 2;
  ctx.save();
  ctx.translate(cx, cy);

  switch (symbolId) {
    case "shield": {
      ctx.fillStyle = "#3a6ea5";
      ctx.beginPath();
      ctx.moveTo(0, -s * 0.85);
      ctx.lineTo(s * 0.78, -s * 0.48);
      ctx.lineTo(s * 0.65, s * 0.35);
      ctx.lineTo(0, s * 0.9);
      ctx.lineTo(-s * 0.65, s * 0.35);
      ctx.lineTo(-s * 0.78, -s * 0.48);
      ctx.closePath();
      ctx.fill();
      ctx.lineWidth = 2.5;
      ctx.strokeStyle = "#cde4ff";
      ctx.stroke();
      ctx.fillStyle = "#8cc4ff";
      ctx.fillRect(-3, -s * 0.45, 6, s * 0.95);
      ctx.fillRect(-s * 0.38, -3, s * 0.76, 6);
      break;
    }
    case "bow": {
      ctx.strokeStyle = "#d49b54";
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(-s * 0.15, 0, s * 0.72, -Math.PI * 0.42, Math.PI * 0.42);
      ctx.stroke();
      // Bowstring
      ctx.strokeStyle = "#e2e8f0";
      ctx.lineWidth = 1.6;
      ctx.beginPath();
      ctx.moveTo(s * 0.04, -s * 0.69);
      ctx.lineTo(s * 0.04, s * 0.69);
      ctx.stroke();
      // Arrow
      ctx.strokeStyle = "#80ed99";
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.moveTo(-s * 0.55, 0);
      ctx.lineTo(s * 0.72, 0);
      ctx.stroke();
      ctx.fillStyle = "#b5f0b8";
      ctx.beginPath();
      ctx.moveTo(s * 0.82, 0);
      ctx.lineTo(s * 0.52, -s * 0.22);
      ctx.lineTo(s * 0.52, s * 0.22);
      ctx.closePath();
      ctx.fill();
      break;
    }
    case "staff": {
      ctx.strokeStyle = "#8f5c38";
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.moveTo(-s * 0.45, s * 0.78);
      ctx.lineTo(s * 0.28, -s * 0.32);
      ctx.stroke();
      // Crystal orb
      ctx.fillStyle = "#c77dff";
      ctx.beginPath();
      ctx.arc(s * 0.38, -s * 0.46, s * 0.34, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#f3d9ff";
      ctx.beginPath();
      ctx.arc(s * 0.3, -s * 0.54, s * 0.12, 0, Math.PI * 2);
      ctx.fill();
      break;
    }
    case "horse": {
      // Stylized knight helm / steed silhouette
      ctx.fillStyle = "#e69d45";
      ctx.beginPath();
      ctx.moveTo(-s * 0.45, s * 0.72);
      ctx.lineTo(-s * 0.38, -s * 0.15);
      ctx.lineTo(-s * 0.05, -s * 0.75);
      ctx.lineTo(s * 0.2, -s * 0.5);
      ctx.lineTo(s * 0.65, -s * 0.2);
      ctx.lineTo(s * 0.52, s * 0.12);
      ctx.lineTo(s * 0.1, s * 0.08);
      ctx.lineTo(s * 0.28, s * 0.72);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = "#ffe5b4";
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.fillStyle = "#1b1d2b";
      ctx.fillRect(s * 0.18, -s * 0.32, 4, 4);
      break;
    }
    case "skull": {
      ctx.fillStyle = "#d8f3dc";
      ctx.beginPath();
      ctx.arc(0, -s * 0.14, s * 0.56, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillRect(-s * 0.32, s * 0.2, s * 0.64, s * 0.44);
      ctx.fillStyle = "#14213d";
      ctx.beginPath();
      ctx.arc(-s * 0.22, -s * 0.12, s * 0.15, 0, Math.PI * 2);
      ctx.arc(s * 0.22, -s * 0.12, s * 0.15, 0, Math.PI * 2);
      ctx.fill();
      // Glowing cyan eyes
      ctx.fillStyle = "#57d1c9";
      ctx.fillRect(-s * 0.25, -s * 0.15, 4, 4);
      ctx.fillRect(s * 0.18, -s * 0.15, 4, 4);
      break;
    }
    case "coin": {
      ctx.fillStyle = "#f6c945";
      ctx.beginPath();
      ctx.arc(0, 0, s * 0.68, 0, Math.PI * 2);
      ctx.fill();
      ctx.lineWidth = 3;
      ctx.strokeStyle = "#fff1a8";
      ctx.stroke();
      ctx.fillStyle = "#c98a12";
      ctx.fillRect(-3, -s * 0.34, 6, s * 0.68);
      break;
    }
    case "crown": {
      ctx.fillStyle = "#ffdf6b";
      ctx.beginPath();
      ctx.moveTo(-s * 0.72, s * 0.5);
      ctx.lineTo(-s * 0.8, -s * 0.45);
      ctx.lineTo(-s * 0.35, 0);
      ctx.lineTo(0, -s * 0.7);
      ctx.lineTo(s * 0.35, 0);
      ctx.lineTo(s * 0.8, -s * 0.45);
      ctx.lineTo(s * 0.72, s * 0.5);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = "#fff8d6";
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.fillStyle = "#ef476f";
      ctx.fillRect(-4, -s * 0.1, 8, 8);
      break;
    }
  }

  ctx.restore();
}

export function drawAllySprite(ctx, unit, time = 0) {
  const r = unit.radius || 15;
  const bob = unit.attackAnim > 0 ? -3 : Math.sin(time * 5 + unit.x * 0.05) * 1.5;

  ctx.save();
  ctx.translate(unit.x, unit.y + bob);

  // Shadow
  ctx.fillStyle = "rgba(0,0,0,0.38)";
  ctx.beginPath();
  ctx.ellipse(0, r * 0.88 - bob, r * 0.85, r * 0.34, 0, 0, Math.PI * 2);
  ctx.fill();

  // Overdrive aura
  if (unit.overdriveTimer > 0) {
    ctx.strokeStyle = "rgba(255, 110, 80, 0.85)";
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(0, 0, r + 6, 0, Math.PI * 2);
    ctx.stroke();
  }

  // Body
  ctx.fillStyle = unit.hitFlash > 0 ? "#ffffff" : unit.color;
  ctx.beginPath();
  ctx.roundRect(-r * 0.75, -r * 0.65, r * 1.5, r * 1.4, 5);
  ctx.fill();
  ctx.lineWidth = 2;
  ctx.strokeStyle = unit.tier >= 3 ? "#ffdf6b" : unit.tier === 2 ? "#cbd5e1" : "#1e2235";
  ctx.stroke();

  // Helmet / Head detail
  ctx.fillStyle = unit.hitFlash > 0 ? "#ffffff" : unit.accent;
  if (unit.baseId === "mage" || unit.classId === "archmage" || unit.classId === "pyromancer") {
    // Wizard hat
    ctx.beginPath();
    ctx.moveTo(-r * 0.75, -r * 0.5);
    ctx.lineTo(0, -r * 1.35);
    ctx.lineTo(r * 0.75, -r * 0.5);
    ctx.closePath();
    ctx.fill();
  } else if (unit.baseId === "ranger" || unit.classId === "sniper" || unit.classId === "windrunner") {
    // Hood + bow
    ctx.fillRect(-r * 0.5, -r * 0.9, r, r * 0.45);
    ctx.strokeStyle = "#f4d58d";
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(r * 0.55, 0, r * 0.6, -1.1, 1.1);
    ctx.stroke();
  } else if (unit.baseId === "cavalry" || unit.classId === "vanguard" || unit.classId === "dragonknight") {
    // Lance + plume
    ctx.fillStyle = "#ff595e";
    ctx.fillRect(-r * 0.2, -r * 1.15, r * 0.4, r * 0.45);
    ctx.strokeStyle = "#fff1a8";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(-r * 0.2, 2);
    ctx.lineTo(r * 1.35, -3);
    ctx.stroke();
  } else if (unit.baseId === "skeleton") {
    ctx.fillStyle = "#f1f5f9";
    ctx.beginPath();
    ctx.arc(0, -r * 0.35, r * 0.45, 0, Math.PI * 2);
    ctx.fill();
  } else {
    // Knight visor + shield / sword
    ctx.fillRect(-r * 0.55, -r * 0.95, r * 1.1, r * 0.42);
    ctx.fillStyle = "#161925";
    ctx.fillRect(-r * 0.15, -r * 0.78, r * 0.55, 3);
    ctx.fillStyle = "#e2e8f0";
    ctx.fillRect(r * 0.65, -r * 0.5, 4, r * 1.1);
  }

  // Tier stars above unit
  if (!unit.isSummon) {
    const stars = "★".repeat(unit.tier || 1);
    ctx.font = "bold 10px sans-serif";
    ctx.textAlign = "center";
    ctx.fillStyle = unit.tier >= 3 ? "#ffdf6b" : unit.tier === 2 ? "#7dd3fc" : "#cbd5e1";
    ctx.fillText(stars, 0, -r - 12);
  }

  ctx.restore();
}

export function drawEnemySprite(ctx, foe, time = 0) {
  const r = foe.radius || 14;
  const bob = Math.sin(time * 6 + foe.x * 0.04) * 1.8;

  ctx.save();
  ctx.translate(foe.x, foe.y + bob);

  // Shadow
  ctx.fillStyle = "rgba(0,0,0,0.42)";
  ctx.beginPath();
  ctx.ellipse(0, r * 0.85 - bob, r * 0.9, r * 0.35, 0, 0, Math.PI * 2);
  ctx.fill();

  if (foe.typeId === "boss_beholder" || foe.typeId === "boss_abyss") {
    // Floating Beholder with central eye & spikes
    ctx.strokeStyle = foe.accent;
    ctx.lineWidth = 2.5;
    for (let i = 0; i < 6; i++) {
      const ang = (i / 6) * Math.PI * 2 + time * 1.2;
      ctx.beginPath();
      ctx.moveTo(Math.cos(ang) * r * 0.7, Math.sin(ang) * r * 0.7);
      ctx.lineTo(Math.cos(ang) * r * 1.25, Math.sin(ang) * r * 1.25);
      ctx.stroke();
    }
    ctx.fillStyle = foe.hitFlash > 0 ? "#ffffff" : foe.color;
    ctx.beginPath();
    ctx.arc(0, 0, r, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = foe.accent;
    ctx.stroke();
    // Eye
    ctx.fillStyle = "#fff";
    ctx.beginPath();
    ctx.arc(-4, -2, r * 0.42, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#ff0054";
    ctx.beginPath();
    ctx.arc(-6, -2, r * 0.2, 0, Math.PI * 2);
    ctx.fill();
  } else if (foe.typeId === "slime") {
    ctx.fillStyle = foe.hitFlash > 0 ? "#ffffff" : foe.color;
    ctx.beginPath();
    ctx.arc(0, 2, r, Math.PI, 0);
    ctx.lineTo(r, r * 0.65);
    ctx.lineTo(-r, r * 0.65);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = "#0b132b";
    ctx.fillRect(-5, -2, 3, 4);
    ctx.fillRect(1, -2, 3, 4);
  } else {
    // Humanoid monster / boss
    ctx.fillStyle = foe.hitFlash > 0 ? "#ffffff" : foe.color;
    ctx.beginPath();
    ctx.roundRect(-r * 0.78, -r * 0.7, r * 1.56, r * 1.45, foe.isBoss ? 8 : 5);
    ctx.fill();
    ctx.lineWidth = foe.isBoss ? 3 : 1.8;
    ctx.strokeStyle = foe.isBoss ? "#ffbe0b" : "#181a24";
    ctx.stroke();

    // Horns / crown for boss/orc
    if (foe.isBoss || foe.typeId === "orc" || foe.typeId === "dark_knight") {
      ctx.fillStyle = foe.accent;
      ctx.beginPath();
      ctx.moveTo(-r * 0.6, -r * 0.65);
      ctx.lineTo(-r * 0.9, -r * 1.15);
      ctx.lineTo(-r * 0.25, -r * 0.65);
      ctx.fill();
      ctx.beginPath();
      ctx.moveTo(r * 0.6, -r * 0.65);
      ctx.lineTo(r * 0.9, -r * 1.15);
      ctx.lineTo(r * 0.25, -r * 0.65);
      ctx.fill();
    }

    // Angry eyes facing left
    ctx.fillStyle = "#ff4d6d";
    ctx.fillRect(-r * 0.45, -r * 0.25, 4, 4);
    ctx.fillRect(-r * 0.1, -r * 0.25, 4, 4);
  }

  ctx.restore();
}
