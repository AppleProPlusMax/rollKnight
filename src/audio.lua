local Audio = {}
Audio.__index = Audio

local SAMPLE_RATE = 22050

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
  local self = setmetatable({
    muted = false,
    bank = {},
  }, Audio)
  return self
end

function Audio:init()
  if not love or not love.audio then return end
  self.bank.lever = synthesizeTone(200, 95, "sawtooth", 0.09, 0.22)
  self.bank.tick = synthesizeTone(520, 420, "square", 0.025, 0.08)
  self.bank.stop0 = synthesizeTone(140, 65, "triangle", 0.08, 0.24)
  self.bank.stop1 = synthesizeTone(165, 70, "triangle", 0.08, 0.24)
  self.bank.stop2 = synthesizeTone(190, 75, "triangle", 0.08, 0.24)
  self.bank.nudge = synthesizeTone(320, 480, "triangle", 0.06, 0.20)
  self.bank.match = synthesizeSequence({ 523.25, 659.25, 783.99 }, "triangle", 0.075, 0.22)
  self.bank.jackpot = synthesizeSequence({ 523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5 }, "square", 0.075, 0.18)
  self.bank.hit = synthesizeTone(170, 75, "sawtooth", 0.05, 0.14)
  self.bank.bow = synthesizeTone(620, 260, "triangle", 0.06, 0.14)
  self.bank.magic = synthesizeTone(720, 1120, "sine", 0.09, 0.15)
  self.bank.meteor = synthesizeTone(140, 38, "sawtooth", 0.25, 0.28)
  self.bank.coin = synthesizeSequence({ 987.77, 1318.51 }, "sine", 0.055, 0.16)
  self.bank.evolve = synthesizeSequence({ 440, 554.37, 659.25, 880 }, "triangle", 0.07, 0.22)
  self.bank.hurt = synthesizeTone(140, 55, "sawtooth", 0.22, 0.28)
end

function Audio:toggleMute()
  self.muted = not self.muted
  return self.muted
end

function Audio:play(key)
  if self.muted then return end
  local src = self.bank[key]
  if not src then return end
  local clone = src:clone()
  clone:play()
end

function Audio:playLever() self:play("lever") end
function Audio:playReelTick() self:play("tick") end
function Audio:playReelStop(col) self:play("stop" .. tostring((col or 0) % 3)) end
function Audio:playNudge() self:play("nudge") end
function Audio:playMatch() self:play("match") end
function Audio:playJackpot() self:play("jackpot") end
function Audio:playHit() self:play("hit") end
function Audio:playBow() self:play("bow") end
function Audio:playMagic() self:play("magic") end
function Audio:playMeteor() self:play("meteor") end
function Audio:playCoin() self:play("coin") end
function Audio:playEvolve() self:play("evolve") end
function Audio:playHurtBase() self:play("hurt") end

return Audio
