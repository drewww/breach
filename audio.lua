-- Audio Manager for Love2D
-- Handles sound effects with pre-loading and source management
-- SFX only - no music functionality

local Audio = {}

-- Private state
local sources = {}        -- Pre-loaded audio sources
local playingSources = {} -- Currently playing sources for cleanup
local masterVolume = 1.0  -- Global volume multiplier
local sfxVolume = 0.5     -- Sound effects volume

-- Sound effect definitions with their file paths
local soundEffects = {
   click = "sound/click.wav",
   dashEnd = "sound/dash_end.wav",
   dashStart = "sound/dash_start.wav",
   explode = "sound/explode_c.wav",
   hitWall = "sound/hit_wall.wav",
   bullet = "sound/impact_b.wav",
   killEnemy = "sound/kill_enemy.wav",
   laser = "sound/laser.wav",
   lose = "sound/lose_b.wav",
   loot = "sound/loot.wav",
   nextLevel = "sound/next_level.wav",
   reload = "sound/reload.wav",
   rocketLaunch = "sound/rocket_launch.wav",
   select = "sound/select_a.wav",
   selfDestruct = "sound/self_destruct.wav",
   shotgun = "sound/shotgun.wav",
   cyclone = "sound/swing.wav",
   open = "sound/open.wav",
   opened = "sound/opened.wav",
   playerHit = "sound/player_hit.wav"
}

-- Initialize the audio system
function Audio.init()
   print("Initializing Audio Manager...")

   -- Pre-load all sound effects
   local loadedCount = 0
   for name, filepath in pairs(soundEffects) do
      local success, source = pcall(love.audio.newSource, filepath, "static")
      if success then
         sources[name] = source
         loadedCount = loadedCount + 1
         print(string.format("Loaded sound: %s (%s)", name, filepath))
      else
         print(string.format("Failed to load sound: %s (%s) - %s", name, filepath, source))
      end
   end

   print(string.format("Audio Manager initialized with %d/%d sounds", loadedCount, #soundEffects))
end

-- Update function to clean up finished sources
-- Call this in love.update(dt)
function Audio.update()
   local toRemove = {}

   for i, source in ipairs(playingSources) do
      if not source or not source:isPlaying() then
         table.insert(toRemove, i)
      end
   end

   -- Remove stopped sources in reverse order to maintain indices
   for i = #toRemove, 1, -1 do
      table.remove(playingSources, toRemove[i])
   end
end

-- Play a sound effect by name
-- Optional parameters: volume (0.0-1.0), pitch (default 1.0), loop (default false)
function Audio.playSfx(name, volume, pitch, loop)
   local source = sources[name]
   if not source then
      print(string.format("Warning: Sound effect '%s' not found", name))
      return nil
   end

   -- Clone the source for simultaneous playback
   local playSource = source:clone()
   if not playSource then
      print(string.format("Warning: Failed to clone sound effect '%s'", name))
      return nil
   end

   -- Apply volume settings
   local finalVolume = (volume or 1.0) * sfxVolume * masterVolume
   playSource:setVolume(finalVolume)

   -- Apply pitch if specified
   if pitch then
      playSource:setPitch(pitch)
   end

   -- Set looping if specified
   if loop then
      playSource:setLooping(true)
   end

   -- Play and track the source
   playSource:play()
   table.insert(playingSources, playSource)

   return playSource
end

-- Volume controls
function Audio.setMasterVolume(volume)
   masterVolume = math.max(0, math.min(1, volume))
end

function Audio.setSfxVolume(volume)
   sfxVolume = math.max(0, math.min(1, volume))
end

-- Get volume levels
function Audio.getMasterVolume() return masterVolume end

function Audio.getSfxVolume() return sfxVolume end

-- Stop all audio
function Audio.stopAll()
   for _, source in ipairs(playingSources) do
      if source then
         source:stop()
      end
   end
   playingSources = {}
end

-- Utility function to check if a sound exists
function Audio.hasSound(name)
   return sources[name] ~= nil
end

-- Get list of available sounds
function Audio.getSoundNames()
   local names = {}
   for name, _ in pairs(sources) do
      table.insert(names, name)
   end
   return names
end

-- Convenience functions for common game sounds
function Audio.playClick() return Audio.playSfx("click", 0.7) end

function Audio.playSelect() return Audio.playSfx("select", 0.8) end

function Audio.playExplode() return Audio.playSfx("explode", 0.9) end

function Audio.playLaser() return Audio.playSfx("laser", 0.8) end

function Audio.playShotgun() return Audio.playSfx("shotgun", 0.9) end

function Audio.playRocket() return Audio.playSfx("rocketLaunch", 0.8) end

function Audio.playReload() return Audio.playSfx("reload", 0.7) end

function Audio.playImpact() return Audio.playSfx("bullet", 0.8) end

function Audio.playLoot() return Audio.playSfx("loot", 0.8) end

function Audio.playNextLevel() return Audio.playSfx("nextLevel", 0.9) end

function Audio.playDashStart() return Audio.playSfx("dashStart", 0.8) end

function Audio.playDashEnd() return Audio.playSfx("dashEnd", 0.8) end

function Audio.playLose() return Audio.playSfx("lose", 0.9) end

function Audio.playSelfDestruct() return Audio.playSfx("selfDestruct", 1.0) end

function Audio.playHitWall() return Audio.playSfx("hitWall", 0.8) end

function Audio.playKillEnemy() return Audio.playSfx("killEnemy", 0.1) end

function Audio.playCyclone() return Audio.playSfx("cyclone", 0.8) end

function Audio.playOpen() return Audio.playSfx("open", 0.7) end

function Audio.playOpened() return Audio.playSfx("opened", 0.7) end

function Audio.playPlayerHit() return Audio.playSfx("playerHit", 0.9) end

return Audio
