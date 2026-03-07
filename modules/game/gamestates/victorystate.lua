local VictoryState = spectrum.GameState:extend("VictoryState")

local uicontrols = require "uicontrols"

--- @class VictoryState : GameState
--- @overload fun(display: Display, overlayDisplay: Display): VictoryState
function VictoryState:__new(display, overlayDisplay)
   spectrum.GameState.__new(self)

   self.display = display
   self.overlayDisplay = overlayDisplay
   self.frames = 0
end

function VictoryState:update(dt)
   uicontrols:update()
   self.frames = self.frames + 1
end

function VictoryState:draw()
   self.display:clear()
   self.overlayDisplay:clear()

   -- Center the text on screen
   local centerX = SCREEN_WIDTH * 2
   local centerY = SCREEN_HEIGHT

   -- Draw main message
   local title = "BREACH COMPLETE"
   self.overlayDisplay:print(
      centerX - math.floor(#title / 2),
      centerY,
      title,
      prism.Color4.GREEN
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

function VictoryState:keypressed(key)
   if key == "escape" then
      self:getManager():enter(spectrum.gamestates.TitleState(self.display, self.overlayDisplay))
   end
end

return VictoryState
