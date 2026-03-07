local DeathState = spectrum.GameState:extend("DeathState")

local uicontrols = require "uicontrols"

--- @class DeathState : GameState
--- @overload fun(display: Display, overlayDisplay: Display): DeathState
function DeathState:__new(display, overlayDisplay)
   spectrum.GameState.__new(self)

   self.display = display
   self.overlayDisplay = overlayDisplay
   self.frames = 0
end

function DeathState:update(dt)
   uicontrols:update()
   self.frames = self.frames + 1
end

function DeathState:draw()
   self.display:clear()
   self.overlayDisplay:clear()

   -- Center the text on screen
   local centerX = SCREEN_WIDTH * 2
   local centerY = SCREEN_HEIGHT

   -- Draw main message
   local title = "BREACH FAILED"
   self.overlayDisplay:print(
      centerX - math.floor(#title / 2),
      centerY,
      title,
      prism.Color4.RED
   )

   -- Draw instruction
   local instruction = "Press ESC to return to title"
   self.overlayDisplay:print(
      centerX - math.floor(#instruction / 2),
      centerY + 2,
      instruction,
      prism.Color4.WHITE
   )

   self.display:draw()
   self.overlayDisplay:draw()
end

function DeathState:keypressed(key)
   if key == "escape" then
      -- Return to title screen
      self:getManager():enter(spectrum.gamestates.TitleState(self.display, self.overlayDisplay))
   end
end

return DeathState
