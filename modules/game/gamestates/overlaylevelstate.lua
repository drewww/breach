--- @class OverlayLevelState : LevelState
--- A specialized LevelState that uses two displays instead of one, overload.
--- @field overlayDisplay Display The overlay display (which by convention has double resolution of the main Display)
--- @field panels Panel[] An array of panels.

---
--- @overload fun(level: Level, display: Display, microDisplay: Display): OverlayLevelState

local OverlayLevelState = spectrum.gamestates.LevelState:extend "OverlayLevelState"

--- @param level Level
--- @param display Display
--- @param overlayDisplay Display
--- @param senses Senses[]
function OverlayLevelState:__new(level, display, overlayDisplay, senses)
   self.overlayDisplay = overlayDisplay
   self.display = display
   self.senses = senses

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
   if prism.messages.OverlayAnimationMessage:is(message) then
      ---@cast message AnimationMessage
      self.overlayDisplay:yieldAnimation(message)
   else
      spectrum.gamestates.LevelState.handleMessage(self, message)
   end
end

-- --- @param panel Panel
-- function OverlayLevelState:addPanel(panel)
--    table.insert(self.panels, panel)
-- end

-- --- @parm panel Panel
-- function OverlayLevelState:removePanel(panel)
--    table.remove(self.panels, panel)
-- end

-- function OverlayLevelState:drawPanels()

-- end

return OverlayLevelState
