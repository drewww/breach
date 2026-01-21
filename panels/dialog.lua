local DialogPanel = Panel:extend("DialogPanel")

local wrap = require("util.helpers").wrap


local PANEL_WIDTH = 60
local PANEL_HEIGHT = 6

function DialogPanel:put(level)
   self.super.preparePut(self)
   local player = level:query(prism.components.PlayerController):first()

   -- Where do we get messages from? What is the data model?
   -- I want to be able to send messages from anywhere that
   -- add a message. and then have some keystroke that advances to the "next" message. So, it's a FIFO queue. And this shows the foremost element in the message queue. Now where is the queue stored?
   -- It could be a player component.

   if player then
      local dialog = player:expect(prism.components.Dialog)

      if dialog:size() > 0 then
         self.display:rectangle("fill", 0, 0, PANEL_WIDTH, PANEL_HEIGHT, " ", prism.Color4.TRANSPARENT,
            C.UI_BACKGROUND)

         local message = dialog:peek()

         if message then
            -- make space for a "profile" picture
            self.display:rectangle("fill", 2, 1, 6, 3, " ", prism.Color4.TRANSPARENT, prism.Color4.BLACK)

            self.display:print(2, 4, "CTRL  ", prism.Color4.WHITE, prism.Color4.DARKGREY)

            local lines = wrap(message, PANEL_WIDTH - 10)

            for i, line in ipairs(lines) do
               self.display:print(9, i, line, prism.Color4.WHITE,
                  C.UI_BACKGROUND)
            end
         end

         self.display:print(PANEL_WIDTH - 19, PANEL_HEIGHT - 1, " [SPACE] to dismiss", prism.Color4.WHITE,
            C.UI_BACKGROUND)
      end
   end

   self.super.cleanupPut(self)
end

return DialogPanel
