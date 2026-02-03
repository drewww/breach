local TitleState = spectrum.GameState:extend("TitleState")

local controls = require "uicontrols"

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

   if controls.tutorial.pressed then
      self.manager:enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "start"))
   end

   if controls.combat.pressed then
      self.manager:enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "ranged"))
   end

   if controls.sandbox.pressed then
      self.manager:enter(spectrum.gamestates.TutorialState(self.display, self.overlayDisplay, "combat"))
   end
end

function TitleState:draw()
   self.display:clear()

   local prototypeText =
   "PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE   PROTOTYPE"
   local scrollOffset = math.floor(self.frames / 200) % #prototypeText
   self.display:print(1 - scrollOffset, 1,
      prototypeText,
      prism.Color4.BLACK, prism.Color4.YELLOW)

   self.display:print(2, 3, "BREACH", prism.Color4.BLACK, prism.Color4.BLUE)

   self.display:print(4, 5, "[i]nstructions", prism.Color4.DARKGREY)
   self.display:print(4, 6, "[t]utorial", prism.Color4.WHITE)
   self.display:print(4, 7, "[c]ombat", prism.Color4.WHITE)
   self.display:print(4, 8, "[s]andbox", prism.Color4.WHITE)


   self.display:print(1 - math.floor(self.frames / 200) - 6, 20,
      prototypeText,
      prism.Color4.BLACK, prism.Color4.YELLOW)

   self.display:draw()
end

return TitleState
