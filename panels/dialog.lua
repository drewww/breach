local DialogPanel = Panel:extend("DialogPanel")

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
         self.display:rectangle("fill", 0, 0, SCREEN_WIDTH * 4 + 1, 4, " ", prism.Color4.TRANSPARENT,
            prism.Color4.DARKGREY)
         local message = dialog:peek()

         if message then
            self.display:print(2, 1, message, prism.Color4.WHITE,
               prism.Color4.DARKGREY)
         end

         self.display:print(SCREEN_WIDTH * 4 - 30, 2, "Press [SPACE] to dismiss", prism.Color4.WHITE,
            prism.Color4.DARKGREY)
      end
   end

   self.super.cleanupPut(self)
end

return DialogPanel
