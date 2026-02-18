local TitleState = spectrum.GameState:extend("TitleState")

local controls = require "uicontrols"

--- @class TitleState : GameState
--- @overload fun(): GameState
function TitleState:__new(display, overlayDisplay)
   self.display = display
   self.overlayDisplay = overlayDisplay

   self.frames = 0

   -- Menu options configuration
   self.menuOptions = {
      { number = 1, label = "instructions", state = nil }, -- No state defined yet
      { number = 2, label = "tutorial",     state = "TutorialState", args = { "start" } },
      { number = 3, label = "combat",       state = "TutorialState", args = { "ranged" } },
      { number = 4, label = "sandbox",      state = "TutorialState", args = { "combat" } },
      { number = 5, label = "controls",     state = "RebindState" },
      { number = 6, label = "credits",      state = "CreditsState" },
   }
end

function TitleState:update(dt)
   -- Controls need to be updated each frame.
   controls:update()

   self.frames = self.frames + 1

   -- Check for menu option selection
   for _, option in ipairs(self.menuOptions) do
      local controlKey = option.number and ("num" .. option.number) or option.key
      if controls[controlKey] and controls[controlKey].pressed and option.state then
         local stateClass = spectrum.gamestates[option.state]
         if option.state == "TutorialState" or option.state == "PlayState" then
            local args = option.args or {}
            self.manager:push(stateClass(self.display, self.overlayDisplay, unpack(args)))
         else
            self.manager:push(stateClass())
         end
      end
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

   -- Render menu options dynamically
   local yPos = 5
   for _, option in ipairs(self.menuOptions) do
      local text = "[" .. option.number .. "] " .. option.label
      local color = option.state and prism.Color4.WHITE or prism.Color4.DARKGREY

      self.display:print(4, yPos, text, color)
      yPos = yPos + 1

      -- Add spacing after sandbox
      if option.number == 4 then
         yPos = yPos + 1
      end
   end

   self.display:print(1 - math.floor(self.frames / 200) - 6, SCREEN_HEIGHT,
      prototypeText,
      prism.Color4.BLACK, prism.Color4.YELLOW)

   self.display:draw()
end

return TitleState
