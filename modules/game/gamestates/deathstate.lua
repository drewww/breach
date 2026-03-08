local DeathState = spectrum.GameState:extend("DeathState")

local uicontrols = require "uicontrols"
local helpers = require "util.helpers"

--- @class DeathState : GameState
--- @field overlayDisplay Display
--- @field display Display


--- @overload fun(display: Display, overlayDisplay: Display, player?: Actor): DeathState
function DeathState:__new(display, overlayDisplay, player)
   spectrum.GameState.__new(self)

   self.display = display
   self.overlayDisplay = overlayDisplay
   self.frames = 0
   self.player = player

   -- Calculate profits and losses
   self.profits = {} -- No profits on death
   self.losses = helpers.calculateLosses(player)
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
   local centerY = SCREEN_HEIGHT - 10

   -- Draw profit/loss screen
   local instructionY = helpers.drawProfitLossScreen(
      self.overlayDisplay,
      centerX,
      centerY,
      self.profits,
      self.losses,
      "BREACH FAILED",
      prism.Color4.RED
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

function DeathState:keypressed(key)
   if key == "escape" then
      -- Return to title screen
      self:getManager():enter(spectrum.gamestates.TitleState(self.display, self.overlayDisplay))
   end
end

return DeathState
