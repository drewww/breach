local DialogPanel = Panel:extend("DialogPanel")

function DialogPanel:put(level)
   self.super.preparePut(self)

   -- Where do we get messages from? What is the data model?
   -- I want to be able to send messages from anywhere that
   -- add a message. and then have some keystroke that advances to the "next" message. So, it's a FIFO queue. And this shows the foremost element in the message queue. Now where is the queue stored?
   -- It could be a player component.
   local player = level:query(prism.components.PlayerController):first()

   if player then
      local dialog = player:expect(prism.components.Dialog)
      local message = dialog:peek()

      if message then
         self.display:print(1, 1, message)
      end
   end

   self.super.cleanupPut(self)
end

return DialogPanel
