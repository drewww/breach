--- @class DualDisplayLevelState : LevelState
--- A specialized LevelState that uses two displays instead of one, overload.
---
--- @overload fun(level: Level, display: Display, microDisplay: Display): DualDisplayLevelState

local DualDisplayLevelState = spectrum.gamestates.LevelState:extend "DualDisplayLevelState"

--- @param level Level
--- @param display Display
--- @param microDisplay Display
function DualDisplayLevelState:__new(level, display, microDisplay)
   self.microDisplay = microDisplay
   DualDisplayLevelState.super.__new(self, level, display)
end

function DualDisplayLevelState:update(dt)
   DualDisplayLevelState.super.update(self, dt)

   self.microDisplay:update(self.level, dt)
end

--- @param message Message
function DualDisplayLevelState:handleMessage(message)
   -- if we are receiving an animation for the overlay display,
   -- dispatch it appropriately. otherwise, dispatch normally.
   if prism.messages.MicroAnimationMessage:instanceOf(message) then
      self.microDisplay:yieldAnimation(message)
   else
      DualDisplayLevelState.super.handleMessage(self, message)
   end
end

return DualDisplayLevelState
