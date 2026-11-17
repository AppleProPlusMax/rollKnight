class SoundEngine {
  constructor() {
    this.ctx = null;
    this.muted = false;
  }

  ensureContext() {
    if (this.muted) return null;
    if (typeof window === "undefined") return null;
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return null;
    if (!this.ctx) {
      this.ctx = new AudioCtx();
    }
    if (this.ctx.state === "suspended") {
      this.ctx.resume().catch(() => {});
    }
    return this.ctx;
  }

  toggleMute() {
    this.muted = !this.muted;
    return this.muted;
  }

  tone({ freq = 440, endFreq = null, type = "square", duration = 0.08, gain = 0.08, delay = 0 }) {
    const ctx = this.ensureContext();
    if (!ctx) return;

    const now = ctx.currentTime + delay;
    const osc = ctx.createOscillator();
    const vol = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq, now);
    if (endFreq !== null) {
      osc.frequency.exponentialRampToValueAtTime(Math.max(20, endFreq), now + duration);
    }

    vol.gain.setValueAtTime(0.0001, now);
    vol.gain.linearRampToValueAtTime(gain, now + 0.008);
    vol.gain.exponentialRampToValueAtTime(0.0001, now + duration);

    osc.connect(vol);
    vol.connect(ctx.destination);
    osc.start(now);
    osc.stop(now + duration + 0.01);
  }

  playLever() {
    this.tone({ freq: 180, endFreq: 95, type: "sawtooth", duration: 0.09, gain: 0.08 });
    this.tone({ freq: 340, endFreq: 220, type: "triangle", duration: 0.06, gain: 0.06, delay: 0.04 });
  }

  playReelTick() {
    this.tone({ freq: 520, endFreq: 420, type: "square", duration: 0.025, gain: 0.025 });
  }

  playReelStop(colIndex = 0) {
    const base = 130 + colIndex * 25;
    this.tone({ freq: base, endFreq: 65, type: "triangle", duration: 0.08, gain: 0.1 });
  }

  playNudge() {
    this.tone({ freq: 320, endFreq: 480, type: "triangle", duration: 0.06, gain: 0.07 });
  }

  playMatch(count = 1) {
    const notes = [523.25, 659.25, 783.99, 1046.5];
    const len = Math.min(notes.length, count + 1);
    for (let i = 0; i < len; i++) {
      this.tone({ freq: notes[i], type: "triangle", duration: 0.12, gain: 0.09, delay: i * 0.055 });
    }
  }

  playJackpot() {
    const fanfare = [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5];
    fanfare.forEach((f, idx) => {
      this.tone({ freq: f, type: "square", duration: 0.14, gain: 0.075, delay: idx * 0.065 });
    });
  }

  playHit() {
    this.tone({ freq: 170, endFreq: 75, type: "sawtooth", duration: 0.05, gain: 0.045 });
  }

  playBow() {
    this.tone({ freq: 620, endFreq: 260, type: "triangle", duration: 0.06, gain: 0.04 });
  }

  playMagic() {
    this.tone({ freq: 720, endFreq: 1120, type: "sine", duration: 0.09, gain: 0.045 });
  }

  playMeteor() {
    this.tone({ freq: 140, endFreq: 38, type: "sawtooth", duration: 0.25, gain: 0.11 });
    this.tone({ freq: 90, endFreq: 30, type: "square", duration: 0.22, gain: 0.07, delay: 0.02 });
  }

  playCoin() {
    this.tone({ freq: 987.77, type: "sine", duration: 0.05, gain: 0.05 });
    this.tone({ freq: 1318.51, type: "sine", duration: 0.1, gain: 0.05, delay: 0.045 });
  }

  playEvolve() {
    [440, 554.37, 659.25, 880].forEach((f, i) => {
      this.tone({ freq: f, type: "triangle", duration: 0.16, gain: 0.09, delay: i * 0.06 });
    });
  }

  playHurtBase() {
    this.tone({ freq: 140, endFreq: 55, type: "sawtooth", duration: 0.22, gain: 0.12 });
  }
}

export const audio = new SoundEngine();
