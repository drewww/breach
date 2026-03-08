local VictoryState = spectrum.GameState:extend("VictoryState")

local uicontrols = require "uicontrols"
local helpers = require "util.helpers"

--- @class VictoryState : GameState
--- @overload fun(display: Display, overlayDisplay: Display, player?: Actor): VictoryState
function VictoryState:__new(display, overlayDisplay, player)
   spectrum.GameState.__new(self)

   self.display = display
   self.overlayDisplay = overlayDisplay
   self.frames = 0
   self.player = player

   -- Calculate profits and losses
   self.profits = helpers.calculateProfits(player)
   self.losses = helpers.calculateLosses(player)
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
   local centerY = SCREEN_HEIGHT - 15

   -- Draw profit/loss screen
   local instructionY = helpers.drawProfitLossScreen(
      self.overlayDisplay,
      centerX,
      centerY,
      self.profits,
      self.losses,
      "BREACH COMPLETE",
      prism.Color4.GREEN
   )

   -- Draw instruction
   local instruction = "Press ESC to return to title"
   self.overlayDisplay:print(
      centerX - math.floor(#instruction / 2),
      instructionY,
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
