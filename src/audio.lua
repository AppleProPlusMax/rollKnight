local Audio = {}
Audio.__index = Audio

local SAMPLE_RATE = 22050
local MAX_POOL_PER_KEY = 4

local function synthesizeTone(freqStart, freqEnd, waveType, duration, volume)
  if not love or not love.sound or not love.audio then
    return nil
  end
  local samples = math.max(1, math.floor(SAMPLE_RATE * duration))
  local sd = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)
  local phase = 0
  for i = 0, samples - 1 do
    local t = i / samples
    local freq = freqStart + (freqEnd - freqStart) * t
    phase = phase + (2 * math.pi * freq) / SAMPLE_RATE

    local raw = 0
    if waveType == "square" then
      raw = math.sin(phase) >= 0 and 1 or -1
    elseif waveType == "sawtooth" then
      raw = 2 * ((phase / (2 * math.pi)) % 1) - 1
    elseif waveType == "triangle" then
      local p = (phase / (2 * math.pi)) % 1
      raw = 1 - 4 * math.abs(p - 0.5)
    else
      raw = math.sin(phase)
    end

    local attack = math.min(1, i / (SAMPLE_RATE * 0.008))
    local decay = math.max(0, 1 - t)
    sd:setSample(i, raw * volume * attack * decay)
  end
  return love.audio.newSource(sd, "static")
end

local function synthesizeSequence(notes, waveType, noteDur, volume)
  if not love or not love.sound or not love.audio then
    return nil
  end
  local noteSamples = math.max(1, math.floor(SAMPLE_RATE * noteDur))
  local totalSamples = noteSamples * #notes
  local sd = love.sound.newSoundData(totalSamples, SAMPLE_RATE, 16, 1)
  local phase = 0
  for nIdx, freq in ipairs(notes) do
    local base = (nIdx - 1) * noteSamples
    for i = 0, noteSamples - 1 do
      local t = i / noteSamples
      phase = phase + (2 * math.pi * freq) / SAMPLE_RATE
      local raw = 0
      if waveType == "square" then
        raw = math.sin(phase) >= 0 and 1 or -1
      elseif waveType == "triangle" then
        local p = (phase / (2 * math.pi)) % 1
        raw = 1 - 4 * math.abs(p - 0.5)
      else
        raw = math.sin(phase)
      end
      local env = math.min(1, i / (SAMPLE_RATE * 0.006)) * math.max(0, 1 - t)
      sd:setSample(base + i, raw * volume * env)
    end
  end
  return love.audio.newSource(sd, "static")
end

function Audio.new()
  return setmetatable({
    muted = false,
    bank = {},
    pools = {},
    lastPlayed = {},
  }, Audio)
end

function Audio:init()
  if not love or not love.audio then return end
  self.bank.lever = synthesizeTone(200, 95, "sawtooth", 0.09, 0.22)
  self.bank.tick = synthesizeTone(520, 420, "square", 0.025, 0.07)
  self.bank.stop0 = synthesizeTone(140, 65, "triangle", 0.08, 0.24)
  self.bank.stop1 = synthesizeTone(165, 70, "triangle", 0.08, 0.24)
  self.bank.stop2 = synthesizeTone(190, 75, "triangle", 0.08, 0.24)
  self.bank.nudge = synthesizeTone(320, 480, "triangle", 0.06, 0.20)
  self.bank.match = synthesizeSequence({ 523.25, 659.25, 783.99 }, "triangle", 0.075, 0.22)
  self.bank.jackpot = synthesizeSequence({ 523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5 }, "square", 0.075, 0.18)
  self.bank.hit = synthesizeTone(170, 75, "sawtooth", 0.05, 0.12)
  self.bank.bow = synthesizeTone(620, 260, "triangle", 0.06, 0.12)
  self.bank.magic = synthesizeTone(720, 1120, "sine", 0.09, 0.13)
  self.bank.meteor = synthesizeTone(140, 38, "sawtooth", 0.25, 0.26)
  self.bank.coin = synthesizeSequence({ 987.77, 1318.51 }, "sine", 0.055, 0.14)
  self.bank.evolve = synthesizeSequence({ 440, 554.37, 659.25, 880 }, "triangle", 0.07, 0.22)
  self.bank.hurt = synthesizeTone(140, 55, "sawtooth", 0.22, 0.26)
end

function Audio:toggleMute()
  self.muted = not self.muted
  return self.muted
end

function Audio:play(key, minInterval)
  if self.muted then return end
  local template = self.bank[key]
  if not template then return end

  local now = (love and love.timer) and love.timer.getTime() or 0
  if minInterval and self.lastPlayed[key] and (now - self.lastPlayed[key]) < minInterval then
    return
  end
  self.lastPlayed[key] = now

  local pool = self.pools[key]
  if not pool then
    pool = {}
    self.pools[key] = pool
  end

  for _, src in ipairs(pool) do
    if not src:isPlaying() then
      src:play()
      return
    end
  end

  if #pool < MAX_POOL_PER_KEY then
    local clone = template:clone()
    pool[#pool + 1] = clone
    clone:play()
  end
end

function Audio:playLever() self:play("lever", 0.05) end
function Audio:playReelTick() self:play("tick", 0.045) end
function Audio:playReelStop(col) self:play("stop" .. tostring((col or 0) % 3), 0.03) end
function Audio:playNudge() self:play("nudge", 0.04) end
function Audio:playMatch() self:play("match", 0.08) end
function Audio:playJackpot() self:play("jackpot", 0.15) end
function Audio:playHit() self:play("hit", 0.055) end
function Audio:playBow() self:play("bow", 0.055) end
function Audio:playMagic() self:play("magic", 0.06) end
function Audio:playMeteor() self:play("meteor", 0.12) end
function Audio:playCoin() self:play("coin", 0.06) end
function Audio:playEvolve() self:play("evolve", 0.1) end
function Audio:playHurtBase() self:play("hurt", 0.12) end

return Audio
