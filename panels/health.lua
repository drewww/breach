local HealthPanel = Panel:extend("HealthPanel")

function HealthPanel:put(level)
   self.super.preparePut(self)

   local player = level:query(prism.components.PlayerController):first()

   if player:has(prism.components.Health) then
      local health = player:expect(prism.components.Health)

      self.display:print(0, 1, "health", prism.Color4.WHITE,
         C.UI_BACKGROUND)

      for i = 1, health.initial do
         local color = i % 2 == 0 and prism.Color4.RED or prism.Color4.RED:lerp(prism.Color4.BLACK, 0.3)

         if i > health.value then
            color = prism.Color4.GREY
         end

         self.display:rectangle("fill", i - 1, 2, 1, 2, " ", prism.Color4.WHITE, color)
      end
   end

   self.super.cleanupPut(self)
end

return HealthPanel
