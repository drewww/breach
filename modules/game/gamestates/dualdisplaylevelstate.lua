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

return DualDisplayLevelState
