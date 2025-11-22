--- @class OverlayLevelState : LevelState
--- A specialized LevelState that uses two displays instead of one, overload.
--- @field overlayDisplay Display The overlay display (which by convention has double resolution of the main Display)

---
--- @overload fun(level: Level, display: Display, microDisplay: Display): OverlayLevelState

local OverlayLevelState = spectrum.gamestates.LevelState:extend "OverlayLevelState"

--- @param level Level
--- @param display Display
--- @param overlayDisplay Display
function OverlayLevelState:__new(level, display, overlayDisplay)
   self.overlayDisplay = overlayDisplay
   OverlayLevelState.super.__new(self, level, display)
end

function OverlayLevelState:update(dt)
   OverlayLevelState.super.update(self, dt)

   self.overlayDisplay:update(self.level, dt)
end

--- @param message Message
function OverlayLevelState:handleMessage(message)
   -- if we are receiving an animation for the overlay display,
   -- dispatch it appropriately. otherwise, dispatch normally.
   if prism.messages.OverlayAnimationMessage:instanceOf(message) then
      self.overlayDisplay:yieldAnimation(message)
   else
      OverlayLevelState.super.handleMessage(self, message)
   end
end

return OverlayLevelState
