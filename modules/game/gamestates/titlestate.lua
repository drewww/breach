local TitleState = spectrum.GameState:extend("TitleState")

local controls = require "controls"

--- @class TitleState : GameState
--- @overload fun(): GameState
function TitleState:__new(display, overlayDisplay)
   self.display = display
   self.overlayDisplay = overlayDisplay

   self.frames = 0
end

function TitleState:update(dt)
   -- Controls need to be updated each frame.
   controls:update()

   self.frames = self.frames + 1

   if controls.dismiss.pressed then
      self.manager:enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "start"))
   end
end

function TitleState:draw()
   self.display:clear()

   prism.logger.info("HI")
   self.display:print(1 - math.floor(self.frames / 200), 1,
      "PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE",
      prism.Color4.BLACK, prism.Color4.YELLOW)

   self.display:print(2, 4, "BREACH", prism.Color4.BLACK, prism.Color4.BLUE)


   self.display:print(1 - math.floor(self.frames / 200) - 3, 20,
      "PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE PROTOTYPE",
      prism.Color4.BLACK, prism.Color4.YELLOW)

   self.display:draw()
end

return TitleState
